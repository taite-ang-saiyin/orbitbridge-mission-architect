param(
    [Parameter(Mandatory = $true)][string]$GodotExe,
    [string]$ProjectPath,
    [switch]$ListOnly
)

$ErrorActionPreference = 'Stop'
$orbitRepo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
if (-not $ProjectPath) { $ProjectPath = Join-Path $orbitRepo 'exports\team-alignment-20261115' }
$orbitProject = (Resolve-Path -LiteralPath $ProjectPath).Path
$orbitManifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw | ConvertFrom-Json
if ($ListOnly) {
    foreach ($orbitScript in $orbitManifest.checks) {
        if (-not (Test-Path -LiteralPath (Join-Path $orbitProject ('tests\' + $orbitScript)))) { throw "Missing $orbitScript" }
        Write-Output $orbitScript
    }
    exit 0
}
$orbitGodot = (Resolve-Path -LiteralPath $GodotExe).Path
$orbitVersion = & $orbitGodot --version
if ($LASTEXITCODE -ne 0 -or "$orbitVersion" -notmatch '^4\.7\.2\.') { throw "Expected Godot 4.7.2, received $orbitVersion" }
$orbitLogs = Join-Path $orbitProject 'exports\team-check-logs'
New-Item -ItemType Directory -Path $orbitLogs -Force | Out-Null
$orbitResults = @()
foreach ($orbitScript in $orbitManifest.checks) {
    $orbitName = $orbitScript.Replace('/', '-').Replace('.gd', '')
    $orbitLog = Join-Path $orbitLogs ($orbitName + '.log')
    $orbitOutputDir = Join-Path $orbitProject ('exports\check-evidence\' + $orbitName)
    $orbitProcess = Start-Process -FilePath $orbitGodot -WindowStyle Hidden -PassThru -ArgumentList @(
        '--headless', '--path', ('"' + $orbitProject + '"'), '--log-file', ('"' + $orbitLog + '"'),
        '--script', ('res://tests/' + $orbitScript), '--', ('"' + $orbitOutputDir + '"'), '--output-dir', ('"' + $orbitOutputDir + '"'))
    $orbitTimeout = if ($orbitScript -eq 'ke2_team_alignment_check.gd') { 240000 } else { 60000 }
    if (-not $orbitProcess.WaitForExit($orbitTimeout)) {
        $orbitProcess.Kill()
        throw "Timed out $orbitScript. Read $orbitLog"
    }
    $orbitText = Get-Content -LiteralPath $orbitLog -Raw
    if ($orbitProcess.ExitCode -ne 0 -or $orbitText -match 'SCRIPT ERROR:|Parse Error:|Compile Error:|FAIL[: ]|TEST FAILURE:') {
        throw "Failed $orbitScript (exit $($orbitProcess.ExitCode)). Read $orbitLog"
    }
    $orbitResults += [ordered]@{ script = $orbitScript; exit_code = 0; log_sha256 = (Get-FileHash -LiteralPath $orbitLog -Algorithm SHA256).Hash.ToLowerInvariant() }
    Write-Output ("PASS " + $orbitScript)
}
$orbitSummary = [ordered]@{ godot = "$orbitVersion"; programs_passed = $orbitResults.Count; checks = $orbitResults }
$orbitSummary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $orbitLogs 'summary.json') -Encoding UTF8
Write-Output ("All " + $orbitResults.Count + " combined check programs passed.")
