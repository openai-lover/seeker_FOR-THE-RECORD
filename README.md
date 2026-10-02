# FOR THE RECORD

> “For the record, this is why I did it.”

<picture>
  <source media="(prefers-reduced-motion: reduce)" srcset="docs/brand/github-hero.png">
  <img src="docs/brand/github-intro.gif" alt="FOR THE RECORD — For the record, this is why I did it." width="960">
</picture>

[View the still brand image](docs/brand/github-hero.png).

A private Android journal for meaningful work and wallet decisions. Keep what you did, why you did it, and the next step worth remembering.

**Version 0.5.3 · Local development preview · English by default**

## A usable record beyond recognized swaps

On a physical Seeker, the connected wallet's recent activity fell outside the
strict swap parser. Version 0.5.3 now lets a confirmed successful, unclassified
activity hold a personal note, original reason, later reflection and lesson.
It stays **Other wallet activity**; no trade type, token amount or return is
invented. Failed, unavailable and parse-error records still cannot be saved.

The normal APK was checked on Seeker on 2 October: Seed Vault account connection,
public activity retrieval, note save, manual revisit, native AI suggestions,
lesson, Android JSON file save and persistence after process restart. The writing
was explicitly authored for verification. A final-build cold AI request took
2,099 ms and offered two candidates for the person to choose; this is one
observation, not an accuracy or performance benchmark. The supported live
Jupiter swap path remains unverified.

[0.5.3 verification and limits](docs/submission/REVISION_053.md) ·
[Current downloads](docs/submission/DOWNLOAD_LINKS.md)

## A clearer revisit in 0.5.2

The primary home action opens the oldest due reason directly. Due dates refresh
while the room stays open, even without a focus timer. Saving a first record
requires its reason; optional prompts cannot accidentally save an empty original
explanation. A short lesson completes a revisit, and later edits preserve its
first completion time. Changed reflection text clears its previous AI selection.
Each decision also has a local JSON export action.

The current isolated Android walkthrough substitutes only a visibly labeled
synthetic RPC response, while running the production reader/parser, current room
screens and real SQLite. It checks original writing, a simulated due date,
reflection, lesson, close/reopen persistence and JSON content. See the
[current judge quickstart](docs/submission/JUDGE_QUICKSTART_052.md) and
[0.5.2 changes and limits](docs/submission/REVISION_052.md).

## Your quiet corner in 0.5.0

A warm room returns to the home screen, with original room, journal and lamp artwork. Three swipeable welcome pages introduce the room with large type, a skip action and persistent completion. Desk, lamp and bookshelf open the decision journal, focus flow and work records. A room entrance, subtle object motion and three bundled Lottie icons respect reduced motion. Replay the guide from the home help button or Settings. Artwork and motion credits are in [asset attributions](assets/ATTRIBUTIONS.md).

The 0.5.0 room was installed and visually checked on Seeker: next/swipe/enter/skip, return after restart, and all three room destinations. Version 0.5.1 keeps that design, adds a much lighter reflection assistant, and fixes large-text layout and revisit refresh issues.

[Submission kit](docs/submission/README.md) · [Pitch](docs/submission/PITCH_CONTENT.md) · [Build instructions](docs/SETUP.md) · [UX review](docs/UX_REVIEW.md)

## Decision Replay in 0.4.1

Save one reason alongside a supported wallet transaction. Choose a revisit date (1, 3 or 7 days), return to the original saved writing, and keep a personal lesson for the next choice. Due entries appear on the home screen; these are in-app reminders, not scheduled push notifications. The existing work journal remains available.

The optional assistant now uses **multilingual-e5-small Q8** for semantic question retrieval: **133 MB**, no API account, and fully local inference. On a physical Seeker with no active network, the optimized Flutter bridge measured **1.661 s cold** and **30–67 ms warm (median 44 ms)**. The engine unloads after 60 seconds idle or when the app goes into the background. These are synthetic-note measurements, not end-to-end interaction timings. Settings can prepare/remove the model; both work outcomes and trade revisits can request a question.

