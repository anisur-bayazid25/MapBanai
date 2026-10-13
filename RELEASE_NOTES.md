MapBanai v2.6.4 — Clear manager setup and better field maps

- New-project manager setup: copy only the project UUID into Code.gs, leave the other four placeholders unchanged, run setupMapBanai to create the API key, photo folder and data tabs, then deploy a new Web app. All instructions are available offline in Help. Complete readable Code.gs, Map.html, Charts.html and guides are included.
- Test Connection verifies the project ID, API key and data-sheet access without sending field records. Clear diagnostics explain sign-in pages, incorrect URLs and unsupported scripts.
- Same six basemaps in GIS and Study Area, including No background. Questionnaire fields replace the duplicate project Data collection fields editor; previous data remain stored. One name editor in the Home three-bar menu. Home icons and titles align with shorter sync timestamps.
- Map exports show only mapped legend categories with actual symbols and editable names. Choose point icons, line patterns and polygon outlines or upload PNG/self-contained SVG point icons. Resolution-aware titles, legends, symbols and north arrows improve FHD/4K readability. Seven independent title/subtitle/legend font choices and readability presets. Images show only basemap attribution when a basemap is included, without feature/reference counts or a No basemap footer.
- Smoother Android sensor compass with GPS travel-bearing fallback and clearer altitude reference/uncertainty. GNSS altitude is not floor height.

Validated: 380 Flutter tests, manager backend contract checks and browser map/chart image-export checks. Static analysis has no errors; three pre-existing unused-variable warnings remain. Native sensor behavior and a live Google deployment require field validation.

For a new project, download the manager workspace ZIP and follow its README. Install app-release.apk. Version 2.6.4+27.
