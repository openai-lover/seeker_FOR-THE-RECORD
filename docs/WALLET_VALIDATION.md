# Wallet validation

## Scope

FOR THE RECORD's free mode uses Mobile Wallet Adapter (MWA) to obtain the
selected public address, then reads public activity through Solana JSON-RPC.
Connecting in this mode must not request a message signature, a transaction
signature, a payment, Firebase authentication, or a private key.

An Android emulator can test the app's MWA integration. Solana Mobile explicitly
supports emulator development and provides a mock wallet for that purpose:
[development setup](https://docs.solanamobile.com/get-started/development-setup),
[official mock wallet source](https://github.com/solana-mobile/mock-mwa-wallet).
This is protocol and application validation. It is not a physical Seeker or
Seed Vault certification. Seed Vault's hardware-backed custody and the actual
Seed Vault Wallet experience require a compatible physical device:
[Seeker documentation](https://docs.solanamobile.com/solana-mobile-stack/seeker).

## Isolated harness

- Dedicated AVD: `ForTheRecord_Wallet_API_36`, Pixel 7 profile, Android API 36,
  x86_64 Google APIs, serial `emulator-5580`.
- Official wallet source commit:
  `d444aff0c72dadd0f5c442ea2bc3559b62916e01`.
- The official source is built locally as a debug test app. It is not included
  in the product release or downloaded from an APK mirror.
- Wallet display name: `FOR THE RECORD TEST ONLY`. No imported private key,
  mnemonic, API credential, or funding is used. The wallet generates a
  disposable key internally. The emulator uses a synthetic test-only lock PIN.
- The app test uses the `.integration` application ID and a temporary SQLite
  database. The runner refuses physical devices and other AVD names.
- Test file: `integration_test/mock_wallet_android_test.dart`.
  Run with `tools/test-mock-wallet.ps1` after installing and authenticating the
  official mock wallet. Approve the first connection; cancel the second.
  `MOCK_WALLET_TEST=true` is required; ordinary test runs skip the harness.

The harness records native method names and rejects any method except
`walletConnect` and `walletDisconnect`. It asserts that approval returns a
32-byte address, disconnect clears the selected account, cancellation remains
disconnected, Firebase stays uninitialized, and payment/Seeker entitlement
flags stay disabled. It deliberately does not submit or sign a transaction.

## Physical-device follow-up

With the owner's permission, install the release APK on a Seeker and verify:

1. The installed Seed Vault Wallet is discovered and displays the expected app
   identity; approve read-only address sharing and return to the app.
2. Cancel the approval and confirm that the app explains cancellation and
   remains usable. Retry without restarting the app.
3. Select another account, disconnect and reconnect, and verify that activity
   follows the selected address while local journal notes remain available.
4. Lock/unlock or background the device during approval and confirm a clean
   return without duplicate requests or a stuck busy indicator.
5. Read existing public activity, then test airplane mode and retry. This needs
   no new transaction and no SOL fee.

Device unlock and wallet approvals belong to the owner. No seed phrase or
private key should be copied into the app, the development computer, test
fixtures, logs, or documentation. Hardware-backed transaction signing, SGT
ownership, and paid features are outside this read-only test's coverage.

## Execution evidence — September 20, 2026

The final x86_64 release APK (0.3.1+4) was installed over the previous test
installation without clearing its data. All six checks below were repeated
successfully on this final build at approximately 23:43 KST. They were performed
through its actual UI, inspecting the Android
accessibility hierarchy before operating each control:

| Check | Observed result |
|---|---|
| Connect from Trade journal | Official mock wallet displayed the FOR THE RECORD identity and a connection approval sheet. |
| Approve public-address sharing | Returned to Trade journal, displayed Wallet connected and the selected address. No signing or transaction prompt appeared. |
| Load public history | Public mainnet RPC completed and displayed the empty-history message for the unfunded test address. This checks a real network response, not a populated swap history. |
| Disconnect in Settings | Cleared the address and restored the Connect Seeker wallet button. |
| Cancel the next wallet request | Returned disconnected with the English cancellation message. |
| Retry after cancellation | Reconnected the same disposable account without restarting the app. |

Final-build screenshots were retained as local validation artifacts:
`mwa-v031-approve.png`, `mwa-v031-connected.png`,
`mwa-v031-disconnected.png`, `mwa-v031-cancelled.png`, and
`mwa-v031-retry-connected.png`. An actual authorization recording,
`mwa-v031.mp4` (35 seconds, 720 × 1600), captures the official wallet approval
sheet and return to the connected app. These show a mock wallet and must be labeled
**Official mock wallet · Android emulator**, not physical Seeker evidence.

- Release APK SHA-256:
  `526DB341B7E156682699359BFE34859062A10EB4B2BC07BBBAE8B76393CC951D`.
- Official mock wallet debug APK SHA-256:
  `089D06835C3E10ABBD2FCAC2DF5A562E75985BAB6951E6CA73257AA9B4388C1D`.
- Emulator fingerprint:
  `google/sdk_gphone64_x86_64/emu64xa:16/BE2A.250530.026.F3/13894323:userdebug/dev-keys`.

The new automated Android harness compiled, but `flutter test` failed to attach
its host runner (`VmServiceDisappearedException`) before executing its assertions.
An earlier attempt also exposed stale generated integration-plugin registration
after a release build; running dependency resolution refreshed that registration.
The runner script uses `flutter drive` and refreshes plugins, but that alternative
has not yet been executed for this harness. No automated pass is claimed for it.
The successful results above are the separately completed manual UI checks.
