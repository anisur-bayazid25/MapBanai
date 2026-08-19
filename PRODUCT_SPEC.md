# MapBanai - Product Specification

**Version:** 1.0.0  
**Last Updated:** 2026-08-17  
**Status:** Foundation Phase

---

## Executive Summary

MapBanai is an offline-first Android field data collection and lightweight GIS application designed for environmental-health and urban field research. It provides two distinct modes: a simple Survey Mode for community researchers and a powerful GIS Mode for professional researchers. The application is completely free, ad-free, and distributed via direct APK download.

---

## Core Principles

1. **Offline-First:** All field data collection works without internet connectivity
2. **Open Source:** Free and ad-free, no tracking or analytics
3. **Accessibility:** Survey Mode must be usable by non-technical field researchers
4. **Data Ownership:** Users maintain complete control of their data
5. **Modularity:** Architecture supports easy feature additions without rewrites

---

## Two Modes of Operation

### MODE 1: SURVEY MODE (Default)

**Target Users:** Community researchers, environmental technicians, health workers, field co-researchers with minimal GIS knowledge

**Design Philosophy:**
- Extremely simple interface
- Large, clear buttons
- Minimal menus
- Step-by-step guidance
- No technical jargon

**Core Capabilities:**
- ✅ Start a survey project
- ✅ Record a point (with photos)
- ✅ Record a path/road
- ✅ Record a boundary/polygon
- ✅ Answer survey questions
- ✅ Attach photographs
- ✅ Save data locally
- ✅ Send/sync data to cloud (optional)

**User Should NOT Need to Understand:**
- GPS coordinates format
- GNSS constellations
- Map layers
- Coordinate projections
- GeoPackages
- GIS concepts

**Example Workflow:**
1. Open app → "Who are you?" → Enter username
2. "New Survey" → Select project
3. Large button: "RECORD POINT"
4. GPS indicator shows: accuracy, satellites, status
5. "SAVE LOCATION" when ready
6. Answer questions (simple form)
7. "TAKE PHOTO" → "SAVE"

---

### MODE 2: GIS MODE (Advanced)

**Target Users:** Researchers, professional field workers, data analysts with GIS experience

**Design Philosophy:**
- Interactive map-centric interface
- Full control over map layers and styling
- Direct coordinate visibility
- Editing capabilities
- Project management tools

**Core Capabilities:**
- ✅ Interactive map with pan/zoom
- ✅ Multiple basemap sources (OSM, offline MBTiles, raster)
- ✅ Current GPS location tracking
- ✅ Layer visibility control
- ✅ Feature selection and inspection
- ✅ Point editing (move, delete)
- ✅ Line editing (add/remove vertices)
- ✅ Polygon editing (vertices, area calculation)
- ✅ Feature attribute editing
- ✅ GPS diagnostics (accuracy, satellites, constellation)
- ✅ Data export (GeoJSON, GeoPackage, KML, GPX)
- ✅ Project management (create, import, duplicate, archive, export)
- ✅ Undo/Redo

---

## Data Requirements

### What Every Feature Must Store

Each captured spatial feature must record:

```
- UUID (unique identifier)
- Project ID
- Layer ID
- Geometry (point, line, polygon)
- Timestamp (when captured)
- Created by (username)
- Updated by (username)
- Updated at (timestamp)
- Horizontal accuracy (meters)
- Vertical accuracy (meters)
- Altitude (meters)
- Provider (GPS, GLONASS, etc.)
- Survey attributes (answers)
- Photos (UUIDs)
- App version (for debugging)
- Project version
```

---

## Survey System

### Lightweight Survey Engine

Inspired by ODK/Kobo but NOT a full clone.

**Supported Question Types:**
- Text (single line)
- Long text (multi-line)
- Integer
- Decimal
- Yes/No (boolean)
- Select one
- Select multiple
- Dropdown
- Date
- Time
- DateTime
- Photo (capture or select)
- Point (record location)
- Line (record path)
- Polygon (record boundary)
- Calculated (computed from other fields)
- Note (read-only text)
- GPS accuracy (auto-populated)
- Hidden metadata (auto-populated)

