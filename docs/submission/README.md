# FOR THE RECORD · CLOCK IN submission kit

**For the record, this is why I did it.**

English materials for the CLOCK IN Solana Mobile Hackathon. Requirements checked against official pages on **20 September 2026**. This kit prepares a submission. Solo registration is complete and the project draft is saved. Final contest submission awaits owner review. Production release and physical-Seeker validation remain incomplete.

## Current 0.5.1 AI evidence

The [28 September checkpoint](CHECKPOINT_051.md) preserves the latest source, new 0.5.1 pitch and remaining work. The competition entry remains a draft; AI Coach has not yet been rerun. The 0.3.1 public demo and download links below are historical.

The [current AI implementation and evidence](../ON_DEVICE_REFLECTION.md) describes the 133 MB E5 semantic assistant, optimized on-device timings and 64 synthetic examples. Thirty further authored examples were fixed before final evaluation: 26 matching first suggestions, with the remaining four handled as ambiguous user choices. This is a small synthetic evaluation, not independent user research or a contest judging score. The 0.5.1 release was installed on the physical Seeker, and download plus question selection were also checked in the normal app. The [historical Seeker report](../SEEKER_DEVICE_041.md) records the earlier wallet connection and public activity retrieval. Supported live swap-to-journal completion remains unverified. The older pitch/demo material below must be updated to the current APK before submission.

## 28 September revision

The local 0.4.0 changes and new pitch/narration copy are in [REVISION_040.md](REVISION_040.md). The linked PDF, PowerPoint and video below are the historical 0.3.1 package and need replacement after the physical-device run. The supplied AI Coach report could not read the image-only PDF or connected source and did not obtain useful video narration. Do not treat the old package as current evidence.

A new [0.4.0 PDF draft](FOR-THE-RECORD-pitch-0.4.0-draft.pdf) contains selectable text on all eight pages. It accurately marks device evidence as pending. The matching pitch copy and narrated recording plan are in the revision document. The draft is not published to the competition portal.

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

## Historical 0.3.1 readiness

Version **0.3.1** passes **88 Flutter tests** with clean analysis. Language/layout checks include eight languages, a 360-pixel viewport and 200% text size. The optional backend's unchanged suite previously passed 40 tests.

The final Android emulator integration walkthrough passes with real SQLite and the native clock. It shows the local project-to-bookmark loop, native missing-wallet handling, and a persistently labeled sample event-to-reflection-to-later-review sequence. The sample data exists only in the integration test, never in the released APK. The [screenshots](screenshots) document those results.

Separate manual testing of the 0.3.1 release app with the **official Solana mock wallet on an Android emulator** verified connection approval, public account return, public mainnet empty history, disconnect, cancellation and retry. It requested no message/transaction signature and moved no assets. The video labels this evidence explicitly. The automated wallet driver did not pass; do not describe the manual result as an automated wallet E2E pass.

The preview uses native MWA and a direct read-only public-RPC path, so the journal requires no paid server or Firebase billing upgrade. Optional shared rooms and purchases remain separate unavailable cloud features. Public RPC is rate-limited infrastructure with no production service guarantee. See [the free preview approach](FREE_PREVIEW_APPROACH.md).

**Physical Seeker, Seed Vault and a supported live event-to-reflection run remain unverified.** The manual empty-history result and labeled fixture flow are distinct evidence. Complete that live path before claiming the competition's meaningful network requirement is established. No user research, retention, profit or performance result is claimed.

## Links

- [Official registration and submission portal](https://solanamobile.radiant.nexus/) — open **HACKATHON HUB**, sign in to Align, complete the builder profile, then open Clock In Registration.
- [Preview website and delivery materials](https://workroom-seeker-6984.web.app/)
- [Requested project repository](https://github.com/openai-lover/seeker_FOR-THE-RECORD) — public source and commit history are available without signing in.
- [Official announcement](https://solanamobile.com/blog/clock-in-the-solana-mobile-hackathon)
- [Binding terms](https://solanamobile.radiant.nexus/legal/clock-in-terms.pdf)

The authenticated submission form was reviewed on 21 September 2026. The draft contains the project title, owner-confirmed eligibility answers, mobile development and SKR disclosures, and links to the pitch, public Drive demo, public GitHub source and direct APK download. Final submission has not been performed.
