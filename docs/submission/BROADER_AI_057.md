# Broader retrieval evaluation and 0.5.7 display improvement

## What changed

0.5.6 introduced private related-record retrieval and conservative read-only SOL/classic SPL transfer classification. 0.5.7 keeps the same multilingual-e5-small Q8 encoder and confidence gate (best >= .82, margin >= .018), but offers **one original source** instead of up to three. Manual browsing remains. A similarity score is not a probability of correctness. No generated reasons, extra model, wallet signature, transfer or paid AI account is added.

## 48-case diagnostic before the change

On 4 October a physical Seeker ran 48 new authored synthetic queries twice against 12 English synthetic records. Eight languages, related/unrelated/ambiguous/edge cases. Labels and policy were frozen before execution; harness commit 838b5cc. Fixture SHA256 e7cb0988d79b429e3917e42adbae20d33d2e1ef975a3a1c438e9f26cc1de6d05. Policy was 0.5.6.

| Group | Unique cases | Displayed | Withheld | Interpretation |
|---|---:|---:|---:|---|
| Related |24|21|3|All displayed first records matched authored labels; 4 had wrong extra candidates|
| Unrelated |10|0|10|All withheld in this set|
| Ambiguous |8|4|4|Three vague prompts still displayed a record; mixed prompts have multiple acceptable labels|
| Edge |6|6|0|All first records matched; two had wrong extra candidates|

Seven labelled cases across groups had at least one irrelevant secondary candidate. This motivated the single-source policy; it does not solve vague-query relevance. Selection repeats were identical. Cold native call 1452 ms; 95 warm calls median 558 ms, nearest-rank p95 606 ms, range 369–689 ms. One/8/32-record probes took 85/425/1559 ms; repeated records make these scaling probes, not retrieval quality tests. Long Unicode completed; empty input and 33 records were rejected; cancellation and subsequent recovery succeeded. Recovery was a new cold load (1728 ms).

## Fresh confirmation after the display change

Sixteen new authored questions, two passes (32 calls), frozen before execution. Same 12 records. Fixture SHA256 f3d5eaec0b3cbfd4e6eb84d9fb41db4f513a0fab290b8cbc16872874715c2f68. Tools: `tool/confirm_eval_cases.dart`, `tool/confirm_eval_057.dart`.

- Related 8/8 displayed the labelled record; unrelated 4/4 withheld.
- Two edge questions matched; one mixed question matched an acceptable label; one generic question withheld.
- Repeated selections identical. No new model weights or confidence threshold tuning.
- Cold native call 1459 ms; 31 warm median 377 ms, nearest-rank p95 391 ms, range 370–427 ms.

Both runs used an isolated debug package, prepared model and available network. No personal database or wallet was opened. Timings are native diagnostic calls, not end-to-end production UI latency; differences between runs are not a controlled speed improvement. Labels are authored, not independent judgments. Translations and shared records are correlated. No general accuracy, offline proof, user study or retention claim is made. All raw synthetic results and summaries, including failures, are in `docs/evidence/retrieval-*-057.json`. The broad run predates the single-source fix; applying the fix to those scores is post-hoc, not fresh validation.

## Current feature demonstration

Physical Seeker, 0.5.7 isolated debug UI, synthetic SOL/SPL activity and synthetic writing in a MemoryRepository. Real native encoder and product screens. New footage shows room, transfer cards, related lookup and the original reason/reflection/lesson. Additional stills show manual browsing and saved synthetic note. Edited narration/demo; not a continuous production wallet-to-export proof, live transfer, actual due-date wait or durable SQLite test.

The separate historical 0.5.5 production recording remains 6:28, with privacy covers and synthetic demo writing on an actual successful Other activity. Its completed export is 1,876 bytes. The prior 1,953-byte export is older October 3 evidence. Do not relabel either as 0.5.7.

## Build and scope

114 Flutter tests passed; static analysis clean; ARM64 and x64 release builds passed. Physical production install updated in place to 0.5.7+14, versionCode 2014 and started successfully. No new production full-flow export verification is claimed. Export code is unchanged from the verified 0.5.5 fix. Room artwork, onboarding, application identity and SQLite schema remain unchanged. Development signing.

Remaining gaps: real independent users, independently rated multilingual relevance, supported existing live transfer/swap validation, production latency distribution. No human research or security clearance is fabricated. Historical free portal audit is partial and scoreless; backend remains undeployed with three production advisories. Contest remains DRAFT.
