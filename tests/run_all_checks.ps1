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
    'mission_review_smoke.gd',
    'creator_earth_framing_smoke.gd',
    'earth_station_smoke.gd',
    'compact_antenna_smoke.gd',
    'acrimsat_hull_smoke.gd',
    'home_smoke.gd',
    'responsive_layout_smoke.gd',
    '3d/preview_smoke.gd',
    'integration_smoke.gd',
    'controller_evaluation_smoke.gd',
    'creator_builder_catalog_smoke.gd',
    'expanded_missions_smoke.gd',
    'mission_control_smoke.gd',
    'prediction_multitarget_smoke.gd',
    'design_workflow_smoke.gd',
    'modular_reference_smoke.gd',
    'operations_smoke.gd',
    'prototype_smoke.gd',
    'readiness_smoke.gd',
    'satellite_builder_smoke.gd',
    'satellite_selection_smoke.gd',
    'ke2_results_integration.gd',
    'ke3_report_binding_check.gd',
    'ke3_team_integration_check.gd',
    'ke3_power_launcher_check.gd',
    'a03_operations_check.gd',
    'a05_debrief_check.gd',
    'a06_retry_check.gd',
    'mission_fixture_check.gd',
    'ke2_recorded_debrief_check.gd',
    'ke2_validated_debrief_check.gd',
    'integration/test_ke3_merge.gd'
    'player_ui_check.gd'
    'debrief_summary_check.gd'
)
$orbitLogs = Join-Path $orbitProject 'exports\check-logs'
New-Item -ItemType Directory -Path $orbitLogs -Force | Out-Null
foreach ($orbitScript in $orbitScripts) {
    $orbitName = [IO.Path]::GetFileNameWithoutExtension($orbitScript)
    $orbitLog = Join-Path $orbitLogs ($orbitName + '.log')
    $orbitEvidence = Join-Path $orbitProject ('exports\check-evidence\' + $orbitName)
    $orbitProcess = Start-Process -FilePath $orbitEditor -ArgumentList @(
        '--headless', '--path', ('"' + $orbitProject + '"'),
        '--script', ('res://tests/' + $orbitScript), '--log-file', ('"' + $orbitLog + '"'),
        '--', ('"' + $orbitEvidence + '"'), '--output-dir', ('"' + $orbitEvidence + '"')
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
Write-Output "All $($orbitScripts.Count) active check programs passed. Historical mock-prototype checks are archived separately."
