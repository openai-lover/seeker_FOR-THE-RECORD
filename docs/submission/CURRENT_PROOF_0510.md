# Current Seeker proof — 0.5.10

Observed on a physical Seeker on 4 October 2026, approximately 21:17–21:30 KST. The production app remains **0.5.10+17 / source `9de8139`**. This follow-up adds diagnostic code and evidence, not an application release or a changed AI model.

## Current UI with public mainnet responses

`tool/public_flow_0510.dart` runs only as the separate `.integration` debug app. It uses the current product UI, parser, native model and real isolated SQLite. The Android package has **no INTERNET permission**. A harness supplies three previously captured public finalized RPC responses through the normal activity normalization path, and provides their public account perspectives. The displayed “Wallet connected” state is supplied by this harness; no MWA authorization occurs in this recording and account ownership is not asserted.

The three cases come from the already published consecutive 15-response sample: case 8 is a supported Jupiter v6 classic-SPL swap; case 0 is a successful unsupported activity; case 2 failed. All original responses and sample selection limits remain in [the sampling report](PUBLIC_MAINNET_REPLAY_058.md). This is **offline public-mainnet replay**, not a new trade, live RPC session, owner wallet flow or broad coverage estimate.

The current screen shows case 8 exchanging exactly **278.854695534 BPxx…jPCy for 348.72045 USDC**. Case 0 remains Other and permits a sourced personal note. Case 2 remains failed and offers no writing action. No amounts or asset symbols were inferred beyond the existing conservative parser.

## Continuous recording and completed export

A new **487.88-second (about 8:08), 1× continuous screen recording** shows the current room, public swap, authored reason, immediate manual reflection, local related-record lookup, exact original quote, question selection, lesson save, Android file picker, completed export, force-stop/reopen and preserved record. The full file preserves time and has no internal cuts. A separate edited feature overview may use excerpts; it is not described as continuous.

The demo reason begins “Demo: I followed a popular claim…” and the three seeded comparison records are explicitly authored. Their dates are fixtures, not claimed user history. The phone clock was not changed. The lookup returned the intended seeded source; its exact reason, reflection and lesson were opened. Question suggestions were 1 and 2; the operator chose 2. The exported question-selection observation was 2,580 ms cold, one isolated UI request, not a latency distribution or production measurement.

Both native exports are **2,264 bytes**. After the first picker returned, the file was checked as nonempty valid JSON before the isolated app was stopped. The second export after restart has an **identical `tradeJournals` payload**, including the original reason, source transaction, first completion time, reflection, selected question and lesson. Top-level export timestamps differ. The safe synthetic/public exports, screenshots and receipt are in [`docs/evidence/final-0510`](../evidence/final-0510/receipt.json). No personal wallet records are included.

This closes a current **isolated public-replay UI/export** evidence gap. It does not replace a current continuous **production account-to-live-RPC** recording. The separate historical 0.5.5 production proof remains correctly dated at 6:28 and 1,876 bytes. The old 1,953-byte and 1,172-byte results are different dated runs.

## Fresh multilingual AI evaluation

Before the first execution, 48 new assistant-authored queries and 24 new English records in three eight-record corpora were frozen. The fixture file SHA256 is `e16233902723a4dc2ba3f3706320a1d1daf5a2fbdc0eb73af9be9f0d0e16ac22`, frozen at 21:06:19 KST. Eight languages and mixed-language/negation/typo cases are included. They differ from the previous 0.5.7 fixtures. The e5-small Q8 model, .82 minimum, .018 margin and single-source policy were unchanged; no tuning followed these results.

Each query ran twice (96 calls); three 24-record mixed-corpus probes ran separately (99 calls total). Repetition does not create more unique examples. Selection outcomes were identical across both passes.

| Unique-query group | Correct source shown | Wrong source shown | Withheld |
|---|---:|---:|---:|
| Related, 24 | 21 | 0 | 3 |
| Unrelated, 12 | 0 | 0 | 12 |
| Ambiguous, 6 | 2 | 1 | 3 |
| Edge, 6 | 6 | 0 | 0 |

The three related abstentions are Portuguese case `fresh-0-related-6`, Hindi `fresh-0-related-7`, and Japanese `fresh-1-related-2`. Ambiguous case `fresh-ambiguous-2` returned record 4 although its authored acceptable set is empty. The other two displayed ambiguous results fall within their declared acceptable sets. All prompts, labels, scores, false positives and abstentions are retained in [the full results](../evidence/final-0510/fresh-results.json). The three 24-record probes returned their declared source; three probes are not a coverage estimate.

The first native call took **1,597 ms**. The 95 warm native calls had median **336 ms**, nearest-rank p95 **375 ms**, range 286–469 ms. Diagnostic frame timings had median 355 ms and p95 390 ms. These are isolated debug measurements with a prepared **132,439,008-byte** model and no app INTERNET permission. They are not production interaction latency or a controlled speed comparison against earlier corpora. Process PSS snapshots were 335,584 KiB before and 621,062 KiB after; they are not peak memory, model-only memory or a leak measurement.

These cases were new and frozen for this run, but **both cases and labels were authored by the same assistant**. They are not independent human labels, held-out real users, or representative general accuracy. Vague requests can still yield a wrong suggestion. The product exposes the exact original text, warns that suggestions may be unrelated, and keeps manual browsing available.

## Further evidence, without fabricated users

A separate authored note on case 0 was saved at 21:29 KST with a real one-day revisit. It remains unreviewed. Its due state can be checked after 5 October 21:30 KST without advancing the phone clock. This is a scheduled technical check, not retention or an independent user study. A consented repeat-use pilot and independent multilingual labels remain pending.

Focused crafted-input proof and actual packaged-manifest outputs are published in [SECURITY_PROOF_0510.md](SECURITY_PROOF_0510.md): 25 targeted checks and 69 backend checks passed. Those are scoped regression tests and packaging checks, not a new independent audit. Three optional-backend advisories and two historical web3.js v1 migration leads remain open.
