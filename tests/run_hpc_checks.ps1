param(
	[string]$Godot = 'C:\Users\ts.htun\Downloads\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64.exe'
)

$ErrorActionPreference = 'Stop'
$checks = @(
	@{ Name = 'HPC simulator tests'; Script = 'res://tests/test_simulator.gd' },
	@{ Name = 'HPC candidate step-engine tests'; Script = 'res://tests/test_hpc.gd' },
	@{ Name = 'HPC demo'; Script = 'res://tests/run_demo.gd' }
)

foreach ($check in $checks) {
	Write-Output "--- $($check.Name) ---"
	$stdoutPath = Join-Path (Get-Location).Path (".orbitbridge-hpc-" + [guid]::NewGuid().ToString('N') + '.out')
	$stderrPath = Join-Path (Get-Location).Path (".orbitbridge-hpc-" + [guid]::NewGuid().ToString('N') + '.err')
	$process = Start-Process -FilePath $Godot -ArgumentList @('--headless', '--path', (Get-Location).Path, '--script', $check.Script) -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
	$processExit = $process.ExitCode
	$stdoutText = Get-Content -Raw -LiteralPath $stdoutPath -ErrorAction SilentlyContinue
	$stderrText = Get-Content -Raw -LiteralPath $stderrPath -ErrorAction SilentlyContinue
	$outputText = "$stdoutText`n$stderrText"
	Remove-Item -LiteralPath $stdoutPath, $stderrPath -ErrorAction SilentlyContinue
	if ($outputText) {
		Write-Output $outputText
	}
	$scriptError = $outputText -match '(?im)^SCRIPT ERROR:|(?im)^ERROR:.*(?:GDScript|script|parse|compile)|(?im)TEST FAILURE:'
	if ($processExit -ne 0 -or $scriptError) {
		Write-Output "$($check.Name) failed (Godot exit $processExit; script error detected: $scriptError)."
		exit 1
	}
	Write-Output "$($check.Name) passed (Godot exit $processExit; no GDScript errors)."
}

exit 0
