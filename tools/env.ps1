$taskRoot = Split-Path $PSScriptRoot -Parent
$env:PUB_CACHE = Join-Path $taskRoot '.tools/pub-cache'
$env:ANDROID_HOME = Join-Path $taskRoot '.tools/android-sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:JAVA_HOME = (Get-ChildItem (Join-Path $taskRoot '.tools/java') -Directory | Select-Object -First 1).FullName
$env:GRADLE_USER_HOME = Join-Path $taskRoot '.tools/gradle'
$env:PATH = "$taskRoot\.tools\flutter\bin;$env:JAVA_HOME\bin;$env:ANDROID_HOME\platform-tools;$env:PATH"
if(Test-Path "$taskRoot/.tools/node"){
  $nodeDirectory=(Get-ChildItem "$taskRoot/.tools/node" -Directory | Select-Object -First 1).FullName
  $env:PATH="$nodeDirectory;$env:PATH"
}
