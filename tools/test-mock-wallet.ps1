param([string]$Serial = 'emulator-5580')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'env.ps1')

# Deliberately restricted to our disposable AVD; never select the first device.
if ($Serial -notmatch '^emulator-[0-9]+$') {
  throw 'This harness is for an isolated Android emulator only.'
}
$taskQemu = ((& adb -s $Serial shell getprop ro.kernel.qemu) -join '').Trim()
$taskAvd = ((& adb -s $Serial emu avd name) | Select-Object -First 1).Trim()
if ($taskQemu -ne '1' -or $taskAvd -ne 'ForTheRecord_Wallet_API_36') {
  throw 'Use the dedicated ForTheRecord_Wallet_API_36 AVD; do not use a personal device.'
}
$taskWallet = ((& adb -s $Serial shell pm path com.solana.mwallet) -join '').Trim()
if (!$taskWallet.StartsWith('package:')) {
  throw 'Build and install the official solana-mobile/mock-mwa-wallet test app first.'
}

Write-Host 'TEST ONLY: use a fresh generated, unfunded mock wallet. Never import keys.'
Write-Host 'Approve the first connection in the mock wallet. Cancel the second.'
$taskPreviousIsolation = $env:WORKROOM_ISOLATED_TEST
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
  $env:WORKROOM_ISOLATED_TEST = '1'
  # Refresh plugin registration: a preceding release build excludes dev plugins.
  & flutter drive --driver=test_driver/mock_wallet.dart `
    --target=integration_test/mock_wallet_android_test.dart `
    -d $Serial --dart-define=MOCK_WALLET_TEST=true
  if ($LASTEXITCODE -ne 0) { throw 'Mock wallet integration test failed.' }
} finally {
  $env:WORKROOM_ISOLATED_TEST = $taskPreviousIsolation
  Pop-Location
}
