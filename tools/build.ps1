param([switch]$Release,[string]$Config)
$ErrorActionPreference='Stop'
# Use a junction because Gradle and Flutter shader tools can misread non-ASCII paths on Windows.
$sourceRoot=Split-Path $PSScriptRoot -Parent
$sourceInfo=Get-Item -LiteralPath $sourceRoot
if($sourceInfo.LinkType -eq 'Junction'){$sourceRoot=$sourceInfo.Target}
$buildAlias=Join-Path $env:TEMP 'for-the-record-build'
if(!(Test-Path -LiteralPath $buildAlias)){New-Item -ItemType Junction -Path $buildAlias -Target $sourceRoot | Out-Null}
$aliasInfo=Get-Item -LiteralPath $buildAlias
if($aliasInfo.LinkType -ne 'Junction' -or $aliasInfo.Target.TrimEnd('\') -ne $sourceRoot.TrimEnd('\')){throw 'The build alias points at another directory. Choose a unique alias before proceeding.'}
Push-Location $buildAlias
try{
  . ./tools/env.ps1
  # Invoke Gradle with the project JDK. A global Flutter jdk-dir can otherwise
  # override JAVA_HOME and select an incompatible Java installation.
  $mode=if($Release){'release'}else{'debug'}
  # Flutter prepares the release-specific plugin registrant and SDK/version
  # properties, without invoking its globally selected Java installation.
  $prepareArgs=@('build','apk','--config-only',"--$mode",'--target','lib/main.dart','--split-per-abi','--target-platform','android-arm64,android-x64')
  if($Config){$prepareArgs+="--dart-define-from-file=$Config"}
  & flutter @prepareArgs
  if($LASTEXITCODE -ne 0){throw 'Flutter build configuration failed'}
  $task=if($Release){'assembleRelease'}else{'assembleDebug'}
  $buildArgs=@('-p','android',$task,'-Ptarget=lib/main.dart','-Ptarget-platform=android-arm64,android-x64','-Psplit-per-abi=true')
  if($Release){$buildArgs+='-Ptree-shake-icons=true'}
  if($Config){
    $defines=Get-Content -LiteralPath $Config -Raw | ConvertFrom-Json
    $encoded=@($defines.PSObject.Properties | ForEach-Object {
      $value=if($_.Value -is [bool]){$_.Value.ToString().ToLowerInvariant()}else{[string]$_.Value}
      [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$($_.Name)=$value"))
    })
    $buildArgs+="-Pdart-defines=$($encoded -join ',')"
  }
  & ./android/gradlew.bat @buildArgs
  if($LASTEXITCODE -ne 0){throw 'Android build failed'}
  if($Release){
    & ./tools/verify-release.ps1 -ApkPath build/app/outputs/apk/release/app-arm64-v8a-release.apk
    & ./tools/verify-release.ps1 -ApkPath build/app/outputs/apk/release/app-x86_64-release.apk
    New-Item -ItemType Directory -Force artifacts | Out-Null
    Copy-Item build/app/outputs/apk/release/app-arm64-v8a-release.apk artifacts/for-the-record-arm64-preview.apk
    Copy-Item build/app/outputs/apk/release/app-x86_64-release.apk artifacts/for-the-record-x64-preview.apk
    Get-ChildItem artifacts/*.apk | ForEach-Object { '{0}  {1}' -f (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower(),$_.Name } | Set-Content artifacts/SHA256SUMS.txt
  }
}finally{Pop-Location}
