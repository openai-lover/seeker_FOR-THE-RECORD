# Public mainnet parser replay — 4 October 2026

## What changed in the evidence

The unchanged 0.5.8 Dart parser was exercised against **15 real, finalized Solana mainnet transactions**, obtained by querying the public Jupiter v6 program, without querying the owner's wallet. This supplements the earlier synthetic classification fixtures. It is an **offline replay**, not a new user trade or a physical-device swap demonstration.

| Result from the transaction's first signer perspective | Count |
|---|---:|
| Successful supported Jupiter v6 classic-SPL swap | 1 |
| Successful activity conservatively left Other | 9 |
| Failed transactions retained as failed/Other | 5 |

All 15 responses are retained, including rejected and failed cases. A further five deliberately modified copies check rejection of inconsistent evidence. **21 targeted tests passed**: 15 classification regressions, one separate authority/endpoint/atomic-amount check, and five synthetic rejection controls. The release's previously reported 116 tests are historical release validation; these 21 are additional evidence tests, not an assertion that a full combined suite was rerun.

## Sampling and reproducibility

- RPC: `https://api.mainnet-beta.solana.com`, finalized commitment.
- Program: `JUP6LkbZbjS1jKKwapdHNy74zcZ3tLUZoi5QNyVTaV4`.
- Started at 08:05:05 UTC (17:05:05 KST) on 4 October 2026.
- First five signatures returned, then ten immediately older signatures using the `before` cursor. The sample was expanded after the initial five yielded no supported swap; all 15 were retained. This exploratory sample is not a preregistered or representative benchmark.
- Slots 453197268–453197269; a very narrow time/program sample.
- `getTransaction`: `jsonParsed`, `maxSupportedTransactionVersion: 0`.
- Each response's bytes and SHA-256 are preserved. The signature list combines the two returned pages; individual transaction response bytes are unmodified.
- First signer is the parser's wallet perspective. No ownership by the app user is asserted and no identity is inferred.

See the [raw fixtures and receipt](../../test/fixtures/public_mainnet_058), [all parser results](../evidence/public-mainnet-replay-058.json), [offline runner](../../tool/replay_public_mainnet.dart), and [targeted tests](../../test/public_mainnet_replay_test.dart).

```sh
dart run tool/replay_public_mainnet.dart test/fixtures/public_mainnet_058 replay.json
flutter test test/public_mainnet_replay_test.dart
```

## Supported real response, case 8

Signature: `2vCgWskb1AV9UVvhmv1vuQdh8pdH5tAWyoqzsgXnF5z3ohpT9RALaPFb7tGiN8xCViJb7kdcLgBXWqe3pvGLuSY8`.

- Exactly one top-level Jupiter route, alongside Compute Budget instructions.
- Route discriminator `e517cb977ae3ad2a`; route authority equals the transaction signer.
- Source and destination balance accounts belong to that signer and use the classic token program.
- Input mint `BPxxfRCXkUVhig4HS1Lh7kZqV6SPJhzfEk4x6fVBjPCy`: 7,870,251,238,438 → 7,591,396,542,904 atomic units at 9 decimals, giving **278.854695534** input.
- Output USDC: 66,440,568,578 → 66,789,289,028 atomic units at 6 decimals, giving **348.72045** output.
- Separate assertions check these deltas directly from the raw balances before comparing parser output. No price, profit, trade motivation or token symbol is inferred for the unknown input mint.

Synthetic negative controls modify only copies: wrong route authority, unowned destination, duplicate Jupiter route, unsupported discriminator, and inconsistent decimals. Each is rejected as Other. They are not represented as additional real mainnet transactions.

## Limits and provenance

This shows one supported real response and conservative handling of this particular sample. It does not establish broad protocol coverage, general accuracy, live account behavior, an independent audit, or a live Seeker swap. Nine successful Other outcomes are retained rather than relabelled as swaps. Transfer-specific evidence remains synthetic. No assets were moved and no wallet signatures were requested.

Production app/tag source remains `9031c0a826ca72a997e91570d58afed424f084ee` (0.5.8+15); parser behavior was not changed for this replay. No APK rebuild or version change. These evidence tools and fixtures are a subsequent source commit. The earlier 0.5.8 presentation and 3:00 video predate this replay; the historical continuous production video remains 0.5.5.

Official RPC method references: [getTransaction](https://solana.com/docs/rpc/http/gettransaction), [JSON response structures](https://solana.com/docs/rpc/json-structures).
