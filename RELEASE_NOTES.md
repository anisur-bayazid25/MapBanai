MapBanai v2.6.2 - Repeated observations and reusable projects

- Site timelines link completed visits to stable feature UUIDs. Compare salinity or another numeric question by questionnaire, inspect earlier answers, and export all observations as CSV. Each visit keeps earlier measurements; the map shows the latest summary.
- Imported visit history joins local observations without duplicates. GeoJSON and visit uploads include feature UUIDs. Timelines show local history; downloading observations from other phones is not added.
- Save project or selected-layer templates. Reuse forms and named layers in fresh projects, or add layers to an existing project. Templates omit collected records, site geometry, photos and cloud credentials.
- Share project packages with optional Apps Script URL/API key. Review and apply updated XLSForms from Google Sheets while preserving earlier records and drafts.
- Offline Help covers field modes and manager setup with a complete copyable Sheets/Drive backend. One or two workbooks use one deployment/key per project. Uploads validate project identity and deduplicate retries.
- WebMap themes, labels, poster captions and PNG/JPEG image export support Android sharing. Missing or blocked basemap tiles may require data-only export.

Install over your existing app using the signed APK. Photos still require geotags; GPS accuracy is recorded without imposing an accuracy threshold.

Automated app/backend checks, static analysis, browser map checks and signing verification cover this release. No phone/emulator or live Google deployment was available. Pilot camera/GNSS and your endpoint before fieldwork. Fill the supplied script configuration with your project UUID, workbook IDs, Drive folder and private key, run setupMapBanai and deploy it; existing Google deployments are not changed automatically.

See FIELD_WORKFLOW.md and ONLINE_QUESTIONNAIRES.md in the repository for setup and limits.
