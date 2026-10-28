# MapBanai v2.8.0 (build 37)

- GIS has a separate hand-drawing toggle beside the GPS indicator. Place points, lines and polygons by tapping the map, with Undo, geometry checks, attribute forms, manual drafts and resume. Walking capture remains available; drawing starts only after choosing a tool.
- Save an entire captured study layer through GIS → Layer options → Save as project layer. The original records remain available for existing exports. Project Settings assigns saved layers to Field Verification, Recurring Collection and/or Study Area Visits, just like imported GIS files.
- Project Settings → Project layers → Create layer from responses selects a questionnaire, an optional question and one or more answer values. Multi-select answers match any selected choice. Choose one or more GPS questions; each valid selected GPS answer becomes a separate point with source response/question metadata. Review the matching count before creating a layer.
- GIS uses a full map with a compact project/layer selector, scrollable panels, geometry filters and an opacity slider. GPS details open on demand. Reference boundaries remain visible behind other study layers. Layout checks cover narrow phones, landscape and large text.
- Saved project layers are snapshots. Later responses do not automatically change them. For repeated observations, keep the same site layer and create a new recurring round; old measurements remain intact.
- Added English/Bangla controls and a universal project workflow guide. No device camera/GNSS field test is claimed by the automated checks.

Install app-release.apk over the existing installation to retain local data.

# MapBanai v2.7.2 (build 36)

- Fixed dark-mode contrast, clipped field captions, overlapping map controls and invisible Needs review markers. Visit and verification status actions have readable labels.
- Study Area panels now open at the height of their content and remain draggable/scrollable. All three workflows have a + action to add a point at a fresh GPS location; line/polygon creation remains in GIS Mode. Fieldworker names come from the main Settings.
- Bulk site/history cleanup shows affected counts, requires the project name and acknowledgement of unsynced-record loss, and keeps survey history by default when clearing a layer.
- GIS Mode centers once on the first fresh device GPS fix. Folded-map basemap icons are consistent; Updated map uses a distinct export icon. Removed duplicate WebMap/CSV actions and project QR generation/import/dependencies; use .mbproj files to transfer projects.
- Feature deletions now queue durable, revisioned deletion records for Google Sheets, with deletion time and fieldworker. Active maps hide deleted sites while Sheets and revision history retain audit records. Full project packages preserve deletion events.
- Guided-visit photos are optional by default; explicit project-manager photo requirements still apply.

**Deletion sync requires the updated manager Code.gs deployment.** Replace the script using the supplied manager workspace and update the existing Web app deployment to a new version, preserving its project ID, connection settings and API key. Until then, deletion records stay safely pending on the phone. Publishing this app does not change your Google deployment.


- Fixed first-launch database locking that prevented project imports and Settings from loading. Screens now share one background SQL executor with independent, safely closed clients.
- Fixed the name prompt's controller lifetime while its closing animation runs. Settings reports recoverable storage errors and offers Retry.
- Fixed overlapping empty-study-area banners, removed the duplicate in-app atlas download action, and corrected dark-theme contrast on project cards.
- Corrected the Settings Save action and preserved pending language/theme choices while editing. The launcher reuses the existing logo M rather than a new symbol.
- Added phone-only live preview and a lightweight scrcpy mirroring helper; emulator use has been removed.
- Study Area opens Field Verification, Recurring Collection and Study Area Visits. Project layers and questionnaires are assigned per workflow; Collection rounds preserve separate salinity/heat measurements and progress.
- Visit sites use readable names, searchable selection, resumable drafts and green/red/yellow status markers. Create recurring point layers from selected numeric survey measurements without altering original responses.
- Nearest unvisited sites sort by straight-line GPS distance. Without a recent location they sort by name; refresh GPS from the list. Completion and review status is specific to the selected collection round.
- Project Settings > Workflow requirements configures required questionnaires and geotagged photos separately for each workflow. Requirements are checked before completion and carried in project packages; share an updated package after changing them. Questionnaire photos can satisfy the photo requirement.
- Compact Google Maps shortcuts open the selected site or current map area externally. Draggable site sheets, shared map controls, a refreshed theme and incremental status updates make the map interface easier to use.
- Responsive home/internal layouts, broader Bangla UI translations, and an adaptive launcher icon using the original orange M from the MapBanai logo, a matching monochrome icon and Android splash screen.
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
