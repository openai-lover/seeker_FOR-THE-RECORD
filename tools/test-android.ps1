param([Parameter(Mandatory=$true)][string]$Device)
$ErrorActionPreference='Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
  . ./tools/env.ps1
  $installed = & adb -s $Device shell pm list packages app.workroom.seeker_workroom
  if($LASTEXITCODE -ne 0){throw 'Cannot inspect target device'}
  if($installed -contains 'package:app.workroom.seeker_workroom') {
    throw 'Use a dedicated empty emulator. Flutter test tooling can replace/remove the main app even when the test APK uses a suffix. Do not uninstall a personal workroom to run tests.'
  }
  $env:WORKROOM_ISOLATED_TEST='1'
  flutter test integration_test/local_android_test.dart -d $Device
  if($LASTEXITCODE -ne 0){throw 'Android integration test failed'}
} finally {
  Remove-Item Env:WORKROOM_ISOLATED_TEST -ErrorAction SilentlyContinue
  Pop-Location
}
