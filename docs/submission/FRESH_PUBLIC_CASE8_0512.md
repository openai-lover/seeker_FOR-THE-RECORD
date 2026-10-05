# Fresh phone RPC read of a known public historical swap - 0.5.12

## What was completed

On October 5, the physical Seeker made two fresh, read-only `getTransaction` requests for the same previously public supported case8 transaction. Both returned HTTP 200 on the first attempt. The first fetch completed at 08:36:44.705465 UTC; the second completed at 08:47:35.340824 UTC after a force-stop and relaunch. Both raw responses were 10,636 bytes with SHA256 `c88cc8ad756dbbd3cff75f7193ed62cab35b1b16dfd9b79c243816faf5009380`, exactly matching the already-public historical fixture. No new signature was searched, and no cached response substituted for a failure.

The current parser and product UI in a separately installed debug harness displayed a successful strict Jupiter classic-SPL swap: **278.854695534 BPxx...jPCy to 348.72045 USDC**. It remains version 0, finalized slot 453197269, with `canJournal=true` and `canRecordReason=true`. The first signer from the returned public transaction supplies context; ownership is not asserted. This is a new retrieval and phone UI observation of a known historical transaction. It is not a new trade or a held-out coverage result.

The operator wrote a DEMO reason, used immediate manual reflection, selected question 4 manually and saved a DEMO lesson. No new AI inference was performed. The reason expresses a test operator's explanation, not the public trader's motive.

## Native export and persistence

The harness used new actual SQLite `known-public-case8-flow-0512.sqlite` within `app.workroom.seeker_workroom.integration`. The first completed native-picker JSON export was privately validated at **17:47:14 KST before force-stop**. After relaunch, the app fetched the same transaction afresh and opened the same isolated database. The second completed export was validated at **17:49:55 KST**.

Both JSON files were **2,392 bytes** and contained one journal. Their complete `tradeJournals` payloads were identical, their `exportedAt` values differed, and the original reason and first `baselineSavedAt` were preserved. Both had `reviewDueAt=null`; the reflection and lesson were nonempty. Validation occurred outside the phone UI. These raw exports remain private. This proof does not establish equality of any prior production database or a delayed due wait.

## Build and execution boundaries

`tool/live_public_case8_0512.dart` was manually built as a debug ARM64 APK, version 0.5.12 / versionCode 2019. The 105,612,661-byte APK SHA256 is `cd76486cc2cffc01ff98adc12d8345e739a2e632f915571a485a1735f66f2b65`. The operator checked the exact `.integration` package, debuggable flag, INTERNET, native ARM64 resources, required room/font/license assets and kernel before in-place installation. The harness SHA256 is `358eb6dd447ad843559a722e30a978c157c8ebb157e6cc52e3b1e682f8d5841a`. It uses production source/tag `ee650639670c7ab35081a92e3435a185b73a6642`, including unchanged parser SHA256 `5acb14ea6c56ac658766bf4d3ba5e0199762afc2e7313f997631568083a30760`; the diagnostic entry point is separate from the production entry point.

The tool requires debug mode and explicit `FTR_ISOLATED_PUBLIC_CASE8=true`, then checks the actual Android database path for the exact isolated package **before RPC or database opening**. It opens no production database and performs no MWA connection, signature or transaction. One manual known-signature fetch is allowed per menu instance, with at most three transport attempts, a 25-second timeout and 2/4-second backoff only for timeout/network and HTTP 429/500/502/503/504. Null or JSON-RPC error terminates without a replacement or fallback. Each actual phone session needed only one attempt.

