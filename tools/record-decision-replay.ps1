param([Parameter(Mandatory=$true)][string]$Device)
$ErrorActionPreference='Stop'
if($Device -notmatch '^emulator-\d+$') { throw 'Use a dedicated empty emulator, never a personal phone.' }
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
  . ./tools/env.ps1
  $installed = & adb -s $Device shell pm list packages app.workroom.seeker_workroom
  if($LASTEXITCODE -ne 0){throw 'Cannot inspect target emulator'}
  if($installed -contains 'package:app.workroom.seeker_workroom') {
    throw 'A personal workroom is installed. Use a different empty emulator; do not remove it.'
  }
  $env:WORKROOM_ISOLATED_TEST='1'
  flutter pub get
  if($LASTEXITCODE -ne 0){throw 'Dependency and test-plugin registration failed'}
  flutter drive --driver=test_driver/walkthrough.dart --target=integration_test/decision_replay_walkthrough_test.dart -d $Device
  if($LASTEXITCODE -ne 0){throw 'Decision Replay walkthrough failed'}
} finally {
  Remove-Item Env:WORKROOM_ISOLATED_TEST -ErrorAction SilentlyContinue
  Pop-Location
}
