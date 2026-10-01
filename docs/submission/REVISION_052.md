# 0.5.2 · Feedback-driven revision

Last observed AI Coach: 34/100, 30 September 2026. It could not read the deck,
obtained no useful demonstration transcript and had no code audit. That result
is not a review of this revision. Final submission is prohibited by the owner.

## Actual changes

- One action on home opens the oldest due reason and shows its original writing.
- Due dates refresh while the room stays open without an active focus session.
- First-reason validation applies to every step of the optional guided form.
- A lesson alone completes a revisit; an empty revisit cannot be saved as done.
- Edits retain the first completion time and an unchanged lesson's saved time.
- Choosing another future revisit date reopens a completed record for review.
- Changed writing clears a previous AI selection and its pending alternatives.
- One-record JSON export includes source facts, preserved reason, edited notes,
  reflection, lesson and question provenance.
- Isolated Android builds include x64 for a dedicated emulator walkthrough.
- New interface messages retain all eight supported language routes.

The app ID, SQLite database, additive schema, room design, onboarding, read-only
wallet behavior and optional pinned model remain compatible with 0.5.1.

## Current reproducible path

`integration_test/decision_replay_walkthrough_test.dart` substitutes the HTTP
response while running the production direct RPC reader, parser, room and real
SQLite. The visible banner identifies synthetic activity, advanced time and
database reopen. It never authorizes a wallet or uses the personal database.
Reduced motion is enabled only for deterministic verification. The fixture is
kept under integration tests, separate from the release entrypoint.

Current analysis, test, Android walkthrough and APK receipts are saved in the
task workspace. Only completed runs may be reported as passing; historical
0.5.1 device evidence remains separately dated and scoped.

## Review sequence

The English visual deck has illustrations, labeled app screens, an editable
model-size chart and an evidence table. The narrated screen walkthrough must
identify its emulator fixture and manual question selection. Physical AI
evidence remains version 0.5.1, 28 September.

Publish the exact source and APK, link readable Slides and a useful transcript,
then use the one free audit only on the actual latest public commit. Reassess
the updated evidence at least three hours after the previous completed review.
Code publication and latest material links remain separate steps until verified.
Do not finalize the competition entry.
