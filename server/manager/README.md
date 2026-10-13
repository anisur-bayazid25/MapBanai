# MapBanai manager workspace — v2.6.6

Use one Google workbook, one Apps Script deployment and one private API key for each project. Questions and answers live in separate tabs. This folder contains the complete Code.gs, Map.html and Charts.html; the same files are copyable offline in app Help.

## Set up a new project

1. Create a new project in MapBanai. Open **Project Details or Help** and copy its project ID (UUID).
2. Create a fresh Google spreadsheet for this project. Import your XLSForm or prepare **survey**, **choices**, and **settings** tabs with the normal XLSForm headers.
3. From that spreadsheet, open **Extensions → Apps Script**. Paste the supplied **Code.gs**. Add HTML files named **Map** and **Charts**, and paste their matching HTML.
4. At the top of Code.gs, replace **only** `PASTE_PROJECT_ID_FROM_MAPBANAI` with your project ID, keeping the quotation marks. Leave the other four placeholders unchanged:
   ```javascript
   projectId: 'your-new-project-id',
   ```
   The spreadsheet from which you opened Apps Script is the “bound workbook.” You do not need to copy its spreadsheet ID.
5. Save. Select **setupMapBanai** in the function dropdown and click **Run**. Authorize Sheets and Drive access with your manager account. It uses this spreadsheet for questions and collected data, generates a private API key, creates a private photo folder, and creates **responses**, **features**, **photos**, and **revisions** tabs.
6. Reload the spreadsheet → **MapBanai → Connection and setup guide**. Copy the generated API key. You can also find **MAPBANAI_API_KEY** in Apps Script → Project Settings → Script properties. This is a MapBanai password, not a Google Cloud API key.
7. Choose **Deploy → New deployment → Web app**. Set **Execute as: Me** and **Who has access: Anyone**, then **Deploy**. Copy the complete Web app URL ending **/exec**. Do not use the editor URL or /dev. If Anyone is unavailable, ask your Google Workspace administrator.
8. In MapBanai **Project Details → Cloud Sync**, paste the URL and key, tap **Save**, then **Test Connection**. It checks project ID, key and data-sheet access without uploading records.
9. Open **Survey Mode → Sync questionnaire → Check Google Sheet → review → Apply**. Save a test response, sync from Home, edit it through **three-bar menu → My responses** and sync again. Check the latest row has revision 2 and both uploaded versions appear in **revisions**.
10. Export/share the project with **Include sync connection** for trusted enumerators. They import it and set **My name** in the Home three-bar menu. Use a fresh spreadsheet and script for each new project.

