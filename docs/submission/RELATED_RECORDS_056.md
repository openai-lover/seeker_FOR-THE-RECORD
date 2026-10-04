# 0.5.6 — retrieve your own reasons, with source quotes

## What changed

The existing on-device multilingual-e5-small Q8 encoder now compares a new note with up to 32 recent records from the same wallet. It opens the exact saved original reason, reflection, lesson and activity source. It does not generate those words, provide trading advice, or upload notes. No second model download is required. The existing five-question reflection selector remains available.

The current record and other wallets are excluded. Deleted or edited inputs invalidate displayed matches. Empty, missing-model and failed searches leave manual browsing available. The first-record form stays uncluttered: the search panel appears only when another record exists. Cancel is available. Eight interface languages are bundled; personal writing is never translated.

The local RPC parser also recognizes a deliberately narrow subset of successful SOL and classic SPL Token transfers. A single top-level parsed transfer, writable accounts, signer/authority and exact before/after balance evidence must agree. Received and sent amounts are shown without relabeling a transfer as a swap. Token-2022, CPI/compound transfers, delegated authority and unsupported patterns remain unclassified. No signing or sending method was added. These branches currently have synthetic regression evidence, not a verified live transfer.

Source: [record selection](../../lib/data/related_records.dart), [native encoder](../../android/app/src/main/cpp/reflection_core.cpp), [read-only parser](../../lib/data/direct_activity.dart), [interface](../../lib/ui/related_records.dart). The parser follows the fields described in [Solana RPC JSON structures](https://solana.com/docs/rpc/json-structures) and [Transfer tokens](https://solana.com/docs/tokens/basics/transfer-tokens).

## Physical native diagnostic — October 4

The separate `.integration` debug package ran on the connected Seeker. It imported no personal database or wallet service. The existing model was already installed, and network access was available. This is neither an offline benchmark nor production-screen latency.

- Eight synthetic English records; 16 authored queries consisting of two themes translated into eight languages; two passes, 32 requests.
- Raw top-ranked record matched the author's intended label in 32/32 calls (16/16 unique queries). This is a narrow diagnostic, not general accuracy or independent evaluation.
- First native request: 1,525 ms. The 31 warm requests had a median of 342 ms and a maximum of 384 ms. These values include ranking eight records, not the maximum 32-record product limit.
- Empty input and 33-record input were rejected. Cancellation returned `cancelled`; subsequent search recovered (1,467 ms cold).
- An unrelated bread question and repeated mixed Unicode still produced superficially high cosine scores. The initial 0.75 display threshold was therefore unsuitable as a confidence claim.

The display policy was tightened **after observing this diagnostic**: best score at least 0.82, best-to-second margin at least 0.018, and displayed candidates within 0.035 of the best. These are product heuristics, not calibrated probabilities. Replaying the same measured scores through that policy displays results for 18/32 calls (9/16 unique queries) and abstains for 14/32 (7/16). Both unrelated probes are suppressed. This is explicitly post-hoc replay, not a new independent or held-out success rate. The lower coverage is published rather than hidden. Manual browsing remains available whenever the model abstains.

Raw synthetic events and fixture hash: [retrieval-eval-056.json](../evidence/retrieval-eval-056.json). Reproducible harness: [retrieval_eval.dart](../../tool/retrieval_eval.dart), [frozen cases](../../tool/retrieval_eval_cases.dart). The fixture was frozen before the first native run; model weights and the fixture were not tuned.

## Evidence still required

No real participant study is claimed. An agent-driven device run cannot be attributed to the owner as a human study. No supported live Jupiter swap, actual delayed revisit, retention metric, or full security clearance is claimed. Current production full-flow video and deck must be refreshed before claiming they demonstrate this new feature. Earlier 0.5.5 footage remains historical evidence only. Backend deployment and outstanding dependency advisories are unchanged.
