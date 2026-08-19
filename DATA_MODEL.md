# MapBanai - Data Model Specification

**Version:** 1.0.0  
**Database:** SQLite with Drift ORM

---

## Overview

The data model supports offline-first field data collection with support for points, lines, and polygons. It maintains data lineage (who created/edited, when) and tracks sync status.

---

## Entity-Relationship Diagram

```
┌──────────────────┐
│   User           │
├──────────────────┤
│ username (PK)    │
│ created_at       │
│ is_active        │
└────────┬─────────┘
         │ created_by
         │ updated_by
         ▼
┌──────────────────────────┐
│   Project                │
├──────────────────────────┤
│ id (PK)                  │
│ name                     │
│ description              │
│ creator (FK → User)      │
│ created_at               │
│ updated_at               │
│ version                  │
│ survey_schema_json       │
│ sync_enabled             │
│ sync_provider            │
└────┬─────────────────────┘
     │
     ├──────────┬──────────────┐
     ▼          ▼              ▼
 ┌────────┐ ┌───────┐    ┌──────────┐
 │ Layer  │ │Feature│    │ Basemap  │
 │(FK→Pr)│ │(FK→Pr)│    │(FK→Proj) │
 └────────┘ └───┬───┘    └──────────┘
               │
        ┌──────┼──────┐
        ▼      ▼      ▼
    ┌───────────────────────────┐
    │   Feature Attributes      │
    ├───────────────────────────┤
    │ id (PK)                   │
    │ feature_id (FK → Feature) │
    │ key                       │
    │ value                     │
    │ value_type                │
    └───────────────────────────┘

    ┌──────────────────────────┐
    │   Photo                  │
    ├──────────────────────────┤
    │ id (PK)                  │
    │ feature_id (FK)          │
    │ project_id (FK)          │
    │ file_path                │
    │ thumbnail_path           │
    │ taken_at                 │
    │ sync_state               │
    └──────────────────────────┘

    ┌────────────────────────────┐
    │   Survey Response          │
    ├────────────────────────────┤
    │ id (PK)                    │
    │ feature_id (FK → Feature)  │
    │ question_id                │
    │ answer_json                │
    │ answered_at                │
    │ answered_by (FK → User)    │
    └────────────────────────────┘

    ┌──────────────────────────┐
    │   Sync Queue             │
    ├──────────────────────────┤
    │ id (PK)                  │
    │ project_id (FK)          │
    │ feature_id (FK)          │
    │ photo_id (FK)            │
    │ sync_state               │
    │ retry_count              │
    │ error_message            │
    └──────────────────────────┘

    ┌────────────────────────────┐
    │   Conflict                 │
    ├────────────────────────────┤
    │ id (PK)                    │
    │ project_id (FK)            │
    │ feature_id (FK)            │
    │ conflict_type              │
    │ local_version              │
    │ remote_version             │
    │ resolution (enum)          │
    │ resolved (boolean)         │
    └────────────────────────────┘

    ┌──────────────────────────┐
    │   Project Version        │
    ├──────────────────────────┤
    │ id (PK)                  │
    │ project_id (FK)          │
    │ version_number           │
    │ username (FK → User)     │
    │ timestamp                │
    │ change_description       │
    └──────────────────────────┘
```

---

## Detailed Entity Specifications

### 1. User

Stores user identities for tracking data ownership.

```sql
CREATE TABLE users (
  username TEXT PRIMARY KEY,
  created_at INTEGER NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  email TEXT,
  organization TEXT
);
```

**Dart Model:**
```dart
class User {
  final String username;
  final DateTime createdAt;
  final bool isActive;
  final String? email;
  final String? organization;

  User({
    required this.username,
    required this.createdAt,
    required this.isActive,
    this.email,
    this.organization,
  });
}
```

**Business Rules:**
- Username is globally unique
- Username cannot contain spaces (enforce [a-zA-Z0-9_-])
- Cannot be deleted (soft delete via is_active)
- Required for every data operation

---

### 2. Project

Container for a survey project with survey schema, layers, and settings.

