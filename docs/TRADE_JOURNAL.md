# Trade Journal implementation — 2026-09-17

This extends the original Workroom repository on `codex/wallet-trade-journal`. The original source was snapshotted before modification. The personal focus workflow, monotonic-clock recovery, shared rooms and SKR purchase guard remain in place.

## Data and request flow

```text
Seed Vault / MWA -> existing challenge + signed message -> Firebase custom token
Firebase UID -> users/{uid}.wallet -> wallet-activity -> read-only ActivityProvider
standard Solana RPC -> conservative parser -> normalized immutable WalletActivity
four guided questions -> TradeJournalEntry -> local SQLite trade_journals
```

The activity request accepts only an optional `before` cursor. A client-supplied wallet is rejected. The existing token verification checks revocation. Neither private notes nor raw transactions are sent to Firestore or logs. No new transaction signing/sending method was added. The original `transaction_guard.dart`, `functions/src/chain.ts` and SKR payment validation are unchanged.

SQLite schema version 2 adds `trade_journals` and an index. The migration does not read, rewrite or delete the original `workroom` row. Immutable JSON snapshots and editable note JSON are separate; `(wallet, signature)` is unique. Notes remain available offline and after disconnecting. Export includes both work records and trade journals. Project history merges their display chronology only; models remain separate. Entries from deleted projects remain local, without a working project link.

## Parser scope and honest limitations

Only finalized mainnet activity referencing the authenticated wallet is requested. This is not an exhaustive token-account index or complete financial history. Each page contains at most 20 signatures, including failures and unsupported activity.

Recognized Jupiter v6 classic instructions: `route`, `exact_out_route`, `shared_accounts_route`, `shared_accounts_exact_out_route`. A recognized instruction discriminator, matching wallet signer/authority, wallet-owned route endpoints, exactly one negative and one positive token balance delta, and successful metadata are required. Amounts use raw integers/BigInt, not floating-point balances. Only classic SPL token balances are supported. Symbols come from a short known-mint map; unknown tokens show a shortened mint, with full mint in details.

Native SOL wrapping/unwrapping, Token-2022 swaps, Jupiter V2/ledger instructions, Raydium and other protocols, bundles with external transfers, ambiguous/missing data and future transaction versions are intentionally not journalable. Already-wrapped SOL is explicitly labeled **wSOL**, never SOL. Missing/failed/unsupported transactions cannot become successful swaps. No BUY/SELL/PNL inference exists. The test transactions are synthetic parser/widget fixtures, not evidence of a real user's trade; no fixtures are bundled into app runtime.

Limits: six requests per UID per 10-minute server window, 60-second in-process cache (100 entries), four RPC workers, 20 transactions/page, 200 displayed client records, seven-second RPC call timeout, two attempts, 25-second provider deadline and 40-second client activity deadline. Functions retains its existing five-instance maximum. Rate limits reduce abuse; they are not a monetary spending cap. Cache is process-local and can miss across instances. RPC failures leave local work usable; pagination failures preserve existing rows/cursor and retry. Stale account responses are discarded.

