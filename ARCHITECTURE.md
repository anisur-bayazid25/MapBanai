# MapBanai - System Architecture

**Version:** 1.0.0  
**Status:** Foundation Design  
**Technology Stack:** Flutter (Dart) + Native Android APIs

---

## Architecture Overview

```
┌─────────────────────────────────────────────┐
│           UI Layer (Presentation)           │
│   - Compose Navigation                      │
│   - Survey Mode Screens                     │
│   - GIS Mode Screens                        │
│   - Settings & Project Management           │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│       Business Logic Layer (BLoC)           │
│   - Survey State Management                 │
│   - Map State Management                    │
│   - Feature Editing Logic                   │
│   - Project Management Logic                │
│   - Sync Logic                              │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│    Repository Layer (Data Abstraction)      │
│   - ProjectRepository                       │
│   - FeatureRepository                       │
│   - SurveyRepository                        │
│   - UserRepository                          │
│   - SyncRepository                          │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│       Local Database Layer                  │
│   - SQLite (via Drift ORM)                  │
│   - GeoPackage Driver                       │
│   - Cached Basemaps (MBTiles)               │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│       Native & External Services            │
│   - Android Location Manager (GNSS)         │
│   - Android Camera/CameraX                  │
│   - Android File System                     │
│   - HTTP Client (for optional sync)         │
│   - MapLibre Native (for GIS Mode)          │
└─────────────────────────────────────────────┘
```

---

## Layer Descriptions

### 1. Presentation Layer (UI)

**Responsibility:** User interface and user interactions

**Key Components:**

#### Navigation Structure
```
lib/ui/
├── navigation/
│   ├── app_router.dart          (GoRouter configuration)
│   ├── routes.dart              (route definitions)
│   └── nav_extensions.dart      (navigation helpers)
├── screens/
│   ├── splash/
│   │   └── splash_screen.dart
│   ├── auth/
│   │   └── user_setup_screen.dart
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── mode_selector.dart
│   ├── survey/
│   │   ├── survey_list_screen.dart
│   │   ├── survey_detail_screen.dart
│   │   ├── point_record_screen.dart
│   │   ├── line_record_screen.dart
│   │   ├── polygon_record_screen.dart
│   │   ├── form_screen.dart
│   │   └── photo_capture_screen.dart
│   ├── gis/
│   │   ├── gis_map_screen.dart
│   │   ├── layer_control_screen.dart
│   │   ├── feature_edit_screen.dart
│   │   ├── attribute_edit_screen.dart
│   │   └── gps_diagnostics_screen.dart
│   ├── projects/
│   │   ├── project_list_screen.dart
│   │   ├── project_create_screen.dart
│   │   ├── project_import_screen.dart
│   │   └── project_export_screen.dart
│   └── settings/
│       ├── settings_screen.dart
│       ├── user_settings_screen.dart
│       ├── gps_settings_screen.dart
│       ├── sync_settings_screen.dart
│       └── about_screen.dart
├── widgets/
│   ├── common/
│   │   ├── app_bar.dart
│   │   ├── buttons.dart
│   │   ├── dialogs.dart
│   │   ├── loading_indicators.dart
│   │   └── error_widgets.dart
│   ├── survey/
│   │   ├── question_types/
│   │   │   ├── text_question.dart
│   │   │   ├── select_question.dart
│   │   │   ├── photo_question.dart
│   │   │   ├── location_question.dart
│   │   │   └── ... (other types)
│   │   ├── form_builder.dart
│   │   └── survey_progress.dart
│   ├── map/
│   │   ├── map_view.dart
│   │   ├── location_indicator.dart
│   │   ├── layer_list.dart
│   │   ├── basemap_selector.dart
│   │   └── gps_indicator.dart
│   └── location/
│       ├── accuracy_display.dart
│       ├── satellite_indicator.dart
│       └── location_status.dart
└── theme/
    ├── app_theme.dart
    ├── colors.dart
    └── text_styles.dart
```

**Framework:** Flutter Compose (Material 3)

**Key Patterns:**
- GoRouter for navigation
- Provider/Riverpod for state management
- Responsive design with MediaQuery
- Accessibility-first UI

---

### 2. Business Logic Layer (BLoC/State Management)

**Responsibility:** Application logic and state management

**Key Components:**