```sql
CREATE TABLE projects (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  creator TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  version TEXT NOT NULL DEFAULT '1.0.0',
  survey_schema_json TEXT NOT NULL,
  sync_enabled INTEGER NOT NULL DEFAULT 0,
  sync_provider TEXT, -- google_drive, webdav, null
  accuracy_filter INTEGER NOT NULL DEFAULT 10, -- meters
  max_wait_time INTEGER NOT NULL DEFAULT 60, -- seconds
  min_distance_line INTEGER NOT NULL DEFAULT 3, -- meters
  min_interval_line INTEGER NOT NULL DEFAULT 2, -- seconds
  max_accuracy_line INTEGER NOT NULL DEFAULT 20, -- meters
  is_archived INTEGER NOT NULL DEFAULT 0,
  
  FOREIGN KEY (creator) REFERENCES users(username)
);
```

**Dart Model:**
```dart
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
  final bool isArchived;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.creator,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.surveySchema,
    required this.layers,
    required this.basemaps,
    required this.gpsSettings,
    required this.syncSettings,
    this.isArchived = false,
  });
}

class GpsSettings {
  final int accuracyFilterMeters; // 5, 10, 15, 20, 30, 50, 100, -1 (none)
  final int maxWaitTimeSeconds;
  final int minDistanceLineMeters;
  final int minIntervalLineSeconds;
  final int maxAccuracyLineMeters;

  GpsSettings({
    this.accuracyFilterMeters = 10,
    this.maxWaitTimeSeconds = 60,
    this.minDistanceLineMeters = 3,
    this.minIntervalLineSeconds = 2,
    this.maxAccuracyLineMeters = 20,
  });
}

class SyncSettings {
  final bool enabled;
  final String? provider; // google_drive, webdav
  final int syncIntervalMinutes;

  SyncSettings({
    this.enabled = false,
    this.provider,
    this.syncIntervalMinutes = 15,
  });
}
```

**Business Rules:**
- Project ID is UUID (v4)
- Name is required and unique within user's projects
- Survey schema must be valid JSON
- Cannot be deleted (soft delete via is_archived)
- Version must follow semantic versioning (X.Y.Z)

---

### 3. Layer

Groups features by geometry type within a project.

```sql
CREATE TABLE layers (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  name TEXT NOT NULL,
  geometry_type TEXT NOT NULL, -- Point, LineString, Polygon
  attribute_schema_json TEXT, -- defines expected attributes
  editable INTEGER NOT NULL DEFAULT 1,
  visible INTEGER NOT NULL DEFAULT 1,
  style_json TEXT, -- fill_color, stroke_color, etc.
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  
  UNIQUE(project_id, name),
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);
```

**Dart Model:**
```dart
class Layer {
  final String id;
  final String projectId;
  final String name;
  final GeometryType geometryType; // Point, LineString, Polygon
  final Map<String, FieldDefinition> attributeSchema;
  final bool editable;
  final bool visible;
  final LayerStyle style;
  final DateTime createdAt;
  final DateTime updatedAt;

  Layer({
    required this.id,
    required this.projectId,
    required this.name,
    required this.geometryType,
    required this.attributeSchema,
    this.editable = true,
    this.visible = true,
    required this.style,
    required this.createdAt,
    required this.updatedAt,
  });
}

enum GeometryType {
  point,
  lineString,
  polygon,
}

class LayerStyle {
  final String fillColor; // hex: #RRGGBB
  final String strokeColor; // hex: #RRGGBB
  final double strokeWidth;
  final double fillOpacity; // 0.0 - 1.0
  final double? label;

  LayerStyle({
    this.fillColor = '#3388ff',
    this.strokeColor = '#000000',
    this.strokeWidth = 2.0,
    this.fillOpacity = 0.5,
    this.label,
  });
}

class FieldDefinition {
  final String fieldName;
  final String fieldType; // text, number, boolean, date, etc.
  final bool required;
  final dynamic defaultValue;
  final String? hint;

  FieldDefinition({
    required this.fieldName,
    required this.fieldType,
    this.required = false,
    this.defaultValue,
    this.hint,
  });
}
```

**Business Rules:**
- Layer ID is UUID (v4)
- Name unique within project
- Cannot have 0 features before deletion
- GeometryType cannot change (immutable)

---

### 4. Feature

The core spatial data entity. Stores point, line, or polygon geometries.

