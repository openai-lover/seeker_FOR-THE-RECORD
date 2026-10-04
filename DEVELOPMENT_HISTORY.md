# FOR THE RECORD · Versioned development history

Historical observations from earlier releases. Current evidence is in [README.md](README.md).

## Versioned development history

The sections below retain dated observations. Their version-specific timings,
screenshots and former availability statements are historical; current materials
are indexed above.

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
[historical 0.5.2 walkthrough](docs/submission/JUDGE_QUICKSTART_052.md) and
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