Google documents [web-app deployment](https://developers.google.com/apps-script/guides/web), [Script Properties](https://developers.google.com/apps-script/guides/properties), and [HTML client/server communication](https://developers.google.com/apps-script/guides/html/communication).

## Update questions

Edit cells in survey/choices/settings. No script redeployment is needed for question edits. Enumerators explicitly check/apply changes in Survey Mode. New collections use the latest form; prior records and drafts retain their snapshots. One online XLSForm is served per project. The app supports its documented XLSForm subset, rather than the entire ODK engine.

## Latest data and revision history

`responses` and `features` hold one current row per stable record ID. `revisions` preserves every successfully uploaded response/feature version with deterministic history IDs, so retries do not duplicate history. Edits made several times offline upload only their latest version; skipped versions need not exist on the server. Questionnaire `form_version` is independent of `response_revision`.

Readable metadata and `answer:<question-name>` columns support analysis; full authoritative JSON occupies `json_1` through `json_4`. Concatenate these four cells before parsing. Formula-like strings are written as text.

The app sends records in sequential batches of at most 20, automatically retries busy-server responses, and saves each acknowledged batch. If interrupted, retry Sync to send only the remaining records. A slow server response is reported separately from internet loss.

Lower revisions or different contents claiming the same revision return a conflict. Both collections are checked before latest rows are written. Google Sheets is not a transactional database; a service failure during writes can partially complete a batch, so retry it. Stable IDs and history IDs make retries safe. Conflicted uploads stay on the phone; coordinate corrections with the manager. This backend does not merge competing edits or download other phones' records.

Photos are deduplicated by content ID and stored in Drive. The `photos` tab includes readable `photo_id`, `filename`, `response_id`, `file_id`, `url` and `mime_type` columns, an embedded thumbnail in `photo_preview`, and **Open photo in Drive** in `photo_link`. Match `response_id` to the response or feature the photo belongs to. The full JSON remains available.

New uploads add previews automatically. For already synced photos, reload the spreadsheet and choose **MapBanai → Refresh photo previews**. Each run attempts up to 50 missing previews; repeat for remaining photos. This requires the manager's Drive permissions. Embedded thumbnails also become visible to spreadsheet viewers, so share the spreadsheet with the intended team only; opening the original requires Drive permission. No files are made public. If a thumbnail is unavailable or the image exceeds Sheets' 2 MB insertion limit, the Drive link still works and refresh can retry later.

To enable this change in your deployed project, replace Code.gs with this complete updated file, preserving your project ID/configuration. Save, then **Deploy → Manage deployments → Edit → New version → Deploy**. Reload the spreadsheet for the new menu. The app URL and API key stay the same; no APK update is needed.

## Map and charts

Reload the spreadsheet → **MapBanai → Map workspace / Charts workspace**. Both workspaces have **Fullscreen**; when Google blocks browser fullscreen inside Sheets, this expands the Sheets dialog, with an Exit fullscreen button to restore it. These manager dialogs require an authenticated manager and do not expose the private API key. The deployed /exec endpoint serves app sync and health, not a public dashboard.

Map: categorical styling for text or numeric columns (including imported `layer`), per-value visibility/colours, editable category names and symbols in Download Map, and graduated numeric colours. Geometry type remains the default, with uniform point symbols. Category legends appear in PNG/JPEG exports for visible mapped features. Collection/project/form/collector filters, spatial answers and GIS geometry, six background choices including No background, twelve designs/custom colors, labels and separate **Download Map** with portrait/landscape, aspect ratios and pixel sizes. Download PNG/JPEG with resolution-scaled symbols/text, editable mapped-only legends, independent fonts and PNG/SVG point icons. Image size is capped at 4096 per side and 8.4 megapixels; 3840×2160 is supported. The manager atlas loads pinned Leaflet 1.9.4 over HTTPS to avoid Apps Script rewriting its minified inline library. The Android HTML export still embeds Leaflet for offline use. Background tiles need internet and may be unavailable. Add multiple GeoJSON files or ZIP shapefile bundles as vector overlays; toggle, colour or remove each overlay. Browser shapefile parsing loads a pinned shapefile-js library over HTTPS on first use. GeoPackage import remains available in the Android app; export it as GeoJSON for direct browser overlay upload. Imported browser overlays are temporary for this workspace and its image export; they do not modify the spreadsheet records. Refreshing the collection clears those temporary overlays.

Charts: eight chart types, count/sum/average/min/max, renamed category labels and custom colors, five designs, numeric scatter plots, PNG/JPEG/SVG and exact landscape/portrait/square export presets including 4K. At most 300 categories are shown. Plotly loads over HTTPS; charts need connectivity.

Workspaces show up to 25,000 current records per request and report truncation. Their displays use latest records, not every history version. Large deployments should use a dedicated backend. A single JSON record is limited to 160,000 characters. API keys grant access to a project; distribute only within the field team.

## Troubleshooting

- Cannot find URL: Deploy → Manage deployments → Web app URL. Cannot find key: reload spreadsheet → MapBanai → Connection and setup guide, or Script properties.
- Questionnaire check fails: verify exact sheet/header names, project UUID, key and deployed version. Store XLSForm expressions as text rather than Google formulas.
- Edited response waiting: verify the URL belongs to the script supplied with this project and retry sync.
- Invalid JSON/405: copy the full Web app /exec URL; verify Execute as: Me and access: Anyone.
- Setup permissions: run setup as the workbook manager; check workbook/folder IDs and Apps Script Executions privately.
- Atlas blank or collection selector empty: replace both complete Code.gs and Map.html files from the matching workspace bundle. Reload the spreadsheet and reopen the atlas. The status box now shows connection, payload and map initialization failures; use Refresh to retry. Check Apps Script → Executions if Google takes more than 45 seconds to return.
- Empty map with records loaded: some responses contain no valid spatial answers. Select features or All collections. Charts can still show non-spatial answers.

Validated with mocked Google services and browser fixtures; no live Google account/deployment or Android device was available. Test one complete import/collect/edit/sync cycle before field rollout.

## Study-area field workflow in v2.6.6

Enumerators import a study map from the top toolbar or open a spatial file from Android. GeoJSON and WGS84 GeoPackage are supported; ZIP shapefile companions together for attributes. The plus button opens the questionnaire at a fresh GPS location. Edit feature requires a questionnaire for new/Updated features, while other statuses allow direct saving or an optional questionnaire. Categories & colors lets users explicitly choose a data column or Verification status for styling; the default is one color.
