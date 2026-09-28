# On-device reflection assistant · 0.5.1

## What it does

The app offers five fixed, translated reflection questions. A multilingual E5 encoder finds the topic closest to the user's writing. It does not generate an answer, make investment recommendations, or summarize facts it has not seen. When two topics are close, the UI asks the user to choose before storing a selection. A changed note invalidates a pending proposal. Manual question selection remains available without a model.

Trade journals persist the selected question, model identifier, source text and timing locally. In the work-outcome editor, the question is a writing aid for the current screen; the user's outcome/next action remains the saved content.

## Data flow

Only the reason, plan and reflection enter the assistant, clipped to 140 Unicode code points each. Wallet addresses, transaction signatures and balances are excluded. Kotlin validates the JSON and sends standard UTF-8 bytes through JNI, preserving supplementary-plane characters. The encoder reads the reflection with 75% weight and the combined context with 25% weight. Thirty authored topic descriptions are embedded once per engine load. Scores are cosine similarities, not calibrated probabilities. A top-two gap below 0.018 or a best score below 0.82 requests user choice.

This is a neural semantic retrieval model, not keyword rules and not a generative LLM. It cannot execute commands from a journal. Encoder input is bounded to 512 tokens; an overlong background is clipped with EOS preserved. Each call encodes its own text; there is no conversation history or cross-note retrieval.

## Model and runtime

- Model: `intfloat/multilingual-e5-small`, Q8 GGUF conversion by TwinSunsLLC, MIT.
- Revision: `b6cac9615d4ecce28d7f22539b7322d695fc2886`.
- File: `multilingual-e5-small-q8_0.gguf`.
- Size: **132,439,008 bytes**, shown as approximately 133 MB in the app.
- SHA-256: `e011debc1208e31bf7b6aebee2d9fc8bd2ca11694a77ed66ac9d0c9d0a877c93`.
- Runtime: llama.cpp v0.5.0, CPU with four threads, built through Android NDK. No LiteRT-LM dependency remains.
- Runtime source archive SHA-256: `78debec727e31cd4f85b3795a94c2864db66d2687a81c5c36e9717fec785568c`.
- Supported AI: ARM64 Android. The x64 preview keeps manual reflection available.

Download starts only on user action, follows HTTPS redirects, checks a fixed length and SHA-256, and discards interrupted partial files. The model lives in private no-backup storage. A cold engine verifies the model again before loading. Weights and authored topic vectors stay warm for 60 seconds; a background transition releases the engine on its worker. Native cancellation uses an abort callback, with one active operation, a 30-second inference deadline and a 15-minute download deadline. No worker closes a context while it is in use.

Removing the AI model leaves all personal records intact. On a successful upgrade download, obsolete app-owned Qwen weights/cache are removed. AI requests have no networking code. Public Solana RPC remains a separate online dependency for fetching public wallet activity.

## Physical Seeker evidence, 28 September 2026

[Raw structured results](AI_DEVICE_051.json) record the optimized JNI/Flutter integration. The test package is separate from the user's app and never opens its database or wallet. Before the final run Wi-Fi/mobile data were disabled and Android reported `Active default network: none`; original network settings were restored afterward.

- First request including hash verification, load and topic preparation: **1,661 ms**.
- Subsequent 63 requests: **30–67 ms**, median **44 ms**.
- Earlier real model download: **25,988 ms** on the available Wi-Fi; not a network performance guarantee.
- 34 development examples: 34 first-choice matches after tuning; these are not held-out evidence.
- 30 further English/Korean examples fixed before final evaluation: **26/30 first-choice matches**. Nine requested a user choice. All four first-choice errors were among those nine and included the expected topic as the other option.
- All 64 examples included the expected topic among the displayed option(s); this is not automatic accuracy of 100%.
- Empty input rejection, Unicode/emoji, cancellation and recovery passed.
- Flutter suite: 93 tests passed, including ambiguity/stale-proposal behavior, persistence, and eight languages at 200% text size. Static analysis clean.

These are small authored synthetic cases on one device, not independent user research. Six non-English/Korean languages have only one probe each. Timings exclude UI transitions, human selection, and the initial download. The first call after idle/background release pays initialization again. Native benchmark peak RSS was about 271 MB; this is not the total Flutter app memory footprint.

The former Qwen3-1.7B implementation required 977,184,032 bytes and took 15.1–16.8 seconds across eight development examples. Both the model and the execution/initialization strategy changed, so this is a product improvement comparison, not a controlled model-only benchmark.

## Release installation check

The normal ARM64 release APK (0.5.1, Android versionCode 2008) was installed over the existing app without uninstalling it. It is 37,811,704 bytes; SHA-256 `234ba0ca6ae9e93d0ff5767b14098e3211ff197317bde663b894f266d3498ea0`. In that release, model download and native question selection were exercised through the actual settings and work-outcome UI using a temporary synthetic note. This smoke check is separate from the accuracy evaluation above. The temporary project/session, isolated test app and device benchmark files were removed afterward. Wi-Fi reconnected, and the normal app was left on its home screen with the model prepared.

## Reproduce

Use `integration_test/local_reflection_test.dart` with `WORKROOM_ISOLATED_TEST=1`; the frozen fixture is `integration_test/fixtures/reflection_cases.dart`. Keep the app installed for the offline second run. Use the project JDK and the setup instructions. No real wallet or financial transaction is involved in these AI checks.

A separate supported live swap-to-journal rehearsal is still required before contest submission. None of these checks is a new contest AI-coach score or a promise of winning.

## Sources

- [Original E5 model](https://huggingface.co/intfloat/multilingual-e5-small)
- [Pinned GGUF conversion](https://huggingface.co/TwinSunsLLC/multilingual-e5-small-gguf/tree/b6cac9615d4ecce28d7f22539b7322d695fc2886)
- [E5 technical report](https://arxiv.org/abs/2402.05672)
- [llama.cpp v0.5.0](https://github.com/ggml-org/llama.cpp/releases/tag/v0.5.0)
- [Bundled license notices](../assets/ai/LICENSES.txt)
