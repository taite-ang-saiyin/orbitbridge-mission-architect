# Myanmar language support

Choose **Home → Settings → Language → မြန်မာ**. This replaces the former Simplified Chinese option. Preferences remain session-only.

Translated surfaces: Home, Settings, Mission Control, Mission Creator, Spacecraft Builder, Flight Readiness, mission review and SE setup dialogs. Operations and Debrief, including their shared shell, continue to display English. Returning to setup restores the selected Myanmar language.

Mission names/descriptions in editable fields, catalog IDs, config values, numeric measurements and units retain their original data. Translation is applied to presentation nodes; it does not set a global TranslationServer locale or rewrite saved executions. Authored preset names can have translated display labels.

## Files

- `data/localization/myanmar.json`: display phrases, including headings, component names, review text and readiness messages.
- `data/localization/myanmar_patterns.json`: variable-number message templates, preserving measurements.
- `scripts/settings/MyanmarText.gd`: display-text lookup and font access.
- `scripts/settings/ScopedLanguage.gd`: scoped presentation refresh, English restoration and wrapped choice-card sizing.
- `assets/fonts/myanmar/`: bundled Noto Sans Myanmar Regular, font source information and SIL Open Font License.

English remains available in the same setting. Dynamic setup labels are refreshed in the selected language. Custom-drawn Mission Flow and resource gauges also use the scoped language. Operations/Debrief scripts and their report content are not translated.

## Verification

The localization smoke test exercises settings selection, all four setup pages, mission review, dynamic text, stable config/component IDs, excluded Operations/Debrief, return to setup, restoration of English/fonts, wrapped cards, Myanmar glyph coverage and numeric error-message formatting.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/myanmar_localization_smoke.gd
```

Expected: 28 checks passed, zero failed. Home's existing smoke test now expects Myanmar instead of Chinese. Native rendered Settings and all four setup pages were inspected during implementation. Browser export was not tested.
