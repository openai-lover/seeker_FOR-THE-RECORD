# Current-device AI diagnostic: 0.5.5 engine

Measured 2026-10-03 23:56 KST on the physical Seeker. This is a synthetic diagnostic, not user research or general AI accuracy.

## Reproducible scope

The isolated `app.workroom.seeker_workroom.integration` debug harness imports the production ReflectionAssistant and native engine from app source [07a0cb3](https://github.com/openai-lover/seeker_FOR-THE-RECORD/tree/07a0cb388e5395f24b3a75c9923aa2f4df5dc7cd). It does not import the journal database or wallet. The production APK and database were not replaced. The harness and fixture are in `tool/reflection_eval.dart` and `tool/reflection_eval_cases.dart`; raw synthetic events are in [evidence/ai-eval-055.json](evidence/ai-eval-055.json).

Five authored themes were translated into English, Korean, Japanese, Spanish, French, Portuguese, Hindi and Chinese: 40 unique notes, repeated three times. Expected question IDs were assigned before execution by the author, with no independent raters. Translations are correlated. 120 requests are not 120 independent examples. The fixture SHA256 was `84739c388edecd9f157067a35dcef983dbc1f3eb3d014d7480cfb1eab50cc284`. No model tuning followed this run.

## Results, including misses

| Measure | Observed result |
|---|---|
| Top choice matches authored label | 33/40 unique notes; 99/120 requests |
| Label included in offered candidates | 38/40 unique notes; 114/120 requests |
| Repeat selections | Identical for all three passes |
| First native inference | 2025 ms, cold |
| 119 warm native calls | Median 30 ms; nearest-rank p95 49 ms; range 16–57 ms |
| Model | multilingual-e5-small Q8 semantic-v2, 132439008 bytes |
| Fresh harness download | 36973 ms on the available connection |

Network was available. These are debug native-call timings, not an offline benchmark, UI end-to-end latency, or production memory benchmark. Debug process PSS was 302911 KiB before and 597105 KiB after; two snapshots include Flutter/runtime/cache/model allocations and do not establish a peak, leak, or model-only cost.

| Case | Authored label | Top choice | Candidates |
|---|---|---|---|
| ko-2 | 2 | 3 | [3, 5] |
| ja-2 | 2 | 5 | [5, 1] |
| ja-4 | 4 | 5 | [5, 4] |
| es-2 | 2 | 5 | [5, 2] |
| pt-2 | 2 | 4 | [4, 2] |
| hi-3 | 3 | 1 | [1, 3] |
| zh-3 | 3 | 2 | [2, 3] |

Korean and Japanese theme 2 missed the expected topic in both candidates. This is a real limitation. The existing production question picker already offers all five authored questions manually (`lib/ui/decision_replay.dart`, question-choice sheet); AI is optional. A human can reject suggestions. No model-quality improvement is claimed by this evidence update.

## Failure-state observations

Missing model returned `model-missing`; empty input returned `empty-note`; cancellation returned `cancelled`, followed by a successful recovery selecting question 5 in 2102 ms cold. Long supplementary Unicode input completed with question 4 in 229 ms. These are observed paths, not exhaustive fault injection. The completed harness screenshot contains synthetic aggregate results only.

## Remaining evidence gaps

Independent multilingual labels, varied held-out notes, release-mode memory and latency, sustained failure testing, actual user studies and uninterrupted current production wallet-to-export video remain future work. No live supported swap, financial action, or due-date wait was performed for this diagnostic. Historical offline 0.5.1 and production 0.5.4 measurements remain separate.
