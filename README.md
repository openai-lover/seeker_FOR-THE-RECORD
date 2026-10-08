# FOR THE RECORD

> “For the record, this is why I did it.”

<picture>
  <source media="(prefers-reduced-motion: reduce)" srcset="docs/brand/github-hero.png">
  <img src="docs/brand/github-intro.gif" alt="FOR THE RECORD — For the record, this is why I did it." width="960">
</picture>

[View the still brand image](docs/brand/github-hero.png).

A private Android journal for meaningful work and wallet decisions. For Seeker owners who already review wallet activity: save a reason, revisit it, and reuse a lesson before the next choice. User research and measured repeat use remain pending.

**Version 0.5.14+21 · Development-signed Android app · English by default**

## Current release and evidence — 8 October 2026

- [Install 0.5.14 and identify the exact source/APK](docs/submission/DOWNLOAD_LINKS.md).
- [Home recall and its verification](docs/submission/HOME_RECALL_0514.md).
- [Current product walkthrough](docs/submission/JUDGE_QUICKSTART.md).
- [Matched 0.5.14 deck/video and evidence scope](docs/submission/MATERIALS_0514.md).
- [Actual76/100 Coach feedback](docs/submission/REVIEW_076_0514.md).

Save why, revisit, then recall the original before the next similar choice. Home now opens saved-note recall without an active wallet connection or another transaction. Choose a saved wallet before seeing notes, browse exact reasons/reflections/lessons offline, or use the unchanged optional local model. Wallet/query/record changes invalidate stale replies; read errors offer Retry.

The app/tag source is `740e9c4`, **0.5.14+21**, ARM versionCode2021. All 287 Flutter tests, clean analysis and both ABI assets/native/manifest gates passed. The normal Seeker received the in-place update. Room art, onboarding, eight languages, reduced motion, SQLite identity, model/parser/export behavior and permissions are preserved.

The current 3-minute main shows physical Seeker0.5.14 in a separate no INTERNET debug package with four authored DEMO notes in memory. It demonstrates Home recall, wallet scope, original browsing/search and scope clearing; it does not prove current production persistence or independent accuracy. All 11 native/PPT notes and renders match. No private wallet writing or raw video is public.

Historical 0.5.12 normal-production9:17, selected public-RPC swap and25.8-hour due-card evidence retain their dates. The0.5.10 authored multilingual AI evaluation retains every failure. One owner personally reviewed0.5.12; external participants and independent AI raters remain zero. Existing scoped security/input/package triage is not comprehensive clearance; historical partial-audit leads and optional undeployed-backend advisories remain. No paid audit or asset movement.

Latest actual Coach **76/100**, all evidence READ, entry **DRAFT**. This is advisory feedback, not a contest result. Ordinary final submission remains blocked by the portal's GitHub recognition gate. The user stopped the recurring automation; no periodic review is running.

## Existing work loop

1. Create a project without a wallet or account.
2. Write an intention and choose a focus period.
3. Pause or finish when you need to. Record an outcome, including a sticking point.
4. Leave one next action. Choose **Make some space** or the last bookmark next time to start with that action already filled in.

Wallet reflections use a read-only flow: connect an MWA wallet and save a reason beside a supported historical swap, or a clearly labeled personal note beside successful unclassified activity. Optional prompts capture a plan, emotion and next action. Revisit the saved writing later and keep a lesson. Personal writing stays on the device; transaction facts remain fixed.

## Built to feel considerate

- **Eight languages:** English, 한국어, 日本語, 简体中文, हिन्दी, Español, Português and Français. English is the first-run default; your choice persists in Settings. User-written notes are never translated.
- **An original identity:** a warm illustrated room, cream paper, green accents and a three-page introduction with skip. An active session bypasses the introduction; motion respects the system and app preferences.
- **A calmer first screen:** one next action, a direct bookmark return and fewer nested cards. Guided reflections show one question at a time.
- **Local first:** SQLite records, no sign-in wall for personal work, recoverable drafts and JSON export.
- **Mobile details:** monotonic time, reboot handling, optional reminders and haptics, scrolling forms, large-text support, visible validation and duplicate-action protection.
- **Honest states:** read-only MWA authorization works without an app account or a paid backend; rate limits and unsupported activity have explicit states. Simulated wallets and trades are confined to tests.

