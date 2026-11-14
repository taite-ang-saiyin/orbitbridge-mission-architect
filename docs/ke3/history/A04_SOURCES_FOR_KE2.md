# A04 source-use notes for KE2

Prepared locally; not sent, published, or installed into a production credit ledger. Source accessibility/title verification below is not NASA endorsement, a human playtest, or confirmation of KE2's canonical attribution.

## Review budget and evidence

The playbook assigns a 45-minute Mission Viz review timebox. Dedicated page review ran on 2026-11-14 from 09:54:34 to 09:58:02 Asia/Rangoon (03:24:34–03:28:02 UTC), 3 minutes 28 seconds within that maximum. Reference reading was bounded, not a claimed 45 minutes of activity. Published descriptions and tutorial code were reviewed; interactive playback of the NASA web apps was NOT TESTED.

Exact HTML document titles, URLs, successful retrieval status and SHA-256 hashes are saved in `verification/a04-source-retrieval.json`. Retrieved HTML files are retained as ignored evidence. No downloaded reference is a runtime dependency.

| Exact title | Exact URL | What was adapted | UI location | Verification |
| --- | --- | --- | --- | --- |
| Mission Visualization | https://nasa.github.io/mission-viz/ | Broad position/progression presentation cue and navigation to its demonstrations. | Operations orbit panel and its attribution footer. | Published page reviewed; HTML retrieved. |
| Trajectory from GMAT | https://nasa.github.io/mission-viz/X3Dom/20160129_Earth_MoonMission_X3D.html | A central body, a trajectory, and a spacecraft marker that reflects progression; reset returns presentation to the supplied starting snapshot. | `ke3/orbit_diagram.gd`, next to the HUD; fresh-run presentation reset. | Document title verified. Visible heading is “Earth Moon Scenegraph for Depicting Cis-Lunar Trajectories.” Published description reviewed; interactive controls NOT TESTED. |
| Elliptical Orbit Simulator | https://nasa.github.io/mission-viz/RMarkdown/Elliptical_Orbit_Design.html | A flat ellipse with a blue central body and a smaller orbiting marker as a readable diagram. | The single orbital path, Earth disk and satellite primitive in `ke3/orbit_diagram.gd`. | Title and published tutorial reviewed. Page credits Daniel A. O’Neil and is dated April 14, 2017. |

The Earth–Moon reference describes a GMAT-generated trajectory. A04 does **not** use that trajectory, its coordinate data, physical equations, source code, or assets. The ellipse tutorial's orbital propagator and Kepler calculations were not reused. A04's 12-position step mapping is an authored diagram convention, not a physical orbital period, target-visibility calculation, or contact model. The timeline layout and flag styling are local presentation work, not claimed NASA algorithms.

The implemented view is labeled **Illustrative trajectory**. The explicit preview and data are labeled **SYNTHETIC**. The Operations footer identifies NASA Mission Viz as the visual-cue reference and points to these notes. No resource cost, legality rule, mission threshold, evaluation, or source-confirmed science result is attributed to these visual references.

## Other materials inspected or not used

- The NASA repository and its `README.md` were inspected for navigation/provenance only: https://github.com/nasa/mission-viz and https://github.com/nasa/mission-viz/blob/main/README.md. Its displayed project heading is `mission-viz`; its description is `Web-based Space Mission Visualization software`. No repository code/assets were incorporated into the UI.
- Local workflow source: **OrbitBridge — KE3 Codex Playbook**, PDF pages 2 and 6, `C:\Users\Asus\Downloads\OrbitBridge_KE3_Codex_Playbook.pdf`. Used for the review budget and A04 scope, not visual assets. No public URL was supplied; public attribution URL is **unverified**. Page 6 was rendered and reviewed; `verification/a04-playbook-page6.png` preserves that check.
- Historical 2023 VR brief: **not consulted or adapted**. No exact title/URL was supplied or independently confirmed; do not attribute A04 to it.
- Optional CSA pacing material: **not consulted or adapted**. No exact title/URL was supplied or independently confirmed; do not attribute A04 to it.
- The original team-plan PDF was not found in the inspected setup files. The existing NASA Mission Viz shortcut supplies the same requested reference URL; confirmation against the team's exact plan revision remains pending.

## KE2 handoff

KE2 should review these source-use records and supply the production credit strings, source IDs, ledger revision, required attribution wording and any project-specific license/disclosure treatment. Until those fields arrive, the on-screen attribution is a preview note, not a finalized production credit. Production wiring remains Part B work.
