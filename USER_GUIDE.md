# MapBanai User Guide

**Offline-first field data collection GIS for Android.**
This guide explains everyday use of MapBanai. For developer/build notes see
`README.md` and `CHANGELOG.md`.

---

## 1. Installing

1. Download `app-release.apk` from the latest
   [GitHub Release](https://github.com/anisur-bayazid25/MapBanai/releases/latest)
   or use **Settings → Check for updates** in the app.
2. Open the APK and allow "install from this source" if Android asks.
3. On first launch you are asked for your **name** — it is stamped on every
   survey response, GPS log and export.

No account, no registration, no internet needed for data collection.

## 2. The Home screen

| Element | What it does |
|---|---|
| Logo + tagline | Large MapBanai logo, top-centre |
| Project selector | Tap to pick the project you are collecting data for |
| **Survey / GIS / GPS / Study Area** | The four collection modes, shown as a 2×2 grid of square tiles |
| **GPS CSV Viewer · Cloud Sync · WebMap** | Utility row under the mode tiles |
| Collected data | Survey-response and GIS-feature counts of the selected project |
| Project settings · History · Export | Project management, past records, and file export |
| ☰ (top-right) | **My name · My responses · Help & manager setup · Settings** |

Everything works offline; tiles open instantly and data stays on the device.

## 3. Projects

- **Home → Project settings → New project**: name + description.
- The selected project appears in the selector at the top of Home.
- Each project keeps its own survey forms, fields, GIS features and
  cloud-sync configuration.
- Archive/restore or delete projects from **Project settings**; deleting
  removes all its collected data (confirm first!).

## 4. Survey Mode

1. Open a project → **Survey**.
2. Import an **XLSForm (.xlsx)** built with ODK/Kobo conventions, or build a
   form with the built-in builder.
   - Multi-language forms (`label::English (en)`, `label::Bangla (bn)`, …)
     let you pick the label language while filling the form.
   - **If you imported a form before v2.4.3 and its skip logic misbehaves,
     delete it and import the .xlsx again** — old imports predate group
     skip-logic support and cannot be repaired in place.
3. Fill the form: conditional questions appear automatically, and whole
   modules hide/show by group skip logic (e.g. an incomplete interview
   skips the remaining modules). Calculations update live — including ODK
   date functions (`today()`, `now()`, `format-date()`), one-time stamps
   (`once()`), totals (`sum()`, `coalesce()`), pattern checks (`regex()`),
   text builders (`concat()`, `join()`), branching (`if()`), select and
   math helpers. Labels containing `${question}` placeholders update live
   with current answers, and colored/styled labels (red warnings, module
   headers) render as in ODK Collect. Photos are captured and geotagged,
   GPS points include accuracy.

   > **Note:** repeat blocks (`begin_repeat`) currently render a single
   > instance — household rosters and similar loops show one entry. Full
   > repeat iteration is planned.
4. Use **Save as draft** to park an unfinished form — resume any time from
   **History → Drafts**.

## 5. GIS Mode

- Draw **points, lines and polygons** directly on the map with your project's
  attribute fields.
- Recording continues in the background with a foreground notification while
  you draw lines/polygons (survives screen-off).
- Drag draft points to adjust before finishing; tap saved features to view,
  edit or delete them.
- Choose basemaps from the app bar (OSM, CartoDB Light/Dark, Esri imagery).

## 6. GPS Mode

- **Record Track**: creates a CSV log; recording continues in the background
  (red banner on Home shows it is active). Press again to stop.
- **Save Point**: capture one precise fix with an optional note.
- Live readouts: latitude/longitude (7 dp), UTC + Dhaka time, accuracy,
  elevation (relative to first fix), speed, satellites in use/view.
- **Compass**: collapsible card — tap to open a full compass rose with
  N/E/S/W marked, degree ticks and a smooth-rotating dial. The red needle
  stays fixed pointing up (the direction the phone faces) while the dial
  turns underneath, like standard phone compasses. The heading is shown as
  **degrees from North** plus cardinal direction (e.g., *135° SE*).
- Logs can be viewed as CSV, shared, renamed, deleted, or projected onto the
  WebMap.

## 7. Study Area Mode

- The map header keeps the visible feature count, category styling and three-state verification filter compact.
- Point details show only ID, layer, name and location. **Unchanged** marks Verification Complete; **Location changed** lets you place the point on the map and save or cancel; **Location removed** deletes it; **Edit / status** lets you edit attributes and choose Pending verification, Verification Complete or Needs review.
- Pending points are circles with a red outline, Verification Complete points are squares with a green outline, and Needs review points are triangles with a yellow outline. The shape shows verification state while the fill colour can still represent a layer or category.
- **Road directions** draws the shortest route through a project layer marked Road network and reports its distance in metres below 1 km or kilometres at/above 1 km. This is a map route, not turn-by-turn navigation.
- Add or classify layers under **Home → Project settings → Project files and map layers**. Supported sources are shapefile/ZIP, CSV, Excel, GeoJSON and GeoPackage in WGS84 (EPSG:4326). Mark a line layer as **Road network** for directions.
- Imported non-road files appear in the **Study layer** dropdown and open as verifiable map features. The selected study layer is drawn once; road networks remain available as route overlays. Baseline imports are not survey responses and do not enter the sync queue until verified or edited.
- For a loose shapefile, select its SHP. Matching DBF, SHX, PRJ and CPG files are discovered in the same accessible folder, ignoring filename case. Android may provide only a cached SHP: select the companion files together, choose their folder when prompted, or use a ZIP. The Android folder choice grants access through the document provider and can be remembered for later imports from that folder. Geometry-only import is an explicit choice when DBF attributes are unavailable.
- **⋮ → Assign previous unassigned sites** previews stored map sites without project ownership. Review IDs, source and date when recorded, then select what to assign or delete. These are not a count of survey interviews.
- Latitude and Longitude fields in Edit are now fully visible. Coordinates and source metadata remain available in the edit workflow; the point summary stays focused on the four identity fields.

## 8. History

**Home → History** lists everything you have collected:

- **Drafts** at the top (orange) — tap *Resume* to continue, or delete.
- Saved sessions grouped by **project (folder)** and then by **date**.
- Every group header is **collapsible** — tap a project or date header to
  fold/unfold that section. Headers show how many items they contain.
- The app-bar photo icon opens the geotagged photo gallery.
- The **Clean up history** icon opens project/layer/day/type/sync-status filters, with optional drafts. Review exact record and pending-sync counts before deleting. Choose **Also remove linked Study Area points** to remove their map state too; related visits are included in the confirmation.
- **Study Area → ⋮ → Clear all sites** offers **Also clear survey history and sync queue**, selected by default. It affects the selected project and study layer. For old imports whose map points have already been cleared, use the History cleanup filters to remove the leftover records.
- History-only deletion keeps map points but prevents unchanged snapshots from recreating deleted queue records. A later saved point edit creates a new pending record. Cloud copies already uploaded are not deleted by local cleanup.

## 9. Cloud Sync

1. Select a project, then set up the sync URL + API key in
   **project settings → Cloud Sync** (Google Sheets Apps Script backend).
2. From Home, tap the **Cloud Sync** tile:
   - Not configured yet? It opens the setup screen.
   - Configured? It uploads unsynced responses, features and photos, showing
     progress ("Syncing photos 3/9…") and a final summary.
3. The tile subtitle shows when the project last synced.

## 10. WebMap

- **Home → WebMap** generates a self-contained HTML map of the selected
  project's data (works offline; map tiles need internet once).
- Filters panel (collapsible) lets you search attributes, filter by form,
  surveyor and date range.
- Switch basemaps with the **layers button** (top-right of the map).
- GPS logs can be projected onto a track-only WebMap from GPS Mode or the
  GPS CSV Viewer.

## 11. Sharing projects between phones

- Sender: project ⋮ menu → **Export Project** → save `.mbproj` file or share;
  small projects also fit in a **QR code**.
- Receiver: open the received `.mbproj` ("Open with MapBanai"), or import via
  **camera QR scan**, **QR from gallery image**, or paste the code text.
- Choose whether to include collected responses and their photos. Forms, original imported XLSForms, project settings, source map files/layers and cloud sync manager scripts are included in either project-package option. Packages with responses also retain current Study Area verification state and drafts.
- The Apps Script URL and API key are included by default for trusted team handoff. Uncheck **Include sync connection** before sharing with anyone who should not receive the key.
- Name conflicts offer *Import as new copy* or *Replace*; nothing is
  overwritten silently.

## 12. Exporting data

**Home → Export** (per project):

- **Project with responses (.mbproj)** includes project setup, collected records/photos and current Study Area state.
- **Project without responses (.mbproj)** includes setup, original GIS files, forms and settings, without collected records or verification edits.
- **Responses only (JSON)** shares saved response/map-history records without project setup, GIS source layers, API key or web URL.

- Survey responses: **CSV** (Kobo/ODK-style columns) or JSON.
- GIS features: **CSV / GeoJSON / KML / GeoPackage**.
- Files land in the device's export folder and can be shared to WhatsApp,
  email, Drive, etc. via the share sheet.

## 13. Settings

Top-right ☰ on Home:

- **User** — your name (attached to everything you collect).
- **Language** — English or বাংলা (Bangla), applied immediately.
- **Theme** — System / Light / Dark.
- **About** — version, creator, update check.
- **Reset data** — danger zone; type your name to confirm.

## 14. Updates

MapBanai checks GitHub releases on launch. When a new version exists, a
banner offers **Download & Install**. First update asks for the Android
"install unknown apps" permission — that is standard for self-updates.

## 15. Troubleshooting

| Problem | Fix |
|---|---|
| No GPS fix | Go outside, ensure location permission is "While using" or "Always"; check the status card in GPS Mode |
| Compass shows "No heading" | Heading needs movement or device sensors; walk a few steps |
| Import says no sites found | Check the file has latitude/longitude columns (any common alias works) |
| Backup restore prompt did not appear | Restore only triggers on a fresh install with a backup present; data also survives via Cloud Sync |
| Uninstall warning | All local data lives on-device — export or sync important projects first |

## 16. Support

- GitHub issues: https://github.com/anisur-bayazid25/MapBanai
- Email: anisur.rahman.bayazid@gmail.com

## v2.6.3: enumerator essentials

1. Home → three-bar menu → **My name**. Your name accompanies new records; saved edits preserve the original collector and record the editor separately.
2. Import the manager's project package and select its project. Survey Mode → **Sync questionnaire** → Check Google Sheet → review → Apply before starting work.
3. Collect offline in Survey, GIS or Study Area; **Visit a study site** supports linked repeated visits.
4. Three-bar menu → **My responses** → open a saved record → edit answers. The response revision advances and the record waits to upload again.
5. Home → **Cloud Sync** when connected. Questionnaire version and response revision are different. Deploy the updated manager backend to sync edits; failures/conflicts stay queued.

Help remains in the three-bar menu, rather than adding another Home card. The [manager guide](server/manager/README.md) explains one workbook, /exec URL, API key retrieval and copying all three script files. Managers can use the Sheet menu for the redesigned map and chart workspaces.

WebMap → **Layers** imports WGS84 reference shapefiles/GeoJSON, with individual visibility, color and opacity. **Download Map** is separate from Explore: choose twelve designs/custom colors, typography, captions, portrait/landscape, aspect ratio and exact pixels; save/share PNG or JPEG. 3840×2160 desktop wallpapers are supported. Limits: 4096 pixels per side and 8.4 megapixels; larger requests show an error. Use No background for vector-only maps. Online backgrounds need internet; keep source credits.

## v2.6.4: map design and simpler setup

Define collection questions using the selected survey form; Project Settings no longer offers a second Data collection fields editor. Existing legacy fields remain stored. Set the enumerator name only through Home → three-bar menu → My name. GIS and Study Area use the same six online/no-background choices plus permitted offline packages.

Download Map now shows only mapped categories in its legend. Rename them (for example Salinity stations, Roads, Buildings), choose point icons/line patterns/area outlines, or upload PNG/self-contained SVG icons up to 512 KB and 2048 pixels per side. Export text, icons and north arrow scale with image resolution; Standard/Large/Extra large controls adjust readability. Title, subtitle and legend fonts are independent, with four bundled offline fonts. Images omit record/layer counts and no-basemap notices; included basemaps retain attribution.

The GPS compass uses orientation sensors relative to magnetic north where available. Keep the phone reasonably flat, calibrate away from metal when prompted, and distinguish its direction from the GPS travel-bearing fallback. Android GNSS altitude references the WGS84 ellipsoid; it is not sea-level elevation or floor height. Indoor readings can be unreliable, including negative values. Use an outdoor reference for relative change; no guessed correction or floor-height offset is applied.

For each new project, create a fresh Google spreadsheet and open Extensions → Apps Script. Paste Code.gs, Map.html and Charts.html from Help. Replace only the project ID, leaving the other four placeholders unchanged. Run setupMapBanai to create the private key, photo folder and data tabs. Reload the sheet → MapBanai → Connection and setup guide to get your key. Deploy → New deployment → Web app → Execute as: Me → Who has access: Anyone. Save the complete /exec URL and key in Project Details → Cloud Sync, then Test Connection. See the [full manager setup](server/manager/README.md).

## v2.6.5: importing and reviewing study maps

Use the top Import button in Study Area Mode. The picker permits multiple files; MapBanai validates GeoJSON, WGS84 GeoPackage, SHP/ZIP, CSV, XLSX and KML/KMZ. Loose shapefiles discover companions in accessible folders, or you can select the companion files together and choose a folder when prompted. A ZIP may contain multiple shapefiles. Use WGS84 (EPSG:4326); projected coordinates need reprojection before import. Project spatial imports support up to 64 MB of source/unpacked files, 50,000 features and 2 million coordinates. GeoPackage imports currently use the first feature table yielding sites.

Opening a spatial file from a file manager offers a selected project, a new project, or View only. View-only maps use temporary storage and do not add projects/sites or permit editing. Availability in Android’s Open with list depends on the file manager’s MIME type; the in-app Import picker is the fallback. A standalone SHP without its DBF prompts you to use a ZIP.

The project selector is left-aligned. Open Study layer and choose Add new Layer to create another map. Tap the plus button to open the selected survey form at your current GPS position. It requires a location captured within 30 seconds; GPS accuracy is recorded. Long-press map placement remains available.

All features start with the same color. Tap Categories & colors, choose a column (e.g. layer), change category colors, show/hide categories and adjust point size. Tap Apply. These choices persist for this project/study layer. Verification status remains a separate filter; styling does not change collected attributes or verification status. The map counter shows visible / total features. Categories affect the on-screen study map; data exports retain the full records.

Imports refresh the map immediately after saving. A sync-queue warning means the features are saved; retry Cloud Sync from Home instead of re-importing.

Study Area → Edit feature: questionnaires are mandatory for newly created features and Updated/New feature statuses. For Pending verification, Completed (legacy), Verified unchanged, Not found and Needs review, saving skips the questionnaire unless Fill questionnaire (optional) is checked. Existing answers are preserved when skipped. Categories & colors offers explicit Verification status coloring as well as attribute columns; the default remains a single color.

### GPS accuracy review

Open Home → Field quality checks. Select **GPS accuracy review limit**; only saved photo/location readings strictly above this limit appear. Nearby-feature pairs, missing answers and other findings are no longer listed here. Missing or unknown accuracy is not treated as exceeding the limit.

Choose **View record** to inspect the original, or **Accept accuracy** to keep it and remove this reading from the review list. Acceptance and the chosen review limit persist per project on this device. The photo/data and sync state are unchanged. Use **Undo** in the confirmation message to restore an accepted finding. A changed GPS reading can appear again. These review decisions are local and are not uploaded to the manager sheet. GPS accuracy remains advisory and does not block photo capture.

Poster exports reserve over 80% of the image for the map, with compact titles and categorical legends. In Download Map, use Fit visible data to fit filtered features, or Current map view to keep the current framing. Coordinates are omitted below the title. Use Explore → Colours & categories for text/numeric columns, per-value colours/visibility, or graduated numeric colours. In Google Sheets, map and charts support Fullscreen (expanded-dialog fallback), and manager maps can add temporary GeoJSON/shapefile ZIP overlays.

Cloud sync sends at most 20 records per batch and preserves acknowledged progress. Retry resumes remaining records. New photo uploads populate previews and Drive links in photos; refresh older previews through the spreadsheet MapBanai menu. Update all matching manager files and redeploy Code.gs when updating the backend.
