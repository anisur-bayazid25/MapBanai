# MapBanai 2.6 field workflow

## Prepare forms and previous data

Install over the existing app and re-import XLSForms to use parser fixes. Existing forms contain stored parsed JSON; keep collected records and import updated forms under a distinct name/version. Namespace-prefixed Excel XML, styled dates, translated labels, default language, groups, defaults and cross-question constraints are supported. Dates, dateTime and time are editable; geotrace/geoshape answers use the map drawing tools.

Unsupported repeats, cascading choice_filter, parameters, dynamic required/read-only expressions and unsupported media types fail import with an explanation. Automatic start/end/device ID metadata produces a warning. MapBanai does not implement the complete ODK specification.

Import previous WGS84 features in Study Area from GeoJSON, KML, shapefile, GeoPackage, CSV or XLSX. Reproject projected datasets before import. Include shapefile DBF/PRJ sidecars. Review attributes and geometry; choose Pending verification, Verified unchanged, Updated, New feature, Not found or Needs review. Add points, lines and polygons as needed. Original baseline attributes and geometry are retained.

## Complete a linked field visit

1. Select the project and tap Start/resume field visit.
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