```sql
CREATE TABLE features (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  layer_id TEXT NOT NULL,
  geometry_type TEXT NOT NULL, -- Point, LineString, Polygon
  geometry_json TEXT NOT NULL, -- GeoJSON Geometry object
  created_by TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_by TEXT,
  updated_at INTEGER,
  accuracy_horizontal REAL, -- meters
  accuracy_vertical REAL, -- meters
  altitude REAL, -- meters
  provider TEXT, -- GPS, GLONASS, Galileo, etc.
  satellites_visible INTEGER,
  satellites_used INTEGER,
  sync_state TEXT NOT NULL DEFAULT 'LOCAL_ONLY',
  -- LOCAL_ONLY, QUEUED, UPLOADING, SYNCED, FAILED, CONFLICT
  sync_timestamp INTEGER,
  sync_error_message TEXT,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  
  FOREIGN KEY (project_id) REFERENCES projects(id),
  FOREIGN KEY (layer_id) REFERENCES layers(id),
  FOREIGN KEY (created_by) REFERENCES users(username),
  FOREIGN KEY (updated_by) REFERENCES users(username)
);

CREATE INDEX idx_features_project_id ON features(project_id);
CREATE INDEX idx_features_layer_id ON features(layer_id);
CREATE INDEX idx_features_sync_state ON features(sync_state);
CREATE INDEX idx_features_created_at ON features(created_at);
```

**Dart Model:**
```dart
class Feature {
  final String id;
  final String projectId;
  final String layerId;
  final GeometryType geometryType;
  final Geometry geometry; // Point, LineString, Polygon
  final String createdBy;
  final DateTime createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;
  final double? accuracyHorizontal; // meters
  final double? accuracyVertical; // meters
  final double? altitude; // meters
  final String? provider; // GPS, GLONASS, etc.
  final int? satellitesVisible;
  final int? satellitesUsed;
  final Map<String, dynamic> attributes; // key-value pairs
  final List<Photo> photos;
  final SyncState syncState;
  final DateTime? syncTimestamp;
  final String? syncErrorMessage;
  final bool isDeleted;

  Feature({
    required this.id,
    required this.projectId,
    required this.layerId,
    required this.geometryType,
    required this.geometry,
    required this.createdBy,
    required this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.accuracyHorizontal,
    this.accuracyVertical,
    this.altitude,
    this.provider,
    this.satellitesVisible,
    this.satellitesUsed,
    this.attributes = const {},
    this.photos = const [],
    this.syncState = SyncState.localOnly,
    this.syncTimestamp,
    this.syncErrorMessage,
    this.isDeleted = false,
  });
}

enum SyncState {
  localOnly,
  queued,
  uploading,
  synced,
  failed,
  conflict,
}

// Geometry types
abstract class Geometry {
  Map<String, dynamic> toGeoJSON();
}

class Point extends Geometry {
  final double latitude;
  final double longitude;

  Point({required this.latitude, required this.longitude});

  @override
  Map<String, dynamic> toGeoJSON() => {
    'type': 'Point',
    'coordinates': [longitude, latitude],
  };
}

class LineString extends Geometry {
  final List<Point> vertices;

  LineString({required this.vertices});

  @override
  Map<String, dynamic> toGeoJSON() => {
    'type': 'LineString',
    'coordinates': vertices.map((p) => [p.longitude, p.latitude]).toList(),
  };

  double get length {
    // Calculate length in meters using haversine formula
    // Implementation omitted for brevity
    return 0.0;
  }
}

class Polygon extends Geometry {
  final List<Point> vertices; // vertices[0] == vertices[last] (closed)

  Polygon({required this.vertices});

  @override
  Map<String, dynamic> toGeoJSON() => {
    'type': 'Polygon',
    'coordinates': [
      vertices.map((p) => [p.longitude, p.latitude]).toList(),
    ],
  };

  double get area {
    // Calculate area in square meters using shoelace formula
    // Implementation omitted for brevity
    return 0.0;
  }

  double get perimeter {
    // Calculate perimeter in meters
    // Implementation omitted for brevity
    return 0.0;
  }
}
```

**Business Rules:**
- Feature ID is UUID (v4)
- Geometry cannot be null
- Created_by cannot change after creation
- Updated_by must be set if features are edited
- At least one of accuracyHorizontal, accuracyVertical must be set
- SyncState follows workflow: LOCAL_ONLY → QUEUED → UPLOADING → SYNCED
- Cannot have null geometry

