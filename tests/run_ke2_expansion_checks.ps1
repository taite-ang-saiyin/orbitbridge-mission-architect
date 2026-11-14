param([Parameter(Mandatory = $true)][string]$GodotExe)

$ErrorActionPreference = 'Stop'
$orbitProject = Split-Path -Parent $PSScriptRoot
$orbitGodot = (Resolve-Path -LiteralPath $GodotExe).Path
$orbitVersion = & $orbitGodot --version
if ($LASTEXITCODE -ne 0 -or "$orbitVersion" -notmatch '^4\.7\.2\.') {
    throw "Expected verified Godot 4.7.2, received: $orbitVersion"
}
Write-Output "Godot $orbitVersion"
$orbitLogs = Join-Path $orbitProject 'exports\check-logs'
New-Item -ItemType Directory -Path $orbitLogs -Force | Out-Null
$orbitChecks = @('test_mission_evaluator', 'ke2_independent_work_check', 'ke2_comparison_api_check',
    'ke2_imaging_presets_check', 'ke2_expansion_candidate_check', 'ke2_results_integration', 'debrief_summary_check')
foreach ($orbitCheck in $orbitChecks) {
    $orbitLog = Join-Path $orbitLogs ($orbitCheck + '.log')
    $orbitProcess = Start-Process -FilePath $orbitGodot -WindowStyle Hidden -PassThru -ArgumentList @(
        '--headless', '--path', ('"' + $orbitProject + '"'), '--log-file', ('"' + $orbitLog + '"'),
        '--script', ('res://tests/' + $orbitCheck + '.gd'))
    if (-not $orbitProcess.WaitForExit(60000)) {
        $orbitProcess.Kill()
        throw "$orbitCheck timed out; see $orbitLog"
    }
    $orbitOutput = Get-Content -LiteralPath $orbitLog -Raw
    if ($orbitProcess.ExitCode -ne 0 -or $orbitOutput -match '(?m)SCRIPT ERROR:|Parse Error:|FAIL ') {
        throw "$orbitCheck failed (exit $($orbitProcess.ExitCode)); see $orbitLog"
    }
    Write-Output "PASS $orbitCheck"
}
Write-Output 'KE2: 7 programs passed. Expansion rules are candidates; integration/export acceptance remains separate.'
