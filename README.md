# FOR THE RECORD

> “For the record, this is why I did it.”

<picture>
  <source media="(prefers-reduced-motion: reduce)" srcset="docs/brand/github-hero.png">
  <img src="docs/brand/github-intro.gif" alt="FOR THE RECORD — For the record, this is why I did it." width="960">
</picture>

[View the still brand image](docs/brand/github-hero.png).

A private Android journal for meaningful work and wallet decisions. Keep what you did, why you did it, and the next step worth remembering.

**Version 0.5.11+18 · Development-signed Android app · English by default**

## Current release and evidence — 4 October 2026

- [Install 0.5.11 and identify its exact source/APK](docs/submission/DOWNLOAD_LINKS.md).
- [Current product walkthrough](docs/submission/JUDGE_QUICKSTART.md).
- [Dated 0.5.10 public-mainnet replay, export/restart and AI evaluation](docs/submission/CURRENT_PROOF_0510.md).
- [Crafted-input regression proof and packaged-manifest outputs](docs/submission/SECURITY_PROOF_0510.md).

The 0.5.11 update removes development footers, internal model/build labels, raw unexpected errors and empty transaction rows. Privacy, licenses and deletion confirmation remain available. [UI changes and checks](docs/submission/PRODUCT_UI_0511.md).

The room now opens saved reasons and lessons first. One reason is enough to
save; optional details stay secondary. Local semantic recall shows one original
record, and JSON export distinguishes pending, saved, cancelled and failed
states. The 0.5.10 release also removes three unnecessary AndroidX test activities
from the packaged app. The current 0.5.11 app source is `0c5dfd7`; later documentation commits do not change that APK.

Dated 0.5.10 evidence includes an **8:08 continuous physical Seeker replay** using
actual public mainnet responses, authored notes, the 0.5.10 UI and isolated
SQLite. It is not a production wallet connection or new live trade. Two native
exports are 2,264 bytes with identical journal payloads after restart. A fresh,
frozen 48-query evaluation reports wrong suggestions and abstentions separately;
labels are assistant-authored, not independent user research. Full methods,
failures and scope boundaries are in the linked report.

The 0.5.11 production build passed 155 Flutter tests and clean analysis; both release
packages passed the manifest gate. Focused backend follow-up passed 25 targeted
checks and 69 full-suite checks. These do not establish a complete security audit.
Real-user impact and a current continuous production account-to-RPC flow remain
open. The contest entry remains **DRAFT**.

Earlier release observations are preserved in [development history](DEVELOPMENT_HISTORY.md).

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

The current production app was installed on Seeker and its read-only MWA
connection confirmed. Current end-to-end evidence uses isolated public replay;
the complete production recording remains the dated 0.5.5 run. A supported live
owner transaction and independent repeat-use outcomes remain unverified. No new
transaction is necessary to inspect existing activity or use the local journal.

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

The [current English materials index](docs/submission/README.md) links the exact
APK, source, native deck, narrated overview and full continuous public-replay
evidence. Current screenshots and new measurements are identified as 0.5.10;
historical production recordings retain their original version and scope.
The entry remains DRAFT, with no final submission performed.

## Privacy and project history

Local notes are not uploaded automatically. The optional AI download contacts Hugging Face and its HTTPS CDN; inference uses local writing on the device. The model can be removed without deleting notes. The free wallet journal sends only public wallet addresses, transaction IDs and read parameters to Solana public RPC. It does not send notes or project names. Optional server features use wallet addresses and service state; chain transactions are public. Exported files contain your notes and should be stored privately. Cloud backup and import/restore are not implemented; export is an archive, not a one-tap restore promise.

Original architecture and earlier validation are retained in `docs/`. Their dates and versions matter: an earlier measurement does not automatically validate a later release. Earlier reference prompts and diagnostic exports remain in the original local archive and are excluded from the published source.

The app was previously named Workroom. Its package identity is `app.workroom.seeker_workroom`; the current product name is **FOR THE RECORD**.

See [the current evidence and its limits](docs/submission/CURRENT_PROOF_0510.md).
