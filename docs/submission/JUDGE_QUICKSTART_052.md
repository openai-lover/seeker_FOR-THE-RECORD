# FOR THE RECORD · Current judge quickstart

Version 0.5.2+9, local development preview. Public download versions are listed
separately in [DOWNLOAD_LINKS.md](DOWNLOAD_LINKS.md). The entry remains a draft.

## Problem and return loop

A transaction history preserves the event, but not the explanation behind the
choice. FOR THE RECORD is a private room for Seeker owners who already revisit
their wallet activity. Save a reason, return to the first saved writing, and keep
a lesson connected to its source transaction. This is a product hypothesis,
not evidence of traction or investment benefit.

## Try the current room

1. Install the ARM64 preview without uninstalling an existing personal workroom.
   Keep the same signing key. Swipe through the welcome pages or choose **Skip**.
2. The desk opens the decision journal, the lamp opens focus, and the shelf holds
   saved work. Choose **Leave a reason**, then connect an MWA compatible wallet.
3. Account selection and direct public RPC are read-only. Choose **Write
   reflection** on a supported swap. Other activity stays visibly unsupported.
4. Write one reason. Choose a revisit in 1, 3 or 7 days, or **No date**. Choose
   **Save reason**. Plan, emotion and next action are optional.
5. **Recorded · Open journal** preserves the first saved explanation separately
   from later edits. **Export this record** saves that record's JSON locally.
6. Once due, the primary **Revisit my reason** action opens the oldest due note.
   Revisit needs no wallet or network. Compare the first writing with today's
   experience, and optionally choose a reflection question.
7. Write a reflection, a lesson, or both. **Save on this device** completes the
   revisit. **Time to reflect → Saved lessons** links the lesson to its source.
   Saved notes and lessons survive a restart.

The optional E5 Q8 encoder selects among five authored questions; it is not a
generative LLM. Its one-time model is 132,439,008 bytes. After setup it works
offline. Ambiguous results ask the user to choose; edited writing invalidates
the earlier suggestion. The user always writes the answer and lesson.

## Reproduce without a live trade

```powershell
./tools/record-decision-replay.ps1 -Device emulator-5554
```

Prepare Flutter, Android API 36 and a compatible JDK using [SETUP.md](../SETUP.md).
The runner rejects a personal phone or an emulator with the normal app installed.
The harness uses the production RPC reader/parser and real temporary SQLite,
with a permanent synthetic-fixture banner. It labels the one-day clock advance
and database close/reopen. Reduced motion is enabled in the test; x64 uses manual
question selection. The fixture is never included in the normal release entrypoint.

This checks supported synthetic activity → first reason → baseline-preserving
edit → due home action → reflection and lesson → reopen → JSON content. It does
not prove a live transaction, physical wallet authorization or native AI on x64.

## Separate evidence and limits

- Seeker 0.4.1, 28 September: wallet account selection and public history were
  checked; retrieved activity was outside the supported subset.
- Seeker 0.5.1, 28 September: model preparation, question selection, offline
  timings and authored evaluations are documented in
  [ON_DEVICE_REFLECTION.md](../ON_DEVICE_REFLECTION.md).
- A supported live swap through a completed revisit is still unverified.
- SKR purchases and SGT verification are future work in the default edition.
  No live payment, interviews, user count or retention rate is claimed.
- JSON export contains private writing. Use demonstration records when sharing.
  Import and cloud backup are not provided. Due notices are in-app, not scheduled
  trade push notifications.

The next consented pilot will measure first-reason activation, completed revisits
per eligible due note and return in days 8–14. Definitions and denominators will
be fixed before collecting evidence. No pilot has run yet.
