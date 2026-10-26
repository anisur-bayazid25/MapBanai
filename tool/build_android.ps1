param([ValidateSet('debug', 'release')][string]$Mode = 'release')

$ErrorActionPreference = 'Stop'
$previousJavaOptions = $env:JAVA_TOOL_OPTIONS
try {
    # Windows Java NIO can bind a Unix-domain socket through a short-name TEMP
    # alias and then fail to connect to it. Use a writable normal path for both
    # the socket and JVM temp files, inherited by daemons and worker JVMs.
    $socketDirectory = if ($env:GRADLE_USER_HOME) {
        Join-Path $env:GRADLE_USER_HOME 'java-tmp'
    } else {
        Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'MapBanai\java-tmp'
    }
    New-Item -ItemType Directory -Path $socketDirectory -Force | Out-Null
    $env:JAVA_TOOL_OPTIONS = "$previousJavaOptions `"-Djdk.net.unixdomain.tmpdir=$socketDirectory`" `"-Djava.io.tmpdir=$socketDirectory`"".Trim()
    Push-Location (Split-Path -Parent $PSScriptRoot)
    try {
        & flutter build apk "--$Mode" --no-pub
        if ($LASTEXITCODE -ne 0) { throw "Android build failed ($LASTEXITCODE)" }
    } finally {
        Pop-Location
    }
} finally {
    $env:JAVA_TOOL_OPTIONS = $previousJavaOptions
}
