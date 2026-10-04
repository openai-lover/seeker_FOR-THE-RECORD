#include "reflection_core.h"
#include <jni.h>
#include <memory>
#include <mutex>
#include <unordered_map>
#include <stdexcept>

namespace {
std::mutex handlesMutex;
std::unordered_map<jlong,std::shared_ptr<ReflectionCore>> handles;
jlong nextHandle = 1;
std::shared_ptr<ReflectionCore> acquire(jlong id) {
    std::lock_guard<std::mutex> lock(handlesMutex);
    auto found=handles.find(id);
    if(found==handles.end()) throw std::runtime_error("engine-closed");
    return found->second;
}
void fail(JNIEnv *env, const char *message) {
    env->ThrowNew(env->FindClass("java/lang/IllegalStateException"), message);
}
}
extern "C" JNIEXPORT jlong JNICALL
Java_app_workroom_seeker_1workroom_ReflectionNative_create(JNIEnv *env,jobject,jstring path) {
    const char *raw=env->GetStringUTFChars(path,nullptr);
    if(!raw) return 0;
    std::string file(raw); env->ReleaseStringUTFChars(path,raw);
    try {
        auto core=std::make_shared<ReflectionCore>(file);
        std::lock_guard<std::mutex> lock(handlesMutex);
        jlong id=nextHandle++; handles.emplace(id,std::move(core)); return id;
    } catch(const std::exception &e){ fail(env,e.what()); return 0; }
}
extern "C" JNIEXPORT jintArray JNICALL
Java_app_workroom_seeker_1workroom_ReflectionNative_select(JNIEnv *env,jobject,jlong id,jbyteArray input,jbyteArray background) {
    try {
        auto core=acquire(id);
        const auto length=env->GetArrayLength(input);
        if(length<=0||length>6000) throw std::runtime_error("empty-note");
        std::string note(length,'\0');
        env->GetByteArrayRegion(input,0,length,reinterpret_cast<jbyte*>(note.data()));
        if(env->ExceptionCheck())return nullptr;
        const auto contextLength=env->GetArrayLength(background);
        if(contextLength>6000) throw std::runtime_error("empty-note");
        std::string context(contextLength,'\0');
        env->GetByteArrayRegion(background,0,contextLength,reinterpret_cast<jbyte*>(context.data()));
        if(env->ExceptionCheck())return nullptr;
        auto selected=core->select(note,context);
        const jint values[3]={selected.question,selected.alternative,selected.uncertain?1:0};
        auto result=env->NewIntArray(3);
        if(result)env->SetIntArrayRegion(result,0,3,values);
        return result;
    } catch(const std::exception &e){ fail(env,e.what()); return nullptr; }
}
extern "C" JNIEXPORT void JNICALL
Java_app_workroom_seeker_1workroom_ReflectionNative_prepare(JNIEnv *env,jobject,jlong id) {
    try { acquire(id)->prepare(); } catch(const std::exception &e){ fail(env,e.what()); }
}
extern "C" JNIEXPORT void JNICALL
Java_app_workroom_seeker_1workroom_ReflectionNative_cancel(JNIEnv *,jobject,jlong id) {
    try { acquire(id)->cancel(); } catch(const std::exception &) {}
}
extern "C" JNIEXPORT void JNICALL
Java_app_workroom_seeker_1workroom_ReflectionNative_close(JNIEnv *,jobject,jlong id) {
    std::lock_guard<std::mutex> lock(handlesMutex); handles.erase(id);
}

extern "C" JNIEXPORT jfloatArray JNICALL
Java_app_workroom_seeker_1workroom_ReflectionNative_rank(JNIEnv *env,jobject,jlong id,jbyteArray query,jobjectArray records) {
    try {
        auto read=[&](jbyteArray bytes) {
            if(!bytes)throw std::runtime_error("empty-note");
            const auto length=env->GetArrayLength(bytes);
            if(length<=0 || length>6000)throw std::runtime_error("empty-note");
            std::string text(length,'\0');
            env->GetByteArrayRegion(bytes,0,length,reinterpret_cast<jbyte*>(text.data()));
            return text;
        };
        if(!records)throw std::runtime_error("empty-note");
        const auto count=env->GetArrayLength(records);
        if(count<=0 || count>32)throw std::runtime_error("empty-note");
        std::vector<std::string> texts;
        for(int i=0;i<count;++i) {
            auto bytes=static_cast<jbyteArray>(env->GetObjectArrayElement(records,i));
            texts.push_back(read(bytes));env->DeleteLocalRef(bytes);
            if(env->ExceptionCheck())return nullptr;
        }
        const auto input=read(query);
        if(env->ExceptionCheck())return nullptr;
        auto scores=acquire(id)->rank(input,texts);
        auto result=env->NewFloatArray(scores.size());
        if(result)env->SetFloatArrayRegion(result,0,scores.size(),scores.data());
        return result;
    }catch(const std::exception &e){fail(env,e.what());return nullptr;}
}