---

### 5. Feature Attributes

Stores key-value pairs for feature properties (survey answers + custom data).

```sql
CREATE TABLE attributes (
  id TEXT PRIMARY KEY,
  feature_id TEXT NOT NULL,
  key TEXT NOT NULL,
  value TEXT, -- can be NULL for nullable fields
  value_type TEXT NOT NULL, -- text, number, boolean, json, date, time
  
  UNIQUE(feature_id, key),
  FOREIGN KEY (feature_id) REFERENCES features(id) ON DELETE CASCADE
);

CREATE INDEX idx_attributes_feature_id ON attributes(feature_id);
```

**Dart Model:**
```dart
class Attribute {
  final String id;
  final String featureId;
  final String key;
  final dynamic value; // String, num, bool, DateTime, etc.
  final AttributeType valueType;

  Attribute({
    required this.id,
    required this.featureId,
    required this.key,
    this.value,
    required this.valueType,
  });
}

enum AttributeType {
  text,
  number,
  boolean,
  date,
  time,
  dateTime,
  json,
}
```

**Examples:**
```
Feature 1:
  damage: "severe" (text)
  damage_extent_m2: 45.5 (number)
  requires_repair: true (boolean)
  photo_ids: ["uuid1", "uuid2"] (json)
  inspection_date: 2026-08-17 (date)
```

---

### 6. Survey Response

Stores answers to survey questions.

```sql
CREATE TABLE survey_responses (
  id TEXT PRIMARY KEY,
  feature_id TEXT NOT NULL,
  question_id TEXT NOT NULL,
  answer_json TEXT, -- can be any valid JSON value
  answered_at INTEGER NOT NULL,
  answered_by TEXT NOT NULL,
  
  UNIQUE(feature_id, question_id),
  FOREIGN KEY (feature_id) REFERENCES features(id) ON DELETE CASCADE,
  FOREIGN KEY (answered_by) REFERENCES users(username)
);

CREATE INDEX idx_survey_responses_feature_id ON survey_responses(feature_id);
```

**Dart Model:**
```dart
class SurveyResponse {
  final String id;
  final String featureId;
  final String questionId;
  final dynamic answer; // Depends on question type
  final DateTime answeredAt;
  final String answeredBy;

  SurveyResponse({
    required this.id,
    required this.featureId,
    required this.questionId,
    required this.answer,
    required this.answeredAt,
    required this.answeredBy,
  });
}
```

---

### 7. Photo

Stores photos attached to features.

```sql
CREATE TABLE photos (
  id TEXT PRIMARY KEY,
  feature_id TEXT NOT NULL,
  project_id TEXT NOT NULL,
  file_path TEXT NOT NULL, -- absolute path on device
  thumbnail_path TEXT,
  taken_at INTEGER NOT NULL,
  file_size INTEGER, -- bytes
  sync_state TEXT NOT NULL DEFAULT 'LOCAL_ONLY',
  sync_timestamp INTEGER,
  
  FOREIGN KEY (feature_id) REFERENCES features(id) ON DELETE CASCADE,
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE INDEX idx_photos_feature_id ON photos(feature_id);
CREATE INDEX idx_photos_project_id ON photos(project_id);
```

**Dart Model:**
```dart
class Photo {
  final String id;
  final String featureId;
  final String projectId;
  final String filePath;
  final String? thumbnailPath;
  final DateTime takenAt;
  final int? fileSize; // bytes
  final SyncState syncState;
  final DateTime? syncTimestamp;

  Photo({
    required this.id,
    required this.featureId,
    required this.projectId,
    required this.filePath,
    this.thumbnailPath,
    required this.takenAt,
    this.fileSize,
    this.syncState = SyncState.localOnly,
    this.syncTimestamp,
  });
}
```

**Business Rules:**
- Photo ID is UUID (v4)
- File must exist on disk at filePath
- Thumbnail is optional (generated on demand)
- FileSize used for storage quota management
- Photos deleted when feature is deleted

---

### 8. Basemap

Stores basemap sources available to a project.

