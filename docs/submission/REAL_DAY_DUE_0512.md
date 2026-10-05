# Real scheduled-day due state - FOR THE RECORD 0.5.12

On **October 5 at 23:18:18.666 KST**, a physical Seeker showed an existing authored Demo journal as due, **25.8064 hours after its original save**. The current product home displayed **Revisit my reason**; root's screenshot observation was at **23:19:30.758 KST**. This is a technical post-due observation from a guarded, isolated read-only snapshot.

## Exact time and unchanged data

| Observation | Recorded value |
|---|---|
| Original saved time | October 4, 21:29:55.564 KST |
| Stored scheduled due time | October 5, 21:29:52.880 KST |
| Actual runtime observation | October 5, 23:18:18.666 KST; isDue=true; one due entry |
| Delay interpretation | One-day scheduled setting; stored due time is 23h59m57.316s after final save. Elapsed time at observation is 25.8064h. |
| Data preservation | All 11 authored Demo rows/settings remain identified by exact unchanged isolated DB/WAL fingerprints. |

Root completed on-phone hash comparisons before/after the guarded read, against previously validated snapshots. Both the due database/WAL and separate known-case database/WAL matched. No new raw database transfer or process force-stop occurred. The production database was not accessed.

The diagnostic opens only the existing isolated SQLite database read-only, checks the expected record/fingerprints, closes SQL **before UI**, then displays the current product home from an in-memory snapshot. Writes, native/remote calls, seeding and clock overrides are blocked; input is absorbed. The isolated writer was inactive. No reflection was saved.

## Current code and bounded runtime evidence

Production app/tag **ee650639670c7ab35081a92e3435a185b73a6642** / **0.5.12+19** is unchanged. Separately compiled private diagnostic, SHA256 **3b0a79005b09d54befe3db2d3d236656752feadae30c4fb37111ba37e10cc8d9**. Its preparation-only header predates the execution receipt. The diagnostic source with internal paths/identity hashes is excluded from this public commit.

The product uses [DateTime.now by default](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/ee650639670c7ab35081a92e3435a185b73a6642/lib/domain/controller.dart#L13). Its [due predicate](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/ee650639670c7ab35081a92e3435a185b73a6642/lib/domain/trade_journal.dart#L120) requires scheduled time <= actual current time and no completed review. The [home filter](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/ee650639670c7ab35081a92e3435a185b73a6642/lib/ui/home.dart#L23) selects the earliest due record, and the [actual action label](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/ee650639670c7ab35081a92e3435a185b73a6642/lib/ui/home.dart#L173) changes to Revisit my reason. [Foreground refresh](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/ee650639670c7ab35081a92e3435a185b73a6642/lib/ui/app.dart#L229) checks due entries every second and on resume.

The runtime log was truncated. Only the usable prefix, including stored/actual times, isDue=true and dueCount=1, was parsed. **Complete runtime JSON is unavailable.** Separate fingerprint checks and visible home evidence must not be described as recovered full-log fields. [The safe receipt](../evidence/real-day-due-0512.json) excludes raw notes, wallet/signature identifiers, record UUIDs and private paths.

## Limits and publication state

An existing isolated record surfaced in the current home after its actual scheduled day passed, without clock manipulation. The instant of crossing the boundary was not continuously recorded. This does not establish normal production-account operation, native journal notification, completed reflection/restart, three/seven-day behavior or human return/retention. Independent participants remain zero.

Root approved the exact public-safe clip after checking all 20 CFR samples and nine boundary samples, and approved the JPEG after visual inspection. The **19.875-second**, **1,520,691-byte** [clip is published in v0.5.12](https://github.com/openai-lover/seeker_FOR-THE-RECORD/releases/download/v0.5.12/FOR-THE-RECORD-real-day-due-0.5.12.mp4), SHA256 **d218ad8607efe0fc5b1e6af3ab6bbd7b9a00163c1707b21828db2c18c0ffbc3a**. Root verified its matching GitHub server digest at **2026-10-05T14:51:02.086229+00:00**, along with all six new material assets; existing APKs, assets and tag were preserved. The JPEG is **169,174 bytes**, SHA256 **de6ccb21a9a850aa6087ff59eba4ae3dbc8bd2918b548722caa72ad289a861f0**, at docs/evidence/real-day-due-0512.jpg. It is approved and present locally/staged, but its source commit/push is not yet verified at note preparation. This is root/agent artifact QA, not human participant validation. The short clip does not record a whole day or the due-boundary crossing. Raw media remain private. The latest actual Coach at preparation is **77/100**, criteria AI 78 / SKR 78 / UX 84 / UI 82 / innovation 74 / ecosystem 67, with **DRAFT** retained. This new technical evidence has not been reassessed.
