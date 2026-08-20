# PROJECT_SHARING_ANALYSIS

Existing implementation, documented BEFORE implementing the project
export / import / sharing subsystem.

Date: 2026-08-19
App version at time of writing: 2.1.1+2

---

## 1. How projects are currently stored

A project is **one row in the `projects` table** of an on-device SQLite
database (`mapbanai.db`), accessed through **Drift** (reactive ORM).

`lib/data/app_database.dart` — `class Projects extends Table`:

| column | type | notes |
|--------|------|-------|
| `id` | INTEGER PK | auto-increment, local identity |
| `name` | TEXT | unique de-facto; `getProjectByName` trims + case-sensitive compare |
| `description` | TEXT | default `''` |
| `archived` | BOOLEAN | default `false` |
| `gpsThresholdM` | REAL | default `10` — GPS accuracy threshold for this project |
| `createdAt` | DATETIME | default now |
| `isActive` | BOOLEAN | default `false`; set `true` when a project is created |

There is **no external/uuid project identity** and **no update timestamp**
or "project version" today. `createdAt` is the only time field.

## 2. Database / storage system

- **Drift** (`package:drift` `^2.20.3`) over **SQLite** (`sqlite3_flutter_libs`)
  — single file `mapbanai.db` in `getApplicationDocumentsDirectory()`.
- `AppDatabase` schema version is **7**; migrations live in
  `MigrationStrategy.onUpgrade` (versions 2→7).
- Tables: `projects`, `survey_sessions`, `stored_forms`, `app_settings`,
  `gps_logs`, `project_fields`.
- Everything runs on-device; no cloud, no server, no sync.
- Photos are NOT in the DB — `PhotoStore` keeps files under the app
  documents folder; the DB stores references in response JSON.

## 3. Current project model

`lib/models/project.dart` (`ProjectModel`) is a small dart-only map-based
model (id, name, createdAt, isActive) used by legacy screens. The **real**
runtime model is Drift's generated `Project` row class plus:

- `ProjectFields` (custom attribute fields: name per project)
- `StoredForms` (per-project survey forms: name, description, `json` blob,
  version, createdAt)

## 4. How forms/questions are currently stored

`StoredForms` table, one row per form. The **entire form definition lives in
the `json` TEXT column** as a `SurveyForm.toJson()` payload
(`lib/models/survey_form.dart`):

```json
{
  "id": "form-id",
  "name": "Form name",
  "description": "...",
  "version": 1,
  "questions": [
    {
      "name": "q1",
      "label": "Question label",
      "type": "select_one",            // QuestionType enum name
      "hint": "...",
      "required": true,
      "relevance": "${q0} = 'yes'",    // conditional logic (XLSForm-style)
      "constraint": ". > 0 and . < 150",
      "constraint_message": "...",
      "choices": [{"name": "a", "label": "A"}],
      "default": "...",
      "read_only": false,
      "calculation": "${width} * ${length}"
    }
  ]
}
```

So questions, choices, validation, relevance/conditional logic and
calculations are all **already JSON-serializable** — no separate
`choices.json`/`logic.json` is needed; they are captured by
`form.json`.

Since schema v7, every form belongs to exactly one project
(`project_id` column; legacy global forms were migrated to the first
project).

## 5. How project settings are stored

- **Project-level settings** are columns on `projects`:
  `description`, `gpsThresholdM`, `archived`, `isActive`.
- **Global app settings** are key/value rows in `app_settings`
  (`user_name`, `language`, update metadata, package-version markers) —
  these are NOT project-scoped and must NOT be part of an exported project.
- GIS basemap choice is **not persisted** — it is a per-session in-memory
  selection (`Basemap.defaults` in `lib/services/map_service.dart`).

## 6. How GIS layers/settings are currently represented

- `lib/services/map_service.dart` defines `Basemap` (id, name, tile URL,
  attribution) with 5 built-in basemaps (OSM, OSM HOT, CartoDB light/dark,
  Esri satellite). No custom/user basemaps; no offline tile packages.
- There is **no persistent layer table**. GIS capture
  (`lib/ui/gis_mode_screen.dart`) builds a MapLibre **style JSON at
  runtime** (`_buildStyleString`) from the chosen basemap + generated
  layers for captured geometries and a `FeatureData` source.