```
lib/bloc/
├── survey/
│   ├── survey_bloc.dart          (survey data list)
│   ├── survey_form_cubit.dart    (current form state)
│   ├── point_record_cubit.dart   (point recording)
│   ├── line_record_cubit.dart    (line recording)
│   ├── polygon_record_cubit.dart (polygon recording)
│   └── photo_cubit.dart          (photo management)
├── gis/
│   ├── map_bloc.dart             (map state)
│   ├── layer_bloc.dart           (layer visibility/selection)
│   ├── feature_edit_cubit.dart   (feature editing)
│   └── basemap_cubit.dart        (basemap selection)
├── location/
│   ├── gnss_provider.dart        (location updates)
│   ├── accuracy_filter_cubit.dart (accuracy checking)
│   └── gps_diagnostics_cubit.dart (GNSS diagnostics)
├── project/
│   ├── project_bloc.dart         (project list)
│   ├── active_project_cubit.dart (current project)
│   ├── project_import_cubit.dart (importing)
│   └── project_export_cubit.dart (exporting)
├── user/
│   ├── user_bloc.dart            (user management)
│   └── auth_cubit.dart           (current user session)
└── sync/
    ├── sync_bloc.dart            (sync orchestration)
    ├── upload_cubit.dart         (upload queue)
    └── conflict_cubit.dart       (conflict resolution)
```

**State Management Approach:**
- **Provider/Riverpod** for services and repositories
- **BLoC** for complex state (survey, map)
- **Cubit** for simple state (current user, active project)
- **StreamController** for real-time GNSS updates

**Key Responsibilities:**
- Validate user input
- Enforce business rules (accuracy filters, required fields)
- Orchestrate sync operations
- Manage real-time location updates
- Handle offline queue

---

### 3. Repository Layer

**Responsibility:** Data abstraction and business logic isolation

```
lib/repository/
├── project_repository.dart
│   - getProjects()
│   - getProjectById(id)
│   - createProject(project)
│   - updateProject(project)
│   - deleteProject(id)
│   - archiveProject(id)
│   - exportProject(id) → ZIP
│   - importProject(zip)
│   - duplicateProject(id)
│
├── feature_repository.dart
│   - getFeaturesByProject(projectId)
│   - getFeaturesByLayer(layerId)
│   - getFeatureById(id)
│   - createFeature(feature)
│   - updateFeature(feature)
│   - deleteFeature(id)
│   - getFeaturesByBounds(bbox)
│   - queryFeatures(sqlFilter)
│
├── survey_repository.dart
│   - getSurveySchemaByProject(projectId)
│   - updateSurveySchema(projectId, schema)
│   - validateAnswer(questionId, answer)
│   - getResponses(featureId)
│   - saveResponses(featureId, responses)
│
├── user_repository.dart
│   - getCurrentUser()
│   - setCurrentUser(username)
│   - listUsers()
│   - getUser(username)
│   - addUser(username)
│   - deleteUser(username)
│
├── sync_repository.dart
│   - getSyncProvider(projectId) → SyncProvider
│   - setSyncProvider(projectId, provider)
│   - queueFeatureForSync(featureId)
│   - startSync(projectId)
│   - getConflicts(projectId)
│   - resolveConflict(featureId, resolution)
│   - getSyncStatus(projectId)
│
├── photo_repository.dart
│   - savePhoto(file, featureId) → Photo
│   - getPhotosByFeature(featureId)
│   - deletePhoto(photoId)
│   - exportPhotos(projectId) → Zip
│
├── basemap_repository.dart
│   - getBasemaps(projectId)
│   - addBasemap(projectId, basemap)
│   - setActiveBasemap(projectId, basemapId)
│   - downloadBasemap(url) → MBTiles file
│   - getOfflineBasemaps()
│
├── geopackage_repository.dart
│   - importGeoPackage(file) → Project
│   - exportGeoPackage(projectId) → file
│
└── settings_repository.dart
    - getSetting(key)
    - setSetting(key, value)
    - getGPSSettings()
    - getSyncSettings()
```

**Design Principles:**
- **Repository Pattern:** Each domain model has a repository
- **Abstraction:** UI/BLoC never touches database directly
- **Dependency Injection:** Repositories injected via Provider
- **Error Handling:** Repository propagates errors as exceptions

---

### 4. Local Database Layer

**Responsibility:** Persistent data storage and retrieval

**Technology:** Drift ORM + SQLite