The request uses `jsonParsed`, numeric `maxSupportedTransactionVersion=1` and finalized commitment. Official method semantics: [Solana getTransaction](https://solana.com/docs/rpc/http/gettransaction). The visible UI shows fresh fetch time, raw hash and scope before allowing the product screen. Its permanent overlay states known historical case, authored DEMO notes and no owner wallet. The product screen's Refresh consumes that fetched snapshot; it does not initiate another RPC request. The explicit `Builder -> MediaQuery.fromView(View.of(context))` wrapper was exercised successfully on the phone while retaining WorkroomApp's own MaterialApp.

The frozen protocol and earlier desktop check are preserved. Both phone request/raw hashes match [the existing public request and raw fixture](../../test/fixtures/public_mainnet_0512_known_refresh/). Phone raw files were not copied into public fixtures. [The safe aggregate](../evidence/fresh-known-public-case8-0512.json) contains exact fetch times, hashes, classification and export validation booleans; private storage paths and writing are excluded. The normal production app was restored to the foreground after the isolated proof. No new production APK, parser policy, model, schema or UI change was required.

## Recorded timeline and verified publication

The private source screen capture is **790.7306 seconds**. The exact privacy-covered, constant-frame-rate derivative is **790.75 seconds (13:10.75)**, **7,877,505 bytes**, SHA256 **67981381e3fe2fcc0d9768b30481e1b3cb8a36e02b9827044c857741525860b7**. It has **zero internal cuts, 1x action speed and no audio**. Root agent visual/privacy QA independently checked all 791 one-second samples and 14 dense contact sheets, including status-bar, keyboard, picker and restart covers. This is agent QA, not independent human validation.

**The first fetch was already in flight when recording began, so its initiating tap is absent.** The recorded timeline shows the resulting fresh read and subsequent product use, completed export, force-stop/relaunch and the **second fresh request**. It is continuous within its recorded interval; it is not a complete first-fetch-tap-to-end recording. The two external JSON validations are not visible as phone actions.

Root approved only this exact privacy-covered derivative for public use. It is now [published in v0.5.12](https://github.com/openai-lover/seeker_FOR-THE-RECORD/releases/download/v0.5.12/FOR-THE-RECORD-continuous-fresh-public-case8-0.5.12.mp4) with the GitHub server digest matching SHA256 **67981381e3fe2fcc0d9768b30481e1b3cb8a36e02b9827044c857741525860b7**, verified at **2026-10-05T18:44:18.8194239+09:00**. The raw source remains private. [The safe recording receipt](../evidence/fresh-public-case8-recording-0512.json) records the published derivative hash and boundaries without private media paths. Manual question 4 and no new AI inference remain the scope of this proof. [The matched-material summary](MATERIALS_FRESH_RPC_0512.md) separates this supplement from the edited main and normal production flow.

## Delayed due state and reminder limitation

The separate `public-mainnet-flow-0510.sqlite` main-file SHA256 remained `099ea4ba6b8d0525806cf6cdac1b9763766fadc5ba2fe1ba96dfeab33a6fd31a` before and after this proof, as checked by the operator. The new harness never opens or clears that database. **This does not prove Android alarm continuity.**

Source inspection distinguishes two mechanisms. Journal `reviewDueAt` is checked by `isDue(actualNow)` and displayed on the home screen, with a foreground one-second ticker and a refresh on resume. No native journal-due alarm scheduling exists in the inspected path. Loading a repository, refreshing or setting language/welcome does not call `_alarm`. Focus-session reminders instead share one package-scoped PendingIntent request code 17 and notification 17 across databases. Focus start/pause/finish/save/cancel, notification configuration or deletion can replace/cancel that alarm; package replacement and force-stop effects were not measured here.

For the existing authored due record, wait until the actual device clock passes **October 5 at 21:29:52.880 KST**. First compare the exact row and due timestamp from a read-only DB/WAL snapshot, then use a guarded preview that opens only the existing due database and shows its home state without seeding, settings writes, note edits or clock changes. The older replay entry point seeds comparison notes and writes language/welcome, so it should not be reused unchanged for this narrower check. A due-card observation will be technical real-time scheduling evidence, not a native notification, independent human repeat-use or retention result.

## Limits

This is a deliberately chosen known public historical swap on a real Seeker, freshly read from RPC and exercised with isolated current code. It strengthens evidence beyond an offline fixture replay. It does not cover the owner's live account path, new transactions, independent labels/users, general parser accuracy or multilingual AI quality. The recording boundary above excludes the initial fetch tap. Raw phone JSON/video, personal records, credentials and private paths remain private.
