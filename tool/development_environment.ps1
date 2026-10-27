# Dot-source this from development commands so an already-running editor also
# uses the migrated paths, without waiting for its inherited environment to reset.
$developmentProjectDirectory = Split-Path -Parent $PSScriptRoot
$developmentSettings = @{}
Get-Content -LiteralPath (Join-Path $developmentProjectDirectory 'android/local.properties') | ForEach-Object {
    if ($_ -match '^([^#=]+)=(.*)$') { $developmentSettings[$Matches[1]] = $Matches[2].Replace('\\', '\') }
}
$developmentAndroidDirectory = Split-Path -Parent $developmentSettings['sdk.dir']
$developmentDrive = [IO.Path]::GetPathRoot($developmentProjectDirectory)
$developmentToolProfile = Join-Path $developmentDrive 'Development/tool-profile'
$env:APPDATA = Join-Path $developmentToolProfile 'Roaming'
$env:LOCALAPPDATA = Join-Path $developmentToolProfile 'Local'
$env:TEMP = Join-Path $developmentDrive 'DevTemp'
$env:TMP = $env:TEMP
$env:GRADLE_USER_HOME = Join-Path $developmentDrive 'gradle-home'
$env:PUB_CACHE = Join-Path $developmentDrive 'pub-cache'
$env:FLUTTER_ROOT = $developmentSettings['flutter.sdk']
$env:ANDROID_HOME = $developmentSettings['sdk.dir']
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ANDROID_USER_HOME = Join-Path $developmentAndroidDirectory 'user-home'
$developmentKotlinDirectory = Join-Path $developmentAndroidDirectory 'kotlin-daemon'
foreach ($developmentPath in @($env:TEMP, $env:GRADLE_USER_HOME, $env:PUB_CACHE,
    $env:ANDROID_USER_HOME, $developmentKotlinDirectory,
    $env:APPDATA, $env:LOCALAPPDATA)) {
    New-Item -ItemType Directory -Path $developmentPath -Force | Out-Null
}
$developmentJavaOptions = $env:JAVA_TOOL_OPTIONS -replace '(?:"-D(?:jdk\.net\.unixdomain\.tmpdir|java\.io\.tmpdir|kotlin\.daemon\.runFilesPath)=[^"]*"|-D(?:jdk\.net\.unixdomain\.tmpdir|java\.io\.tmpdir|kotlin\.daemon\.runFilesPath)=\S+)', ''
$env:JAVA_TOOL_OPTIONS = "$developmentJavaOptions -Djdk.net.unixdomain.tmpdir=$env:TEMP -Djava.io.tmpdir=$env:TEMP -Dkotlin.daemon.runFilesPath=$developmentKotlinDirectory".Trim()
$env:Path = (Join-Path $env:FLUTTER_ROOT 'bin') + ';' + $env:Path
if (-not $env:JAVA_HOME) {
    $developmentJdk = Get-ChildItem -LiteralPath (Join-Path $developmentAndroidDirectory 'jdk') -Directory |
        Where-Object { $_.Name -like 'jdk-17*' } | Select-Object -First 1
    if ($developmentJdk) { $env:JAVA_HOME = $developmentJdk.FullName }
}
