# FOR THE RECORD · CLOCK IN submission kit

**For the record, this is why I did it.**

English materials for the CLOCK IN Solana Mobile Hackathon. Requirements checked against official pages on **20 September 2026**. This kit prepares a submission. It does not claim that registration, submission, production release, physical-Seeker validation, or contest submission has happened.

## Start here

[Download links, APK details and the submission route](DOWNLOAD_LINKS.md).

1. [Requirements and official links](REQUIREMENTS.md)
2. [Submission text](SUBMISSION_COPY.md)
3. [Three-minute demo script and storyboard](DEMO_SCRIPT.md)
4. [Device rehearsal and evidence](DEVICE_REHEARSAL.md)
5. [Release and submission checklist](RELEASE_CHECKLIST.md)
6. [Judge quickstart](JUDGE_QUICKSTART.md)

The English pitch is available as an [editable PowerPoint](FOR-THE-RECORD-pitch.pptx) and [PDF](FOR-THE-RECORD-pitch.pdf). The editable source of its copy is [PITCH_CONTENT.md](PITCH_CONTENT.md).

The [three-minute demo video](FOR-THE-RECORD-demo-3min.mp4) contains **123 seconds of actual recorded app footage**, original motion typography and close views of saved records. It uses English on-screen explanations, a quiet original two-note brand sound and [matching English captions](FOR-THE-RECORD-demo-3min.srt). There is no spoken narration or stock media. See [capture details and chapters](DEMO_VIDEO.md).

## Current readiness

Version **0.3.1** passes **88 Flutter tests** with clean analysis. Language/layout checks include eight languages, a 360-pixel viewport and 200% text size. The optional backend's unchanged suite previously passed 40 tests.

The final Android emulator integration walkthrough passes with real SQLite and the native clock. It shows the local project-to-bookmark loop, native missing-wallet handling, and a persistently labeled sample event-to-reflection-to-later-review sequence. The sample data exists only in the integration test, never in the released APK. The [screenshots](screenshots) document those results.

Separate manual testing of the 0.3.1 release app with the **official Solana mock wallet on an Android emulator** verified connection approval, public account return, public mainnet empty history, disconnect, cancellation and retry. It requested no message/transaction signature and moved no assets. The video labels this evidence explicitly. The automated wallet driver did not pass; do not describe the manual result as an automated wallet E2E pass.

The preview uses native MWA and a direct read-only public-RPC path, so the journal requires no paid server or Firebase billing upgrade. Optional shared rooms and purchases remain separate unavailable cloud features. Public RPC is rate-limited infrastructure with no production service guarantee. See [the free preview approach](FREE_PREVIEW_APPROACH.md).

**Physical Seeker, Seed Vault and a supported live event-to-reflection run remain unverified.** The manual empty-history result and labeled fixture flow are distinct evidence. Complete that live path before claiming the competition's meaningful network requirement is established. No user research, retention, profit or performance result is claimed.

## Links

- [Official registration and submission portal](https://solanamobile.radiant.nexus/) — open **HACKATHON HUB**, sign in to Align, complete the builder profile, then open Clock In Registration.
- [Preview website and delivery materials](https://workroom-seeker-6984.web.app/)
- [Requested project repository](https://github.com/openai-lover/seeker_FOR-THE-RECORD) — source is pushed; private repository visibility requires judge-access verification.
- [Official announcement](https://solanamobile.com/blog/clock-in-the-solana-mobile-hackathon)
- [Binding terms](https://solanamobile.radiant.nexus/legal/clock-in-terms.pdf)

The portal's private submission form was behind sign-in during this review. The exact private field labels, character limits and upload restrictions have therefore not been verified. The prepared copy is organized by content purpose for transfer into that form.
