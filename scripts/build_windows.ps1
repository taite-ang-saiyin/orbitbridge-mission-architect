param(
    [Parameter(Mandatory = $true)][string]$GodotExe,
    [string]$OutputDirectory = "",
    [switch]$Verify
)

$ErrorActionPreference = 'Stop'
$orbitProject = Split-Path -Parent $PSScriptRoot
$orbitEditor = (Resolve-Path -LiteralPath $GodotExe).Path
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $orbitProject 'exports\windows'
}
$orbitOutput = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $orbitOutput -Force | Out-Null
$orbitExecutable = Join-Path $orbitOutput 'OrbitBridge.exe'
$orbitExportLog = Join-Path $orbitOutput 'export.log'
$orbitProcess = Start-Process -FilePath $orbitEditor -ArgumentList @(
    '--headless', '--path', ('"' + $orbitProject + '"'),
    '--export-release', '"Windows Demo"', ('"' + $orbitExecutable + '"'),
    '--log-file', ('"' + $orbitExportLog + '"')
) -WindowStyle Hidden -PassThru -Wait
if ($orbitProcess.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $orbitExecutable)) {
    throw "Windows export failed. Read $orbitExportLog"
}
Copy-Item -LiteralPath (Join-Path $orbitProject 'docs\windows-demo-readme.txt') -Destination (Join-Path $orbitOutput 'README.txt')
if ($Verify) {
    $orbitCheckLog = Join-Path $orbitOutput 'verification.log'
    $orbitCheck = Start-Process -FilePath $orbitExecutable -ArgumentList @(
        '--headless', '--log-file', ('"' + $orbitCheckLog + '"'), '--', '--verify-demo'
    ) -WindowStyle Hidden -PassThru -Wait
    $orbitCheckText = Get-Content -LiteralPath $orbitCheckLog -Raw
    if ($orbitCheck.ExitCode -ne 0 -or $orbitCheckText -notmatch 'Windows demo verification: \d+ checks passed; 0 failed\.') {
        throw "Exported app check failed. Read $orbitCheckLog"
    }
    Write-Output ($orbitCheckText -split "`n" | Where-Object { $_ -match '^K14 scenarios:|^Windows package checks:|^Windows demo verification:' })
}
Get-FileHash -LiteralPath $orbitExecutable -Algorithm SHA256 | Format-List
Write-Output "Windows app ready: $orbitExecutable"
