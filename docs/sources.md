# Source ledger and assumptions

Prepared 14 November 2026. Distinguish user-supplied planning requirements, verified primary sources, and proposed gameplay assumptions. Reading a reference is not independent verification of organizer eligibility or permission to implement before kickoff.

## Team proposal

- Title: OrbitBridge 33 Hour Hackathon Team Plan.
- User-supplied file: `OrbitBridge_33_Hour_Hackathon_Team_Plan.pdf` (original retained by the user; not copied into this repository).
- Reviewed all 22 pages as extracted text; visually checked KE1 assignment pages 11 and 18.
- Pages 1/3/9: preparation and kickoff boundaries. Pages 7/18: sample 1U mass rule and KE1 handoff. Pages 8-10: architecture and proposed contracts. Pages 13-15: schedule and acceptance tests.
- The proposal says the live challenge resource tab was not independently retrieved. Do not convert that statement into verified competition eligibility.

## Current team repository

- URL: https://github.com/taite-ang-saiyin/orbitbridge-mission-architect.git
- Initial clone reviewed at commit `01e1d06` on `main`; README names GDScript, local JSON, and an offline Windows primary delivery.
- Existing project.godot declares Godot 4.7 features and Forward Plus. It includes an assembly-name setting but no C# scripts or C# project files were present at initial clone.
- These observations describe the cloned state, not a finalized team agreement. The earlier proposal selected browser delivery and Compatibility rendering; record the team decision before changing either scope or project configuration.

## NASA rule record: cubesat_101_1u_sample

- Title: CubeSat 101: Basic Concepts and Processes for First-Time CubeSat Developers.
- Primary PDF: https://science.nasa.gov/wp-content/uploads/2023/06/nasa_csli_cubesat_101_508.pdf
- Verified accessible NASA-hosted copy: https://www.nasa.gov/wp-content/uploads/2017/03/nasa_csli_CubeSat_101_508.pdf
- Offline copy: [NASA_CubeSat_101.pdf](references/NASA_CubeSat_101.pdf).
- Original alternate URL from proposal: https://www3.nasa.gov/sites/default/files/atoms/files/nasa_csli_cubesat_101_508.pdf
- Intended use: visible sample 1U launch-readiness check, not a claim of flight certification.
- Proposal's value: spacecraft mass strictly below 1.33 kg, converted to strictly below 1330 g.
- Comparator: <, not <=. Boundary tests: 1329 g passes this check; 1330 g and 1331 g fail.
- Primary-source verification: VERIFIED on 14 November 2026. Opened the alternate NASA-hosted PDF, downloaded it, extracted the full relevant page, and visually checked the checklist. Locator: Appendix C, Templates, item 6, 1U CubeSat Acceptance Checklist; printed page 79, PDF page 87 of 96 (zero-based page 86). Checklist revision date: 02/20/2014. The mass field states "Mass (< 1.33 kg)". The science.nasa.gov URL timed out; use the verified NASA-hosted copy for access. Event resource-list eligibility remains unverified.
- Intended implementation: scripts/core/mission_validator.gd and selected launch-profile data; NOT IMPLEMENTED.
- Intended display: Builder/readiness total mass, threshold, verdict, sample-profile label, and source credit; NOT IMPLEMENTED.
- Proposed credit: "Sample 1U mass check adapted from NASA CubeSat 101, Appendix C, item 6, p.79. This educational profile requires total modeled spacecraft mass below 1.33 kg. Other values are illustrative."

KE1 gives KE2 the verified locator, units, comparator, source ID, and actual implementation location. KE2 confirms the credit in the exported build and verifies the challenge resource-list requirement separately.

## NASA mission systems reference

- Title: Design and Develop Science Missions, Julie Levri, 26 March 2025.
- URL: https://www.nasa.gov/wp-content/uploads/2025/04/250323-design-and-develop-science-mission.pdf?emrc=a454cf
- Verified by opening the official PDF. Slide 8 describes launch, space, ground, and user segments.
- Proposed game mapping: launcher -> launch; bus/instrument/power/radio/storage -> space; contact/downlink reception -> ground; returned observations/data and player-defined goals -> user.
- This mapping is an educational adaptation, not a validated real mission design.

## NASA trade-study reference

- Title: Mission Design Lab, Goddard Engineering and Technology Directorate.
- URL: https://etd.gsfc.nasa.gov/capabilities/integrated-design-center/mission-design-lab/
- Verified by opening the official page. It describes tailored trade studies and subsystem comparisons, including mass, power, data rates, and risk.
- Proposed use: compare a compact CubeSat design with an illustrative larger design, or change one subsystem and explain the trade-off with KE2.

## Tool references

- Godot Windows download: https://godotengine.org/download/windows/
- Godot command-line guide: https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html
- Godot Web export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- Codex AGENTS.md: https://learn.chatgpt.com/docs/agent-configuration/agents-md
- Antigravity rules: https://antigravity.google/docs/rules/
- Official pages opened during preparation. Godot's page lists 4.7.2 Standard Windows x64. Actual local download/version verification belongs in tool-setup.md; a web listing alone does not prove a working installation.
- AGENTS.md is the shared instruction file. GEMINI.md is a small compatibility pointer. No global assistant settings are changed.

## Assumptions requiring explicit labels

Catalog component mass/power/cost values unless separately sourced; credit-based budget; alternate-profile thresholds; launcher capacities; fixed orbital contact/observation windows; observation and downlink rates; and any essential-power shortcut. Identify their assumption IDs in the future catalog. Never attach a NASA source ID to invented parameters merely because the profile also has one NASA-derived rule.
