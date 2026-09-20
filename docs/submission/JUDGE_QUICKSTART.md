# FOR THE RECORD · Judge quickstart

**For the record, this is why I did it.**

[Download the Android preview and release materials](DOWNLOAD_LINKS.md).

The preview demonstrates a private Android work journal and a direct read-only path for supported wallet activity. The journal does not require a paid backend. Public RPC has availability limits, and real-wallet physical-device validation remains an open evidence gate.

## Try the local workflow

1. Install the supplied **ARM64 preview APK** on a compatible Android phone. Use the x64 build only for a compatible emulator. The release notes identify the exact version, hash and signing type.
2. Open FOR THE RECORD. English is the default.
3. Create a project named “My next release.” Set the intention to “Make the first screen easier to understand.”
4. Choose a duration and start a focus session. Pause and resume if desired. Finish early for this short walkthrough.
5. Save a result and a next action. Suggested result: “Made the primary action clearer.” Suggested next action: “Test the screen with one new user.”
6. Return home and open the project book. Check that the saved record and next action remain after restarting the app.
7. Open Settings, change the interface language, and return to English. User-written content should not change.

The local workflow requires no account, wallet or network. A saved record comes from the user's explicit action. Letting the timer expire does not fabricate a result.

## What the wallet preview demonstrates

The source contains a native Mobile Wallet Adapter bridge and a conservative parser for supported finalized activity. The direct mode uses the selected wallet account and public RPC without requiring Firebase Authentication or Functions. The journal separates event facts from private reflection. Unsupported activity stays unsupported.

A successful real-wallet run on a physical device remains unverified. Automated test fixtures are not real transactions. Public RPC can rate-limit or reject requests, so retry states should preserve local records. Optional cloud rooms and payment functionality remain unavailable. No live trade or payment is necessary to try the local workflow or inspect an already-existing supported transaction.

## Data and code

Work records and reflection text stay in local SQLite. JSON export creates a portable copy containing private writing, so use a demonstration project for review. The export is not a cloud synchronization or restore service.

- [Source archive](https://workroom-seeker-6984.web.app/downloads/FOR-THE-RECORD-source-0.3.0.zip)
- [Requested source repository](https://github.com/openai-lover/seeker_FOR-THE-RECORD) — publication and access require verification.
- [Free preview implementation and limits](FREE_PREVIEW_APPROACH.md)
- [Current release checklist](RELEASE_CHECKLIST.md)

Historical results apply to the versions they name. Consult the new release evidence for version 0.3.0.