**Question Properties:**
- id, label, hint
- required (boolean)
- default value
- options (for select/dropdown)
- validation rules (min, max, regex)
- relevant (conditional show/hide logic)
- calculation (formula-based values)
- appearance (UI hints)
- help text

**Survey Schema:**
- Exportable as JSON
- Importable from JSON
- Versioning support
- Project-scoped (each project has its survey)

**Conditional Questions:**
```
Example: Show "damaged_extent" only if damage == "yes"
Show "repair_cost" only if damage == "yes" AND damage_type != "minor"
```

---

## User Management

### No Mandatory Online Accounts

**On First Launch:**
- Simple prompt: "Who are you?"
- Username input (required)
- Optional email, organization

**Every Feature Records:**
- `created_by` (username)
- `created_at` (timestamp)
- `updated_by` (username)
- `updated_at` (timestamp)

**Features:**
- Switch local user (Settings → User → Switch)
- No unnecessary personal data collection
- No tracking or analytics
- Credentials stored in secure Android storage

---

## Projects

### Project Structure

Each project contains:

```
{
  project_id: UUID,
  name: string,
  description: string,
  creator: string,
  created_at: timestamp,
  updated_at: timestamp,
  version: string (e.g., "1.0.0"),
  survey_schema: JSON,
  layers: [Layer],
  basemaps: [Basemap],
  gps_settings: {
    accuracy_filter: "10m" (default),
    max_wait_time: 60 (seconds, default),
    min_distance_line: 3 (meters, default),
    min_interval_line: 2 (seconds, default),
    max_accuracy_line: 20 (meters, default)
  },
  sync_settings: {
    enabled: boolean,
    provider: "google_drive" | "webdav" | null,
    sync_interval: number (minutes)
  }
}
```

### Project Operations

- **Create:** New project with survey schema
- **Import:** Load from exported ZIP
- **Duplicate:** Clone existing project
- **Archive:** Mark as inactive (soft delete)
- **Export:** Package everything as ZIP

### Project Versioning

Track changes to projects:

```
{
  version: "1.0.0",
  username: string,
  timestamp: datetime,
  change_description: string
}
```

---

## Location & GNSS

### GNSS Capture Requirements

For every location fix, capture:

```
- Latitude, Longitude (WGS84)
- Altitude (meters, above mean sea level)
- Horizontal accuracy (meters)
- Vertical accuracy (meters)
- Speed (m/s)
- Bearing (degrees)
- Timestamp (UTC)
- Provider (GPS, GLONASS, Galileo, BeiDou, etc.)
- Satellites visible (count)
- Satellites used (count)
- GNSS constellation info (where available)
```

### Supported Constellations

- GPS (U.S.)
- GLONASS (Russia)
- Galileo (EU)
- BeiDou (China)
- QZSS (Japan)
- NavIC/IRNSS (India)
- SBAS (augmentation systems)

**Note:** Do NOT require raw GNSS measurements. Advanced diagnostics may come later.

---

## Accuracy Filter

### Configurable by Project

**Options:**
- 5 m
- 10 m (default)
- 15 m
- 20 m
- 30 m
- 50 m
- 100 m
- No filter

**Maximum Wait Time (configurable):**
- Default: 60 seconds

### Behavior

**Never silently save a location that fails accuracy requirements.**

When accuracy filter not met:

```
Options:
  [WAIT LONGER]
  [SAVE ANYWAY] (stored with actual accuracy, not filter value)
  [CANCEL]
```

Always store the actual accuracy with every feature.

---

## Point Recording Workflow

### POINT RECORDING

```
1. User taps "RECORD LOCATION"
2. Shows:
   - Accuracy (meters)
   - Satellites (visible/used)
   - Coordinates (DMS or decimal, configurable)
   - GPS status icon

3. App waits for acceptable accuracy
4. Once met, shows: "SAVE LOCATION"
5. User taps SAVE
6. If survey questions exist, present form
7. Prompt for photos (optional)
8. Confirm save to database
```

---

## Line Recording Workflow

### RECORDING PATHS/ROADS

