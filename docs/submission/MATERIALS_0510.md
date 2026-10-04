# 0.5.10 release and material consistency

App/tag source: `9de8139614cfd0c6374036e0b0ceb68abeee7602`, version `0.5.10+17`, ARM64 versionCode 2017. The 37,713,149-byte APK has SHA256 `3b2e8a11ad1a322dfcc510d46d90097c246fd995adaa1c7ff9d2984d94f19564`; the GitHub server digest matches. This release excludes test runtime dependencies that added three unnecessary exported activities. Both release-package gates, 145 Flutter tests and analysis passed. A physical Seeker in-place update and read-only MWA connection were confirmed without signing or collecting personal files.

## Current English materials

- The same eleven-slide native deck, PPT and PDF now identify 0.5.10. All eleven slides were rendered and inspected. All eleven exported speaker notes match the native notes. Source links and the evidence table distinguish current packaging from earlier functional measurements.
- The final edited video is **2:55** (175 seconds), filename `FOR-THE-RECORD-demo-0.5.10.mp4`. Its 3,906,589 bytes have SHA256 `dcc1c0c4e764d612645d84a321858055fd5239267e2ce23a713359a1c69de1a3`. The older features MP4s are superseded by this H.264 Main / 48 kHz AAC file. Trailing silence was removed and encoding compatibility adjusted; the footage and spoken content are unchanged.
- The video explains the current packaging fix, then uses explicitly dated 0.5.8 typing, 0.5.9 export footage with a labelled final-frame hold, and evidence stills. English synthetic narration, transcript and SRT accompany it. It is not a continuous current production wallet flow.
- Existing native Slides and Drive video IDs and their anyone-reader permissions were retained. No new access grant was made. The APK, PPT, PDF, final video, transcript and SRT have matching local/server SHA256 receipts.
- Drive preview subsequently played the 2:55 file. Portal FROM AUDIO regeneration then returned 2,377 characters with the correct version, metrics and limitations. An earlier 3:00 transcription had appended an unrelated NCBI URL not present in the narration; that suffix is absent from the current transcription. Temporary HTTP errors occurred while the replacement video was being prepared. The cause of those errors was not independently established. ASR changed “Historical mainnet” to “Simple mainnet”; the writeup and methods retain the exact provenance.

## Evidence dates and limitations

The 0.5.9 export check used synthetic records, actual separate SQLite, and the Android picker. Both 1,172-byte single-record exports matched after restart. Its offline diagnostic used a prepared model, no application INTERNET permission, 16 reused authored queries and 32 calls; native cold 1,701 ms, warm median 571 ms and p95 614 ms. These results are not relabelled as a new 0.5.10 measurement. The UI, export logic, model, retrieval policy and parser are unchanged.

The historical 0.5.5 production flow remains a separate 6:28 video with a 1,876-byte export. The older 1,953-byte result belongs to October 3. Neither figure is substituted for the 0.5.9 synthetic export. No current complete production recording, supported live user swap, independent user study or comprehensive security clearance is claimed.

## AI Coach reassessment on October 4

The actual result after these improvements is **79/100**, up from 78, completed around 20:22 KST. A fresh portal reload confirmed 79, all four evidence categories READ, the 0.5.10 writeup and APK, and DRAFT status. The conservative observation at 20:30 sets the next review minimum at 23:30 KST, and another review requires substantive new evidence.

Criteria: AI 85, SKR integration 77, UX 85, UI 82, innovation 76, ecosystem impact 65. The Coach credited packaging checks, export completion/persistence, offline diagnostics and 145 tests. It still requested a current continuous production Seeker flow, a supported real/mainnet activity shown inside the app, independently labelled AI evaluation, actual repeat-use participants, minimal crafted-input proof for the historical SQL lead, and packaged-manifest check output.

The Coach described the deck as 0.5.8 despite the verified 0.5.10 cover, evidence table, source and notes; older screenshots are explicitly dated. The cause of this discrepancy is unproven. The warning about reviewer-directed instructions also remains; no removal is claimed. READ status does not establish a new complete source audit. No additional audit or final submission was performed.

Methods: [packaging and audit triage](AUDIT_TRIAGE_0510.md), [dated offline/export evidence](RELIABLE_USE_059.md), [mainnet replay](PUBLIC_MAINNET_REPLAY_058.md).
