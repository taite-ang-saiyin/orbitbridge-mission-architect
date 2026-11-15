param([Parameter(Mandatory = $true)][string]$GodotExe)

$ErrorActionPreference = 'Stop'
$evidenceRoot = Split-Path -Parent $PSScriptRoot
$evidenceEditor = (Resolve-Path -LiteralPath $GodotExe).Path
$evidenceLogs = Join-Path $evidenceRoot 'exports\hpc-goal-evidence-v1'
$evidenceBundle = Join-Path $evidenceRoot 'docs\handoffs\hpc-goal-evidence-v1'
New-Item -ItemType Directory -Path $evidenceLogs -Force | Out-Null
$evidenceChecks = @(
    @{ Name = 'generate'; Script = 'tests/run_hpc_goal_examples.gd'; UserArgs = @() },
    @{ Name = 'verify-persisted'; Script = 'tests/run_hpc_goal_examples.gd'; UserArgs = @('--verify-only') },
    @{ Name = 'hpc-regression'; Script = 'tests/test_hpc.gd'; UserArgs = @() },
    @{ Name = 'prediction-multitarget'; Script = 'tests/prediction_multitarget_smoke.gd'; UserArgs = @() },
    @{ Name = 'legacy-regression'; Script = 'tests/test_simulator.gd'; UserArgs = @() }
)
$evidenceResults = @()
$evidencePortableLogs = Join-Path $evidenceBundle 'logs'
foreach ($evidenceCheck in $evidenceChecks) {
    $evidenceLog = Join-Path $evidenceLogs ($evidenceCheck.Name + '.log')
    $evidenceArguments = @('--headless', '--path', ('"' + $evidenceRoot + '"'), '--log-file', ('"' + $evidenceLog + '"'), '--script', ('res://' + $evidenceCheck.Script))
    if ($evidenceCheck.UserArgs.Count -gt 0) { $evidenceArguments += @('--') + $evidenceCheck.UserArgs }
    $evidenceProcess = Start-Process -FilePath $evidenceEditor -ArgumentList $evidenceArguments -WindowStyle Hidden -PassThru
    if (-not $evidenceProcess.WaitForExit(60000)) {
        $evidenceProcess.Kill()
        throw ('Timed out: ' + $evidenceCheck.Name)
    }
    $evidenceText = Get-Content -LiteralPath $evidenceLog -Raw
    if ($evidenceProcess.ExitCode -ne 0 -or $evidenceText -match 'SCRIPT ERROR:|Parse Error:|Compile Error:|TEST FAILURE:') {
        Write-Output $evidenceText
        throw ('Failed: ' + $evidenceCheck.Name + ' (exit ' + $evidenceProcess.ExitCode + ')')
    }
    $evidenceResults += [ordered]@{
        name = $evidenceCheck.Name
        command = 'godot --headless --path . --script ' + $evidenceCheck.Script + $(if ($evidenceCheck.UserArgs.Count -gt 0) { ' -- ' + ($evidenceCheck.UserArgs -join ' ') } else { '' })
        exit_code = $evidenceProcess.ExitCode
        script_errors = $false
        log_path = 'logs/' + $evidenceCheck.Name + '.log'
        log_sha256 = (Get-FileHash -LiteralPath $evidenceLog -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    Write-Output ('PASS ' + $evidenceCheck.Name + ' (exit ' + $evidenceProcess.ExitCode + ')')
    Write-Output ($evidenceText -split "`n" | Where-Object { $_ -match 'HPC goal evidence:|tests passed:|PASS prediction/' })
}
New-Item -ItemType Directory -Path $evidencePortableLogs -Force | Out-Null
foreach ($evidenceCheck in $evidenceChecks) {
    Copy-Item -LiteralPath (Join-Path $evidenceLogs ($evidenceCheck.Name + '.log')) -Destination (Join-Path $evidencePortableLogs ($evidenceCheck.Name + '.log'))
}
$evidenceVerification = [ordered]@{
    bundle_revision = 'hpc-goal-evidence-v1.0.0'
    source_commit_sha = 'dce75db845f6c494b8c25c9028dd9c0648aabd91'
    runner_sha256 = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToLowerInvariant()
    manifest_sha256 = (Get-FileHash -LiteralPath (Join-Path $evidenceBundle 'manifest.json') -Algorithm SHA256).Hash.ToLowerInvariant()
    checks = $evidenceResults
    exit_code = 0
    note = 'Certificate-store diagnostics are environment messages. Script failures are checked independently of process exit status.'
}
$evidenceJson = ($evidenceVerification | ConvertTo-Json -Depth 8).Replace("`r`n", "`n")
[IO.File]::WriteAllText((Join-Path $evidenceBundle 'verification.json'), $evidenceJson + "`n", (New-Object Text.UTF8Encoding($false)))
Write-Output 'All HPC goal-evidence checks passed.'
exit 0
