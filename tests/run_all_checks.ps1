param([Parameter(Mandatory = $true)][string]$GodotExe)

$ErrorActionPreference = 'Stop'
$orbitProject = Split-Path -Parent $PSScriptRoot
$orbitEditor = (Resolve-Path -LiteralPath $GodotExe).Path
$orbitScripts = @(
    'validation/test_mission_validator.gd',
    'validation/test_mission_readiness.gd',
    'validation/test_mission_fixtures.gd',
    'test_hpc.gd',
    'test_simulator.gd',
    'test_mission_evaluator.gd',
    'integration/test_mission_flow.gd',
    'integration/test_screen_flow.gd',
    'acceptance/test_k14_acceptance.gd',
    'home_smoke.gd',
    'responsive_layout_smoke.gd',
    '3d/preview_smoke.gd'
)
$orbitLogs = Join-Path $orbitProject 'exports\check-logs'
New-Item -ItemType Directory -Path $orbitLogs -Force | Out-Null
foreach ($orbitScript in $orbitScripts) {
    $orbitName = [IO.Path]::GetFileNameWithoutExtension($orbitScript)
    $orbitLog = Join-Path $orbitLogs ($orbitName + '.log')
    $orbitProcess = Start-Process -FilePath $orbitEditor -ArgumentList @(
        '--headless', '--path', ('"' + $orbitProject + '"'),
        '--script', ('res://tests/' + $orbitScript), '--log-file', ('"' + $orbitLog + '"')
    ) -WindowStyle Hidden -PassThru
    if (-not $orbitProcess.WaitForExit(45000)) {
        $orbitProcess.Kill()
        throw "Timed out: $orbitScript. Read $orbitLog"
    }
    $orbitText = Get-Content -LiteralPath $orbitLog -Raw
    if ($orbitProcess.ExitCode -ne 0 -or $orbitText -match 'SCRIPT ERROR:|Parse Error:|Compile Error:|FAIL:|TEST FAILURE:') {
        Write-Output $orbitText
        throw "Failed: $orbitScript (exit $($orbitProcess.ExitCode))"
    }
    Write-Output ("PASS " + $orbitScript)
    Write-Output ($orbitText -split "`n" | Where-Object { $_ -match 'checks passed|tests passed:|Evaluator checks:|K14 scenarios:' })
}
Write-Output 'All 12 active check programs passed. Historical mock-prototype checks are archived separately.'
