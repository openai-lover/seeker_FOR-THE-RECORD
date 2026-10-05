# Fixed public-mainnet sampling at the 0.5.11 baseline — 5 October 2026

## What this evidence adds

A plan frozen **before RPC requests** sampled four newest finalized signatures referencing each public Jupiter v6, System and classic Token program at three time epochs, five minutes apart. All **36 selected positions / 36 unique signatures** are retained. The listing slots span **453488052–453490377 across 9 distinct slots**; this extends the previous two-slot Jupiter-only sample without selecting replacements after seeing classifications.

This is **public RPC fixture replay at the unchanged 0.5.11 parser**, not current owner live app flow, a newly created trade, account ownership, independent classification accuracy or representative network coverage. No connected wallet, personal database, signature, transfer or token purchase was used.

## Observed baseline results — transaction version ceiling 0

| Outcome | Selected positions |
|---|---:|
| Available response, current parser: successful Other | 19 |
| Available response, current parser: failed Other | 7 |
| Unreplayed: RPC -32015 says transaction version 1 unsupported at configured ceiling 0 | 10 |
| New supported swap or transfer | 0 |

**Do not combine capture errors with production failed-listing behavior.** Of those ten version-1 capture errors, **eight already had failed signature-listing flags and two had successful listing flags**. The production client skips `getTransaction` for failed listing entries and preserves failure; this evidence collector deliberately fetched every selected position. There were **15 failed signature listings in total**: seven available failed responses and eight unsupported-version responses. Therefore this sample does not mean ten otherwise successful user activities would be unavailable in the app.

| Epoch | Public address referenced | Successful Other | Failed Other | Unsupported-version response | Failed listing flags |
|---|---|---:|---:|---:|---:|
| 0 | jupiter | 1 | 0 | 3 | 2 |
| 0 | system | 3 | 0 | 1 | 1 |
| 0 | classic-token | 3 | 0 | 1 | 1 |
| 1 | jupiter | 2 | 1 | 1 | 2 |
| 1 | system | 3 | 0 | 1 | 1 |
| 1 | classic-token | 4 | 0 | 0 | 0 |
| 2 | jupiter | 1 | 2 | 1 | 3 |
| 2 | system | 0 | 3 | 1 | 4 |
| 2 | classic-token | 2 | 1 | 1 | 1 |

All request attempts returned HTTP 200; ten contained the retained JSON-RPC -32015 error. There were **45 requests / 45 attempts**, no retries, no null responses, no missing selection positions and no duplicate selected signatures. Errors were not refetched at a different version during this baseline. There was no extra search, page expansion or provider switch to obtain a successful case.

There are **no classified positive cases** in this new baseline sample, so no new exact-amount positive proof can be claimed. The earlier supported public case8 and its exact atomic-balance proof remain honestly dated in [the 0.5.8 sampling report](PUBLIC_MAINNET_REPLAY_058.md). Successful compound/unsupported activity remains Other; failed responses remain failed. No data were relabelled to improve results.

## Fixed protocol and provenance

- Protocol SHA-256: `abc98638dcebe6472604e4e2305f43079c2953c5b1a11cfa68265da1feca72d7`.
- Frozen before fetch at `2026-10-05T05:41:11.433053+00:00`; epoch0 actual UTC anchor `2026-10-05T05:42:36.393053+00:00`. Epoch targets are anchor+0, +300 and +600 seconds. Completed `2026-10-05T05:53:04.854215+00:00`.
- An earlier unused plan was retained as `protocol-v1-unused.json`; v2 only clarified that epoch0 uses actual run start, avoiding compressed intervals during script preparation. **No RPC call occurred before the final v2 protocol was frozen.**
- Provider: `https://api.mainnet-beta.solana.com`, no API credential.
- `getSignaturesForAddress`: each program address, `commitment: finalized`, `limit: 4`, returned newest-first order. Referencing a program address does not prove a simple top-level instruction or a swap.
- `getTransaction`: unchanged `commitment: finalized`, `encoding: jsonParsed`, `maxSupportedTransactionVersion: 0`.
- One bounded same-request retry was allowed only for HTTP429/5xx or transport failures, after ten seconds; longer server retry-after would stop that request. It was not used.
- Available transactions are replayed from their **first signer** uniformly. This public perspective does not assert ownership. Sponsored/multi-signer/alternate-authority perspectives can remain unsupported and are not searched for a better result.
- Raw response bytes, each request/attempt/time/error and SHA-256 are retained. The runner makes no RPC requests; unavailable results with no first signer are explicitly unreplayed.

Official method semantics were checked before fetching: [getSignaturesForAddress](https://solana.com/docs/rpc/http/getsignaturesforaddress) returns newest-first signatures referencing an address; [getTransaction](https://solana.com/docs/rpc/http/gettransaction) takes commitment/encoding/version ceiling and can return null. Actual version-1 rejection is grounded in these retained RPC errors, not inferred from a missing response.

## Code and focused verification

- Baseline app/tag: **0.5.11+18 / `0c5dfd70243940d6598804e9ff3d111ae920051d`**.
- `lib/data/direct_activity.dart` exactly matched that tag's Git blob `141439990f154ad58683f6a1e13d2fced0175dcf` before later compatibility work. Baseline file SHA-256 `6ddd4790be2a16272ba9f76e72d9c0d5d81c6527338b7e455f47f193fd0864d7` is pinned; do not reinterpret these results as a later release's measurements.
- [Offline evidence runner](../../tool/public_parser_protocol_0511.dart), [focused regression tests](../../test/public_parser_protocol_0511_test.dart), [raw fixtures/protocol/receipt](../../test/fixtures/public_mainnet_0511_protocol), and [machine-readable result plus file manifest](../evidence/public-parser-0511-protocol.json).
- **46 focused checks passed**: six unavailable/malformed-response controls, four protocol/hash/selection/proof accounting checks, and 36 retained-row replay regressions. The saved observed classifications are regression expectations created after observation, **not independent ground-truth labels**. Full155tests, builds, APK installation and personal device flow were not rerun for this baseline.
- Positive-proof accounting has zero cases; a passing empty positive-proof loop does not establish parser accuracy.

Reproduce offline from the repo:

```powershell
.tools/flutter/bin/cache/dart-sdk/bin/dart.exe --packages=.dart_tool/package_config.json tool/public_parser_protocol_0511.dart test/fixtures/public_mainnet_0511_protocol replay.json
.tools/flutter/bin/flutter.bat test --no-pub --reporter expanded test/public_parser_protocol_0511_test.dart
```

## Limits and separate follow-up

This is a small convenience sample of three high-volume public addresses at three epochs, not random or representative. The version ceiling revealed a concrete read-compatibility boundary, but the unchanged narrow instruction classifier supplied no new supported swap or transfer. General accuracy, retention, human validation and live owner-wallet swap behavior remain unproved.

Any later version-1 compatibility confirmation must preserve this baseline and query **the exact same36 selected signatures** under a separately frozen configuration. That would be a post-fix same-sample compatibility confirmation, not held-out accuracy or a new success-seeking sample. No product source or APK was changed in this baseline task.
