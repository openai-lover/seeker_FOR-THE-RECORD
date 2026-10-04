param([Parameter(Mandatory=$true)][string]$ApkPath)
$ErrorActionPreference='Stop'
$taskRoot=Split-Path $PSScriptRoot -Parent
$aapt=Join-Path $taskRoot '.tools/android-sdk/build-tools/36.0.0/aapt.exe'
if(!(Test-Path -LiteralPath $aapt)){throw 'Release manifest verification requires Android build-tools 36.0.0.'}
if(!(Test-Path -LiteralPath $ApkPath)){throw 'Release APK is missing.'}
$manifest=(& $aapt dump xmltree $ApkPath AndroidManifest.xml 2>&1) -join "`n"
if($LASTEXITCODE -ne 0){throw 'Cannot inspect the packaged release manifest.'}
if($manifest -match 'androidx\.test\.|dev\.flutter\.integration_test|E: instrumentation'){
  throw 'Release APK contains a test component. Inspect releaseRuntimeClasspath before publishing.'
}
if($manifest -match 'android:debuggable\([^\r\n]*0xffffffff'){
  throw 'Release APK is debuggable.'
}
if($manifest -notmatch 'package="app\.workroom\.seeker_workroom"'){
  throw 'Release APK does not have the production application ID.'
}
if($manifest -notmatch 'android\.permission\.INTERNET'){
  throw 'Release APK is missing Internet permission needed for public activity and model setup.'
}
if($manifest -notmatch 'app\.workroom\.seeker_workroom\.WorkroomActivity'){
  throw 'Release APK is missing its production launcher.'
}
Write-Output "Release manifest verified: $([IO.Path]::GetFileName($ApkPath))"
