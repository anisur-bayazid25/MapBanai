MapBanai v2.6.5 — Easier study-map imports and category styling

- Android file selection now allows spatial files regardless of MIME filtering, with app-side format validation. ZIP shapefiles retain companion attributes, including multiple shapefiles in one ZIP.
- Open spatial files from a file manager into an existing project, a new project, or a view-only Study Area map. Standalone SHP needs its companion DBF; use ZIP on Android. Supported formats include GeoJSON, WGS84 GeoPackage, SHP/ZIP, CSV, Excel and KML/KMZ.
- Study imports preserve project binding and refresh immediately after saving. Sync-queue failures are reported separately instead of hiding successfully imported sites.
- Only top-toolbar import/export controls remain. Project name aligns left; Add new Layer is inside the study-layer dropdown. Plus opens the selected questionnaire at the current fresh GPS location. Long-press point placement remains available.
- Categories & colors: all features have the same default color. Explicitly choose a column such as layer, set colors, select visible categories and adjust point size. Choices persist per project/study layer without changing data or verification status.
- Home Field quality checks and Offline maps buttons are centered together.

Manager setup and scripts are included in the release. Live Android document-provider behavior still needs device verification. GeoPackage uses the first feature table yielding sites; ZIP limits are 100 MB compressed / 200 MB unpacked. Existing sync and questionnaire setup remains unchanged.

Validation: 394 Flutter tests passed, actual Shyampur ZIP imported 460 sites with all attributes, and manager backend checks passed. Analysis has no errors; three existing test warnings remain.

Version 2.6.5+28.

Study Area → Edit feature: questionnaires are mandatory for newly created features and Updated/New feature statuses. For Pending verification, Completed (legacy), Verified unchanged, Not found and Needs review, saving skips the questionnaire unless Fill questionnaire (optional) is checked. Existing answers are preserved when skipped. Categories & colors offers explicit Verification status coloring as well as attribute columns; the default remains a single color.
