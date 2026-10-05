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
# Inspect the actual signed container, not just Gradle success or its manifest.
# A stale Flutter asset intermediate can otherwise package a valid launcher
# without the room, fonts or license screen resources.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$releaseZip=[IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ApkPath).Path)
try {
    $requiredAssets=@(
        'AssetManifest.bin','FontManifest.json','NativeAssetsManifest.json',
        'assets/room/study.png','assets/room/lamp.png','assets/room/journal.png',
        'assets/fonts/NotoSansKR.ttf','assets/fonts/Lora.ttf','assets/ai/LICENSES.txt',
        'assets/motion/activity.json','assets/motion/bookmark.json','assets/motion/checkmark.json',
        'assets/motion/LICENSE-useAnimations.txt'
    )
    foreach($asset in $requiredAssets) {
        $entry=$releaseZip.GetEntry('assets/flutter_assets/'+$asset)
        if($null -eq $entry -or $entry.Length -le 0) {
            throw "Release APK is missing a required Flutter asset: $asset"
        }
    }
    $abis=@(@('arm64-v8a','x86_64') | Where-Object {
        $null -ne $releaseZip.GetEntry('lib/'+$_+'/libapp.so')
    })
    if($abis.Count -ne 1){throw 'Release APK must contain exactly one supported ABI.'}
    foreach($library in @('libapp.so','libflutter.so','libreflection_native.so')) {
        $entry=$releaseZip.GetEntry('lib/'+$abis[0]+'/'+$library)
        if($null -eq $entry -or $entry.Length -le 0){throw "Release APK is missing native library: $library"}
    }
} finally { $releaseZip.Dispose() }
Write-Output "Release assets and native libraries verified: $([IO.Path]::GetFileName($ApkPath))"
