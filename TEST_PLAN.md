# MapBanai - Test Plan

**Version:** 1.0.0  
**Last Updated:** 2026-08-17  
**Strategy:** Test-Driven Development (TDD) with focus on data integrity and offline resilience

---

## Testing Overview

### Test Pyramid

```
           ▲
          /│\      E2E Tests (10%)
         / │ \     - Full app workflows
        ───────   - Device testing
       /    │    \
      /   Integration Tests (30%)
     /      │      \ - Multi-component
    ─────────────── - Database + Location
   /         │       \
  /   Unit Tests (60%)  \
 /           │            \ - Isolated logic
───────────────────────────   - Services, Repositories
 Controllers  Services  Models
```

**Target Coverage:** >85% overall

---

## Unit Tests

### Database Layer Tests

**File:** `test/unit/database/`

#### Project DAO Tests
- [ ] `test_project_create` - Insert new project
- [ ] `test_project_read` - Retrieve project by ID
- [ ] `test_project_update` - Update project fields
- [ ] `test_project_list` - Get all projects
- [ ] `test_project_delete_soft` - Soft delete (is_archived)
- [ ] `test_project_unique_name_per_user` - Constraint validation
- [ ] `test_project_version_increment` - Version tracking
- [ ] `test_project_export_data` - Get all related data
- [ ] `test_project_cascade_delete` - Delete with layers/features

#### Feature DAO Tests
- [ ] `test_feature_create_point` - Insert point feature
- [ ] `test_feature_create_line` - Insert line feature
- [ ] `test_feature_create_polygon` - Insert polygon feature
- [ ] `test_feature_read` - Retrieve feature by ID
- [ ] `test_feature_list_by_project` - Query by project
- [ ] `test_feature_list_by_layer` - Query by layer
- [ ] `test_feature_query_bbox` - Spatial query (bounding box)
- [ ] `test_feature_update_geometry` - Update feature geometry
- [ ] `test_feature_update_attributes` - Update feature attributes
- [ ] `test_feature_update_sync_state` - Track sync state
- [ ] `test_feature_soft_delete` - Mark as deleted
- [ ] `test_feature_accuracy_storage` - Store accuracy values
- [ ] `test_feature_lineage` - Track created_by, updated_by

#### Attribute Tests
- [ ] `test_attribute_create` - Insert attribute
- [ ] `test_attribute_get_by_feature` - Query by feature
- [ ] `test_attribute_update_value` - Update attribute value
- [ ] `test_attribute_delete` - Remove attribute
- [ ] `test_attribute_unique_key_per_feature` - Constraint

#### Photo Tests
- [ ] `test_photo_create` - Insert photo record
- [ ] `test_photo_get_by_feature` - Query by feature
- [ ] `test_photo_get_by_project` - Query by project
- [ ] `test_photo_update_sync_state` - Track sync state
- [ ] `test_photo_delete` - Remove photo record
- [ ] `test_photo_cascade_delete_on_feature_delete` - Cascade

#### Survey Response Tests
- [ ] `test_response_create` - Insert answer
- [ ] `test_response_get_by_feature` - Query by feature
- [ ] `test_response_update` - Update answer
- [ ] `test_response_unique_question_per_feature` - Constraint

#### Sync Queue Tests
- [ ] `test_sync_queue_add_feature` - Queue for upload
- [ ] `test_sync_queue_add_photo` - Queue photo
- [ ] `test_sync_queue_get_pending` - Query by state
- [ ] `test_sync_queue_update_state` - Change sync state
- [ ] `test_sync_queue_increment_retry` - Track retries
- [ ] `test_sync_queue_remove_on_success` - Cleanup
- [ ] `test_sync_queue_max_retries` - Retry limit

#### Conflict Tests
- [ ] `test_conflict_create` - Insert conflict
- [ ] `test_conflict_get_unresolved` - Query by project
- [ ] `test_conflict_resolve` - Mark as resolved
- [ ] `test_conflict_archive` - Keep resolved conflicts

#### Transaction Tests
- [ ] `test_transaction_rollback_on_constraint` - Fail atomically
- [ ] `test_transaction_all_or_nothing` - Atomicity
- [ ] `test_concurrent_writes_isolation` - Concurrency

