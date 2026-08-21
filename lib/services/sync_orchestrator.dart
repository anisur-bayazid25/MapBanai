import 'package:http/http.dart' as http;
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/cloud_sync_service.dart';
import 'package:mapbanai/services/photo_sync_service.dart';

class FullSyncResult {
  final SyncResult data;
  final PhotoSyncResult photos;
  final String? dataError;

  const FullSyncResult({
    required this.data,
    required this.photos,
    this.dataError,
  });

  String get summary {
    final dataPart =
        '${data.responsesSynced} responses, ${data.featuresSynced} features';
    final photoPart = photos.total == 0
        ? 'no photos to sync'
        : '${photos.synced}/${photos.total} photos synced'
            '${photos.skippedOversized > 0 ? ' (${photos.skippedOversized} skipped too large)' : ''}'
            '${photos.failed > 0 ? ' (${photos.failed} failed)' : ''}';
    return '$dataPart, $photoPart';
  }

  bool get hasErrors => dataError != null || photos.failed > 0;
}

class SyncOrchestrator {
  final AppDatabase db;
  final http.Client? client;
  final Future<void> Function(Duration)? delay;
  final int maxPhotoBytes;

  SyncOrchestrator(
    this.db, {
    this.client,
    this.delay,
    this.maxPhotoBytes = PhotoSyncService.defaultMaxBytes,
  });

  /// Runs data sync first, then photo sync, reporting both counts.
  Future<FullSyncResult> syncAll(int projectId) async {
    final dataService = CloudSyncService(db, client: client);
    final photoService = PhotoSyncService(
      db,
      client: client,
      delay: delay,
      maxPhotoBytes: maxPhotoBytes,
    );

    SyncResult dataResult = const SyncResult(responsesSynced: 0, featuresSynced: 0);
    String? dataError;
    try {
      dataResult = await dataService.syncProject(projectId);
    } on CloudSyncException catch (e) {
      dataError = e.message;
    } catch (e) {
      dataError = e.toString();
    }

    PhotoSyncResult photoResult;
    try {
      photoResult = await photoService.syncPhotos(projectId);
    } catch (e) {
      photoResult = PhotoSyncResult(
        total: 0,
        synced: 0,
        failed: 0,
        skippedOversized: 0,
      );
      dataError ??= e.toString();
    }

    return FullSyncResult(
      data: dataResult,
      photos: photoResult,
      dataError: dataError,
    );
  }
}
