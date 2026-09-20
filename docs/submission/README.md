# FOR THE RECORD · CLOCK IN submission kit

**For the record, this is why I did it.**

English materials for the CLOCK IN Solana Mobile Hackathon. Requirements checked against official pages on **20 September 2026**. This kit prepares a submission. It does not claim that registration, submission, production deployment, or real-wallet validation has happened.

## Start here

[Download links, APK details and the submission route](DOWNLOAD_LINKS.md).

1. [Requirements and official links](REQUIREMENTS.md)
2. [Submission text](SUBMISSION_COPY.md)
3. [Three-minute demo script and storyboard](DEMO_SCRIPT.md)
4. [Device rehearsal and evidence](DEVICE_REHEARSAL.md)
5. [Release and submission checklist](RELEASE_CHECKLIST.md)
6. [Judge quickstart](JUDGE_QUICKSTART.md)

The English pitch is available as an [editable PowerPoint](FOR-THE-RECORD-pitch.pptx) and [PDF](FOR-THE-RECORD-pitch.pdf). The editable source of its copy is [PITCH_CONTENT.md](PITCH_CONTENT.md).

The [three-minute demo video](FOR-THE-RECORD-demo-3min.mp4) combines actual Android emulator interaction with still captures of the running app. It has English on-screen explanations and no audio. [Supplemental English captions](FOR-THE-RECORD-demo-3min.srt) match the final chapter edit. This is an edited preview walkthrough, not continuous physical-device or live-wallet evidence.

## Current readiness

The current source supports an offline work journal, local trade reflections, Android recovery behavior, native Mobile Wallet Adapter and direct read-only Solana activity. The version 0.3.0 Flutter suite passes all 84 tests and analysis is clean. The localization and layout checks include eight languages and a 360-pixel viewport at 200% text scale. Forty backend tests also pass; the optional backend is separate from the free journal path.

On September 20, an Android emulator walkthrough of the updated interface completed the project, intention, focus, result and journal path using SQLite and the native clock. The final direct-mode run also verified the native missing-wallet path. The screenshots in [screenshots](screenshots) document the run. This is emulator evidence, not a physical Seeker or successful live-wallet test.

The preview uses a **direct read-only wallet path** so the journal does not require Firebase billing or a paid server. MWA supplies the selected account, and the app reads public Solana activity. Optional shared rooms and purchases remain separate cloud features. See [the free preview approach](FREE_PREVIEW_APPROACH.md).

The open evidence gate is a successful **real-wallet run on a physical device**. Parser tests and emulator screens do not establish that result. Public RPC also has rate limits and no production service guarantee. Keep these limits visible in the entry and verify the live wallet-to-reflection path before final submission.

## Links

- [Official registration and submission portal](https://solanamobile.radiant.nexus/) — open **HACKATHON HUB**, sign in to Align, complete the builder profile, then open Clock In Registration.
- [Preview website and delivery materials](https://workroom-seeker-6984.web.app/)
- [Requested project repository](https://github.com/openai-lover/seeker_FOR-THE-RECORD) — publication and access require final verification.
- [Official announcement](https://solanamobile.com/blog/clock-in-the-solana-mobile-hackathon)
- [Binding terms](https://solanamobile.radiant.nexus/legal/clock-in-terms.pdf)

The portal's private submission form was behind sign-in during this review. The exact private field labels, character limits and upload restrictions have therefore not been verified. The prepared copy is organized by content purpose for transfer into that form.
