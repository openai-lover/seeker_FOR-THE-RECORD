$ErrorActionPreference='Stop'
$sourceRoot=Split-Path $PSScriptRoot -Parent
$sourceInfo=Get-Item -LiteralPath $sourceRoot
if($sourceInfo.LinkType -eq 'Junction'){$sourceRoot=$sourceInfo.Target}
$aliasPath=Join-Path $env:TEMP 'for-the-record-check'
if(!(Test-Path $aliasPath)){New-Item -ItemType Junction -Path $aliasPath -Target $sourceRoot | Out-Null}
if((Get-Item $aliasPath).Target.TrimEnd('\') -ne $sourceRoot.TrimEnd('\')){throw 'Build alias belongs to another project'}
Push-Location $aliasPath
try{
  . ./tools/env.ps1
  flutter pub get
  if($LASTEXITCODE -ne 0){throw 'pub get failed'}
  flutter analyze --no-pub
  if($LASTEXITCODE -ne 0){throw 'Analysis failed'}
  flutter test --no-pub
  if($LASTEXITCODE -ne 0){throw 'Flutter tests failed'}
  node functions/node_modules/typescript/bin/tsc -p functions/tsconfig.json
  if($LASTEXITCODE -ne 0){throw 'Functions build failed'}
  node functions/node_modules/tsx/dist/cli.mjs --test functions/test/domain.test.ts functions/test/activity.test.ts
  if($LASTEXITCODE -ne 0){throw 'Server tests failed'}
}finally{Pop-Location}