```
lib/database/
├── database.dart                 (main Drift database instance)
├── tables/
│   ├── projects.dart             (Project table)
│   ├── layers.dart               (Layer table)
│   ├── features.dart             (Feature table: Point/Line/Polygon)
│   ├── attributes.dart           (Feature attributes/properties)
│   ├── survey_responses.dart     (Survey answers)
│   ├── users.dart                (User records)
│   ├── photos.dart               (Photo metadata)
│   ├── basemaps.dart             (Basemap configurations)
│   ├── sync_queue.dart           (Features pending sync)
│   ├── sync_status.dart          (Sync state per feature)
│   ├── conflicts.dart            (Sync conflicts)
│   ├── app_settings.dart         (Key-value settings)
│   └── project_versions.dart     (Version history)
│
├── dao/
│   ├── project_dao.dart
│   ├── feature_dao.dart
│   ├── survey_dao.dart
│   ├── user_dao.dart
│   ├── photo_dao.dart
│   ├── sync_dao.dart
│   └── settings_dao.dart
│
└── migrations/
    ├── migration_001_init.dart
    ├── migration_002_add_fields.dart
    └── ... (future migrations)
```

**Core Tables:**

```sql
-- Projects
CREATE TABLE projects (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  creator TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  version TEXT DEFAULT '1.0.0',
  survey_schema_json TEXT,
  sync_enabled INTEGER DEFAULT 0,
  sync_provider TEXT,
  accuracy_filter INTEGER DEFAULT 10,
  max_wait_time INTEGER DEFAULT 60
);

-- Layers
CREATE TABLE layers (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  name TEXT NOT NULL,
  geometry_type TEXT NOT NULL, -- Point, LineString, Polygon
  editable INTEGER DEFAULT 1,
  visible INTEGER DEFAULT 1,
  style_json TEXT,
  FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- Features (stores all spatial geometries)
CREATE TABLE features (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  layer_id TEXT NOT NULL,
  geometry_type TEXT NOT NULL, -- Point, LineString, Polygon
  geometry_json TEXT NOT NULL,  -- GeoJSON geometry
  created_by TEXT,
  created_at INTEGER NOT NULL,
  updated_by TEXT,
  updated_at INTEGER NOT NULL,
  accuracy_horizontal REAL,     -- meters
  accuracy_vertical REAL,       -- meters
  altitude REAL,
  provider TEXT,                -- GPS, GLONASS, etc.
  sync_state TEXT DEFAULT 'LOCAL_ONLY', -- LOCAL_ONLY, QUEUED, UPLOADING, SYNCED, FAILED, CONFLICT
  sync_timestamp INTEGER,
  is_deleted INTEGER DEFAULT 0,
  FOREIGN KEY (project_id) REFERENCES projects(id),
  FOREIGN KEY (layer_id) REFERENCES layers(id)
);

-- Feature Attributes (key-value pairs)
CREATE TABLE attributes (
  id TEXT PRIMARY KEY,
  feature_id TEXT NOT NULL,
  key TEXT NOT NULL,
  value TEXT,
  value_type TEXT, -- text, number, boolean, json
  FOREIGN KEY (feature_id) REFERENCES features(id)
);

-- Survey Responses
CREATE TABLE survey_responses (
  id TEXT PRIMARY KEY,
  feature_id TEXT NOT NULL,
  question_id TEXT NOT NULL,
  answer_json TEXT,
  answered_at INTEGER,
  answered_by TEXT,
  FOREIGN KEY (feature_id) REFERENCES features(id)
);

-- Photos
CREATE TABLE photos (
  id TEXT PRIMARY KEY,
  feature_id TEXT NOT NULL,
  project_id TEXT NOT NULL,
  file_path TEXT NOT NULL,
  thumbnail_path TEXT,
  taken_at INTEGER,
  file_size INTEGER,
  sync_state TEXT DEFAULT 'LOCAL_ONLY',
  FOREIGN KEY (feature_id) REFERENCES features(id),
  FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- Users
CREATE TABLE users (
  username TEXT PRIMARY KEY,
  created_at INTEGER,
  is_active INTEGER DEFAULT 1
);

-- App Settings (key-value)
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,
  value TEXT,
  updated_at INTEGER
);

-- Sync Queue
CREATE TABLE sync_queue (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  feature_id TEXT,
  photo_id TEXT,
  sync_state TEXT, -- QUEUED, UPLOADING, FAILED
  retry_count INTEGER DEFAULT 0,
  error_message TEXT,
  created_at INTEGER,
  FOREIGN KEY (project_id) REFERENCES projects(id)
);

-- Sync Conflicts
CREATE TABLE conflicts (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  feature_id TEXT,
  local_version TEXT,
  remote_version TEXT,
  conflict_type TEXT, -- update, delete, attribute
  created_at INTEGER,
  resolved INTEGER DEFAULT 0,
  resolution TEXT,
  FOREIGN KEY (project_id) REFERENCES projects(id)
);
```