```sql
CREATE TABLE basemaps (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  name TEXT NOT NULL,
  source_type TEXT NOT NULL, -- osm, mbtiles, raster, vector
  source_url TEXT, -- URL or file path
  is_active INTEGER NOT NULL DEFAULT 0,
  attribution TEXT,
  created_at INTEGER NOT NULL,
  
  UNIQUE(project_id, name),
  FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);
```

**Dart Model:**
```dart
class Basemap {
  final String id;
  final String projectId;
  final String name;
  final BasemapSourceType sourceType;
  final String sourceUrl;
  final bool isActive;
  final String? attribution;
  final DateTime createdAt;

  Basemap({
    required this.id,
    required this.projectId,
    required this.name,
    required this.sourceType,
    required this.sourceUrl,
    this.isActive = false,
    this.attribution,
    required this.createdAt,
  });
}

enum BasemapSourceType {
  osm, // OpenStreetMap
  mbtiles, // Local MBTiles
  raster, // Raster imagery (GeoTIFF, etc.)
  vector, // Vector tiles (Mapbox style)
}
```

**Examples:**
```
1. OpenStreetMap
   - sourceType: osm
   - sourceUrl: "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
   - attribution: "© OpenStreetMap contributors"

2. Offline MBTiles
   - sourceType: mbtiles
   - sourceUrl: "/data/maps/offline.mbtiles"
   - attribution: "Custom dataset"

3. User-provided raster
   - sourceType: raster
   - sourceUrl: "/data/maps/satellite_2024.tif"
```

---

### 9. Sync Queue

Tracks features and photos waiting to be synced.

```sql
CREATE TABLE sync_queue (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  feature_id TEXT,
  photo_id TEXT,
  sync_state TEXT NOT NULL, -- QUEUED, UPLOADING, FAILED
  retry_count INTEGER NOT NULL DEFAULT 0,
  max_retries INTEGER NOT NULL DEFAULT 3,
  error_message TEXT,
  last_attempt_at INTEGER,
  created_at INTEGER NOT NULL,
  
  FOREIGN KEY (project_id) REFERENCES projects(id),
  FOREIGN KEY (feature_id) REFERENCES features(id),
  FOREIGN KEY (photo_id) REFERENCES photos(id)
);

CREATE INDEX idx_sync_queue_project_id ON sync_queue(project_id);
CREATE INDEX idx_sync_queue_sync_state ON sync_queue(sync_state);
```

**Dart Model:**
```dart
class SyncQueueItem {
  final String id;
  final String projectId;
  final String? featureId;
  final String? photoId;
  final SyncState syncState;
  final int retryCount;
  final int maxRetries;
  final String? errorMessage;
  final DateTime? lastAttemptAt;
  final DateTime createdAt;

  SyncQueueItem({
    required this.id,
    required this.projectId,
    this.featureId,
    this.photoId,
    this.syncState = SyncState.queued,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.errorMessage,
    this.lastAttemptAt,
    required this.createdAt,
  });
}
```

**Business Rules:**
- Either featureId or photoId must be non-null (but not both required)
- Retry using exponential backoff: wait = 2^retryCount seconds
- After maxRetries, move to FAILED state (allow manual retry)

---

### 10. Conflict

Stores sync conflicts for user resolution.

```sql
CREATE TABLE conflicts (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  feature_id TEXT NOT NULL,
  conflict_type TEXT NOT NULL, -- update, delete, attribute
  local_data_json TEXT NOT NULL,
  remote_data_json TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  resolved INTEGER NOT NULL DEFAULT 0,
  resolution TEXT, -- local, remote, merge (if merge, include merge data)
  resolved_at INTEGER,
  
  FOREIGN KEY (project_id) REFERENCES projects(id),
  FOREIGN KEY (feature_id) REFERENCES features(id)
);

CREATE INDEX idx_conflicts_project_id ON conflicts(project_id);
CREATE INDEX idx_conflicts_resolved ON conflicts(resolved);
```

**Dart Model:**
```dart
class Conflict {
  final String id;
  final String projectId;
  final String featureId;
  final ConflictType conflictType;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime createdAt;
  final bool resolved;
  final ConflictResolution? resolution;
  final DateTime? resolvedAt;

  Conflict({
    required this.id,
    required this.projectId,
    required this.featureId,
    required this.conflictType,
    required this.localData,
    required this.remoteData,
    required this.createdAt,
    this.resolved = false,
    this.resolution,
    this.resolvedAt,
  });
}

enum ConflictType {
  update, // Both local and remote modified
  delete, // Local deleted, remote still exists
  attribute, // Attribute conflict
}

enum ConflictResolution {
  keepLocal,
  keepRemote,
  merge,
}
```

