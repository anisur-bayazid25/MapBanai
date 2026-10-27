param([string]$DeviceId)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'development_environment.ps1')
$adbCommand = Join-Path $env:ANDROID_HOME 'platform-tools/adb.exe'
if (-not $DeviceId) {
    $phones = @(& $adbCommand devices | ForEach-Object {
        if ($_ -match '^(\S+)\s+device$' -and $Matches[1] -notlike 'emulator-*') { $Matches[1] }
    })
    if ($phones.Count -ne 1) { throw 'Connect one authorized USB-debugging phone, or pass -DeviceId SERIAL.' }
    $DeviceId = $phones[0]
}
if ($DeviceId -like 'emulator-*') { throw 'Select a physical phone.' }
$mirrorRoot = Join-Path ([IO.Path]::GetPathRoot($PSScriptRoot)) 'Development/scrcpy'
$mirrorCommand = Get-ChildItem -LiteralPath $mirrorRoot -Filter scrcpy.exe -Recurse -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending | Select-Object -First 1
if (-not $mirrorCommand) { throw 'Install the official Windows scrcpy archive under E:\Development\scrcpy. See ANDROID_PREVIEW.md.' }
$env:ADB = $adbCommand
$mirrorLogRoot = Join-Path ([IO.Path]::GetPathRoot($PSScriptRoot)) 'Development'
Start-Process -FilePath $mirrorCommand.FullName -WorkingDirectory $mirrorCommand.DirectoryName -WindowStyle Hidden -ArgumentList @(
    '--serial', $DeviceId, '--max-size=1024', '--max-fps=30', '--video-bit-rate=2M',
    '--no-audio', '--window-title=MapBanai-Phone-Preview'
) -RedirectStandardOutput (Join-Path $mirrorLogRoot 'scrcpy-preview.log') `
  -RedirectStandardError (Join-Path $mirrorLogRoot 'scrcpy-preview-error.log') | Out-Null
Write-Output 'Phone mirror opened. Keep Flutter preview running in its terminal; press r there to hot reload.'
