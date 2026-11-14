# Satellite Builder integration

Changed: `scripts/screens/SpacecraftBuilder.gd`, `scripts/visualization/CraftPreview.gd`, `data/mock/DesignCatalog.gd`, `scripts/screens/FlightReadiness.gd`, `scripts/screens/MissionOperations.gd`, `tests/design_workflow_smoke.gd`. Added `data/mock/SatelliteAdapter.gd`, `tests/satellite_builder_smoke.gd`, this document, and nine GLBs plus Godot import settings under `assets/3d/satellite/`.

Source: https://github.com/nasa/NASA-3D-Resources/tree/master/3D%20Models/Satellite%20Kit
The supplied files required Draco decompression for Godot. Geometry, materials and authored transforms are retained. All three slots use the same visual scale (35); native origins align the wings and radio with the body. Numbers identify appearance only. Original files outside the project are unchanged.

The draft stores `body_id`, `wings_id`, `radio_id`. Development IDs are `dev_body_1..3`, `dev_wings_1..3`, `dev_radio_1..3`. Starter is variant 1 in each slot. These are provisional, not KE1-approved IDs or capabilities.

`SatelliteAdapter.catalog(key)` returns option IDs, names, descriptions, specifications and asset paths. `validate(draft)` returns selected_ids, can_proceed, per-selection blockers, warnings, totals_text and capabilities. `refresh(draft)` stores a deep copy in draft.validated_design. Replace this adapter with KE1's catalog and validation implementation. Unknown IDs block continuation; missing art uses a placeholder without changing validation. The development adapter permits preview progression for known IDs and clearly warns that engineering validation is unavailable.

KE1 still needs to supply canonical IDs, names, specifications and costs with agreed units, starter combination, budget/totals, compatibility rules and readiness validation. No production numerical values were invented. Empty capabilities and unavailable totals intentionally expose this gap.

Readiness revalidates and shows the same selected NASA parts. Launch copies the returned result into draft.run_design; Operations takes a deep copy as run_configuration, the handoff seam for HPC. HPC must provide its actual start-run API and capability schema. Current Operations playback and other existing Readiness charts/checks remain explicitly labeled legacy UI fixtures, independent of the selected satellite; they are not engineering predictions.

Verification: Godot 4.7.2 imported all nine decompressed GLBs. Satellite smoke checks all IDs/slots, validation snapshots, unknown-ID blockers, reset, navigation persistence and the exact Readiness-to-Operations handoff. Native Compatibility renderer screenshot checked starter assembly and layout. Workflow smoke updated for the three-category builder.

Browser verification remains pending: no web preset or installed export templates were present. Project uses Compatibility renderer. Export must include all nine dynamically loaded model resources (use all-resources export), then browser-test rendering, rotation, selections, scrolling and state round trips. Older tests asserting removed six-category picker/exploded UI require migration if still used.

## Visual refresh

All former ArchitectSpacecraft and SpacecraftVisual actor entry points now use SatelliteAssembly.gd, with the NASA kit for previews and operations. Operations passes the mission draft IDs into the assembly, including its expanded view. Shared presentation materials add gold foil/seams, silver antenna metal and blue photovoltaic cell grids. The Builder uses a large studio preview and compact three-variant cards. Native rendering and selection/workflow smoke tests verified the refresh; the satellite smoke also checks that Operations renders the reviewed component IDs.

## Current modular reference design and app styling

The whole-satellite selection experiment has been replaced by three independent Body, Solar Panels and Radio choices. Every combination uses three replaceable slots. Body GLBs derive from AcrimSAT, MiRaTa and ICECube with solar-material geometry removed and display bounds normalized; these are compatible visual adaptations, not exact flight configurations. Wings provide twin, segmented and four-panel appearances. Radios provide parabolic dish, compact dish and antenna array appearances. Attachment placement aligns radio bases to the selected body's upper bounds. All three independent component IDs remain in validation and run snapshots.

`tools/extract_reference_bodies.py` reproduces the body GLBs from the retained NASA source assets. The original complete GLBs remain in assets/3d/real for provenance. SatelliteAssembly preserves the embedded body materials. The old whole-satellite cards are no longer exposed.

App styling now shares a navy/cyan theme, sidebar navigation, compact workflow headings and consistent action areas across Mission Control, Creator, Builder, Readiness, Operations and Debrief. Mission Control and the isolated Earth stage use the textured 3D Earth. Debrief's comparison table sizing is corrected. The existing illustrated landing screen is retained. Reference screenshots guide the styling; unavailable service features are not represented as live or online.

Verified all 27 combinations, replacement isolation, persistence/reset, Readiness/run consistency, workflow at 1280×720 and 1024×768, and native renders of all six dashboard screens. Browser export remains unverified as previously documented.