**Example Conflict:**
```
Feature was edited locally and also updated on cloud:
- Local: damage="moderate", updated_at=2026-08-17 10:00
- Remote: damage="severe", updated_at=2026-08-17 10:05
- User resolves: keepRemote (accept cloud version)
```

---

### 11. App Settings

Key-value store for application preferences.

```sql
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL,
  updated_by TEXT
);
```

**Dart Model:**
```dart
class AppSetting {
  final String key;
  final String value;
  final DateTime updatedAt;
  final String? updatedBy;

  AppSetting({
    required this.key,
    required this.value,
    required this.updatedAt,
    this.updatedBy,
  });
}
```

**Common Settings:**
```
current_user → username (String)
app_language → en, bn, etc. (String)
units_distance → m, km, mi (String)
units_area → m2, ha, acres (String)
theme_mode → light, dark (String)
sync_wifi_only → true/false (Boolean)
```

---

### 12. Project Version History

Tracks changes to project schema and settings.

```sql
CREATE TABLE project_versions (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  version_number TEXT NOT NULL, -- semantic version
  username TEXT NOT NULL,
  timestamp INTEGER NOT NULL,
  change_description TEXT,
  survey_schema_snapshot TEXT, -- full schema at this version
  
  UNIQUE(project_id, version_number),
  FOREIGN KEY (project_id) REFERENCES projects(id),
  FOREIGN KEY (username) REFERENCES users(username)
);
```

**Dart Model:**
```dart
class ProjectVersion {
  final String id;
  final String projectId;
  final String versionNumber;
  final String username;
  final DateTime timestamp;
  final String changeDescription;
  final SurveySchema surveySchemaSnapshot;

  ProjectVersion({
    required this.id,
    required this.projectId,
    required this.versionNumber,
    required this.username,
    required this.timestamp,
    required this.changeDescription,
    required this.surveySchemaSnapshot,
  });
}
```

---

## Survey Schema

The survey schema defines the questions users answer when recording features.

**JSON Format:**
```json
{
  "id": "survey-001",
  "name": "Environmental Assessment",
  "version": "1.0.0",
  "questions": [
    {
      "id": "q1",
      "type": "text",
      "label": "What is the name of the location?",
      "hint": "e.g., 'Park entrance'",
      "required": true
    },
    {
      "id": "q2",
      "type": "select_one",
      "label": "What type of damage is present?",
      "options": [
        {"value": "none", "label": "No damage"},
        {"value": "minor", "label": "Minor"},
        {"value": "moderate", "label": "Moderate"},
        {"value": "severe", "label": "Severe"}
      ],
      "required": true
    },
    {
      "id": "q3",
      "type": "decimal",
      "label": "Area affected (m²)",
      "relevant": "${q2} != 'none'", // Only show if damage exists
      "required": false,
      "validation": {
        "min": 0,
        "max": 10000
      }
    },
    {
      "id": "q4",
      "type": "photo",
      "label": "Take a photo of the damage",
      "relevant": "${q2} != 'none'",
      "required": false
    },
    {
      "id": "q5",
      "type": "calculated",
      "label": "Damage category",
      "calculation": "if(${q2}=='none', 'OK', if(${q3}<10, 'Minor', 'Major'))",
      "required": false
    }
  ],
  "conditionals": [
    {
      "condition": "${q2} != 'none'",
      "show_questions": ["q3", "q4"]
    }
  ]
}
```

