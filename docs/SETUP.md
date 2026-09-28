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

The build script uses the project JDK 17 directly through Gradle, so a globally configured Flutter Java path does not override it. The native reflection engine uses NDK 28.2 and CMake 3.22.1. CMake fetches a pinned, SHA-256-checked llama.cpp archive; the AI weights are an optional runtime download. Kotlin 2.4.0 and the existing R8 override are retained. The bootstrap installs the project's local toolchain. Alternatively use your Flutter installation: run flutter pub get, flutter analyze, flutter test, then flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64. ARM64 is the physical Seeker download; x64 is provided for emulator review.

The native MWA identity defaults to the existing HTTPS project site. Set IDENTITY_URI with a Dart define for a different deployment. Setting DIRECT_WALLET=false disables direct wallet access when no cloud backend is configured. Never put a paid private RPC key in a distributed APK.

## Optional cloud features

Shared rooms, SGT checks and pack purchases are not part of the default free edition. The preserved [legacy setup](LEGACY_SETUP.ko.md) describes their architecture. A complete Firebase configuration selects that server path instead of direct RPC. Firebase Functions requires a Blaze billing account even where no-cost usage quotas apply; do not enable it merely to run the free journal. PAYMENTS_ENABLED stays false until an operator explicitly configures and validates sales.

## Signing and upgrades

The application ID remains app.workroom.seeker_workroom and the SQLite name remains workroom.sqlite. Export before replacing an older preview and retain the same signing key. Do not uninstall to work around a signing mismatch unless you have separately saved your records.

Without android/key.properties, optimized APKs use a development signing certificate. A stable release key and the operator's support/privacy information are needed for a public store release. The hackathon preview is a review APK, not a claim of store readiness.

## Verification

Run flutter analyze and flutter test for the app. Optional backend tests are pnpm --dir functions test and pnpm --dir functions build.

The English walkthrough uses an isolated package suffix and a temporary SQLite database. Set WORKROOM_ISOLATED_TEST=1, then run flutter drive --driver=test_driver/walkthrough.dart --target=integration_test/final_walkthrough_test.dart -d a-dedicated-emulator. Its sample trade is labeled on every screen and exists only in the integration test. Use a dedicated emulator without a wallet for the missing-wallet assertion. Never run a data-resetting test on a user's installed app.

The separately gated official mock-wallet harness is described in [wallet validation](WALLET_VALIDATION.md). Its automated runner is not claimed as passed; the final release's approval, cancellation, disconnect and retry were verified through its actual UI.


### Native AI on Windows

If CMake/Ninja reports a missing executable under a non-ASCII SDK path, copy the SDK's `cmake/3.22.1` directory into the ignored project `work/native-cmake/3.22.1` directory, then set `cmake.dir` in the ignored `android/local.properties` to that absolute ASCII path (forward slashes work). This avoids a CMake file-API path encoding issue without changing the shared SDK. Do not commit local machine paths. The app CMake file constrains compiler concurrency; ARM64 and x64 are the release targets.

For the isolated device checks, set `WORKROOM_ISOLATED_TEST=1`, configure a debug APK targeting `integration_test/local_reflection_test.dart`, and build with the project JDK. Drive the resulting debug APK using `test_driver/local_reflection.dart` and `--keep-app-running`. This keeps synthetic cases in the `.integration` package and preserves its downloaded model for an offline second run. The native debug engine uses RelWithDebInfo for representative CPU inference speed. Always restore network settings after an offline check and leave the normal app installed.