---

### Service Layer Tests

**File:** `test/unit/services/`

#### Location Service Tests
- [ ] `test_location_permission_request` - Request location permission
- [ ] `test_location_permission_denied` - Handle denial
- [ ] `test_location_get_current` - Get single location
- [ ] `test_location_stream_updates` - Listen for updates
- [ ] `test_location_accuracy_extraction` - Parse accuracy
- [ ] `test_location_provider_detection` - Detect GPS/GLONASS/etc
- [ ] `test_location_timeout` - Handle timeout
- [ ] `test_location_error_handling` - Catch exceptions

#### GNSS Service Tests
- [ ] `test_gnss_get_satellites_visible` - Visible satellite count
- [ ] `test_gnss_get_satellites_used` - Used satellite count
- [ ] `test_gnss_get_constellation` - Identify constellation
- [ ] `test_gnss_get_signal_strength` - Signal level
- [ ] `test_gnss_parse_nmea` - NMEA sentence parsing (if applicable)

#### Accuracy Filter Service Tests
- [ ] `test_filter_accuracy_pass` - Acceptable accuracy
- [ ] `test_filter_accuracy_fail` - Below threshold
- [ ] `test_filter_wait_timeout` - Max wait exceeded
- [ ] `test_filter_update_settings` - Change filter values
- [ ] `test_filter_no_filter_option` - Disable filter

#### Survey Service Tests
- [ ] `test_survey_schema_validation` - Valid schema
- [ ] `test_survey_schema_invalid_question` - Invalid structure
- [ ] `test_survey_parse_json` - Parse schema from JSON
- [ ] `test_survey_question_validation` - Required fields
- [ ] `test_survey_answer_validation` - Answer matches type
- [ ] `test_survey_conditional_evaluation` - Show/hide logic
- [ ] `test_survey_calculation_evaluation` - Computed values
- [ ] `test_survey_conditional_complex` - Nested conditions
- [ ] `test_survey_export_json` - Export to JSON

#### Accuracy Filter Service Tests
- [ ] `test_filter_check_passes` - Acceptable accuracy
- [ ] `test_filter_check_fails` - Below threshold
- [ ] `test_filter_get_required_accuracy` - Return setting
- [ ] `test_filter_get_max_wait_time` - Return setting
- [ ] `test_filter_update_settings` - Change settings

#### Export Service Tests
- [ ] `test_export_geojson_single_feature` - Point export
- [ ] `test_export_geojson_multiple_features` - Multi-feature
- [ ] `test_export_geojson_with_attributes` - Include properties
- [ ] `test_export_csv_headers` - CSV column headers
- [ ] `test_export_csv_data` - CSV row data
- [ ] `test_export_csv_escaping` - Handle special chars
- [ ] `test_export_kml` - KML format
- [ ] `test_export_gpx` - GPX format

#### Import Service Tests
- [ ] `test_import_geojson_valid` - Valid GeoJSON
- [ ] `test_import_geojson_invalid` - Invalid structure
- [ ] `test_import_geojson_unknown_type` - Unknown geometry type
- [ ] `test_import_csv_mapping` - Map columns to attributes
- [ ] `test_import_csv_type_conversion` - Parse numbers/dates
- [ ] `test_import_project_zip` - Extract project package
- [ ] `test_import_project_schema_validation` - Validate after import

#### Camera Service Tests
- [ ] `test_camera_take_picture` - Capture photo
- [ ] `test_camera_permission_request` - Request camera permission
- [ ] `test_camera_save_to_disk` - Save photo file
- [ ] `test_camera_compress_image` - Compress for storage
- [ ] `test_camera_generate_thumbnail` - Create thumbnail
- [ ] `test_camera_error_handling` - Handle capture errors

#### Map Service Tests
- [ ] `test_map_load_basemap` - Load OSM tiles
- [ ] `test_map_add_layer` - Add feature layer
- [ ] `test_map_set_visibility` - Toggle layer visibility
- [ ] `test_map_fit_bounds` - Zoom to features
- [ ] `test_map_animate_location` - Pan to location
- [ ] `test_map_offline_mbtiles` - Load offline tiles

