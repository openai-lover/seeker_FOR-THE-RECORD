#include "reflection_core.h"
#include <algorithm>
#include <cmath>
#include <mutex>
#include <numeric>
#include <stdexcept>

static std::once_flag backend;
// Authored topic descriptions, not user records. Embedded once per engine load.
// This uses neural semantic matching, with no keyword rules or remote inference.
static const std::array<std::array<const char *,6>,5> topics = {{
    {{"I am unsure of my motive. Why did I make that choice?",
      "I need to clarify what I wanted from this decision.",
      "I cannot explain the purpose of starting this, or what I hoped to achieve.",
      "내가 왜 이런 선택을 했는지, 진짜 원하는 것이 무엇인지 모르겠다.",
      "그때 내가 중요하게 여긴 가치와 선택의 동기를 알고 싶다.",
      "무엇을 위해 시작했는지 내 목적이 분명하지 않다."}},
    {{"My actual experience was different from what I expected.",
      "I did not follow the plan I had written before acting.",
      "I expected one result but experienced something different instead.",
      "미리 세운 계획과 실제 행동이 달랐다. 그 차이를 돌아보고 싶다.",
      "기대했던 결과와 현실이 달라서 놀랐다.",
      "처음 예상한 것과 실제로 일어난 일을 비교하고 싶다."}},
    {{"Other people's opinions and pressure drove my choice.",
      "I followed the crowd because I was afraid of missing out.",
      "I copied someone else's choice because their confidence persuaded me.",
      "주변 사람들이 하는 것을 따라갔다. 남의 말과 비교가 선택에 영향을 줬다.",
      "그 사람의 확신과 추천에 이끌려 내 판단 없이 따라 했다.",
      "소외되고 싶지 않아서 다른 사람들의 분위기에 맞췄다."}},
    {{"I want to decide what to check before making a future decision.",
      "What is one criterion to verify next time before acting?",
      "I need a practical question to ask myself before my next choice.",
      "다음번 선택을 하기 전에 확인할 구체적인 기준을 정하고 싶다.",
      "앞으로 결정하기 전에 살펴볼 항목을 하나 만들고 싶다.",
      "다음 선택 전에 무엇부터 점검해야 할까?"}},
    {{"An action helped me this time and I want to repeat it.",
      "I found a useful habit that worked well and will keep doing it.",
      "This approach made things better. I want to preserve what worked.",
      "이번에 해본 행동이 실제로 도움이 됐다. 효과가 있었으니 다음에도 반복하고 싶다.",
      "잘됐던 방법을 다음에도 계속 쓰고 싶다.",
      "이 습관 덕분에 좋은 변화가 있었다. 계속 이어가고 싶다."}}
}};
bool ReflectionCore::abort(void *opaque) {
    return static_cast<ReflectionCore *>(opaque)->cancelled.load();
}
ReflectionCore::ReflectionCore(const std::string &path, int threads) {
    std::call_once(backend, [] {
        llama_log_set([](ggml_log_level,const char *,void *) {},nullptr);
        llama_backend_init();
    });
    auto mp=llama_model_default_params(); mp.n_gpu_layers=0;
    model=llama_model_load_from_file(path.c_str(),mp);
    if(!model) throw std::runtime_error("model-load");
    auto cp=llama_context_default_params();
    cp.n_ctx=512; cp.n_batch=512; cp.n_ubatch=512;
    cp.n_threads=threads; cp.n_threads_batch=threads;
    cp.embeddings=true; cp.pooling_type=LLAMA_POOLING_TYPE_MEAN;
    cp.attention_type=LLAMA_ATTENTION_TYPE_NON_CAUSAL;
    cp.abort_callback=abort; cp.abort_callback_data=this;
    context=llama_init_from_model(model,cp);
    if(!context) {llama_model_free(model);model=nullptr;throw std::runtime_error("context-load");}
}
ReflectionCore::~ReflectionCore() {
    if(context) llama_free(context);
    if(model) llama_model_free(model);
}
std::vector<float> ReflectionCore::embed(const std::string &text) {
    if(cancelled.load()) throw std::runtime_error("cancelled");
    const std::string input="query: "+text;
    const auto *vocab=llama_model_get_vocab(model);
    int count=-llama_tokenize(vocab,input.data(),input.size(),nullptr,0,true,false);
    if(count<=0||count>6000) throw std::runtime_error("context-limit");
    std::vector<llama_token> tokens(count);
    if(llama_tokenize(vocab,input.data(),input.size(),tokens.data(),count,true,false)!=count)
        throw std::runtime_error("tokenize");
    // Preserve EOS when a multilingual background exceeds the encoder window.
    if(tokens.size()>512) {tokens.resize(512);tokens.back()=llama_vocab_eos(vocab);}
    auto batch=llama_batch_init(tokens.size(),0,1); batch.n_tokens=tokens.size();
    for(int i=0;i<batch.n_tokens;++i) {
        batch.token[i]=tokens[i];batch.pos[i]=i;batch.n_seq_id[i]=1;
        batch.seq_id[i][0]=0;batch.logits[i]=true;
    }
    const int status=llama_encode(context,batch); llama_batch_free(batch);
    if(cancelled.load()) throw std::runtime_error("cancelled");
    if(status!=0) throw std::runtime_error("encode");
    const float *data=llama_get_embeddings_seq(context,0);
    if(!data) throw std::runtime_error("embeddings");
    std::vector<float> result(data,data+llama_model_n_embd(model));
    double norm=0;for(float value:result)norm+=value*value;norm=std::sqrt(norm);
    if(!std::isfinite(norm)||norm<=0)throw std::runtime_error("embeddings");
    for(float &value:result)value/=norm;
    return result;
}
ReflectionChoice ReflectionCore::select(const std::string &note,const std::string &background) {
    if(note.empty()||note.size()>6000||background.size()>6000) throw std::runtime_error("empty-note");
    if(prototypes.empty()) {
        std::vector<std::vector<std::vector<float>>> prepared;
        for(const auto &topic:topics) {
            prepared.emplace_back();
            for(const auto *text:topic) prepared.back().push_back(embed(text));
        }
        prototypes=std::move(prepared);
    }
    auto primary=embed(note);
    auto full=background.empty()||background==note?primary:embed(background);
    ReflectionChoice result{};
    for(int i=0;i<5;++i) {
        double best=-1;
        for(const auto &prototype:prototypes[i]) {
            const double main=std::inner_product(primary.begin(),primary.end(),prototype.begin(),0.0);
            const double contextScore=std::inner_product(full.begin(),full.end(),prototype.begin(),0.0);
            best=std::max(best,0.75*main+0.25*contextScore);
        }
        result.scores[i]=best;
    }
    std::array<int,5> order={0,1,2,3,4};
    std::sort(order.begin(),order.end(),[&](int a,int b){return result.scores[a]>result.scores[b];});
    result.question=order[0]+1;result.alternative=order[1]+1;
    result.margin=result.scores[order[0]]-result.scores[order[1]];
    // A conservative product heuristic, not a calibrated probability.
    result.uncertain=result.margin<0.018||result.scores[order[0]]<0.82;
    if(cancelled.load())throw std::runtime_error("cancelled");
    return result;
}