- "Layer settings" therefore amount to: basemap id + style seed
  (line/fill paint derived from runtime variables). These can be exported
  as a compact `layers.json` **configuration snapshot** so an imported
  project can re-derive the same map behavior; no tile data is stored
  on-device today and none can be exported.

## 7. Existing export/import mechanisms

Yes — for **DATA / RESPONSES only**, never for the project itself:

- `lib/services/data_export_service.dart` — survey responses as
  JSON/CSV (Kobo/ODK style), and `DataImportService` for survey-form JSON.
- `lib/services/gis_export_service.dart` — GIS captured features to
  CSV/GeoJSON/Shapefile-ish files.
- `lib/ui/data_export_screen.dart` — "Export" button on Home writes those
  files to external storage `Export/<project>/` (via
  `_writeAppendCsv`-style helpers also reused by GPS logs/waypoints).
- `lib/services/xlsform_parser.dart` + `xlsx_reader.dart` — import
  **XLSForm (.xlsx) templates** into `stored_forms`.
- `lib/services/update_checker.dart` / `update_downloader.dart` —
  GitHub-Release based in-app update mechanism.

There is **no project export/import** (no way to move a project definition
between devices), and file-sharing today only covers data files via
`share_plus` (CSV/GeoJSON) from `data_export_screen.dart`? — share_plus is
used for responses CSV. Project definitions cannot leave the device.

## 8. Current Android minimum SDK

- `android/app/build.gradle`: **minSdk = 23** (Android 6.0, 2015),
  targetSdk = Flutter default (34/35 for Flutter 3.24), compileSdk 36,
  AGP 8.1 / Gradle 8.3, Kotlin 1.8-compatible.
- Dependencies already meet or exceed 23: maplibre_gl (≥21), geolocator
  (≥21/23), sqlite3_flutter_libs, permission_handler (≥21), image_picker,
  path_provider, file_picker (≥21), share_plus (≥21).
- **Decision: keep minSdk 23.** It is already below the practical 2018
  target (Android 8.x = API 26), no dependency forces higher, and
  Storage Access Framework (API 19+), ACTION_SEND (API 1+) and DocumentFile
  work on all supported devices. No manifest permissions for storage are
  required thanks to SAF.

---

## Design decisions for the new subsystem (short)

1. **Package format**: ZIP container, extension `.mbproj`, package format
   version 1, payload JSON files + SHA-256 checksums (`package:crypto`;
   `package:archive` is already a dependency for ZIP I/O).
2. **Identity**: add a nullable `external_id` TEXT column (uuid) to
   `projects` (schema 7 → 8) as the stable cross-device project identity;
   local integer `id` stays the runtime identity.
3. **Export scope** (all project definition):
   `manifest.json` + `project.json` (metadata: name, description, external
   id, gps threshold, timestamps, project version) + `form/*.json` (one
   entry per stored form — full question/choice/logic/validation structure
   is already in the form JSON) + `layers.json` (basemap/style config
   snapshot) + optional `assets/` (future-proof; empty now) + `metadata/
   version.json` (schema versions). **Excluded**: survey_sessions/responses,
   GPS logs, photos, app_settings, credentials, keys.
4. **Import**: SAF file picker + Android file association
   (`application/vnd.mapbanai.project` intent filter + `.mbproj` path
   patterns + `mapbanai://project/import?file=...` URI scheme); validation
   pipeline (magic manifest, package version, required files, JSON parse,
   ZIP path-traversal guard, size limits); extract to temp dir; duplicate
   detection by external_id/name → "Import as new copy / Replace / Cancel";
   DB writes inside a transaction; temp cleanup on every path.
5. **Sharing**: `ProjectTransferProvider` abstraction with
   `NativeShareProvider` (share_plus ACTION_SEND content-URI) implemented;
   future providers (LAN/Bluetooth/Nearby) plug in behind the same
   interface.
6. **QR**: versioned payloads `MAPBANAI-PROJECT-V1:...`
   (zlib+base64url JSON). Small projects render inline; oversized →
   "Project is too large for direct QR transfer." bootstrap QR carries
   identity info only. Generation in-app; string-level parse/validate +
   camera scan deferred (no new native deps; scope-conservative).
7. **Security**: never extract blindly; reject `../`, absolute paths,
   symlinks; treat package as untrusted input; no secrets in packages;
   no code execution.