---

### Repository Layer Tests

**File:** `test/unit/repository/`

#### Project Repository Tests
- [ ] `test_create_project` - Insert new project
- [ ] `test_get_projects` - List all projects
- [ ] `test_get_project_by_id` - Retrieve specific project
- [ ] `test_update_project` - Modify project
- [ ] `test_archive_project` - Soft delete
- [ ] `test_export_project_zip` - Export with all data
- [ ] `test_import_project_zip` - Import from ZIP
- [ ] `test_duplicate_project` - Clone existing project

#### Feature Repository Tests
- [ ] `test_create_feature_point` - Create point
- [ ] `test_create_feature_line` - Create line
- [ ] `test_create_feature_polygon` - Create polygon
- [ ] `test_get_features_by_project` - List project features
- [ ] `test_get_features_by_layer` - List layer features
- [ ] `test_get_features_by_bounds` - Spatial query
- [ ] `test_update_feature` - Modify feature
- [ ] `test_delete_feature` - Soft delete
- [ ] `test_attach_photo_to_feature` - Link photo
- [ ] `test_save_survey_responses` - Store answers

#### User Repository Tests
- [ ] `test_get_current_user` - Get active user
- [ ] `test_set_current_user` - Switch user
- [ ] `test_list_users` - Get all users
- [ ] `test_add_user` - Create new user
- [ ] `test_delete_user` - Remove user
- [ ] `test_user_not_found` - Handle missing user

#### Sync Repository Tests
- [ ] `test_get_sync_provider` - Retrieve provider
- [ ] `test_set_sync_provider` - Store provider config
- [ ] `test_queue_feature_for_sync` - Add to queue
- [ ] `test_get_sync_queue` - Retrieve pending
- [ ] `test_mark_synced` - Update state on success
- [ ] `test_handle_sync_error` - Store error message
- [ ] `test_get_conflicts` - Retrieve unresolved
- [ ] `test_resolve_conflict` - Apply resolution

---

### Utility & Helper Tests

**File:** `test/unit/utils/`

#### GIS Utilities Tests
- [ ] `test_distance_two_points` - Haversine distance
- [ ] `test_distance_point_to_line` - Perpendicular distance
- [ ] `test_polygon_area` - Shoelace formula
- [ ] `test_polygon_perimeter` - Line segment sum
- [ ] `test_bbox_contains_point` - Point-in-bbox
- [ ] `test_bbox_intersection` - Two bbox overlap
- [ ] `test_coordinate_conversion` - DMS ↔ decimal
- [ ] `test_bearing_calculation` - Angle between points

#### Formatter Tests
- [ ] `test_format_distance_m` - Format meters
- [ ] `test_format_distance_km` - Format kilometers
- [ ] `test_format_distance_mi` - Format miles
- [ ] `test_format_area_m2` - Format square meters
- [ ] `test_format_area_hectares` - Format hectares
- [ ] `test_format_area_acres` - Format acres
- [ ] `test_format_date_locale` - Localize date
- [ ] `test_format_time_locale` - Localize time

#### Validator Tests
- [ ] `test_validate_username` - Username format
- [ ] `test_validate_email` - Email format
- [ ] `test_validate_number_range` - Number min/max
- [ ] `test_validate_text_required` - Required field
- [ ] `test_validate_text_pattern` - Regex validation
- [ ] `test_validate_date_format` - Date parsing

---

## Integration Tests

**File:** `test/integration/`

### Location & GNSS Workflow
- [ ] `test_record_point_single_location` - Record point
- [ ] `test_record_point_accuracy_filter` - Accuracy validation
- [ ] `test_record_point_accept_after_wait` - Wait for good fix
- [ ] `test_record_point_save_anyway` - Override accuracy
- [ ] `test_record_point_cancel_aborts` - Discard recording
- [ ] `test_gnss_constellation_detection` - Multiple satellites
- [ ] `test_location_indoor_vs_outdoor` - Accuracy differences