Thirty additional English/Korean examples yielded 26 matching first suggestions. All four errors were flagged ambiguous, with the expected topic among two options; the UI asks the user to choose. Another 34 development examples matched after tuning and are not independent evidence. This is a small authored evaluation, not a general accuracy claim or a contest score. See [implementation, sources and limits](docs/ON_DEVICE_REFLECTION.md) and [raw device results](docs/AI_DEVICE_051.json).

New records preserve their first saved reason and plan separately from later edits. For older records, the baseline is the last persisted note at the first update after upgrading; earlier revisions cannot be reconstructed.

The 0.5.1 changes are local. Existing public downloads, presentation and demo may still describe 0.3.1. See [the revised submission draft](docs/submission/REVISION_040.md).

Local 0.5.1 verification on 28 September: 93 Flutter tests passed, static analysis reported no issues, and 64 synthetic-note device checks plus Unicode, cancellation and recovery checks passed without an active network. The supported live swap-to-journal release gate below remains separate.

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

## What is ready, and what is still a release gate?

The default APK runs the local work journal and direct read-only wallet journal without Firebase configuration or billing. MWA supplies the selected public address; the device queries the official Solana mainnet public RPC and parses supported finalized swaps locally. It never requests a message signature or transaction signature in this mode.

**The supported live swap-to-journal rehearsal remains required before competition submission.** A real Seeker wallet connection and public activity read succeeded on 28 September; the retrieved activity was outside the supported swap subset. Automated tests and an Android emulator walkthrough are documented; a complete supported live swap-to-reflection flow is not claimed. Public RPC is best-effort and may rate-limit or reject traffic. Shared rooms, SGT verification and purchases remain optional server features and are hidden in the default edition. They require a separate configured backend. The preview APK uses a development signing key. See [the free approach](docs/submission/FREE_PREVIEW_APPROACH.md).

The prior 0.3.1 release passed 88 Flutter tests and clean analysis; these historical results do not establish 0.4.1 device readiness. A separate manual check of the release app with the official Solana mock wallet on an Android emulator verified approve, account return, an empty mainnet history response, disconnect, cancellation and retry. It involved no message/transaction signing or asset movement. This is separate from the labeled sample reflection flow and does not establish physical Seeker or supported live event-to-reflection behavior.

The activity parser deliberately accepts only a supported subset of successful Jupiter v6 classic SPL-token swaps. Unsupported, ambiguous and failed transactions remain read-only activity rather than being presented as successful swaps. This is not a complete trading history, trading venue or profit/loss service.

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

The [English submission kit](docs/submission/README.md) contains the requirements, official registration link, product description, pitch copy, three-minute demo script, captions and release checklist. The accompanying delivery package contains the pitch deck and media. Required contest materials are an Android APK, GitHub source, demo video and pitch presentation. Verify the final entry's live integration before submitting.

The final walkthrough uses real local storage and native time. Its sample transaction-to-reflection sequence is visibly labeled **SAMPLE DATA · UI DEMONSTRATION · NOT A LIVE TRADE**. The fixture lives only in the integration test and is never enabled in the released application. It demonstrates implemented UI and persistence, while live-wallet operation remains a separate evidence gate.

## Privacy and project history

Local notes are not uploaded automatically. The optional AI download contacts Hugging Face and its HTTPS CDN; inference uses local writing on the device. The model can be removed without deleting notes. The free wallet journal sends only public wallet addresses, transaction IDs and read parameters to Solana public RPC. It does not send notes or project names. Optional server features use wallet addresses and service state; chain transactions are public. Exported files contain your notes and should be stored privately. Cloud backup and import/restore are not implemented; export is an archive, not a one-tap restore promise.

Original architecture and earlier validation are retained in `docs/`. Their dates and versions matter: 0.2.0 and 0.3.0 results do not automatically validate 0.3.1. Earlier reference prompts and diagnostic exports remain in the original local archive and are excluded from the published source.

The app was previously named Workroom. Its package identity is `app.workroom.seeker_workroom`; the current product name is **FOR THE RECORD**.

See [the dated Seeker evidence](docs/SEEKER_DEVICE_041.md).