Official sources reviewed:
- [Solana getSignaturesForAddress](https://solana.com/docs/rpc/http/getsignaturesforaddress)
- [Solana getTransaction](https://solana.com/docs/rpc/http/gettransaction)
- [Jupiter instruction IDL](https://github.com/jup-ag/instruction-parser/blob/main/src/idl/jupiter.ts)
- [Jupiter developer updates](https://t.me/s/jup_dev?before=157) — newer V2 instructions exist; unsupported formats fail closed.
- [MWA native identity / Digital Asset Links](https://github.com/solana-mobile/mobile-wallet-adapter/blob/main/spec/spec.md)

## Product and visual choices

Home now leads with the previous next action / start-focus card. The room remains below it, with project-book, achievement and journal navigation. Growth still depends on work records, never trading volume or returns. The bottom navigation remains Workroom / Journal / Settings; Journal has Work / Trade segments. A short, optional four-question flow captures reason, plan, emotion and next action; a separate later reflection edits only private notes.

Korean and English use a localization delegate, product string catalog and parameterized translations. Language follows the device unless selected in Settings. User-written titles and notes are not translated. UI retains cream, dark green, brass, bundled fonts and restrained cards. Official product pages were visited in the browser: [Craft](https://www.craft.do/ko) for hierarchy/spacing, [Day One](https://dayoneapp.com/guides/tips-and-tutorials/prompt-packs/) for writing prompts, [stoic](https://www.getstoic.com/) for guided reflection, and [Linear's 2024 redesign article](https://linear.app/now/how-we-redesigned-the-linear-ui) for compact state hierarchy. No screen/assets were copied.

## Firebase deployment

- Project: `workroom-seeker-6984` / Workroom; no unrelated project used.
- CLI browser OAuth completed. Android package registered: `app.workroom.seeker_workroom`.
- Android Firebase app: `1:59289817024:android:5dffe07d41c4b070458225`.
- Authentication initialized; custom-token flow needs no password/social provider.
- Firestore `(default)`: Native / Standard, `asia-northeast3`, free tier.
- Hosting and Firestore rules deployed successfully with `--only firestore:rules,hosting`.
- [Identity landing page](https://workroom-seeker-6984.web.app) and [Digital Asset Links](https://workroom-seeker-6984.web.app/.well-known/assetlinks.json) returned HTTP 200; asset links uses JSON content type and the preview's development certificate.
- **Functions and TTL indexes are not deployed.** Spark billing is disabled; TTL deployment explicitly returned billing-disabled HTTP 403. Functions requires Blaze. No paid upgrade was performed.
- `SOLANA_RPC_URL` is not set. After the owner authorizes billing, set this via Firebase Secret Manager, deploy the single Workroom API and existing indexes, and perform real-device validation. Never put RPC provider keys in Flutter defines or chat.
- Public Android configuration is in ignored `config/local.json`; server public parameters in ignored `functions/.env.workroom-seeker-6984`. `PAYMENTS_ENABLED=false`.
- The APK has real project/identity configuration, but its intended API URL is not yet live. This is **not** a completed wallet/auth/SGT production integration.

After explicit billing approval, from the repository's configured Node 22 environment:

```powershell
node functions/node_modules/firebase-tools/lib/bin/firebase.js functions:secrets:set SOLANA_RPC_URL --project workroom-seeker-6984
node functions/node_modules/firebase-tools/lib/bin/firebase.js deploy --only 'functions:workroom:api,firestore:indexes' --project workroom-seeker-6984
```

Review the CLI's final resource changes and billing/IAM requirements at that time. Do not enable payments or send mainnet funds during the journal test. TTL only cleans expired records; application code already enforces challenge expiry.

## Validation and build

Baseline: Flutter analysis clean; original Flutter suite 18 pass / 1 date-dependent golden failure. Functions build and 29 tests passed. Golden nondeterminism was repaired by injecting a wall clock, with no golden tolerance increase. Final logs and device results are summarized in `TRADE_VALIDATION.md`.

New tests cover serialization, immutable facts, SQLite v1 -> v2 byte-for-byte preservation of the original JSON row, duplicate signatures, CRUD/reopen, stale account response rejection, pagination retry, auth isolation, failed/unknown transactions, strict cursors, cache/rate limits, guided reflection, disconnected/offline/empty/error states and large Korean text. English journal screenshots under `test/goldens/07-*` and `08-*` use labeled synthetic test data, not live transactions.

Canonical build: `./tools/build.ps1 -Release -Config config/local.json`. Android Studio's bundled Java 25 is incompatible with this project's Gradle 8.14.3; use the installed JDK 17 (`flutter config --jdk-dir=<JDK17>`). Do not run Flutter tests and builds concurrently. For Android integration tests, set `WORKROOM_ISOLATED_TEST=1`; this selects the `.integration` debug package. IMPORTANT: Flutter runner still touched the base package in this environment, so use ONLY a dedicated empty emulator through `tools/test-android.ps1 -Device <id>`. That script refuses devices with the main app installed. A suffix alone is not a data-preservation guarantee. Clear that environment variable for the real app build. The APK is release-optimized and development-signed; it is not a Store production build.

## Changed implementation files

- Backend: `functions/src/activity.ts`, `functions/src/index.ts`, `functions/test/activity.test.ts`.
- Persistence/model: `lib/domain/trade_journal.dart`, `trade_journal_controller.dart`, `controller.dart`, `lib/data/repository.dart`, `remote.dart`.
- UI/localization: `lib/ui/app.dart`, `home.dart`, `focus.dart`, `books.dart`, `settings.dart`, `shared.dart`, `design.dart`, `room_scene.dart`, new `trade_journal.dart`, new `lib/l10n/strings.dart`, `legacy_catalog.dart`.
- Android: `WorkroomActivity.kt` identity icon extension; `android/app/build.gradle.kts` opt-in isolated debug test package.
- Config/hosting: `.firebaserc`, `firebase.json`, `.gitignore`, `hosting/index.html`, `hosting/favicon.png`, `hosting/.well-known/assetlinks.json`.
- Tests/build: `test/trade_journal_test.dart`, `trade_journal_widget_test.dart`, `activity_remote_test.dart`, existing `widget_test.dart`, `integration_test/local_android_test.dart` with an isolated temporary DB, and intentional goldens; `pubspec.yaml`/lock, `tools/check.ps1`.
- Documentation: this file, validation/checklist and updates to README/architecture/setup/artifact notes.
