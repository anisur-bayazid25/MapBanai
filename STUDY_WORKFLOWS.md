# Study Area workflows

The home Study Area button opens three options:

| Workflow | Purpose | Progress |
| --- | --- | --- |
| Field Verification | Existing feature verification, edits and location corrections | Existing verification state |
| Recurring Collection | Salinity, heat or other repeated measurements at stable sites | Independent for each collection round |
| Study Area Visits | STS/facility visits with optional questionnaires | Done / undone / needs review |

Select a project, its site layer and a questionnaire before opening the map.
Recurring Collection also selects a **Collection round**, with name, optional
period/season and date. A new round starts red/uncollected. Saving a valid
questionnaire turns that site green for that round. Yellow flags review. Marking
it uncollected again preserves earlier observations. Facility visits may be
marked done without filling a questionnaire.

The map uses compact icons with tooltips: questionnaire, done/undone/review,
Google Maps, timeline and center. The tuning icon changes the layer, form and
round. Detailed configuration stays outside the map. The red/green/yellow legend
also uses shapes, and the filter icon selects a status.

## First collection → recurring site layer

1. Collect the first measurements in Survey Mode. Include a geopoint question.
2. Open Study Area → Recurring Collection for that project.
3. Choose **Create layer from responses**. Select the source questionnaire and
   numeric measurement, such as Salinity (ppt). Preview matching sites.
4. Name and create the layer. Only saved, located records with that measurement
   become sites. Other measurements/responses stay separate and untouched.
5. Choose that site layer, a questionnaire and a new collection round. Open the
   map and collect a new observation at each point.

A site keeps its identity across rounds. Measurements are separate child records,
not replacements for the first reading. Site timelines show each round/period
and can export observation CSV. The project response CSV includes round, season,
site and workflow columns as well as questionnaire answers.

## Project-owned uploads

Project layers accept the existing shapefile/ZIP, GeoJSON, CSV, Excel and
GeoPackage formats. Choose which workflows can use each uploaded file. Existing
files without an assignment remain available in all workflows for compatibility;
use their workflow chips to narrow that assignment. Each workflow remembers its
own layer/form selection. Road layers remain shared routing references.

Round definitions, layer assignments and selections travel in project packages.
Including responses also carries observations and status events. Local backups
preserve them. The cloud response payload preserves workflow/round/site context;
the bundled manager source adds readable columns for these fields. No deployed
Apps Script endpoint is modified automatically.

## Implementation notes

No database table migration is needed. Project definitions use the existing
workspace settings, and observations/status events use survey rows with
`workflow: study_collection_v1`. Status changes never overwrite baseline feature
geometry, attributes or earlier answers. Completion follows the project workflow requirements; selected questionnaires and attached media are validated. Drafts do not count as collected and resume with their original
form snapshot. Version checks prevent stale draft saves.

Google Maps opens via its documented universal URL with `api=1`; no Google Maps
API key is required. MapBanai still performs its own offline storage.

## Validation on 27 October 2026

All 479 automated tests passed, including project transfer, round isolation,
draft recovery/validation, filtered measurement extraction and compact layouts
at narrow/landscape sizes with large text. Static analysis reported no errors
or warnings; existing informational lints remain. The manager backend checks
passed. An authorized local Android debug compilation and installation succeeded.
The later user request authorizes a local signed v2.7.0+34 APK build. Publishing and deployed server changes remain on hold. See `ANDROID_PREVIEW.md` for hot reload and the E: development paths.


## Workflow requirements and nearest sites

Open Project Settings > Workflow requirements. Each workflow has independent questionnaire and geotagged-photo switches. Defaults preserve earlier behavior: Field Verification requires both, Recurring Collection requires a questionnaire, Study Area Visits requires neither. Save settings and send the updated project package to the field team. They are project configuration, not a new authentication/role system.

Completion checks the current project policy; a valid questionnaire photo also satisfies the photo requirement. Photo-only observations support saved drafts and history/timeline reopening. Each saved record includes the applied requirements for quality review. Templates retain project requirements; new projects start without prior rounds/progress.

On the map, the nearby arrow lists only unvisited sites in the selected layer/round. A GPS fix within two minutes sorts by straight-line distance; absent/invalid location sorts names. The list offers GPS refresh and selecting a row centers its map pin without marking it complete. Yellow review sites remain available through the review filter.

The external-arrow button opens the selected point in Google Maps; without a selected point it opens the current map area. Google Maps is external; the in-app map retains MapLibre and its existing basemap/offline support.


## Final v2.7.0 checks

All 496 Flutter tests passed after workflow requirements, photo-only drafts, distance ranking, Google Maps URL validation, all three workflow shortcuts, large-font Bangla settings and incremental map-status regression tests were added. The final catalogue-only addition was rechecked with all five localization tests and the WebMap Node check. App-source analysis has no errors or warnings; repository-wide analysis retains three pre-existing unused-local warnings in `test/gis_map_controller_test.dart` and informational style lints. Android aapt2 compiled all launcher/splash resources successfully.

Physical-device frame-rate profiling and carrier-network throughput comparisons remain field checks. Automated tests validate layout, state and persistence, and do not establish Google Maps-equivalent frame rates.


The initial release packaging exposed Kotlin 2.2 metadata diagnostics. Build review also found the optimizer bundled with AGP 8.1 was older than the documented Kotlin 2.2 requirement. `android/settings.gradle` now pins R8 8.10.21 using the official plugin-management replacement, retaining the existing AGP/Gradle setup. References: [Android Kotlin compatibility](https://developer.android.com/build/kotlin-support) and [R8 replacement instructions](https://r8.googlesource.com/r8/+/refs/heads/main/README.md#replacing-r8-in-android-gradle-plugin).


Local signed APK v2.7.0+34 built and verified; see `BUILD_VERIFICATION_2.7.0.md` for certificate, checksum, tests and remaining Android-tooling diagnostics. No release was published.