**Key Features:**
- Spatial queries (within bounds)
- Efficient indexing (GIS columns, project_id, layer_id)
- Foreign key constraints
- Transaction support
- Migration support

---

### 5. Services Layer

**Responsibility:** Specialized business services

```
lib/services/
├── location_service.dart
│   - startLocationUpdates()
│   - stopLocationUpdates()
│   - getCurrentLocation()
│   - getLocationStream()
│   - getGNSSStatus()
│   - requestLocationPermissions()
│
├── gnss_service.dart
│   - getGNSSStatus()
│   - getVisibleSatellites()
│   - getUsedSatellites()
│   - getConstellation(svId)
│   - getSignalStrength()
│   - getNMEASentences()
│
├── camera_service.dart
│   - takePicture() → File
│   - getGallery() → File[]
│   - compressImage(file) → File
│   - generateThumbnail(file) → File
│
├── accuracy_filter_service.dart
│   - checkAccuracy(location) → boolean
│   - getRequiredAccuracy() → meters
│   - getMaxWaitTime() → seconds
│   - updateFilterSettings()
│
├── survey_service.dart
│   - validateSurvey(surveyJson) → error[]
│   - parseSchema(json) → Schema object
│   - evaluateConditional(question, responses) → boolean
│   - calculateExpression(expression, values) → value
│
├── export_service.dart
│   - exportToGeoJSON(project, features) → File
│   - exportToGeoPackage(project, features) → File
│   - exportToCSV(project, features) → File
│   - exportToKML(project, features) → File
│   - exportToGPX(project, features) → File
│   - exportToZIP(project) → File (project package)
│
├── import_service.dart
│   - importProject(file) → Project
│   - importGeoJSON(file) → Feature[]
│   - importGeoPackage(file) → Feature[]
│   - importCSV(file, schema) → Feature[]
│   - importKML(file) → Feature[]
│   - importZIP(file) → Project
│
├── sync_service.dart
│   - createSyncProvider(type, config) → SyncProvider
│   - startSync(project)
│   - pauseSync(project)
│   - resumeSync(project)
│   - getSyncStatus(project)
│   - handleConflict(feature, resolution)
│
├── map_service.dart
│   - initializeMap()
│   - loadBasemap(config)
│   - addLayer(layer)
│   - removeLayer(layer)
│   - setLayerVisibility(layerId, visible)
│   - fitBounds(bbox)
│   - animateToLocation(lat, lng)
│
├── file_service.dart
│   - getAppDirectory() → Directory
│   - getPhotoDirectory(projectId) → Directory
│   - getBasemapDirectory() → Directory
│   - getBackupDirectory() → Directory
│   - deleteFile(path)
│
└── notification_service.dart
    - showNotification(title, message)
    - showSyncProgress()
    - showError(error)
    - cancelNotification()
```

---

### 6. Models & Data Classes

```
lib/models/
├── domain/
│   ├── project.dart             (Project entity)
│   ├── layer.dart               (Layer entity)
│   ├── feature.dart             (Feature entity)
│   ├── survey.dart              (Survey schema)
│   ├── user.dart                (User entity)
│   ├── photo.dart               (Photo entity)
│   ├── basemap.dart             (Basemap entity)
│   └── sync_state.dart          (Sync state enum)
│
├── dto/
│   ├── project_dto.dart         (Data transfer objects)
│   ├── feature_dto.dart
│   ├── survey_dto.dart
│   └── ...
│
└── request_response/
    ├── sync_request.dart        (API request/response models)
    ├── sync_response.dart
    └── ...
```

**Key Models:**

