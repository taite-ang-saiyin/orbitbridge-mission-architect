OrbitBridge - Windows demo

Open OrbitBridge.exe. Godot does not need to be installed on the demo computer.
The game data is inside the executable. Keep this README with the demo if sharing it.

Quick demo
1. Select Start Mission, then Continue Mission.
2. For the tested success example, choose Capture Imagery, Equator, Polar - 600 km,
   4 observations, 30 MB returned, 6 orbits, budget 100, and Observe First policy.
3. In Satellite Builder, the starter totals are 1060 g and 82 credits.
4. Continue to Readiness, then choose Launch Mission.
5. Choose Skip to End, then View Debrief.
6. This example captures 4 observations, returns 48 MB and scores 100.
The default preset has different goals; results depend on the selected settings.

Try a blocked design
Choose the Advanced imaging camera in Builder. Weight becomes 1380 g.
The sample 1U rule requires weight strictly below 1330 g, so launch is blocked.
Choose the Basic imaging camera again to return to the starter design.

Controls
F11 switches between fullscreen and a window.
Observe, Send data and Save power each use one mission step when allowed.
Play follows the selected policy trace. Skip to End finishes playback.
Stop mission ends the run with no numeric score. Retry same mission starts with clean counters.
Modify design opens Builder with a copy of the completed mission. Cancel Retry restores
the original run and result. A valid changed design starts a new run when launched.
Show credits opens the source details. Focus the report and use arrow/Page Up/Page Down
keys to scroll; Tab moves to the next control.
Use Home, then Quit to close the app.

Model and source
Parts, costs, power rules, appearances and orbit windows are illustrative training values.
The sample mass check is adapted from NASA CubeSat 101, Appendix C item 6,
printed page 79 / PDF page 87: mass < 1.33 kg (1330 g).
This is an educational sample profile, not flight certification.
NASA reference: https://www.nasa.gov/wp-content/uploads/2017/03/nasa_csli_CubeSat_101_508.pdf
Godot Engine: https://godotengine.org/license/

Optional automated check
From a terminal in this folder:
.\OrbitBridge.exe --headless --log-file verification.log -- --verify-demo
The app runs its checks, writes the log and closes automatically.
Opening the app normally never runs this mode.

Survey can show per-target deliveries but scoring is unavailable in this build.
The optional run-comparison feature and browser version are not verified for this demo.