### Survey Recording Workflow
- [ ] `test_record_point_with_survey` - Point + form
- [ ] `test_survey_conditional_show_hide` - Display logic
- [ ] `test_survey_calculation_results` - Computed fields
- [ ] `test_survey_validation_required_field` - Missing required
- [ ] `test_survey_validation_number_range` - Min/max
- [ ] `test_survey_required_photo` - Photo required
- [ ] `test_survey_answer_persistence` - Save to database

### Line Recording Workflow
- [ ] `test_record_line_auto_vertices` - Auto-collection
- [ ] `test_record_line_minimum_distance` - Vertex filtering
- [ ] `test_record_line_minimum_interval` - Time-based filtering
- [ ] `test_record_line_pause_resume` - Pause/resume
- [ ] `test_record_line_cancel_discards` - Abort recording
- [ ] `test_record_line_statistics` - Distance/time updates
- [ ] `test_record_line_accuracy_constraint` - Max accuracy

### Polygon Recording Workflow
- [ ] `test_record_polygon_auto_vertices` - Auto-collection
- [ ] `test_record_polygon_undo_vertex` - Remove last vertex
- [ ] `test_record_polygon_minimum_vertices` - Require 3+
- [ ] `test_record_polygon_auto_close` - Close on finish
- [ ] `test_record_polygon_area_perimeter` - Statistics
- [ ] `test_record_polygon_pause_resume` - Pause/resume
- [ ] `test_record_polygon_cancel_discards` - Abort

### Photo Workflow
- [ ] `test_attach_photo_to_point` - Photo + point
- [ ] `test_attach_multiple_photos` - Multi-photo
- [ ] `test_photo_thumbnail_generation` - Create thumbnail
- [ ] `test_photo_disk_storage` - Save to app directory
- [ ] `test_photo_attachment_persistence` - Store reference
- [ ] `test_photo_export_with_feature` - Include in export
- [ ] `test_photo_deletion` - Remove photo

### Data Export Workflow
- [ ] `test_export_single_feature_geojson` - Export point
- [ ] `test_export_project_features_geojson` - Export all
- [ ] `test_export_includes_attributes` - Include properties
- [ ] `test_export_includes_photos` - Bundle photos
- [ ] `test_export_to_csv` - CSV format
- [ ] `test_export_to_kml` - KML format
- [ ] `test_export_to_gpx` - GPX format
- [ ] `test_export_project_zip` - Complete package

### Data Import Workflow
- [ ] `test_import_geojson_creates_features` - Import points
- [ ] `test_import_geojson_creates_layers` - Layer creation
- [ ] `test_import_csv_with_mapping` - Map columns
- [ ] `test_import_project_zip_creates_all` - Full restoration
- [ ] `test_import_project_zip_validates_schema` - Validation
- [ ] `test_import_project_zip_handles_conflicts` - Existing data
- [ ] `test_import_maintains_data_integrity` - All data preserved

### Offline-First Workflow
- [ ] `test_record_point_offline` - No network
- [ ] `test_record_features_offline` - Multiple offline
- [ ] `test_queue_for_sync_offline` - Queued state
- [ ] `test_resume_sync_on_network` - Retry when online
- [ ] `test_sync_preserves_local_data` - Never delete local
- [ ] `test_offline_map_rendering` - Offline basemap
- [ ] `test_offline_photo_storage` - Local photo storage

### Sync Workflow
- [ ] `test_sync_single_feature` - Upload point
- [ ] `test_sync_multiple_features` - Batch upload
- [ ] `test_sync_with_photos` - Upload photos
- [ ] `test_sync_authentication` - OAuth/credentials
- [ ] `test_sync_progress_tracking` - Status updates
- [ ] `test_sync_network_error_retry` - Retry logic
- [ ] `test_sync_quota_exceeded` - Handle quota
- [ ] `test_sync_conflict_detection` - Detect conflicts
- [ ] `test_sync_conflict_resolution` - Resolve conflicts
- [ ] `test_sync_state_transitions` - State flow
- [ ] `test_sync_does_not_block_local_recording` - Async sync

