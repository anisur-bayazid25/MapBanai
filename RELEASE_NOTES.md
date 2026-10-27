# MapBanai v2.7.0 (build 34)

- Study Area opens Field Verification, Recurring Collection and Study Area Visits. Project layers and questionnaires are assigned per workflow; Collection rounds preserve separate salinity/heat measurements and progress.
- Visit sites use readable names, searchable selection, resumable drafts and green/red/yellow status markers. Create recurring point layers from selected numeric survey measurements without altering original responses.
- Nearest unvisited sites sort by straight-line GPS distance. Without a recent location they sort by name; refresh GPS from the list. Completion and review status is specific to the selected collection round.
- Project Settings > Workflow requirements configures required questionnaires and geotagged photos separately for each workflow. Requirements are checked before completion and carried in project packages; share an updated package after changing them. Questionnaire photos can satisfy the photo requirement.
- Compact Google Maps shortcuts open the selected site or current map area externally. Draggable site sheets, shared map controls, a refreshed theme and incremental status updates make the map interface easier to use.
- Responsive home/internal layouts, broader Bangla UI translations, and a new adaptive map-pin launcher icon, monochrome icon and matching Android splash screen.
- In-app update downloads stream with backpressure, check resumed ranges/source URLs and provide a browser fallback. Mobile-carrier throughput still needs a real-network comparison; APK size and carrier/CDN routing can also affect download time.

Install app-release.apk over the existing app to retain data. This release includes the updated manager workspace as downloadable files; deploying the manager server remains a separate manager action.

# MapBanai v2.6.10

- Clean survey history by project, layer, day, record type or sync status, with previews and optional linked map-point deletion. Cleared records are removed from the sync queue and stay removed until a point is edited again.
- Project Settings imports now appear as selectable Study Area layers. Adding a baseline shapefile no longer adds every imported point to survey history or the sync queue.
- Both screens discover shapefile companions in accessible folders, accept multiple selected files, and offer a companion-folder picker. Missing DBF attributes have a clear geometry-only choice.
- Faster map interaction: preserve the native map while selecting points and receiving GPS fixes, avoid full redraws when closing details, remove duplicate source drawing and process large map files in a worker.
- Home export supports full .mbproj packages with responses/photos, project setup without responses, and responses-only JSON. Project packages include GIS source files, forms, settings and the sync URL/API key by default.
- Unassigned map sites can be reviewed and selected before assignment or deletion. Project settings distinguish survey counts from map-history records.
- Repaired the Windows build helper's Java socket/temp path.

Install app-release.apk over the existing MapBanai installation to preserve local data. Bulk deletion removes local history and pending uploads; records already uploaded to the cloud remain there.

## v2.6.9

- Study Area Mode now opens the project layer manager directly, with project settings shared between imports made in either screen.
- Imports from Study Area Mode preserve the source file as a project layer. Imported files can be removed with all their points, local revision history and pending sync records.
- Batched map drawing keeps large point files responsive, and selecting points no longer triggers a full marker redraw.

Install app-release.apk over the existing MapBanai installation to preserve local data.
# MapBanai v2.6.8

- Fixed the Study Area toolbar card wrapping its feature count vertically on phone screens.
- Fixed verification saves for imported sites without a local project ID, and refreshes feature details after a concurrent edit conflict.

Install app-release.apk over the existing MapBanai installation to preserve local data.

## v2.6.7

- Cleaner Study Area review cards show only feature ID, layer, name and location. Quick actions mark a feature unchanged, move it to a corrected location, remove it, or edit its fields/status.
- Verification now uses Pending verification, Verification Complete and Needs review. Circle, square and triangle shapes distinguish status while category colours remain available.
- Added project road layers and shortest-path routes from the current GPS location, with distances shown in metres below 1 km and kilometres above it.
- Project settings now import study-area, facility and road source files in shapefile/ZIP, CSV, Excel, GeoJSON and GeoPackage formats. Original source files, XLSForms, project settings and cloud sync manager scripts travel in the project package.
- Fixed the clipped Latitude/Longitude labels in the Study Area edit form.

Install app-release.apk over the existing MapBanai installation to preserve local data. Project packages include the sync URL and API key by default for trusted team sharing; clear the option before exporting to other recipients.

## v2.6.6

- Poster map fills over 80% of the image, with compact titles/legends and a fit-data extent option. Shared by Android WebMap and Google Sheets atlas.
- WebMap categorical colours, per-value visibility and editable symbols support text fields such as imported layer categories. Added browser GeoJSON/shapefile ZIP overlays and map/chart fullscreen controls.
- Manager atlas startup repaired; clear loading and initialization errors replace blank dropdowns. Study status data is available in the manager map.
- Sync sends at most 20 records per batch, retries busy-server responses and preserves acknowledged progress. Server timeouts no longer appear as internet loss.
- Photos sheet shows readable metadata, private embedded thumbnails and clickable Drive links. Spreadsheet menu can refresh existing photo previews.
- Field quality now reviews only recorded GPS/photo accuracy above the selected limit. Accept accuracy persists per project on the device, with Undo and View record.
- Existing in-app Help explains the updated workflows and includes the complete matching manager scripts.

Install app-release.apk over the existing MapBanai installation to preserve local data. For Google Sheets, replace Code.gs, Map.html and Charts.html with the matching files, keeping the project ID/configuration. Save and deploy a new version for the sync API; reload the spreadsheet and reopen its workspace. Run MapBanai → Refresh photo previews for older uploaded photos.

Browser overlay uploads are temporary and do not change sheet records. Browser GeoPackage import is not included; use the Android importer or convert to GeoJSON. Accuracy acceptance is local and is not uploaded to the manager workbook. Basemap and manager library loading require internet.

Validation: 402 Flutter tests pass; backend contracts and browser map/chart/export checks pass. APK signature and version verified. Full analysis has no errors, with existing test warnings and style notices.
