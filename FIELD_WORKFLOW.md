# MapBanai 2.6.3 field workflow

## One project, three ways to collect

Choose a project, a named study layer and a survey form. The same selected form supplies questions, choices, conditions and required fields in Survey, GIS and Study Area. Survey is the simplest questionnaire route; GIS captures geometry before opening the form; Study Area reviews existing sites before filling the form and recording a revision. GPS diagnostics/tracks work independently.

Each project has its own layers, form selection and sync connection. Create layers such as **Salinity October**, **Salinity December** and **Household baseline** from the Study Area/GIS selector. The project atlas combines layers and lets you filter to one. Collections retain their layer and form snapshot. For repeated measurements, use linked field visits so earlier observations remain separate records; editing a site's attributes changes its current state.

Select the project inside Study Area before importing data or starting a visit. Previous sites that have no project are hidden until you deliberately choose **Assign previous unassigned sites** in the Study Area menu. Assign only after selecting the correct project/layer. Sites already owned by another project are never claimed. Export the selected study layer as GeoJSON to retain geometry, answers and revision history.

## Prepare forms and previous data

Install over the existing app and re-import XLSForms to use parser fixes. Existing forms contain stored parsed JSON; keep collected records and import updated forms under a distinct name/version. Namespace-prefixed Excel XML, styled dates, translated labels, default language, groups, defaults and cross-question constraints are supported. Dates, dateTime and time are editable; geotrace/geoshape answers use the map drawing tools.

Unsupported repeats, cascading choice_filter, parameters, dynamic required/read-only expressions and unsupported media types fail import with an explanation. Automatic start/end/device ID metadata produces a warning. MapBanai does not implement the complete ODK specification.

Import previous WGS84 features in Study Area or Project Settings from GeoJSON, KML (Study Area), shapefile, GeoPackage, CSV or XLSX. Reproject projected datasets before import. SHP companion files are discovered in an accessible folder; Android also supports multiple selection or a companion-folder picker. Project source layers appear in the Study layer selector. Baseline imports do not count as survey responses or enter the sync queue. Review a site using Unchanged, Location changed, Location removed or Edit/status; verification states are Pending verification, Verification Complete and Needs review.

## Complete a linked field visit

1. Select the project and tap Visit a study site.
2. Select a baseline site, review its attributes/location, assign a status and explain changes. Add new sites in Study Area first.
3. Select the project's form and fill it. Known site attributes prefill matching questions. Saved drafts retain their original form definition even after a form update.
4. Take/import a geotagged photo, then finalize. Answers, evidence and the map revision share a permanent visit ID.
5. Resume interrupted visits from Home or History. A failed map update remains saved for retry; conflicting site edits require explicit review before rebasing.

Multipart geometries and collections remain intact through display/export. Editing multipart vertices or polygon holes is not implemented; redrawing a single polygon retains existing holes.

## Photos and GPS accuracy

JPEG EXIF GPS coordinates are mandatory and verified before saving. Camera captures require a valid fresh, non-mock fix (at most 30 seconds old). **GPS accuracy is recorded and displayed when available, but no accuracy threshold blocks photos.** Geometry captured from GPS still uses its own accuracy check; map taps are available.

The external camera returns before MapBanai obtains location. Stay at the capture location until saving finishes; this is not exact shutter-time positioning. If location is unavailable, retain the pending photo and retry. Gallery images preserve valid original GPS tags; otherwise they require the current location, so import untagged images at their original location. PNG images are converted to JPEG.

## Revision history and team exchange

Study Area shows revision history, authors, change notes and linked visits. Export all sites or only changed features. **Use GeoJSON for team exchange:** it retains typed attributes, stable feature/revision IDs, original baseline and revision lineage. Import previews updates and conflicts before applying them. Conflicts offer keep local, use incoming, or preserve as a separate feature; no choice is silently selected. CSV/XLSX are tabular exports and do not carry full revision history. HTML exports bundle feature data, but background tiles require internet.

## Offline basemaps

Open Offline maps and configure a provider-approved HTTPS MapLibre v8 style URL, name and attribution. Choose bounds, zoom levels and storage budget. The downloader limits packages to 6,000 tiles and 10–500 MB, with a 100 MB storage reserve. Built-in OSM/CARTO/Esri sources are excluded from bulk downloading. Supply your own server or a provider that permits offline use; a ready-to-download provider is not bundled.

Keep the app open while downloading. Cancel/delete incomplete packages and retry if interrupted. Completed packages appear in the Basemap selector across GIS, Study Area and geometry capture. Their attribution remains displayed. MapLibre's downloaded cache is outside full backups and must be downloaded again after reinstalling.

## Field quality and data protection

The project Field quality screen checks visible required answers, constraints, missing/untagged evidence, recorded GPS accuracy/age and nearby feature candidates. Accuracy and possible duplicates are advisory, with links to inspect the affected record. Location age cannot be inferred where no timestamp was recorded.

