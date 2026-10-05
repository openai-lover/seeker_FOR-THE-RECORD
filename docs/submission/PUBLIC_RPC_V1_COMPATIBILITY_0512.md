# Same-sample public RPC v1 read compatibility — 5 October 2026

## Concrete compatibility fix and observed outcomes

The separately frozen 0.5.11 baseline sampled **36 unique finalized public signatures** from three public program addresses at three epochs. Ceiling0 yielded 26 available responses and ten RPC-32015 errors explicitly saying transaction version1 was unsupported. The **0.5.12+19 candidate** raises the bounded read ceiling to **numeric1** and retains conservative instruction classification and failed-listing behavior.

A separate protocol fetched **exactly those same36 signatures**, finalized/jsonParsed/ceiling1, without new signature lookup, search, replacement, success filtering or provider switch. All36 responses became available: **10version1,21version0,5legacy**. There were36requests/36attempts, no retries/errors/nulls. Raw result objects for all26 previously available transactions were exactly unchanged.

| Current candidate replay result | Count |
|---|---:|
| Successful Other, sourced personal reason allowed | 21 |
| Failed Other, writing disallowed | 15 |
| Supported swap or transfer | 0 |
| Prior unavailable captures now available | 10 |
| Prior26 normalized activity results changed | 0 |

**The practical successful-activity improvement is two entries, not ten.** Eight of the recovered version1 captures already had failed signature-listing flags. The production client skips transaction fetches for failed listing entries and preserves failure. This evidence collector deliberately refetched failed entries too, accounting for all15 failed listings. The two previously successful-but-unavailable cases, **e0-jupiter-0** and **e2-classic-token-3**, now normalize as **success/Other/unsupported-activity**. Actual unchanged `WalletActivity` getters confirm both allow `canRecordReason`; neither is a swap or transfer. Across all36, `canRecordReason` is true for21, `canJournal` for0 and `isTransfer` for0.

No money was moved and no unsupported activity was relabelled as a swap. This is **same-sample post-fix read compatibility**, not held-out classification accuracy, owner-wallet ownership, live production app proof, general protocol coverage, independent labels or a new trade.

| Original epoch | Public address referenced | Successful Other | Failed Other | New swap/transfer |
|---|---|---:|---:|---:|
| 0 | jupiter | 2 | 2 | 0 |
| 0 | system | 3 | 1 | 0 |
| 0 | classic-token | 3 | 1 | 0 |
| 1 | jupiter | 2 | 2 | 0 |
| 1 | system | 3 | 1 | 0 |
| 1 | classic-token | 4 | 0 | 0 |
| 2 | jupiter | 1 | 3 | 0 |
| 2 | system | 0 | 4 | 0 |
| 2 | classic-token | 3 | 1 | 0 |

## Preserved selection and provenance

- Original [fixed baseline](PUBLIC_PARSER_PROTOCOL_0511.md) remains immutable: 36selected positions,9slots453488052–453490377, first-signer public perspective.
- Baseline protocol SHA `abc98638dcebe6472604e4e2305f43079c2953c5b1a11cfa68265da1feca72d7`; baseline fetch receipt SHA `90a88d773d02232a81f9c56187fdd1d0363fc6abf29f3a147aeeef51ac1e3738`.
- Separate compatibility protocol frozen `2026-10-05T05:59:32.329041+00:00`, SHA `bc705d8a3eda0310708cbbf274dd43554ecf69a0fd3feef67de93f8b9008bea0`; fetch completed `2026-10-05T06:01:35.104643+00:00`. Fetch happened during candidate preparation; offline candidate replay waited for patch-focused checks to finish.
- Provider stayed `https://api.mainnet-beta.solana.com`. Only `getTransaction` was called; no `getSignaturesForAddress` in this follow-up. Same signatures/context/order/error flags were preserved.
- Every raw response/attempt/hash and timestamp, including failed listings, is retained in [the current compatibility fixtures](../../test/fixtures/public_mainnet_0512_compatibility). Raw v0/legacy transaction payloads equal their original baseline payloads.
- Official [getTransaction configuration](https://solana.com/docs/rpc/http/gettransaction) documents encoding, commitment and the numeric supported-version ceiling. The actual ten baseline -32015 responses and successful ceiling1 responses provide the concrete evidence for this compatibility boundary.

## Code and focused checks

Candidate at replay was **uncommitted 0.5.12+19 working tree**, after compatibility-focused checks; no released APK or physical production0512 proof is asserted here. Candidate `lib/data/direct_activity.dart` SHA-256: **`5acb14ea6c56ac658766bf4d3ba5e0199762afc2e7313f997631568083a30760`**. It was checked before and after replay. Baseline app/tag remains0.5.11+18 / `0c5dfd70243940d6598804e9ff3d111ae920051d`, parser SHA6ddd4790be2a16272ba9f76e72d9c0d5d81c6527338b7e455f47f193fd0864d7. Do not relabel the baseline/current physical0511 video as0512.

- [Guarded offline candidate runner](../../tool/replay_public_compatibility_0512.dart), [focused compatibility tests](../../test/public_compatibility_0512_test.dart).
- [Machine-readable outcomes/provenance/file hashes](../evidence/public-rpc-v1-0512.json), [safe recordability aggregate and domain-source hash](../evidence/note-recordability-0512.json).
- **43 focused checks passed**, after security agent patch-focused checks: exactsame36 selection, frozen protocol and raw hashes,10v1/21v0/5legacy, unchanged26 prior activities,15 failed flags, positive-proof accounting and36 row regressions.
- These are observed-output regressions, not independent labels. No classified positive cases exist in this sample; a zero positive-proof-failure count is not positive classification proof.
- After this focused run, analyzer-only fixes add braces to the runner and null-aware elements/braces to the baseline runner. Executed source snapshots are retained as `.txt` in each fixture; historical executed hashes remain unchanged, and final style-only hashes are recorded separately. No frozen data, transaction/parser behavior or result was changed for style.

## Remaining limits

The original sample is small and nonrandom, selected from three public addresses at three epochs. A program-address reference can involve compound/CPI/unsupported activity; a first signer can differ from another authority. This follow-up reuses exposed inputs and is **not held-out**. It shows bounded read availability recovery and preserved conservative results, not new supported swap/transfer coverage or human validation. Existing supported public swap proof is still the separately dated case8. No owner wallet, personal DB, wallet signature or asset movement was used.