**Dart Model:**
```dart
class SurveySchema {
  final String id;
  final String name;
  final String version;
  final List<Question> questions;
  final List<ConditionalLogic> conditionals;

  SurveySchema({
    required this.id,
    required this.name,
    required this.version,
    required this.questions,
    this.conditionals = const [],
  });
}

class Question {
  final String id;
  final QuestionType type;
  final String label;
  final String? hint;
  final bool required;
  final dynamic defaultValue;
  final List<QuestionOption>? options; // for select_one, select_multiple
  final QuestionValidation? validation;
  final String? relevant; // conditional display logic
  final String? calculation; // for calculated fields
  final String? appearance; // UI hint
  final String? help;

  Question({
    required this.id,
    required this.type,
    required this.label,
    this.hint,
    this.required = false,
    this.defaultValue,
    this.options,
    this.validation,
    this.relevant,
    this.calculation,
    this.appearance,
    this.help,
  });
}

enum QuestionType {
  text,
  longText,
  integer,
  decimal,
  yesNo,
  selectOne,
  selectMultiple,
  dropdown,
  date,
  time,
  dateTime,
  photo,
  point,
  line,
  polygon,
  calculated,
  note,
  gpsAccuracy,
  hiddenMetadata,
}

class QuestionOption {
  final String value;
  final String label;

  QuestionOption({
    required this.value,
    required this.label,
  });
}

class QuestionValidation {
  final num? min;
  final num? max;
  final String? pattern; // regex
  final List<String>? allowedValues;

  QuestionValidation({
    this.min,
    this.max,
    this.pattern,
    this.allowedValues,
  });
}
```

---

## Constraints & Validations

| Entity | Constraint | Rule |
|--------|-----------|------|
| User | Primary Key | username |
| User | Pattern | [a-zA-Z0-9_-]+ |
| Project | Unique | (name) per user |
| Project | Semantic Version | X.Y.Z |
| Layer | Unique | (project_id, name) |
| Layer | GeometryType | Immutable after creation |
| Feature | Primary Key | UUID v4 |
| Feature | Geometry | Not null |
| Feature | Accuracy | At least one of H/V required |
| Feature | SyncState | Valid enum value |
| Attribute | Unique | (feature_id, key) |
| Photo | File Exists | filePath must exist |
| Basemap | Unique | (project_id, name) |
| Conflict | Unique | (project_id, feature_id) unresolved |

---

## Indexes for Performance

```sql
-- Feature lookups
CREATE INDEX idx_features_project_id ON features(project_id);
CREATE INDEX idx_features_layer_id ON features(layer_id);
CREATE INDEX idx_features_sync_state ON features(sync_state);
CREATE INDEX idx_features_created_at ON features(created_at);

-- Photo lookups
CREATE INDEX idx_photos_feature_id ON photos(feature_id);
CREATE INDEX idx_photos_project_id ON photos(project_id);

-- Survey responses
CREATE INDEX idx_survey_responses_feature_id ON survey_responses(feature_id);

-- Attributes
CREATE INDEX idx_attributes_feature_id ON attributes(feature_id);

-- Sync queue
CREATE INDEX idx_sync_queue_project_id ON sync_queue(project_id);
CREATE INDEX idx_sync_queue_sync_state ON sync_queue(sync_state);

-- Conflicts
CREATE INDEX idx_conflicts_project_id ON conflicts(project_id);
CREATE INDEX idx_conflicts_resolved ON conflicts(resolved);
```

---

## GeoJSON Export Format

When exporting features, use standard GeoJSON FeatureCollection:

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": "feature-uuid",
      "geometry": {
        "type": "Point",
        "coordinates": [longitude, latitude]
      },
      "properties": {
        "created_by": "alice",
        "created_at": "2026-08-17T10:30:00Z",
        "accuracy_horizontal": 5.2,
        "accuracy_vertical": 2.1,
        "altitude": 125.5,
        "provider": "GPS",
        "damage": "moderate",
        "area_m2": 45.5,
        "requires_repair": true
      }
    }
  ]
}
```

---

## Data Integrity Rules

1. **Referential Integrity**
   - Foreign keys enforced by SQLite
   - Cascade delete where appropriate
   - No orphaned records

2. **Temporal Consistency**
   - createdAt ≤ updatedAt
   - timestamps in UTC
   - syncTimestamp after creation for synced items

3. **Sync Consistency**
   - Feature syncState drives SyncQueueItem state
   - No orphaned queue items
   - Resolved conflicts archived (not deleted)

4. **Uniqueness**
   - Project names unique per user
   - Layer names unique per project
   - Feature IDs globally unique
   - User usernames globally unique

---

## Future Enhancements

- Spatial indexes (R-tree via GeoPackage)
- Full-text search on attributes
- Time-series data (tracking changes over time)
- Compound sync queue items (batch upload)
- Backup/restore snapshots
