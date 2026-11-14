# Returned validated KE2 report commands

Working directory: `C:\Workspace\OrbitBridge\Event\ke3_outline_preview`. B02 and official B10 NOT TESTED.

Packet check (working directory this report folder):

```powershell
& 'C:\Program Files\WindowsApps\OpenAI.CodexPrimaryRuntime.v26-1112-737-0_26.1112.737.0_x64__3k8sg7r9htsxt\dependencies\python\python.exe' -X utf8 -B verify_packet.py
```

Exit0;48 checks passed;0 mismatches. Archive contents read without executing embedded commands.

## import

```powershell
& 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' '--path' 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview' '--headless' '--editor' '--quit'
```

Exit 0; PASS; script errors=False. Log: `C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\import.log`.

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

## validated-headless

```powershell
& 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' '--path' 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview' '--headless' '--script' 'res://tests/ke2_validated_debrief_check.gd' '--' '--output-dir' 'C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\validated-headless'
```

Exit 0; PASS; script errors=False. Log: `C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\validated-headless.log`.

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
VALIDATED KE2 DEBRIEF: 63 checks; 0 failures
FIXTURE PASS

## old-recorded-headless

```powershell
& 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' '--path' 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview' '--headless' '--script' 'res://tests/ke2_recorded_debrief_check.gd' '--' '--output-dir' 'C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\old-recorded-headless'
```

Exit 0; PASS; script errors=False. Log: `C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\old-recorded-headless.log`.

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
KE2 RECORDED SAMPLE DEBRIEF: 49 checks; 0 failures
FIXTURE PASS with KE2 recorded sample

## a05-headless

```powershell
& 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' '--path' 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview' '--headless' '--script' 'res://tests/a05_debrief_check.gd' '--' '--output-dir' 'C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\a05-headless'
```

Exit 0; PASS; script errors=False. Log: `C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\a05-headless.log`.

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
SYNTHETIC A05: 139 checks; 0 failures
FIXTURE PASS

## a06-headless

```powershell
& 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' '--path' 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview' '--headless' '--script' 'res://tests/a06_retry_check.gd' '--' '--output-dir' 'C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\a06-headless'
```

Exit 0; PASS; script errors=False. Log: `C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\a06-headless.log`.

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
SYNTHETIC A06 P0: 100 checks; 0 failures
FIXTURE PASS

## validated-windowed

```powershell
& 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' '--path' 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview' '--audio-driver' 'Dummy' '--resolution' '1280x960' '--script' 'res://tests/ke2_validated_debrief_check.gd' '--' '--output-dir' 'C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\validated-windowed' '--capture'
```

Exit 0; PASS; script errors=False. Log: `C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\validated-windowed.log`.

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
OpenGL API 3.3.0 NVIDIA 576.80 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 4060 Laptop GPU
VALIDATED KE2 DEBRIEF: 67 checks; 0 failures
FIXTURE PASS

## old-recorded-windowed

```powershell
& 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' '--path' 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview' '--audio-driver' 'Dummy' '--resolution' '1280x960' '--script' 'res://tests/ke2_recorded_debrief_check.gd' '--' '--output-dir' 'C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\old-recorded-windowed' '--capture'
```

Exit 0; PASS; script errors=False. Log: `C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\old-recorded-windowed.log`.

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
OpenGL API 3.3.0 NVIDIA 576.80 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 4060 Laptop GPU
KE2 RECORDED SAMPLE DEBRIEF: 52 checks; 0 failures
FIXTURE PASS with KE2 recorded sample

## a05-windowed

```powershell
& 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' '--path' 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview' '--audio-driver' 'Dummy' '--resolution' '1280x960' '--script' 'res://tests/a05_debrief_check.gd' '--' '--output-dir' 'C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\a05-windowed' '--capture'
```

Exit 0; PASS; script errors=False. Log: `C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\a05-windowed.log`.

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
OpenGL API 3.3.0 NVIDIA 576.80 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 4060 Laptop GPU
SYNTHETIC A05: 156 checks; 0 failures
FIXTURE PASS

