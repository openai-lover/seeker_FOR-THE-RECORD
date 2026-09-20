# Submission copy

The exact revised mobile-development answer saved in the portal is in [SUBMISSION_ENTRY_EN.md](SUBMISSION_ENTRY_EN.md). Use the sections below as supporting copy. This is English copy grounded in the current source and known deployment state. Do not remove the implementation-status disclosure unless fresh evidence establishes the live path.

## Project name

FOR THE RECORD

## Tagline

For the record, this is why I did it.

## Short description

A decision journal for Seeker: leave your future self the reason behind today's choices. Revisit supported wallet activity with your own notes, and pick up unfinished work with your next step already waiting.

## Product description

A week after a swap, would you remember what you were thinking? FOR THE RECORD lets you save your reason, plan and next step beside supported wallet activity, then return to add what you learned. Your own words give past decisions their context back.

The app starts with a useful offline workflow. Create a project, set an intention, choose a focus duration, then record the result and next action. Returning users choose “Continue from your bookmark” to begin with their last next action already filled in. Project books preserve the work over time. Users can edit or delete their records and export them as JSON.

The Solana extension uses native Mobile Wallet Adapter to select an account and reads supported finalized activity directly through public RPC. This keeps the journal usable without a paid backend or Firebase billing upgrade. A conservative local parser recognizes a narrow set of Jupiter v6 classic SPL swaps. Four guided steps capture reason, plan, emotion and next action; each can be left blank. Later, users reopen the record and add what they learned. Chain facts stay separate from editable personal notes. Unsupported or ambiguous activity remains explicitly unsupported.

Private writing stays in local SQLite. Core work journaling needs no wallet, account or network. The journal does not execute trades, predict returns or reward trading volume.

## Why mobile and why Seeker

Reflection is most useful near the moment of a decision. A phone makes it easy to capture a short reason and return later. Native Android integration supports wallet handoff, local storage, optional reminders, file export and recovery after the app leaves the foreground. Seeker adds a natural audience of people already using a mobile wallet. The product's Solana value depends on demonstrating the actual wallet-to-reflection path on a device.

## What makes it different

Work sessions and supported wallet events share one behavior: state an intention, keep the result, and leave a next action. The app separates immutable event facts from editable reflection and gives offline work immediate value. It focuses on remembering decisions without presenting activity as profit, performance advice or a reason to trade more.

## User experience

English is the new default. Settings offer Korean, Japanese, Simplified Chinese, Hindi, Spanish, Portuguese and French. User-written notes keep their original language. The interface uses clear action labels, large touch targets and explicit saving and recovery states. Motion, haptics and reminders are optional. The final submission should use the exact tested build and a verified language walkthrough. Translations still require fluent human review before a broad release.

## Technology

Flutter and Dart for the app. Kotlin for Android Mobile Wallet Adapter, elapsed-time recovery, notifications and file export. SQLite for local records. The direct read-only wallet path uses public Solana RPC and a conservative parser. The repository also retains optional Firebase/TypeScript infrastructure for shared features and purchases. Those cloud features are not required for the journal and remain unavailable without their backend. No custom on-chain program is required for the journal.

## Current implementation status — include this disclosure

The 0.3.1 source contains the native MWA bridge, conservative activity parser and local journal flow. It adds a more focused home screen, a direct bookmark return, four-step reflection writing and an original skippable launch signature. Direct wallet reads remove the journal's paid-server dependency. Automated and emulator results must be read against their exact build versions. Those checks establish local logic and emulator behavior; they do not establish successful physical-device wallet operation.

The direct journal path does not require Firebase Functions or a paid RPC account. Public RPC is shared infrastructure with rate limits and no production service guarantee. A successful real-wallet run on a physical device remains unverified. SKR purchases and optional cloud rooms remain unavailable in the free preview. Complete the live wallet-to-reflection evidence before claiming that the entry meets the hackathon's functional network requirement. Sample screenshots containing transactions use synthetic test fixtures and are not live trading evidence.

## Development during the hackathon

The repository includes work-session persistence and recovery, native wallet integration, server-side verification and transaction guards, a conservative wallet activity parser, and private trade reflections. The latest iteration adds the FOR THE RECORD identity, an English default, eight-language selection, a bookmark return and guided reflection writing. Preserve commit history and list the actual start date and new work in the final entry. Do not infer the project's origin or team membership from archive timestamps.

## Validation statement

Version 0.3.1 passes 88 Flutter tests and clean static analysis, including eight languages at a 360-pixel viewport and 200% text size. The optional backend's unchanged suite previously passed 40 tests. The new Android integration walkthrough passes with actual SQLite and native time: project, intention, early finish, saved next action and bookmark return. It also checks native missing-wallet handling and a persistently labeled sample event-to-reflection-to-later-review sequence. Test fixtures are absent from the release app.

A separate manual test of the 0.3.1 app with the official Solana mock wallet on an Android emulator verified connection approval, account return, public mainnet empty history, disconnect, cancellation and retry. It requested no transaction or message signature and moved no assets. This is native integration evidence; it is not physical Seeker, Seed Vault, or supported live trade-to-reflection evidence. The automated wallet driver did not pass, so this wallet result is reported as manual. Physical-device accessibility and fluent-speaker review remain open.

## Roadmap

First complete the live wallet and device evidence. Then validate the translations and primary tasks with fluent speakers and target users. Measure time to first saved record, successful return to the next action and voluntary repeat use. Choose production RPC infrastructure according to measured usage, then prepare a stable signing key, a verified privacy notice and dApp Store assets. Broader activity parsing is a later expansion and should retain the same strict treatment of unsupported formats.

## Links to enter

- Source repository target: https://github.com/openai-lover/seeker_FOR-THE-RECORD — source and full commit history are public and accessible to judges.
- ARM64 preview APK: https://github.com/openai-lover/seeker_FOR-THE-RECORD/releases/download/v0.3.1/FOR-THE-RECORD-0.3.1-arm64.apk
- Playable demo page: https://workroom-seeker-6984.web.app/#preview
- Video file: https://workroom-seeker-6984.web.app/downloads/FOR-THE-RECORD-demo.mp4
- English pitch PDF: https://workroom-seeker-6984.web.app/downloads/FOR-THE-RECORD-pitch.pdf

Verify the final public links after deployment. [Download details and APK SHA-256](DOWNLOAD_LINKS.md) identify the exact preview artifact. A local source archive is included in the owner's complete delivery. It is not publicly hosted and does not replace judge access to the GitHub repository and its history.

## Owner-supplied fields

The account owner must supply or verify the builder's name, contact email, team roster, representative, residence, age/eligibility declarations, funding status and actual project start date. No identity or declaration has been invented in this kit.

Public Google Drive demo used in the actual submission draft: https://drive.google.com/file/d/14Dk5ewt73P9MhbMu5d-tpu5zE1UTfOsI/view?usp=drivesdk