### Conflict Resolution Workflow
- [ ] `test_conflict_local_vs_remote_update` - Conflicting edits
- [ ] `test_conflict_keep_local` - Use local version
- [ ] `test_conflict_keep_remote` - Use remote version
- [ ] `test_conflict_merge` - Combine versions
- [ ] `test_conflict_multiple_features` - Many conflicts
- [ ] `test_conflict_resolution_updates_sync_queue` - Re-queue after
- [ ] `test_conflict_archived_after_resolution` - Record resolution

### Project Management Workflow
- [ ] `test_create_project_new` - Create from scratch
- [ ] `test_open_project_existing` - Load project
- [ ] `test_switch_project` - Change active project
- [ ] `test_archive_project` - Mark inactive
- [ ] `test_duplicate_project` - Clone with data
- [ ] `test_project_gps_settings` - Configure accuracy
- [ ] `test_project_sync_settings` - Configure cloud sync

### GIS Editing Workflow
- [ ] `test_select_point_on_map` - Tap to select
- [ ] `test_move_point` - Drag point
- [ ] `test_edit_line_vertices` - Modify line
- [ ] `test_edit_polygon_vertices` - Modify polygon
- [ ] `test_add_polygon_vertex` - Insert vertex
- [ ] `test_delete_polygon_vertex` - Remove vertex
- [ ] `test_edit_feature_attributes` - Modify properties
- [ ] `test_undo_edit` - Undo operation
- [ ] `test_redo_edit` - Redo operation

---

## Widget/UI Tests

**File:** `test/widget/`

### Screen Tests
- [ ] `test_home_screen_renders` - Initial load
- [ ] `test_home_screen_survey_mode_button` - Navigation
- [ ] `test_home_screen_gis_mode_button` - Navigation
- [ ] `test_survey_list_screen_empty` - No projects
- [ ] `test_survey_list_screen_with_projects` - Show list
- [ ] `test_survey_list_screen_project_selection` - Tap project
- [ ] `test_point_record_screen_renders` - Initial load
- [ ] `test_point_record_screen_accuracy_display` - Show accuracy
- [ ] `test_line_record_screen_distance_update` - Live statistics
- [ ] `test_polygon_record_screen_area_update` - Live statistics
- [ ] `test_map_screen_renders` - Map loads
- [ ] `test_map_screen_features_display` - Show features
- [ ] `test_gis_mode_layer_control` - Layer visibility
- [ ] `test_gis_mode_basemap_selector` - Switch basemap
- [ ] `test_settings_screen_renders` - Load settings
- [ ] `test_settings_user_dropdown` - Switch user
- [ ] `test_settings_language_selection` - Change language

### Form Tests
- [ ] `test_survey_form_renders_all_questions` - Display form
- [ ] `test_survey_form_text_input` - Type text
- [ ] `test_survey_form_number_input` - Enter number
- [ ] `test_survey_form_select_one_option` - Choose option
- [ ] `test_survey_form_select_multiple_options` - Multi-select
- [ ] `test_survey_form_required_validation` - Missing required
- [ ] `test_survey_form_conditional_display` - Show/hide based on logic
- [ ] `test_survey_form_calculate_field` - Computed value display
- [ ] `test_survey_form_photo_attachment` - Add photo
- [ ] `test_survey_form_submission` - Save form

### Component Tests
- [ ] `test_accuracy_display_widget_renders` - Show accuracy
- [ ] `test_satellite_indicator_updates` - Show satellites
- [ ] `test_gps_status_indicator_renders` - Show status
- [ ] `test_location_indicator_markers` - Map marker
- [ ] `test_button_disabled_state` - Inactive button
- [ ] `test_dialog_confirmation` - Show dialog
- [ ] `test_loading_indicator_animates` - Progress animation

---

## Device/E2E Tests

**File:** `test/e2e/`

### Complete User Workflows
- [ ] `test_full_survey_mode_workflow` - End-to-end survey
- [ ] `test_full_gis_mode_workflow` - End-to-end GIS
- [ ] `test_full_point_recording` - Record point workflow
- [ ] `test_full_line_recording` - Record line workflow
- [ ] `test_full_polygon_recording` - Record polygon workflow
- [ ] `test_full_sync_workflow` - Sync with cloud
- [ ] `test_full_export_import_workflow` - Export & re-import
- [ ] `test_offline_then_sync` - Offline → sync
- [ ] `test_conflict_scenario` - Conflict resolution
- [ ] `test_large_dataset_performance` - Many features

