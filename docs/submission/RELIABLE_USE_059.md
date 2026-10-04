# 0.5.9: clear export completion and offline execution evidence

## Product change

Export now shows an in-progress label, prevents repeated taps, and reports either **File saved** or **Export cancelled**. The native callback already returned a truthful boolean in 0.5.5, but the Dart bridge discarded it. The bridge now requires an actual boolean; null or malformed callbacks fail rather than becoming success. Both whole-app and individual-record exports use the same component. All eight supported UI languages include the new messages.

The room, onboarding, application identity, SQLite schema, JSON structure, model weights, retrieval policy and transaction classifier are unchanged. An update does not delete existing data. Completion means the Android output stream was written, flushed and closed; it does not guarantee a cloud document provider's later synchronization.

145 Flutter tests passed and full analysis was clean on October 4. This comprises the prior 116 tests, 21 public-mainnet replay tests and eight new bridge/UI export regressions. ARM64 and x64 release builds passed. The historical eight native writer tests from 0.5.5 remain separate; they were not rerun for this Dart presentation change.

## Physical Seeker: actual SQLite and native export, synthetic records

A separate `.integration` debug application used the production UI, `LocalRepository` and native file picker with an isolated `public-fixtures-059.sqlite` database. It did not import the personal app database, connect a wallet or query RPC. All reasons, activities and the wallet placeholder were synthetic.

Picker cancellation displayed the cancellation message and allowed retry. A whole-app export completed. A new marker was then saved into one synthetic reflection, and a single-record export completed with the visible success message. Only after completion, the isolated app was force-stopped and reopened. A second 1,172-byte export contained an exactly identical `tradeJournals` payload, including the marker. Export timestamps differ. The initial whole-app export was 3,449 bytes. The operator inserted the marker within a word; the exact text was retained in the verification rather than silently corrected.

This is current physical storage/export evidence, **not a current production wallet-to-export flow**. The separate historical 0.5.5 production flow is 6:28 and its export is 1,876 bytes. Neither historical export size applies to this new synthetic test.

## Physical Seeker: AI without application network permission

The diagnostic debug manifest removes `android.permission.INTERNET`, and build guards require the isolated package and reject release tasks. Both APK and installed-package inspection showed no INTERNET permission. A connection probe failed with host lookup error 7. The phone's network settings were not changed. A previously prepared 132,439,008-byte model was used; no model download or AI service was called.

The unchanged encoder and one-source policy ran the **same 16 authored 0.5.7 confirmation queries**, twice, against 12 synthetic records. Across each pass: eight related queries returned the labelled record, four unrelated queries were withheld, one mixed query returned an acceptable source, one generic query was withheld, and two edge cases returned their labelled source. Repeated selections were identical. A separate synthetic reflection request returned question 4.

| Measurement | Observed result |
|---|---:|
| Retrieval calls | 32 (16 unique reused cases) |
| First cold native call | 1,701 ms |
| 31 warm native calls | median 571 ms; nearest-rank p95 614 ms; range 535–621 ms |
| Warm diagnostic-frame completion | median 591 ms; p95 642 ms |
| Separate reflection-question native call | 1,034 ms |

These are isolated debug measurements, not production UI latency, independent labels, new held-out accuracy, a controlled speed comparison or user research. The earlier 0.5.7 network-available median of 377 ms remains a different run. No weights or policy were tuned on this offline rerun. The network permission restriction is specific to the diagnostic; the production app still needs Internet for read-only activity lookup and initial model setup.

Raw synthetic results and fixture hash: [offline-059.json](../evidence/offline-059.json). Harness: [offline_eval_059.dart](../../tool/offline_eval_059.dart). Previous broad evaluation and failures: [BROADER_AI_057.md](BROADER_AI_057.md).

## Remaining limits

The historical production flow, current isolated flow, public-mainnet parser replay and authored AI evaluation are different evidence. No current supported live user swap, delayed real due-date wait, independent study or repeat-use retention is claimed. The optional backend is undeployed and its three advisories remain open. The partial portal audit is not a security clearance; see [EXPORT_RELIABILITY_055.md](EXPORT_RELIABILITY_055.md) and [BACKEND_SECURITY_STATUS_2026-10-01.md](../BACKEND_SECURITY_STATUS_2026-10-01.md).

The competition entry remains a draft.
