#pragma once
#include "llama.h"
#include <array>
#include <atomic>
#include <string>
#include <vector>

struct ReflectionChoice {
    int question;
    int tokens;
    int alternative;
    bool uncertain;
    double margin;
    std::array<double, 5> scores;
};

// Worker-thread owned. Each note gets an empty inference context.
class ReflectionCore {
public:
    ReflectionCore(const std::string & path, int threads = 4);
    ~ReflectionCore();
    ReflectionCore(const ReflectionCore &) = delete;
    ReflectionCore & operator=(const ReflectionCore &) = delete;
    ReflectionChoice select(const std::string &note, const std::string &background = "");
    std::vector<float> rank(const std::string &query, const std::vector<std::string> &records);
    void prepare() { cancelled.store(false); }
    void cancel() { cancelled.store(true); }
private:
    llama_model * model = nullptr;
    llama_context * context = nullptr;
    std::atomic<bool> cancelled{false};
    std::vector<std::vector<std::vector<float>>> prototypes;
    std::vector<float> embed(const std::string &text);
    static bool abort(void * opaque);
};
