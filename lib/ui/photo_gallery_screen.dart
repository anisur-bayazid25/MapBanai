import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mapbanai/services/coordinate_utils.dart';
import 'package:mapbanai/services/photo_store.dart';
import 'package:mapbanai/ui/common/confirm_dialog.dart';
import 'package:mapbanai/ui/common/loading_indicator.dart';

/// Grid of all captured photos with geotag badges, full-screen preview and
/// delete with confirmation.
class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  List<PhotoRecord>? _photos;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final photos = await PhotoStore.list();
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load photos: $e';
      });
    }
  }

  Future<void> _viewPhoto(PhotoRecord record) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _PhotoViewScreen(record: record),
      ),
    );
    if (result == 'delete') {
      await _deletePhoto(record);
    }
  }

  Future<void> _deletePhoto(PhotoRecord record) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete photo',
      message: 'Remove this photo from the device? This cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      destructive: true,
    );
    if (!confirmed) return;
    await PhotoStore.delete(record);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photos'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    final photos = _photos;
    if (photos == null) {
      return const AppLoadingIndicator();
    }
    if (photos.isEmpty) {
      return Center(
        child: Text(
          'No photos yet.\nCapture photos from a survey form to see them here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return InkWell(
          onTap: () => _viewPhoto(photo),
          onLongPress: () => _deletePhoto(photo),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: photo.thumbPath.isNotEmpty
                    ? Image.file(
                        File(photo.thumbPath),
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(photo.path),
                        fit: BoxFit.cover,
                      ),
              ),
              if (photo.isGeotagged)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PhotoViewScreen extends StatelessWidget {
  final PhotoRecord record;

  const _PhotoViewScreen({required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          record.fileName,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          IconButton(
            tooltip: 'Delete photo',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => Navigator.pop(context, 'delete'),
          ),
        ],
      ),
      body: Center(
        child: Image.file(File(record.path), fit: BoxFit.contain),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              record.isGeotagged
                  ? Icons.location_on
                  : Icons.location_off,
              color: record.isGeotagged ? Colors.green : Colors.orange,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.gpsLabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: record.isGeotagged ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (record.latitude != null && record.longitude != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      formatCoordinate(record.latitude!, record.longitude!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    record.gpsStatus == 'none'
                        ? 'No coordinates were available at capture time'
                        : 'Captured ${record.capturedAt.toLocal().toIso8601String()}',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}