# KE3 branch handoff

Operations, orbit/timeline, Debrief, scoped credits, Retry presentation and the isolated A01-A07 previews are now available in this branch. Start with [docs/ke3/README.md](docs/ke3/README.md).

The root `project.godot`, SE MissionController and production routes are preserved from main. This branch does **not** claim real Builder -> KE1 -> HPC -> KE2 -> Results integration. B02 and official B10 remain **NOT TESTED**.

Reusable UI/session code is in `ke3/`. Explicit development-only entries and immutable recorded reports are in `preview/`; tests are under `tests/`. A portable runner creates a separate preview project, leaving team startup/settings untouched:

```powershell
python tools/ke3/verify.py --godot 'C:/path/to/Godot_v4.7.2-stable_win64_console.exe' --output-dir 'C:/Temp/OrbitBridge-KE3-check' --mode all
```

Use a new output directory for each execution. Raw cache, logs, screenshots, engine binaries and Web exports are excluded from this handoff.