## a06-windowed

```powershell
& 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' '--path' 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview' '--audio-driver' 'Dummy' '--resolution' '1280x960' '--script' 'res://tests/a06_retry_check.gd' '--' '--output-dir' 'C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\a06-windowed' '--capture'
```

Exit 0; PASS; script errors=False. Log: `C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\a06-windowed.log`.

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
OpenGL API 3.3.0 NVIDIA 576.80 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 4060 Laptop GPU
SYNTHETIC A06 P0: 104 checks; 0 failures
FIXTURE PASS

## a07-900x680

```powershell
& 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' '--path' 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview' '--audio-driver' 'Dummy' '--resolution' '900x680' '--script' 'res://tests/a07_local_qa_check.gd' '--' '--size' '900x680' '--output-dir' 'C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\a07-900x680'
```

Exit 0; PASS; script errors=False. Log: `C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\a07-900x680.log`.

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
OpenGL API 3.3.0 NVIDIA 576.80 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 4060 Laptop GPU
A07 RESULT: 80 checks; 0 failures; viewport (900, 680)
FIXTURE PASS

## validated-headless

```powershell
& 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' '--path' 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview' '--headless' '--script' 'res://tests/ke2_validated_debrief_check.gd' '--' '--output-dir' 'C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\validated-headless'
```

Exit 0; PASS; script errors=False. Log: `C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\validated-headless.log`.

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
VALIDATED KE2 DEBRIEF: 63 checks; 0 failures
FIXTURE PASS

## validated-windowed

```powershell
& 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' '--path' 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview' '--audio-driver' 'Dummy' '--resolution' '1280x960' '--script' 'res://tests/ke2_validated_debrief_check.gd' '--' '--output-dir' 'C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\validated-windowed' '--capture'
```

Exit 0; PASS; script errors=False. Log: `C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\validated-windowed.log`.

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
OpenGL API 3.3.0 NVIDIA 576.80 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 4060 Laptop GPU
VALIDATED KE2 DEBRIEF: 67 checks; 0 failures
FIXTURE PASS

## ke2-reply-edges-headless

```powershell
& 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' '--path' 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview' '--headless' '--script' 'C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\ke2_reply_edges.gd' '--' 'C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\reply-edges-headless' 'C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\reply-contract-examples'
```

Exit 0; PASS; script errors=False. Log: `C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\ke2-reply-edges-headless.log`.

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
KE2 REPLY EDGES: 24 checks; 0 failures
FIXTURE PASS

## ke2-reply-edges-windowed

```powershell
& 'C:\Workspace\OrbitBridge\Godot_v4.7.2-stable_win64\Godot_v4.7.2-stable_win64_console.exe' '--path' 'C:\Workspace\OrbitBridge\Event\ke3_outline_preview' '--audio-driver' 'Dummy' '--resolution' '1280x960' '--script' 'C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\ke2_reply_edges.gd' '--' 'C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\reply-edges-windowed' 'C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\reply-contract-examples' '--capture'
```

Exit 0; PASS; script errors=False. Log: `C:\Workspace\OrbitBridge\Event\ke3_validated_ke2_debrief_check\evidence\ke2-reply-edges-windowed.log`.

Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
OpenGL API 3.3.0 NVIDIA 576.80 - Compatibility - Using Device: NVIDIA - NVIDIA GeForce RTX 4060 Laptop GPU
KE2 REPLY EDGES: 29 checks; 0 failures
FIXTURE PASS

Runner invocation from this report folder:

```powershell
& 'C:\Program Files\WindowsApps\OpenAI.CodexPrimaryRuntime.v26-1112-737-0_26.1112.737.0_x64__3k8sg7r9htsxt\dependencies\python\python.exe' -X utf8 -B run_checks.py
```

Actual runner exit0. finalize.py records preservation/report only; exit0.