### Device-Specific Tests
- [ ] `test_on_small_phone` - 4.5" screen
- [ ] `test_on_large_tablet` - 10" screen
- [ ] `test_landscape_orientation` - Rotate device
- [ ] `test_portrait_orientation` - Restore portrait
- [ ] `test_weak_gps_signal` - Poor accuracy
- [ ] `test_no_internet` - Offline mode
- [ ] `test_slow_network` - Slow sync
- [ ] `test_app_pause_resume` - Background/foreground

---

## Test Data & Fixtures

### Mock Data Generators

**File:** `test/fixtures/`

```dart
// User fixtures
final testUser = User(
  username: 'alice',
  createdAt: DateTime(2026, 8, 17),
  isActive: true,
);

// Project fixtures
final testProject = Project(
  id: 'proj-001',
  name: 'Environmental Survey',
  description: 'Test project',
  creator: 'alice',
  ...
);

// Survey schema fixtures
final testSurveySchema = SurveySchema(
  id: 'survey-001',
  questions: [
    Question(
      id: 'q1',
      type: QuestionType.text,
      label: 'Name',
      required: true,
    ),
    ...
  ],
);

// Feature fixtures
final testPoint = Feature(
  id: 'feature-001',
  geometry: Point(latitude: 10.5, longitude: 20.5),
  ...
);

final testLine = Feature(
  id: 'feature-002',
  geometry: LineString(vertices: [...]),
  ...
);

// Location fixtures
final testLocation = Location(
  latitude: 10.5,
  longitude: 20.5,
  accuracy: 5.2,
  provider: 'GPS',
  ...
);
```

### Database Test Setup

```dart
// Drift testing setup
Future<AppDatabase> createTestDatabase() async {
  return AppDatabase(testExecutor());
}

// Clear database between tests
setUp(() async {
  db = await createTestDatabase();
});

tearDown(() async {
  await db.close();
});
```

---

## Continuous Integration

### GitHub Actions Workflow

**File:** `.github/workflows/test.yml`

```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
```

---

## Test Execution Commands

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/database/project_dao_test.dart

# Run tests matching pattern
flutter test --name "location"

# Run with reporter
flutter test --reporter=expanded

# Watch mode (re-run on changes)
flutter test --watch
```

---

## Coverage Goals

| Category | Target |
|----------|--------|
| Overall | >85% |
| Database Layer | >95% |
| Repository Layer | >90% |
| Service Layer | >85% |
| BLoC/State | >80% |
| UI Widgets | >70% |
| Utils/Helpers | >90% |

---

## Test Review Checklist

Before merging, verify:
- [ ] All new code has tests
- [ ] Tests pass locally: `flutter test`
- [ ] Coverage maintained/improved
- [ ] No flaky tests (run 3x)
- [ ] Integration tests pass
- [ ] Device tests pass (if applicable)
- [ ] No console warnings
- [ ] Documentation updated

---

## Known Issues & Workarounds

### Android Emulator
- Location service may not work in emulator
- **Workaround:** Use `sendUserSims`  or physical device

### Map Library Testing
- MapLibre rendering difficult to test
- **Workaround:** Test via integration tests on device

### Sync Testing
- Requires network
- **Workaround:** Use HTTP mocking (Mockito, DIO)

---

## Performance Benchmarks

| Operation | Target | Actual |
|-----------|--------|--------|
| App startup | <3s | TBD |
| Load 1000 features | <500ms | TBD |
| Export GeoJSON (100 features) | <1s | TBD |
| Import GeoJSON (100 features) | <2s | TBD |
| Sync 100 features | <30s | TBD |
| Map pan/zoom (60fps) | 60fps | TBD |

---

## Test Maintenance

- Review and update tests quarterly
- Refactor flaky tests immediately
- Update test data as app evolves
- Keep test documentation current
- Monitor test execution time
- Archive obsolete tests
