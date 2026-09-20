# Build and run FOR THE RECORD

## Free default edition

No Firebase project, billing upgrade, API key or account is required for the default APK. Personal records use SQLite. The optional wallet journal authorizes an MWA wallet and reads finalized activity directly from https://api.mainnet.solana.com. Private notes never leave the device through this path.

The public endpoint is rate-limited and is not a production SLA. The client loads eight signatures per page, limits concurrent requests to two, coalesces identical requests, caches pages for 60 seconds and limits retries. See [free-mode details](submission/FREE_PREVIEW_APPROACH.md).

### Windows

Verified toolchain: Flutter 3.47.4, Dart 3.13.3, JDK 17, Android API 36.

```powershell
./tools/bootstrap.ps1
./tools/build.ps1 -Release
```

The bootstrap installs the project's local toolchain. Alternatively use your Flutter installation: run flutter pub get, flutter analyze, flutter test, then flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64. ARM64 is the physical Seeker download; x64 is provided for emulator review.

The native MWA identity defaults to the existing HTTPS project site. Set IDENTITY_URI with a Dart define for a different deployment. Setting DIRECT_WALLET=false disables direct wallet access when no cloud backend is configured. Never put a paid private RPC key in a distributed APK.

## Optional cloud features

Shared rooms, SGT checks and pack purchases are not part of the default free edition. The preserved [legacy setup](LEGACY_SETUP.ko.md) describes their architecture. A complete Firebase configuration selects that server path instead of direct RPC. Firebase Functions requires a Blaze billing account even where no-cost usage quotas apply; do not enable it merely to run the free journal. PAYMENTS_ENABLED stays false until an operator explicitly configures and validates sales.

## Signing and upgrades

The application ID remains app.workroom.seeker_workroom and the SQLite name remains workroom.sqlite. Export before replacing an older preview and retain the same signing key. Do not uninstall to work around a signing mismatch unless you have separately saved your records.

Without android/key.properties, optimized APKs use a development signing certificate. A stable release key and the operator's support/privacy information are needed for a public store release. The hackathon preview is a review APK, not a claim of store readiness.

## Verification

Run flutter analyze and flutter test for the app. Optional backend tests are pnpm --dir functions test and pnpm --dir functions build.

The English walkthrough uses an isolated package suffix and a temporary SQLite database. Set WORKROOM_ISOLATED_TEST=1, then run flutter drive --driver=test_driver/walkthrough.dart --target=integration_test/english_walkthrough_test.dart -d a-dedicated-emulator. Never run a data-resetting test on a user's installed app.
