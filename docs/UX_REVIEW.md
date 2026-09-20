# UX and logic review — FOR THE RECORD 0.3.0

Review date: 20 September 2026. This was a code, automated interaction, and layout review. It was not a human usability study, a native-speaker translation review, or physical Seeker certification.

## Changes made from the review

| User situation | Change |
|---|---|
| First launch on a non-English device | English is the default. Settings offers English, Korean, Japanese, Simplified Chinese, Hindi, Spanish, Portuguese, and French. User-written titles and notes retain their original text. |
| Leave an outcome immediately after typing | Back navigation persists the draft before leaving, including before the 500 ms autosave delay. A storage failure keeps the editor open. Editing an already saved page requires a discard decision. |
| Enter an invalid focus duration | The dialog shows a visible validation message and remains open for correction. |
| Restart a phone with a paused timer or an outcome draft | The known duration is retained. Only a running timer with an uncertain elapsed duration asks for recovery. |
| Add a later reflection to a journal | Partial edits preserve earlier reasons, plans, emotions, next actions, and project links. Explicit clearing remains possible. |
| Switch wallets, disconnect, or leave a screen during a request | Delayed activity, profile, room, and purchase responses are guarded against replacing newer state or notifying disposed screens. |
| A purchase finalizes after the quote deadline | An exact authorized on-chain payment can still earn its entitlement. Initial submission remains subject to quote expiry; message, signer, asset, amount, recipient, and reference checks remain enforced. |
| Use wallet history without a paid backend | The default read-only path uses MWA to select a wallet and reads public activity directly from Solana RPC. It sends no notes, signs no transactions, and needs no Firebase service. A build with both cloud and direct-wallet features disabled explains the unavailable connection. |
| Prefer reduced motion or large text | The opening animation respects reduced-motion settings. Scrollable layouts and wrapping controls are used; narrow-screen locale smoke tests are included. |

## Evidence for this revision

**Final full suite: 84 tests passed; Flutter analyzer reported no issues.**

- **34 focused Flutter tests passed:** controller, journal persistence, remote-state guards, transaction guard, and the first six UX regressions.
- **9 existing widget tests passed:** offline work and trade-journal interactions, including regenerated visual baselines for the redesigned interface.
- **40 Functions tests passed; TypeScript checking passed:** sign-in challenge verification, room logic, activity normalization, signed-order checks, and receipt validation. Fixtures and mocks were used; no payment was made.
- **10 direct-activity tests passed:** conservative local Jupiter parsing, exact amounts, unsupported and failed transactions, address/cursor validation, request privacy, retry limits, bounded concurrency, and cache behavior. The Retry-After test exposed a case-sensitive header lookup; it was fixed and passed the final rerun. These tests use an HTTP mock, not a physical wallet or live transaction history.
- **8 direct-connection tests passed:** authorize-only wallet connection without Firebase or signing, preservation of private notes, account-switch and disconnect races, missing wallets, and cancelled approvals.
- **16 UX widget regressions passed:** `test/ux_regression_test.dart` covers draft navigation and save failure, explicit keep-draft behavior, preservation of a user title matching an interface label, duration validation, unavailable-mode communication, and real Home, Settings, Work journal, and Trade journal screens in all eight languages at 360 × 800 logical pixels with 200% text. The tests exposed Spanish and French Home overflows; the updated layout passed the confirming run.

Widget tests exercise rendered Flutter widgets with synthetic data and injected clocks. Visual baselines are regression artifacts, not evidence of user satisfaction. Older validation files in this repository describe earlier builds and should not be read as fresh checks of this revision.

## Remaining release checks

- Physical Seeker wallet approval, account switching, genuine SGT admission, two-device shared sessions, and live payment recovery.
- Deployed Firebase HTTP paths, production configuration, and current Firestore rule integration. This review did not redeploy or retest the service end to end.
- TalkBack, keyboard navigation, long-session battery behavior, and glyph rendering on physical devices. Layout smoke tests do not certify accessibility or font coverage.
- Native-speaker review of the six added translations and task-based usability sessions with people unfamiliar with the app.
- Production signing, support/operator details, privacy retention commitments, and store or contest submission acceptance.

The current preview should be presented as an offline-capable journal with a free, read-only public-RPC wallet path. Wallet activity needs a compatible wallet and network access; public RPC rate limits can interrupt loading. Optional cloud collaboration and payments still need their own configuration and validation. The preview should not be described as fully validated on a physical Seeker or approved for production payments.
