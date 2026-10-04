# 0.5.9 materials and evidence provenance

The app/tag source is `0731bf59d9e74e0fe38934854861d45bfc88131e`, version 0.5.9+16, ARM64 versionCode 2016. The development-signed APK is 37,881,752 bytes, SHA256 `c7c561e48d54183b82e43ea3d544bc50aef7c1afcc9af16114681fc78aa7cb33`. GitHub's server digest matches. A normal in-place Seeker update and resumed production activity were observed. No private record export was collected for this release.

## Matching published material

- Eleven English native slides, PDF and PPT. All slides were rendered and inspected; all eleven exported speaker notes matched the native notes. The latency chart was resized after visual review.
- Three-minute edited demonstration with English synthetic narration, SRT and transcript. It includes 25 seconds of dated 0.5.8 typing and a 20-second current 0.5.9 export segment, including an explicitly labelled final-frame hold. Remaining segments are stills. This is not a continuous production wallet flow.
- Current export/offline screenshots are from the physical Seeker's separate diagnostic package. They contain synthetic data only. Version 0.5.8 room/writing images and historical 0.5.7 AI material retain their original dates.
- Portal audio transcription was regenerated from the new video: 2,301 characters. Its values and limits match the narration; ASR spells Jupiter as “jupyter”. This spelling does not change the named program in the source/writeup.
- Existing native Slides and Drive video file IDs and anyone-reader permissions were retained. No new access grant was made.

The APK and five material assets have matching local/server SHA256 receipts. The newest AI Coach score before this release's reassessment remains 78/100; this release is not yet scored. The entry remains DRAFT.

## Evidence separation

Current isolated export verification uses actual SQLite and the Android picker. A changed synthetic reflection survived force-stop/reopen; two 1,172-byte record exports have identical journal payloads. The initial whole-app synthetic file was 3,449 bytes. The current offline test ran 32 calls on 16 reused authored cases with a prepared model and no application INTERNET permission. These facts do not establish current production wallet flow, independent AI accuracy or real-user retention.

The historical 0.5.5 production video remains 6:28 and its export is 1,876 bytes. The older 1,953-byte result belongs to October 3. Public-mainnet replay is a separate offline parser exercise using 15 public program responses. No version, storage method or transaction source is relabelled.

Methods: [reliable use](RELIABLE_USE_059.md), [public-mainnet replay](PUBLIC_MAINNET_REPLAY_058.md), [broader AI evaluation](BROADER_AI_057.md), [historical production flow](CONTINUOUS_DEVICE_055.md).