Full backups include the database, photos/sidecars, GPS logs and Study Area history, with checksums and SQLite integrity validation. Restore remaps attachment paths, including revision histories. Copy important backups outside app-private storage before uninstalling. Edits requeue sync; remote endpoints must support updates by stable ID. No live endpoint was available for server integration testing.

## Field validation and building

On the target phone, test date editing, geotagged capture with low accuracy, draft recovery after restart, revisiting and adding sites, team merge conflicts, GeoJSON export, backup restoration and a permitted offline map in airplane mode. No Android device/emulator was connected during development; native camera/GNSS and real download behavior still need this check.

Run `powershell -File tool/build_android.ps1 -Mode release` on this workstation. It applies a process-local Windows Java socket-path workaround. Release version is 2.6.0+23, minimum Android API 23. Existing Kotlin metadata diagnostics are emitted during successful Android builds; review them when upgrading the toolchain.

A useful next addition is a user-selected portable backup destination with restore preview and attachment counts.


## Project atlas and sync

Open WebMap for the current project; its folder button switches projects. Filter by study layer, form, collector, source, status, dates, search or numeric answer. The attribute table contains the collected answers. GeoJSON and CSV export the filtered results; Android opens the share sheet. HTML sharing produces a portable atlas with embedded data and Leaflet. Online street/imagery tiles require internet and provider availability.

Sync is selected-project only. Study-area edits enter the same outbox as collections, with stable site IDs, layer IDs, typed answers and revision metadata. The receiving script must upsert stable IDs and retain these fields. History cleanup removes local queue entries and prevents unchanged map snapshots from recreating them; already uploaded cloud records remain there. URLs and API keys survive partial saves, successful sync and replacement of the same project definition, and are included by default in project packages through the Include sync connection option.

## GNSS altitude and responsive quality checks

GPS now shows the phone's **GNSS altitude**, its vertical accuracy and the WGS84 ellipsoid reference. It no longer silently subtracts the first fix and calls the result elevation. A relative-height reference is available only when explicitly set. Indoor phone GNSS cannot reliably measure your building floor height; unavailable altitude is shown as unavailable.

Field Quality validates each form in a separate worker with a three-second deadline and displays record progress. A timeout becomes a review issue; it does not silently pass the form. Dense duplicate scans are bounded and report when their limit is reached. Photo accuracy warnings remain advisory.

## Design references and next priorities

The shared questionnaire route follows [ODK Collect's offline form workflow](https://docs.getodk.org/collect-intro/). Geometry followed by typed attributes follows [QField digitizing](https://docs.qfield.org/how-to/data-collection/digitize/). Project-owned forms, layers and synchronization follow [Mergin Maps' project sync model](https://merginmaps.com/docs/manage/synchronisation/). These informed MapBanai's **one project, one form, three entry routes** workflow; this is a product direction, not a claim that no other app supports it.

Next priorities: a site timeline comparing repeated salinity visits; collector assignments and coverage summaries; server-side conflict review and deletion acknowledgements; external GNSS support for projects needing precise heights. Linked observations, rather than overwriting a site each round, follow the [one-to-many observation model](https://merginmaps.com/docs/layer/one-to-n-relations/). These future priorities are not bundled as unfinished features in this release.


## New local improvements

Map studio provides PNG/JPEG, themed posters, titles and labels. See [design references](GEOSPATIAL_APP_IDEAS.md). Project sharing can optionally include the sync connection. [Google Sheets questionnaire setup](ONLINE_QUESTIONNAIRES.md) explains how to deploy the handler and update XLSForms without overwriting previous observations. These features are included in the published releases.

## v2.6.2 - Repeated observations and templates

Guided visits remain separate observations, linked through stable feature UUIDs. Study Area and the visit selector expose timelines, numeric comparisons and complete CSV export. Imported visit revisions and local saved interviews are deduplicated by visit UUID. Keep measurement units and question names consistent across form versions.

Reusable project/layer templates preserve definitions, omit data and credentials, and create fresh project/layer identities. Templates are stored in database settings for backup preservation.

This release also includes online XLSForm updates, optional connection sharing, styled PNG/JPEG export and offline Help with the complete Google backend. The parent/child pattern follows Mergin Maps one-to-many relations: https://merginmaps.com/docs/layer/one-to-n-relations/ (no service dependency added).

## v2.6.3: enumerator flow and manager workspace

Set My name in the Home three-bar menu, import/select a project, sync its questionnaire from Survey Mode, collect offline, correct records through My responses, then use Home Cloud Sync. Each saved correction keeps its UUID, increments response_revision and records edited_by/edited_at. Original user_name remains the collector. The revision-aware backend updates current rows and stores uploaded versions in revisions; competing versions remain queued for manager review. This does not download other devices' records or implement automatic conflict merging.

[Manager setup](server/manager/README.md) includes all three Apps Script files and explains preserving your key/URL while redeploying. Twelve map designs and reference vector layers support field reports and presentations. Project Settings source layers are selectable in Study Area; road networks stay available for directions. Home Export offers project packages with or without responses/photos, and response-only files without project configuration.
