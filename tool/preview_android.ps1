param([string]$DeviceId, [switch]$ListDevices)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'development_environment.ps1')
$projectDirectory = Split-Path -Parent $PSScriptRoot
$adbCommand = Join-Path $env:ANDROID_HOME 'platform-tools/adb.exe'
$flutterCommand = Join-Path $env:FLUTTER_ROOT 'bin/flutter.bat'
if ($ListDevices) {
    & $adbCommand devices -l
    if ($LASTEXITCODE -ne 0) { throw 'Unable to list connected Android devices.' }
    return
}
if (-not $DeviceId) {
    $devices = @(& $adbCommand devices)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to list connected Android devices.' }
    $connectedPhones = @($devices | ForEach-Object {
        if ($_ -match '^(\S+)\s+device$' -and $Matches[1] -notlike 'emulator-*') { $Matches[1] }
    })
    if ($connectedPhones.Count -ne 1) {
        $devices | Write-Output
        throw 'Connect one phone with USB debugging enabled and approve its prompt, or pass -DeviceId SERIAL. See ANDROID_PREVIEW.md.'
    }
    $DeviceId = $connectedPhones[0]
}
if ($DeviceId -like 'emulator-*') { throw 'The emulator was removed. Select a physical Android phone.' }
$deviceState = & $adbCommand -s $DeviceId get-state 2>&1
if ($LASTEXITCODE -ne 0 -or "$deviceState".Trim() -ne 'device') {
    throw 'Phone unavailable or unauthorized. Unlock it and approve the USB debugging prompt.'
}
Push-Location $projectDirectory
try {
    Write-Output "Running a debug preview on phone: $DeviceId"
    Write-Output 'Press r for hot reload, R for hot restart, q to stop. The first run compiles and installs a debug app.'
    & $flutterCommand run --debug --no-pub -d $DeviceId
    if ($LASTEXITCODE -ne 0) { throw "Phone preview failed ($LASTEXITCODE)." }
} finally { Pop-Location }
