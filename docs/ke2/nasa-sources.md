# KE2 NASA sources and submission credits

Owner KE2. Source review dated 14 November 2026.

The KE2 JSON ledger stores source metadata, units, locators, profile scope, implementation evidence, attribution, and verification status. This document provides a readable record and credit text for the submission owner. [Source ledger](../../data/nasa_sources.json).

## CubeSat 101 sample mass criterion

| Field | Record |
| --- | --- |
| Source ID | `cubesat_101_1u_sample` |
| Title | CubeSat 101: Basic Concepts and Processes for First-Time CubeSat Developers |
| NASA organization | NASA CubeSat Launch Initiative, CSLI |
| Document revision | October 2017 |
| Locator | Appendix C, Templates, item 6, 1U CubeSat Acceptance Checklist |
| Page | Printed 79, PDF 87 of 96, zero-based index 86 |
| Checklist revision | 02/20/2014 |
| Original criterion | Mass strictly below 1.33 kg |
| Conversion | 1 kg = 1000 g, so the threshold is strictly below 1330 g |
| Applicable game profile | `cubesat_1u_sample`, OrbitBridge's sample 1U educational profile |
| Intended validator | `res://scripts/core/mission_validator.gd`, KE1 handoff pending |
| Intended profile catalog | `res://data/launch_profiles.json`, KE1 handoff pending |
| Builder and credits paths | SE/KE3 handoffs pending |
| Source and conversion | Verified |
| Actual mass-check, display, and export verification | Pending |

The verified locator is Appendix C, item 6. The checklist's source wording is `Mass (< 1.33 kg)`. Both official NASA URLs opened during source review. The offline copy's SHA256 is retained in the ledger. [Primary NASA PDF](https://science.nasa.gov/wp-content/uploads/2023/06/nasa_csli_cubesat_101_508.pdf), [alternate NASA PDF](https://www.nasa.gov/wp-content/uploads/2017/03/nasa_csli_CubeSat_101_508.pdf), [offline reference](../references/NASA_CubeSat_101.pdf).

| Modeled spacecraft mass | Expected sample-profile mass check |
| --- | --- |
| 1329 g | Pass |
| 1330 g | Fail |
| 1331 g | Fail |

These expectations apply to the educational sample profile. Other selected profiles use their own readiness rules. Overall readiness also depends on the remaining KE1 checks. Actual validator cases T11/T12, profile switching, Builder labels, and exported credits remain pending. [Testing status](testing.md).

### Exact source credit

Copy the following text and include the primary NASA PDF link.

> NASA CubeSat Launch Initiative, CubeSat 101: Basic Concepts and Processes for First-Time CubeSat Developers (October 2017), Appendix C, item 6, printed p. 79 (PDF p. 87). Reference for OrbitBridge's sample 1U educational profile: modeled spacecraft mass < 1.33 kg (< 1330 g). This profile-specific educational criterion is not a universal satellite limit or flight certification.

The credit records the profile's reference. The release description should reflect the pending gameplay verification recorded above. [NASA source](https://science.nasa.gov/wp-content/uploads/2023/06/nasa_csli_cubesat_101_508.pdf).

## Mission-segment terminology

NASA's Design and Develop Science Missions webinar by Julie Levri, dated March 26, 2025, describes launch, space, ground, and user segments on slide 8. The ledger uses local bibliographic ID `nasa_design_develop_science_missions_2025`. Current feedback code maps contact-window blocks to ground and power/storage/visibility blocks to space. The recorded HPC report demonstrates the ground label. Report source-ID linkage and visible credits remain pending. [NASA webinar PDF](https://www.nasa.gov/wp-content/uploads/2025/04/250323-design-and-develop-science-mission.pdf?emrc=a454cf), [feedback implementation](../../scripts/evaluation/mission_feedback.gd), [recorded report](../handoffs/ke2-hpc-report-v0.1.json).

### Exact terminology credit

> Mission-segment terminology adapted from NASA, Design and Develop Science Missions, Julie Levri, March 26, 2025, slide 8. OrbitBridge's feedback mappings and corrective actions are educational adaptations.

Include the official webinar URL with this text. [NASA source](https://www.nasa.gov/wp-content/uploads/2025/04/250323-design-and-develop-science-mission.pdf?emrc=a454cf).

## Mission Design Lab planning reference

NASA Goddard's Engineering and Technology Directorate describes tailored trade studies and subsystem analysis on its Mission Design Lab page. The ledger records local bibliographic ID `nasa_goddard_mission_design_lab`, with the sections Tailored Trade Study and MDL Disciplines. Existing project notes use it for planning future subsystem comparisons. Gameplay implementation remains pending. [NASA Goddard reference](https://etd.gsfc.nasa.gov/capabilities/integrated-design-center/mission-design-lab/), [planning notes](../sources.md).

### Planning-reference credit

> Planning reference: NASA Goddard Space Flight Center, Engineering and Technology Directorate, Mission Design Lab, sections Tailored Trade Study and MDL Disciplines. No implemented NASA trade-study tool is claimed.

## Submission and integration status

The two additional bibliographic IDs are local to this ledger. Coordinate their shared report use through the team's interface change process. The current evaluator emits `source_ids: []`. Its recorded HPC sample also carries `launch_approved: false`. KE1's actual sourced readiness result and KE3's credit lookup are pending. [Ledger evidence](../../data/nasa_sources.json), [report provenance](../handoffs/ke2-hpc-report-v0.1.metadata.json).

The submission owner can use the exact credit paragraphs for their documented uses. Claims about executed gameplay features should follow their recorded verification status. Component values, rates, fixed windows, and scoring remain project assumptions unless individually sourced. Challenge resource-list eligibility remains unverified. [Source assumptions](../sources.md).
