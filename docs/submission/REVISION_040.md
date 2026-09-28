# FOR THE RECORD - 0.4.0 submission revision

Prepared 28 September 2026. This is a working submission draft. Physical Seeker evidence, final narration, publication and a fresh AI Coach result are pending. Existing public URLs may serve 0.3.1.

## Short description

FOR THE RECORD is a private journal for wallet decisions on Seeker. Attach one reason to a supported Solana transaction, revisit the original writing later, and save a personal lesson for your next choice. An optional local AI model selects a reflection question without sending your notes to a server.

## Product description

A wallet history records what happened. FOR THE RECORD adds the user's explanation and makes it easy to return to that explanation. The first audience is Seeker users who already review their swaps and want a consistent reflection habit.

The user connects a wallet through native Mobile Wallet Adapter, selects a supported historical swap and saves one reason. A revisit date brings the entry onto the home screen. During review, the first saved reason stays visible alongside the later reflection. The user can save a personal lesson and reopen its source record.

Qwen3-0.6B runs through Google LiteRT-LM on ARM64 Android after a one-time model download. It reads a bounded excerpt of the private note and selects one of five questions. The user writes the answer. This is a real local inference implementation; physical Seeker speed and quality remain to be demonstrated.

The existing offline work journal supports intentions, focus sessions and a saved next action. Eight interface languages are available. Wallet authorization and public RPC reads remain separate from personal writing. The default edition asks for no transaction signature and executes no trade. Supported activity is limited to a subset of successful Jupiter v6 classic SPL-token swaps; other activity remains explicitly unsupported.

## Pitch copy - eight slides

### 1. FOR THE RECORD
Private reflection for wallet decisions on Seeker.
For the record, this is why I did it.

### 2. The missing reason
Your wallet remembers the transaction. Your journal remembers why.
A later review is more useful when the original explanation is still available.
Initial audience: Seeker users who want to learn from their own wallet decisions.

### 3. Decision Replay
Save a reason beside a supported transaction. Choose when to revisit it.
The home screen brings back the saved writing. A later reflection becomes a personal lesson with a link to its source.
Show the actual 0.4.0 app here; use visibly labeled sample data only when necessary.

### 4. AI on the phone
One question selected for your writing. The answer remains yours.
Optional Qwen3-0.6B inference through LiteRT-LM. One 347 MB download; then no cloud inference or API account.
Physical Seeker inference evidence is pending. Do not replace that status with a speed claim until measured.

### 5. Solana connection
Native Mobile Wallet Adapter supplies the selected public account.
The device reads supported finalized swaps through public RPC.
Transaction facts stay fixed. Personal writing stays local.
The recorded reason is written after the transaction; it is not proof of prior intent.

### 6. A reason to return
The next review starts with a specific earlier choice, not a blank page.
One-tap reason saving reduces the initial writing effort. A personal lesson makes the review reusable.
Retention is a hypothesis. A pilot should measure first reason saved, completed revisit and second-week return, with participant consent.

### 7. Delivery and evidence
0.4.0 adds baseline preservation, scheduled in-app revisits, personal lessons and a local AI bridge.
Separate implemented features from physical-device evidence. Prior emulator results concern 0.3.1.
Complete the Seeker wallet-to-record and offline AI run before final submission; do not claim traction or measured latency yet.

### 8. FOR THE RECORD
Your decisions, with the reasons you want to remember.
Next milestone: demonstrate the complete loop on Seeker and learn from returning users.

## Three-minute demo recording plan

Use spoken narration plus matching captions. Show actual actions in the new app. This storyboard is not a claim that the footage already exists.

| Time | Capture | Narration |
|---|---|---|
| 0:00-0:20 | Seeker and app home | “A wallet shows what I did. FOR THE RECORD helps me remember why, and return to that reason later.” |
| 0:20-0:45 | Real MWA connection and supported history | “I connect my wallet with Mobile Wallet Adapter. The app reads public activity. It does not ask me to sign a transaction.” |
| 0:45-1:10 | Save one reason and choose revisit date | “I choose a supported swap, write one reason and save. I can add detail now or come back later.” |
| 1:10-1:35 | Reopen original record and review | “The first saved explanation remains visible. My later reflection goes beside it, so I can compare what I expected with what I experienced.” |
| 1:35-2:05 | Downloaded AI, offline inference | “This optional model runs on the phone. It uses my writing to choose one reflection question. My notes are not sent to an AI service.” |
| 2:05-2:30 | Write lesson, save, open its source | “I write the answer and keep one lesson for the next choice. I can always return to the record behind it.” |
| 2:30-2:50 | Close and reopen app; local persistence | “The record stays on this device. The app also supports an offline work journal and eight interface languages.” |
| 2:50-3:00 | Closing title | “FOR THE RECORD. My decisions, with the reasons I want to remember.” |

For an early review before the due date, reopen the entry manually and say so. Do not make a newly created entry appear days old. Use a non-sensitive record and exclude balances/addresses from footage where possible. If no supported live swap exists, disclose that limitation; do not execute a trade just to stage the demo.

## Submission repairs from the supplied AI Coach result

1. Connect the correct GitHub repository in the portal and complete its requested audit. A public URL in prose is different from the connected CODE input.
2. Export the final deck with actual text and confirm text extraction works. The old image-only PDF is not adequate evidence for AI reading.
3. Record understandable spoken narration and captions. The supplied transcript contained repeated “You” and did not explain the product.
4. Publish matching APK, source, presentation and video versions after device verification. Re-run AI Coach against those same artifacts.
5. Review the final entry before submission. The portal's final submission agreement locks edits.

## Official judging

The official announcement weights Stickiness/PMF, UX, innovation and presentation/demo at 25% each. AI Coach's categories and score are feedback, not the official final result. SKR is an optional separate prize; adding an artificial payment step does not establish product value.

The portal schedule displayed 9 October 2026, 15:59 GMT+9 as the submission deadline when checked on 28 September. Check the live portal again before the final submission.

Sources: [Official announcement](https://solanamobile.com/blog/clock-in-the-solana-mobile-hackathon), [submission portal](https://solanamobile.radiant.nexus/), and the user-supplied AI Coach report. A score of 100 or a win cannot be guaranteed.