```
1. User taps "START RECORDING"
2. GPS automatically collects vertices as user walks

Default Settings:
  - Minimum distance between vertices: 3 m
  - Minimum time between vertices: 2 seconds
  - Maximum accuracy for vertex: 20 m

3. Display updates:
   - Total distance (meters/km)
   - Elapsed time
   - Current accuracy
   - Vertex count

4. User buttons:
   - [PAUSE] - Temporarily stop collecting
   - [RESUME] - Continue from pause
   - [FINISH] - Complete line, prompt for save
   - [CANCEL] - Discard line

5. Do NOT create redundant vertices
   (respect minimum distance/interval settings)

6. Preserve raw observations where practical
```

---

## Polygon Recording Workflow

### RECORDING BOUNDARIES

```
1. User taps "START RECORDING BOUNDARY"
2. GPS automatically collects vertices as user walks around perimeter

3. Display updates:
   - Area (m², hectares, acres - user configurable)
   - Perimeter (meters/km)
   - Accuracy
   - Elapsed time
   - Vertex count

4. User buttons:
   - [UNDO] - Remove last vertex
   - [PAUSE] - Temporarily stop collecting
   - [RESUME] - Continue from pause
   - [FINISH] - Close polygon (auto-connects first/last vertex)
   - [CANCEL] - Discard polygon

5. Require at least 3 valid vertices

6. In GIS Mode:
   - Allow post-collection vertex editing
   - Move vertices
   - Add/remove vertices
   - Recalculate area/perimeter
```

---

## Photography

### Using CameraX

