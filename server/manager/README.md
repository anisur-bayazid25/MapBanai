# MapBanai manager workspace — v2.6.3

Use one Google workbook, one Apps Script deployment and one private API key for each project. Questions and answers live in separate tabs. This folder contains the complete Code.gs, Map.html and Charts.html; the same files are copyable offline in app Help.

## Install or upgrade

1. Back up your workbook and existing script. Import your XLSForm into Google Sheets, preserving `survey`, `choices`, `settings` tabs and headers. Keep `form_id` and question names stable; increment `version` when changing questions.
2. Open that workbook → Extensions → Apps Script. Replace Code.gs with this file. Add HTML files named **Map** and **Charts**, and paste their matching HTML. Do not paste them inside Code.gs.
3. Set `MAPBANAI.projectId` to the UUID in MapBanai Project Details or Help. For a bound workbook leave the other placeholders: setup uses that workbook, retains the existing `MAPBANAI_API_KEY` and `PHOTOS_FOLDER_ID`, or creates a private key/photo folder. Explicit configuration can select separate question/data workbooks. Use one setup per project.
4. Save and run **setupMapBanai** as the manager. Authorize Sheets/Drive access. It creates missing output tabs and extends compatible legacy **Responses/Features** without deleting rows. Unrelated tabs using reserved names with incompatible headers cause an error; rename those unrelated tabs.
5. Reload the spreadsheet → **MapBanai → Connection and setup guide** to see your key. You can also find `MAPBANAI_API_KEY` under Apps Script → Project Settings → Script properties, or in the private setup execution log. This is a private MapBanai password, not a Google Cloud API key.
6. First deployment: **Deploy → New deployment → Web app → Execute as Me → Who has access Anyone → Deploy**. Copy the Web app URL ending **/exec**, not the editor URL or /dev. Google Workspace policy may restrict available access options.
7. Existing deployment: **Deploy → Manage deployments → Edit → Version: New version → Deploy**. Keep the same deployment URL and existing key. Merely saving code does not update the deployed endpoint.
8. App → Project Details → Cloud Sync: save the /exec URL and key. Survey Mode → Sync questionnaire → Check Google Sheet → review → Apply. Save a test response, Home → Cloud Sync, then edit it from the three-bar menu → My responses and sync again. Confirm the same latest row now has response_revision 2 and both uploaded revisions exist in `revisions`.
9. Export/share the project with **Include sync connection** for trusted enumerators. They import the package and set **My name** in the Home three-bar menu. Keep the same project identity across the team.

Google documents [web-app deployment](https://developers.google.com/apps-script/guides/web), [Script Properties](https://developers.google.com/apps-script/guides/properties), and [HTML client/server communication](https://developers.google.com/apps-script/guides/html/communication).

## Update questions

Edit cells in survey/choices/settings. No script redeployment is needed for question edits. Enumerators explicitly check/apply changes in Survey Mode. New collections use the latest form; prior records and drafts retain their snapshots. One online XLSForm is served per project. The app supports its documented XLSForm subset, rather than the entire ODK engine.

## Latest data and revision history

`responses` and `features` hold one current row per stable record ID. `revisions` preserves every successfully uploaded response/feature version with deterministic history IDs, so retries do not duplicate history. Edits made several times offline upload only their latest version; skipped versions need not exist on the server. Questionnaire `form_version` is independent of `response_revision`.

Readable metadata and `answer:<question-name>` columns support analysis; full authoritative JSON occupies `json_1` through `json_4`. Concatenate these four cells before parsing. Formula-like strings are written as text. The existing legacy answer columns are retained. Historical rows from the old backend are preserved when upgraded; there is no way to recover edits the old backend previously discarded.

Lower revisions or different contents claiming the same revision return a conflict. Both collections are checked before latest rows are written. Google Sheets is not a transactional database; a service failure during writes can partially complete a batch, so retry it. Stable IDs and history IDs make retries safe. Conflicted uploads stay on the phone; coordinate corrections with the manager. This backend does not merge competing edits or download other phones' records.

Photos are deduplicated by content ID, stored in Drive, and linked from `photos`. New files use folder permissions; this script does not retroactively remove public permissions from old photos. Existing photo links/tabs are retained.

## Map and charts

Reload the spreadsheet → **MapBanai → Map workspace / Charts workspace**. These manager dialogs require an authenticated manager and do not expose the private API key. The deployed /exec endpoint serves app sync and health, not a public dashboard.

Map: collection/project/form/collector filters, spatial answers and GIS geometry, six background choices including No background, twelve designs/custom colors, labels and separate **Download Map** with portrait/landscape, aspect ratios and pixel sizes. Download PNG/JPEG. Image size is capped at 4096 per side and 8.4 megapixels; 3840×2160 is supported. Background tiles need internet and may be unavailable.

Charts: eight chart types, count/sum/average/min/max, renamed category labels and custom colors, five designs, numeric scatter plots, PNG/JPEG/SVG and exact landscape/portrait/square export presets including 4K. At most 300 categories are shown. Plotly loads over HTTPS; charts need connectivity.

Workspaces show up to 25,000 current records per request and report truncation. Their displays use latest records, not every history version. Large deployments should use a dedicated backend. A single JSON record is limited to 160,000 characters. API keys grant access to a project; distribute only within the field team.

## Troubleshooting

- Cannot find URL: Deploy → Manage deployments → Web app URL. Cannot find key: reload spreadsheet → MapBanai → Connection and setup guide, or Script properties.
- Questionnaire check fails: verify exact sheet/header names, project UUID, key and deployed version. Store XLSForm expressions as text rather than Google formulas.
- Edited response waiting: deploy this revision-aware Code.gs. The new app refuses an old backend acknowledgement for edits.
- Invalid JSON/405: use /exec and deploy a new version with doPost.
- Setup permissions: run setup as the workbook manager; check workbook/folder IDs and Apps Script Executions privately.
- Empty map: some responses contain no valid spatial answers. Charts can still show those answers.

Validated with mocked Google services and browser fixtures; no live Google account/deployment or Android device was available. Test one complete import/collect/edit/sync cycle before field rollout.
