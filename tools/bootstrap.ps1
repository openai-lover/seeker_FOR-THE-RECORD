param([switch]$WithEmulator,[switch]$WithServer)
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$projectRoot=Split-Path $PSScriptRoot -Parent
Set-Location $projectRoot
New-Item -ItemType Directory -Force '.tools' | Out-Null
if(!(Test-Path '.tools/flutter/bin/flutter.bat')){
  git -c core.longpaths=true clone --depth 1 --branch 3.47.4 https://github.com/flutter/flutter.git .tools/flutter
  if($LASTEXITCODE -ne 0){throw 'Flutter clone failed. Check Git/network/Windows long-path support.'}
}
if(!(Test-Path '.tools/java/jdk-17.0.20.1+1')){
  $jdkUrl='https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.20.1%2B1/OpenJDK17U-jdk_x64_windows_hotspot_17.0.20.1_1.zip'
  Invoke-WebRequest $jdkUrl -OutFile '.tools/jdk.zip'
  if((Get-FileHash '.tools/jdk.zip' -Algorithm SHA256).Hash -ne 'E53A79C3C3D86865BD7E787903884331068E71321714FFD44F145785AFFC7CB0'){throw 'JDK checksum mismatch'}
  Expand-Archive '.tools/jdk.zip' '.tools/java' -Force
}
if(!(Test-Path '.tools/android-sdk/cmdline-tools/latest/bin/sdkmanager.bat')){
  Invoke-WebRequest 'https://dl.google.com/android/repository/commandlinetools-win-15859902_latest.zip' -OutFile '.tools/android-tools.zip'
  Expand-Archive '.tools/android-tools.zip' '.tools/android-sdk/cmdline-tools' -Force
  Rename-Item '.tools/android-sdk/cmdline-tools/cmdline-tools' 'latest'
}
if($WithServer -and !(Test-Path '.tools/node/node-v22.23.2-win-x64/node.exe')){
  Invoke-WebRequest 'https://nodejs.org/dist/v22.23.2/node-v22.23.2-win-x64.zip' -OutFile '.tools/node22.zip'
  if((Get-FileHash '.tools/node22.zip' -Algorithm SHA256).Hash -ne '1177B4137BA5ADAA56354AE40F1080C7450E8AE09CECB47DA459D1C52AC99F97'){throw 'Node checksum mismatch'}
  Expand-Archive '.tools/node22.zip' '.tools/node' -Force
}
. ./tools/env.ps1
& '.tools/android-sdk/cmdline-tools/latest/bin/sdkmanager.bat' --licenses
& '.tools/android-sdk/cmdline-tools/latest/bin/sdkmanager.bat' 'platform-tools' 'platforms;android-36' 'build-tools;36.0.0' 'ndk;28.2.13676358'
if($LASTEXITCODE -ne 0){throw 'Android SDK installation failed'}
if($WithEmulator){& '.tools/android-sdk/cmdline-tools/latest/bin/sdkmanager.bat' 'emulator' 'system-images;android-36;google_apis;x86_64'}
Write-Output 'Tools installed. Run ./tools/build.ps1. Keep Windows builds under the ASCII junction created by that script.'
