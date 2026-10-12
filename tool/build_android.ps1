param([ValidateSet('debug', 'release')][string]$Mode = 'release')

$ErrorActionPreference = 'Stop'
$previousJavaOptions = $env:JAVA_TOOL_OPTIONS
try {
    # JDK 17's Windows loopback socket fails with some long temporary paths.
    # Keep the workaround local to this build and preserve existing options.
    $socketDirectory = Join-Path $env:SystemRoot 'Temp'
    if (-not (Test-Path -LiteralPath $socketDirectory -PathType Container)) {
        throw "Java socket directory does not exist: $socketDirectory"
    }
    $env:JAVA_TOOL_OPTIONS = "$previousJavaOptions -Djdk.net.unixdomain.tmpdir=$socketDirectory".Trim()
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