## Current operating scope

The default APK runs local work and a read-only wallet journal without Firebase
configuration or billing. Native MWA supplies the selected account; the device
queries Solana public RPC. It requests no message or transaction signature in
this mode. Public infrastructure can rate-limit or reject traffic.

The parser accepts a narrow subset of Jupiter v6 classic-SPL swaps and simple
SOL/classic-SPL checked transfers with consistent authority and balance evidence.
Compound, CPI, Token2022 and uncertain activity stays Other. Successful Other
can hold a sourced personal note; failed or unreadable activity cannot. This is
not a complete trading history or profit/loss service.

The new 0.5.11 production recording uses existing MWA authorization and actual
read-only RPC activity on Seeker. Its successful Other activity supports an
authored DEMO note, immediate reflection, completed export and reopening. It does
not verify a supported live swap. The raw recording and JSON remain private; the
supplemental privacy-covered derivative preserves time without internal cuts; main highlights are explicitly edited. No edits to prior personal records
were observed; whole prior database equality was not verified. Independent
repeat-use outcomes remain unverified. No new transaction is necessary to
inspect existing activity or use the local journal.

Shared rooms, SGT verification and purchases are hidden in the default edition.
Their optional backend is undeployed and has three unresolved production
advisories. The release is development-signed. Exact limits and audit leads are
linked from the current evidence section above.

## Run and verify

The project retains the existing Android application ID and SQLite database name so an update can preserve data. Export before replacing an installed preview, and use the same signing key; do not uninstall an existing app just to bypass a signature mismatch.

The verified toolchain is Flutter 3.47.4 / Dart 3.13.3, JDK 17, Android API 36 and Node 22. Package versions are locked. On Windows, the included bootstrap and build scripts configure a local toolchain; read [setup](docs/SETUP.md) before enabling online services.

```powershell
./tools/bootstrap.ps1
./tools/build.ps1 -Release
```

```sh
flutter pub get
flutter analyze
flutter test
pnpm --dir functions install --frozen-lockfile
pnpm --dir functions build
pnpm --dir functions test
```

No environment file is needed for the free default edition. `config/example.json` is only for optional server features. Keep signing keys, passwords, RPC credentials and private notes out of Git. `config/local.json` is ignored.

For isolated Android verification:

```powershell
$env:WORKROOM_ISOLATED_TEST='1'
flutter drive --driver=test_driver/walkthrough.dart --target=integration_test/final_walkthrough_test.dart -d <dedicated-emulator-id>
```

## Competition materials

The [English materials index](docs/submission/README.md) links the exact APK and
source, current native deck, **3:00 edited production main demo**, separate
**10:08 uncut production proof**, and dated public-response replay.
Current isolated UI screenshots are 0.5.11; AI/replay measurements are dated
0.5.10. Main-demo clips retain original 1x speed with cuts. Supplemental proof
preserves the complete timeline with privacy covers and no internal cuts.

All 11 fresh renders were inspected; native and final-production PPT notes match
exactly. [Provenance](docs/submission/MATERIALS_PRODUCTION_0511.md) records assets
and hashes. Historical files retain their scope. Entry: DRAFT; not submitted.

## Privacy and project history

Local notes are not uploaded automatically. The optional AI download contacts Hugging Face and its HTTPS CDN; inference uses local writing on the device. The model can be removed without deleting notes. The free wallet journal sends only public wallet addresses, transaction IDs and read parameters to Solana public RPC. It does not send notes or project names. Optional server features use wallet addresses and service state; chain transactions are public. Exported files contain your notes and should be stored privately. Cloud backup and import/restore are not implemented; export is an archive, not a one-tap restore promise.

Original architecture and earlier validation are retained in `docs/`. Their dates and versions matter: an earlier measurement does not automatically validate a later release. Earlier reference prompts and diagnostic exports remain in the original local archive and are excluded from the published source.

The app was previously named Workroom. Its package identity is `app.workroom.seeker_workroom`; the current product name is **FOR THE RECORD**.

See [the current evidence and its limits](docs/submission/CURRENT_PROOF_0510.md).