```dart
// domain/project.dart
class Project {
  final String id;
  final String name;
  final String description;
  final String creator;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String version;
  final SurveySchema surveySchema;
  final List<Layer> layers;
  final List<Basemap> basemaps;
  final GpsSettings gpsSettings;
  final SyncSettings syncSettings;
}

// domain/feature.dart
class Feature {
  final String id;
  final String projectId;
  final String layerId;
  final GeometryType geometryType; // Point, LineString, Polygon
  final Geometry geometry;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;
  final double accuracyHorizontal;
  final double accuracyVertical;
  final double altitude;
  final String provider;
  final Map<String, dynamic> attributes;
  final List<Photo> photos;
  final SyncState syncState;
}

// domain/survey.dart
class SurveySchema {
  final String id;
  final String name;
  final List<Question> questions;
  final List<ConditionalLogic> conditionals;
  final String version;
}

class Question {
  final String id;
  final String type; // text, select_one, photo, point, etc.
  final String label;
  final String hint;
  final bool required;
  final dynamic defaultValue;
  final List<Option> options;
  final Validation validation;
  final String relevant;
  final String calculation;
  final String appearance;
  final String help;
}
```

---

### 7. Utilities

```
lib/utils/
├── constants.dart               (app-wide constants)
├── extensions.dart              (Dart extensions)
├── validators.dart              (input validation)
├── formatters.dart              (number, date formatting)
├── error_handler.dart           (error conversion)
├── logger.dart                  (logging)
├── local_notifications.dart     (notifications)
├── permissions_helper.dart      (Android permissions)
├── gis_utils.dart               (coordinate transforms, distance calc)
├── geojson_builder.dart         (GeoJSON creation)
└── device_info.dart             (device capabilities)
```

---

## Key Design Patterns

### 1. Repository Pattern
- **Purpose:** Abstract data access
- **Benefit:** Easy to swap implementations (test vs. real)

### 2. Provider/Riverpod for Dependency Injection
- **Purpose:** Manage service lifecycle
- **Benefit:** Easy testing, singleton services

### 3. BLoC for Complex State
- **Purpose:** Separate business logic from UI
- **Benefit:** Testable, reusable logic

### 4. Offline-First Architecture
- **Purpose:** All data stored locally first, sync is optional
- **Benefit:** Works without internet, user data owned locally

### 5. Pluggable SyncProvider
- **Purpose:** Support multiple cloud backends
- **Benefit:** Not locked to one provider

---

## Data Flow Examples

### Recording a Point with Survey Answers

```
User taps "RECORD POINT"
           ↓
LocationService starts listening to GNSS
           ↓
AccuracyFilterService checks each fix
           ↓
User sees: Accuracy, Satellites, GPS Status
           ↓
When accuracy passes filter:
  - Show "SAVE LOCATION" button
           ↓
User taps "SAVE LOCATION"
           ↓
FeatureRepository.createFeature()
           ↓
Database.insert(features, attributes)
           ↓
Show survey form (from SurveyService)
           ↓
User answers questions
           ↓
SurveyService.validateAnswers()
           ↓
SurveyResponseRepository.saveResponses()
           ↓
FeatureRepository.updateFeature() (set sync_state = QUEUED)
           ↓
SyncBloc notified → add to sync queue
           ↓
Show confirmation: "Point saved"
```

### Syncing a Feature to Cloud

```
User taps "SYNC" or auto-sync triggers
           ↓
SyncBloc.startSync(projectId)
           ↓
SyncRepository gets provider (Google Drive, WebDAV, etc.)
           ↓
For each feature in sync queue:
  - SyncProvider.upload(feature, photos)
           ↓
On success:
  - Update sync_state = SYNCED
  - Keep local copy (never delete)
           ↓
On failure:
  - Update sync_state = FAILED
  - Store error message
  - Retry logic (exponential backoff)
           ↓
On conflict:
  - Store in conflicts table
  - Show conflict resolution UI
  - User chooses: Keep Local | Keep Remote | Merge
           ↓
Update UI with sync status
```

### Editing a Polygon

```
User taps feature on map
           ↓
FeatureEditCubit loads feature
           ↓
Show polygon with vertices
           ↓
User can:
  - Drag vertex (move it)
  - Add vertex (long-press on edge)
  - Delete vertex (tap + confirm)
           ↓
Real-time update of:
  - Area calculation
  - Perimeter calculation
  - Vertex count
           ↓
User taps "SAVE CHANGES"
           ↓
FeatureRepository.updateFeature()
           ↓
Update geometry, updated_by, updated_at
           ↓
Set sync_state = QUEUED
           ↓
Show confirmation + timestamp
```

---

## Error Handling Strategy

### Layers Handle Different Error Types