- Capture photos directly from survey or point-record mode
- Each photo has:
  - UUID
  - Feature UUID (what it's attached to)
  - Project ID
  - Timestamp
  - Filename

- Store locally first (on device storage)
- Compress images appropriately
- Enable thumbnail preview
- Support multiple photos per feature

---

## Mapping

### MapLibre Native (NOT Google Maps)

**Basemap Support:**
- OpenStreetMap (default, requires permission)
- Offline MBTiles
- User-provided raster imagery (GeoTIFF, etc.)
- Custom map sources (JSON style specs)

**Restrictions:**
- Do NOT bundle Google satellite imagery
- Do NOT scrape Google tiles
- Satellite imagery must be legally licensed or user-provided

**Attribution:**
- Every basemap must include proper attribution
- Display attribution on map

**Map Features:**
- Pan and zoom
- Current location marker
- Location tracking (follow-me mode)
- Feature rendering
- Offline support

---

## Layers

### Layer Definition

```
{
  id: UUID,
  name: string,
  geometry_type: "Point" | "LineString" | "Polygon",
  attribute_schema: {
    // Field definitions tied to survey schema
  },
  editable: boolean,
  visible: boolean,
  style: {
    // Simple styling rules
    fill_color, stroke_color, fill_opacity, etc.
  }
}
```

### Supported Geometry Types

- Point (with attributes)
- LineString (with attributes)
- Polygon (with attributes)

### Styling

Simple styling only (not a full cartographic system):
- Fill color, stroke color
- Stroke width
- Opacity
- Basic label support

---

## Data Export & Import

### Export Formats

The application must export to multiple formats:

1. **GeoPackage** (preferred spatial format)
2. **GeoJSON** (for web tools)
3. **CSV** (for spreadsheets)
4. **KML** (for Google Earth, etc.)
5. **GPX** (for GPS devices)
6. **ZIP** (project package)

### ZIP Project Package Contains

```
project/
  ├── project.json        (metadata, schema, settings)
  ├── survey_schema.json  (questions and logic)
  ├── features.geojson    (all spatial data)
  ├── features.gpkg       (optional GeoPackage)
  ├── layers.json         (layer definitions)
  ├── basemaps.json       (basemap configurations)
  ├── photos/
  │   ├── {uuid}.jpg
  │   └── ...
  ├── versions.json       (version history)
  └── metadata.json       (exported timestamp, app version)
```

---

## Offline-First Sync

### Sync States

Every feature tracked:

```
- LOCAL_ONLY      (never synced)
- QUEUED          (waiting for sync)
- UPLOADING       (actively syncing)
- SYNCED          (successfully uploaded)
- FAILED          (sync failed, retry available)
- CONFLICT        (conflict detected, user action needed)
```

### Sync Provider Interface

Design a pluggable `SyncProvider` interface:

```
abstract class SyncProvider {
  upload(project, features, photos)
  download(project)
  authenticate()
  getStatus()
}
```

### Initial Providers (Planned)

- **Google Drive** (authenticate via OAuth)
- **WebDAV** (generic server support)
- **Future:** MEGA, S3, Nextcloud, custom HTTPS

### Key Rules

- **Phone is the source of truth** until sync succeeds
- **Never delete local data** after upload
- **Never block field collection** because sync fails
- Sync is **optional** and asynchronous
- Conflict resolution strategy must be defined

---

## Security & Privacy

### Security Requirements

1. **No Advertising**
2. **No Analytics**
3. **No Tracking**
4. **No Unnecessary Network Access**
5. **Credentials** in secure Android storage (KeyStore)

### Never Hard-Code

- API keys
- Passwords
- OAuth secrets
- Server URLs (configurable)

### Data Privacy

- Collect only necessary field data
- No fingerprinting or device identifiers
- Users can delete all data locally
- Exported data is user's responsibility

---

## Localization (i18n)

### Initial Support

- **English** (default)

### Planned Support

- **Bangla** (early priority)

### Architecture

- All user-facing strings in Android string resources
- No hardcoded UI text
- Support for RTL languages (future)
- Regional date/time formatting

---

## Build & Distribution

### Build Requirements

- Build without Play Store
- Support `gradlew assembleDebug`
- Support `gradlew test`
- Eventually support `gradlew assembleRelease`
- Do NOT require Play Store signing (local signing OK)

### APK Distribution

- Direct APK download (no Play Store)
- Installation via ADB or direct file transfer
- Self-hosted download link (user manages)

### Versioning

- Semantic versioning (e.g., 1.0.0)
- Version tracked in app
- Version included with every exported feature

---

## Development Phases

### Phase 1: Foundation (Current)
- ✅ Project structure
- ✅ Android/Flutter setup
- ✅ Compose UI framework
- ✅ Navigation system
- ✅ Data models (Project, User, Feature)
- ✅ Local database (Drift/SQLite)
- ✅ Settings/preferences
- ✅ Test infrastructure
- ✅ Successful build (gradlew test, assembleDebug)

### Phase 2: Survey Mode Basic
- Survey schema & validation
- Form rendering
- Point recording (with photos)
- Local sync
- Basic project management
- Settings UI

### Phase 3: GIS Mode Basic
- MapLibre integration
- Basemap support
- Feature rendering
- Layer management
- GPS location tracking
- Data export (GeoJSON, CSV)

### Phase 4: Advanced Editing
- Point/line/polygon editing
- Vertex manipulation
- Attribute editing
- Undo/redo
- GeoPackage support

### Phase 5: Sync & Cloud
- SyncProvider interface
- Google Drive integration
- WebDAV integration
- Conflict resolution
- Offline queue management

### Phase 6: Polish & Distribution
- Bangla localization
- GPS diagnostics
- Advanced styling
- Performance optimization
- Release build & signing
- Installation documentation

---

## Non-Requirements (Out of Scope)

- ❌ Google Maps as primary map
- ❌ WebView-based map
- ❌ Play Store distribution
- ❌ Raw GNSS measurements (advanced feature only)
- ❌ Advanced cartographic styling
- ❌ Real-time collaboration
- ❌ Cloud-first (offline-first only)
- ❌ Google satellite imagery
- ❌ Advertising or tracking
- ❌ Mandatory online account

---

## Success Criteria

### Build Phase Success
- [ ] Project structure created
- [ ] Dependencies resolved
- [ ] `gradlew test` passes
- [ ] `gradlew assembleDebug` produces APK
- [ ] APK installs on Android device
- [ ] App launches without crashes
- [ ] Basic navigation works

### MVP Success
- [ ] Survey Mode: Record point + answer questions
- [ ] Survey Mode: Record line and polygon
- [ ] Photos can be attached
- [ ] Data saved locally
- [ ] GIS Mode: View data on map
- [ ] Export to GeoJSON
- [ ] All core validations working
- [ ] Zero placeholder buttons

---

## References

- Android Location APIs: https://developer.android.com/training/location
- MapLibre Native Android: https://maplibre.org/maplibre-native-sss/
- Flutter: https://flutter.dev/
- GeoPackage: https://www.geopackage.org/
- ODK/Kobo: https://www.kobotoolbox.org/ (inspiration only)
