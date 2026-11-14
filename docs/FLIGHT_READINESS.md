# Flight Readiness

The landing page opens Home. Create a mission, review its summary and tick the acknowledgement before continuing to Builder, choose its spacecraft, then review Flight Readiness using the sidebar or the footer actions. The shared progress strip has been removed.

## Layout and behavior

- Eight checks come from `scripts/core/mission_validator.gd`, using the selected mission and actual component catalog. Each check expands to show its details.
- The interactive orbit preview and specification card reflect the current selections.
- Resource gauges use calculated mass, standby/solar power, and storage capacity. The selected launch profile sets the mass limit. The sample 1U criterion remains visible; the source citation is retained in validation data rather than the Resource Summary text.
- Coverage lists authored observation windows for each selected target and orbit. This is not a prediction of flight success.
- View Details opens a themed in-game overlay with all eight checks, messages and corrective guidance. The content scrolls inside the viewport. Close, Escape or the backdrop dismisses it.
- Launch remains disabled until every required check passes. The launch entry point validates the current selections again.

## Files

- `scripts/screens/FlightReadiness.gd`: page layout and launch action.
- `ui/components/ReadinessDetails.gd`: responsive details overlay.
- `ui/components/ReadinessStatus.gd` and `ResourceGauge.gd`: status symbols and resource gauges.
- `scripts/screens/Workbench.gd`: page headings, scroll area and pinned footer actions.
- `scripts/integration/mission_runtime.gd`: catalog selection and validated launch handoff.

## Verification

Run the headless Godot scripts `tests/readiness_smoke.gd`, `tests/design_workflow_smoke.gd` and `tests/creator_builder_catalog_smoke.gd`. They verify responsive bounds, expandable checks, overlay content and dismissal, profile limits, independent component selection and launch handoff. Automated geometry checks do not replace a rendered visual review.
