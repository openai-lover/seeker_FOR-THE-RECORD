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
  $mode=if($Release){'--release'}else{'--debug'}
  $buildArgs=@('build','apk',$mode,'--target','lib/main.dart')
  if($Release){$buildArgs+='--split-per-abi'}
  if($Config){$buildArgs+="--dart-define-from-file=$Config"}
  & flutter @buildArgs
  if($LASTEXITCODE -ne 0){throw 'Flutter build failed'}
  if($Release){
    New-Item -ItemType Directory -Force artifacts | Out-Null
    Copy-Item build/app/outputs/flutter-apk/app-arm64-v8a-release.apk artifacts/for-the-record-arm64-preview.apk
    Copy-Item build/app/outputs/flutter-apk/app-x86_64-release.apk artifacts/for-the-record-x64-preview.apk
    Get-ChildItem artifacts/*.apk | ForEach-Object { '{0}  {1}' -f (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower(),$_.Name } | Set-Content artifacts/SHA256SUMS.txt
  }
}finally{Pop-Location}
