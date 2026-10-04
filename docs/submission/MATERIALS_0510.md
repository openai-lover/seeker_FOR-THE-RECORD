# 0.5.10 release and material consistency

App/tag source: `9de8139614cfd0c6374036e0b0ceb68abeee7602`, version `0.5.10+17`, ARM64 versionCode 2017. The 37,713,149-byte APK has SHA256 `3b2e8a11ad1a322dfcc510d46d90097c246fd995adaa1c7ff9d2984d94f19564`; the GitHub server digest matches. This release excludes test runtime dependencies that added three unnecessary exported activities. Both release-package gates, 145 Flutter tests and analysis passed. A physical Seeker in-place update and read-only MWA connection were confirmed without signing or collecting personal files.

## Current English materials

- The same eleven-slide native deck, PPT and PDF now identify 0.5.10. All eleven slides were rendered and inspected. All eleven exported speaker notes match the native notes. Source links and the evidence table distinguish current packaging from earlier functional measurements.
- The final edited video is **2:55** (approximately 175.08 seconds), filename `FOR-THE-RECORD-features-0.5.10-final.mp4`. Its 3,198,690 bytes have SHA256 `7b8f6583f72b2ba99f83841155a9a9826d6a001ac1e74afcd0dae046feca7fb4`. The older 3:00 MP4 has been superseded by this final file. Only trailing silence was removed; the spoken content is unchanged.
- The video explains the current packaging fix, then uses explicitly dated 0.5.8 typing, 0.5.9 export footage with a labelled final-frame hold, and evidence stills. English synthetic narration, transcript and SRT accompany it. It is not a continuous current production wallet flow.
- Existing native Slides and Drive video IDs and their anyone-reader permissions were retained. No new access grant was made. The APK, PPT, PDF, final video, transcript and SRT have matching local/server SHA256 receipts.

## Evidence dates and limitations

The 0.5.9 export check used synthetic records, actual separate SQLite, and the Android picker. Both 1,172-byte single-record exports matched after restart. Its offline diagnostic used a prepared model, no application INTERNET permission, 16 reused authored queries and 32 calls; native cold 1,701 ms, warm median 571 ms and p95 614 ms. These results are not relabelled as a new 0.5.10 measurement. The UI, export logic, model, retrieval policy and parser are unchanged.

The historical 0.5.5 production flow remains a separate 6:28 video with a 1,876-byte export. The older 1,953-byte result belongs to October 3. Neither figure is substituted for the 0.5.9 synthetic export. No current complete production recording, supported live user swap, independent user study or comprehensive security clearance is claimed.

The actual Coach result before reassessing these materials is 78/100. This file does not claim a new score. The competition entry remains DRAFT. Methods: [packaging and audit triage](AUDIT_TRIAGE_0510.md), [dated offline/export evidence](RELIABLE_USE_059.md), [mainnet replay](PUBLIC_MAINNET_REPLAY_058.md).
