MapBanai v2.6.3 — Easier field collection, corrections and map downloads

- Enumerator shortcuts in the existing three-bar menu: My name, My responses, Help & manager setup and Settings. Questionnaire sync is visible in Survey Mode; data sync stays on Home.
- Saved corrections retain stable IDs and original collectors, record editors and increment response revisions. They return to the upload queue. An older backend cannot silently acknowledge edited data.
- Updated manager Code.gs uses one workbook/deployment/key per project, preserves compatible old Responses/Features and existing keys, stores uploaded revision history and rejects conflicts. Map.html and Charts.html provide refreshed manager workspaces, themes, filters and image downloads. All three files are copyable in offline Help and attached to this release with setup guidance.
- Separate Download Map button with twelve designs, custom colors/type/captions, portrait/landscape, aspect ratios and exact HD/Full HD/QHD/4K/custom sizes. Save or share PNG/JPEG; export limit is 4096 pixels per side and 8.4 megapixels.
- Project-owned shapefile/ZIP/GeoJSON references with visibility/color/opacity, package portability and image exports. Six basemaps include topographic, humanitarian, cycling and No background.

Install the signed APK over the existing app to retain local storage. Photos require geotags; GPS accuracy is noted without a mandatory threshold. Repeated observations and reusable templates remain available.

Managers must update Code.gs (and Map.html/Charts.html for the new workspaces), run setupMapBanai and deploy a new version of their existing /exec endpoint. The APK does not modify your Google deployment. See the attached manager README and ONLINE_QUESTIONNAIRES.md for URL/key retrieval and migration. The backend uploads records; it does not download other phones' data or automatically merge competing edits.

Validation includes automated Flutter/backend tests, static analysis, browser workspaces/map exports and production signing checks. No physical Android device or live Google deployment was available; test the native save picker and one complete collect/edit/sync cycle before rollout.
