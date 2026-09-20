# Device rehearsal and evidence

Run this on a dedicated test device or emulator with disposable records. Do not run destructive integration helpers against someone's personal installation. The original project notes warn that Flutter's integration runner affected the main package despite a test suffix.

## The complete first-use journey

| Action | Expected result | Evidence |
|---|---|---|
| Fresh launch | English appears without a language/setup barrier | Screenshot + version |
| Create project | Clear name, focus intention and duration | Continuous capture |
| Start, pause, resume, finish early | Only one active focus session, understandable elapsed time | Capture and logs |
| Save result and next action | One record only, explicit saved state | Reopen the record |
| Return home | Previous next action makes the next step obvious | Screenshot |
| Edit / cancel / delete | Cancel preserves content, destructive actions are understandable | Capture with disposable record |
| Export | Android file picker saves JSON containing work and trade journals | File inspection |
| Go offline | Local records remain usable and wallet limitations remain clear | Capture |

## Eight-language and accessibility pass

Select each language in Settings: English, Korean, Japanese, Simplified Chinese, Hindi, Spanish, Portuguese and French. Verify the selected language survives restart. Check home, project creation, focus controls, save/validation messages, journal, settings and wallet errors. Check that notes retain their original text. A translated menu alone is not a complete localization pass.

Repeat the main path on a narrow phone and at large system text size. Verify no clipped action labels, missing glyphs, obscured fields, keyboard-covered save buttons or horizontal overflow. Check the actual Hindi and CJK fonts on the target device. Read the interface with TalkBack and verify meaningful labels and focus order. Test the system reduce-motion preference and app motion toggle. Fluent-speaker review remains a separate release task.

## Recovery and privacy

Background the app, lock the screen and reopen it. Force-stop and reopen using a disposable session. Reboot and inspect the explicit elapsed-time confirmation. Verify that no extra work record appears without user confirmation. Check that notification failure does not change the underlying time calculation. Review exported JSON before sharing because it contains private writing.

## Solana evidence gate

Use the direct wallet path in the current release. The older [Seeker checklist](https://github.com/openai-lover/seeker_FOR-THE-RECORD/blob/main/docs/SEEKER_CHECKLIST.md) also includes optional cloud features and should not be read as requiring a paid backend for the journal. Record the actual device model, Android version, app version, source revision and outcome.

1. Confirm the direct read-only mode and its configured public RPC endpoint. No Firebase billing upgrade is required for this journal path.
2. Connect an owner-approved real wallet through MWA. Confirm cancellation and missing-wallet handling.
3. Verify the selected account matches the MWA response, and switching or disconnecting the account prevents stale activity from appearing under a new account.
4. Retrieve one already-existing supported, finalized transaction. Do not trade solely to make a demo unless the owner separately chooses to do so.
5. Compare its signature, mints and integer amounts with a reputable Solana explorer.
6. Save a reflection, restart offline and confirm that the notes remain.
7. Verify unsupported and failed transactions never appear as successful supported swaps. Check rate-limit and unavailable-RPC states without losing saved writing.

Do not mark this gate complete based on synthetic fixtures, automated parser tests, source inspection or emulator screens alone. No SKR payment is required for the core journal demo. SKR is a separate optional award and payments remain disabled in the existing configuration.

## Evidence record

For every run, record: date/time, operator, device or emulator identity, APK version, APK SHA-256, source commit, exact test steps, observed result and screenshot/video path. Record failures too. Keep old-version results clearly separate from new-release evidence.