```
Presentation: Show user-friendly error messages
             (e.g., "GPS signal weak, try outside")

BLoC: Convert app errors to UI states
      (e.g., ErrorState, LoadingState)

Repository: Map database errors to domain exceptions
            (e.g., FeatureNotFound, DatabaseError)

Database: Transaction rollback on constraint violation

Services: Throw specific exceptions (LocationTimeoutError)
```

### Sync Errors

```
- Network unavailable: Queue for later
- Permission denied: Show settings link
- Quota exceeded: Warn user
- Conflict: Show merge UI
- Invalid data: Show validation errors
```

---

## Testing Strategy

```
lib/test/
├── unit/
│   ├── services/
│   ├── repositories/
│   ├── blocs/
│   └── utils/
│
├── integration/
│   ├── location_test.dart
│   ├── survey_test.dart
│   ├── sync_test.dart
│   └── export_import_test.dart
│
└── widget/
    ├── survey_form_test.dart
    ├── map_widget_test.dart
    └── settings_screen_test.dart
```

---

## Performance Considerations

### Database Queries
- Index frequently queried columns (project_id, layer_id, created_at)
- Use pagination for large feature lists
- Cache basemap metadata

### Geometry Operations
- Cache GeoJSON parsing results
- Batch vertex updates
- Defer map redraws

### Photos
- Compress before saving
- Generate thumbnails async
- Delete old photos (configurable retention)

### Location Updates
- Batch GNSS updates (not every fix)
- Use background location only when recording
- Stop updates when app backgrounded (unless recording)

---

## Security Model

### Data at Rest
- SQLite encrypted (optional, via Drift)
- Sensitive credentials in Android Keystore
- Photos stored in app-private directory

### Data in Transit
- TLS/HTTPS for sync operations
- OAuth tokens for cloud providers
- Never log sensitive data

### Permissions
- Request only necessary permissions
- Show permission rationale UI
- Handle permission denial gracefully

---

## Scalability

### Large Projects
- Pagination for feature lists
- Lazy-load layers
- Spatial indexing for map queries
- Background sync for large uploads

### Export/Import
- Stream large GeoJSON files
- Batch database inserts
- Progress indicators for user feedback

---

## Migration from MVP to Future Versions

### Adding New SyncProvider
```
1. Implement SyncProvider interface
2. Add provider selection UI
3. Add credential storage (Keystore)
4. Register in SyncRepository
5. Test with mock data
```

### Adding Advanced GIS Features
```
1. Extend Feature model
2. Add new geometry type
3. Implement editing UI
4. Update export/import
5. Add tests
```

### Adding Raw GNSS Measurements
```
1. Add new GNSS service methods
2. Store raw measurements in database
3. Add diagnostics UI
4. Update export format
```

---

## Technology Rationale

| Component | Choice | Why |
|-----------|--------|-----|
| Language | Dart (Flutter) | Cross-platform, modern, good performance |
| UI Framework | Material 3 (Flutter) | Native Android feel, accessible, well-documented |
| Database | SQLite (Drift) | Offline-first, GIS support, lightweight |
| Location APIs | Android native (via Method Channel) | Direct GNSS access, required for accurate location |
| Map | MapLibre Native | OSM-based, offline support, no tracking |
| Camera | CameraX | Modern Android camera API, good quality |
| State Management | Provider/Riverpod + BLoC | Testable, flexible, clear data flow |
| Testing | Flutter testing framework | Built-in, good coverage support |

---

## File Structure Summary

```
mapbanai/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── ui/
│   │   ├── navigation/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── theme/
│   ├── bloc/
│   ├── repository/
│   ├── services/
│   ├── models/
│   ├── database/
│   ├── utils/
│   └── constants.dart
├── test/
│   ├── unit/
│   ├── integration/
│   └── widget/
├── android/
│   ├── app/
│   ├── gradle/
│   └── ...
├── ios/
│   └── ...
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## Next Steps

1. ✅ Define architecture (this document)
2. 🔄 Create Flutter project structure
3. 🔄 Set up dependencies (pubspec.yaml)
4. 🔄 Create database schema (Drift DAOs)
5. 🔄 Implement navigation structure
6. 🔄 Create core services (location, camera, etc.)
7. 🔄 Build basic UI screens
8. 🔄 Implement local storage
9. 🔄 Add test suite
10. 🔄 Ensure successful build: `flutter test` and `flutter build apk`
