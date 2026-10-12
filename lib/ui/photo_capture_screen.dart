import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbanai/services/geotag_writer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mapbanai/services/location_service.dart';
import 'package:mapbanai/services/photo_store.dart';

/// Field capture only returns photos with verified GPS embedded in the image.
class PhotoCaptureScreen extends StatefulWidget {
  const PhotoCaptureScreen({super.key});

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  final LocationService _locationService = LocationService();

  PhotoRecord? _record;
  bool _busy = false;
  String? _status;
  double? _accuracy;

  Uint8List? _pendingBytes;
  ImageSource? _pendingSource;
  DateTime? _capturedAt;

  Future<void> _capture(ImageSource source) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'Opening photo picker…';
      _accuracy = null;
    });
    try {
      // The fresh fix is acquired AFTER returning from the external camera.
      // A fix acquired before opening it can be minutes old by capture time.
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 92,
        requestFullMetadata: true,
      );
      if (!mounted) return;
      if (picked == null) {
        setState(() {
          _busy = false;
          _status = null;
        });
        return;
      }
      _pendingBytes = await picked.readAsBytes();
      _pendingSource = source;
      _capturedAt = DateTime.now();
      if (!mounted) return;
      await _storePendingPhoto();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status =
            'Photo could not be captured. Allow camera/photos permission and retry. $e';
      });
    }
  }

  Future<void> _storePendingPhoto() async {
    final bytes = _pendingBytes;
    if (bytes == null) return;
    setState(() {
      _busy = true;
      _status = 'Getting fresh GPS coordinates… Accuracy will be recorded.';
    });
    try {
      Position? position;
      // Existing valid gallery coordinates describe where the photo was taken.
      // Fresh camera captures always use the current field GPS fix.
      if (_pendingSource == ImageSource.camera ||
          !GeotagWriter.hasEmbeddedGps(bytes)) {
        position = await _locationService.getPhotoFix();
      }
      if (!mounted) return;
      final record = await PhotoStore.saveGeotagged(
        bytes,
        latitude: position?.latitude,
        longitude: position?.longitude,
        altitude:
            position?.altitude.isFinite == true ? position!.altitude : null,
        capturedAt: _capturedAt,
        accuracy: position?.accuracy,
        gpsFixedAt: position?.timestamp,
        preserveExistingGps: _pendingSource == ImageSource.gallery,
      );
      if (!mounted) return;
      setState(() {
        _record = record;
        _pendingBytes = null;
        _pendingSource = null;
        _accuracy = record.accuracy;
        _busy = false;
        _status = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _record = null;
        _status =
            'Photo is waiting for GPS and has not been saved. Stay at the photo location. $e';
      });
    }
  }

  Future<void> _retake() async {
    final previous = _record;
    setState(() {
      _record = null;
      _accuracy = null;
      _status = null;
    });
    if (previous != null) await PhotoStore.delete(previous);
  }

  Future<void> _save() async {
    final record = _record;
    if (record == null || !record.isGeotagged) return;
    Navigator.of(context).pop(record);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Photo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _record != null ? _buildPreview() : _buildCaptureUi(),
      ),
    );
  }

  Widget _buildCaptureUi() {
    return Column(
      children: [
        if (_accuracy != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed, color: Colors.green, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'GPS fix ready · ±${_accuracy!.round()} m — photo will be '
                    'geotagged',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_camera_back_outlined,
                  size: 72,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  _status ??
                      'Every photo must contain GPS coordinates. '
                          'Stay at the photo location until GPS is confirmed. '
                          'Gallery photos keep their existing GPS when valid.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
        if (_busy) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
        ],
        if (_pendingBytes != null) ...[
          FilledButton.icon(
            onPressed: _busy ? null : _storePendingPhoto,
            icon: const Icon(Icons.gps_fixed),
            label: const Text('Retry GPS for selected photo'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _busy ? null : () => Geolocator.openAppSettings(),
            child: const Text('Open app permission settings'),
          ),
          TextButton(
            onPressed: _busy ? null : () => Geolocator.openLocationSettings(),
            child: const Text('Open device location settings'),
          ),
        ],
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _capture(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Open camera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _capture(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final record = _record!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(record.path),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: record.isGeotagged
                ? Colors.green.shade50
                : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: record.isGeotagged
                  ? Colors.green.shade200
                  : Colors.orange.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                record.isGeotagged ? Icons.location_on : Icons.location_off,
                color: record.isGeotagged ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.isGeotagged ? 'Geotagged' : 'Not geotagged',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: record.isGeotagged
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.latitude != null && record.longitude != null
                          ? '${record.latitude!.toStringAsFixed(6)}, '
                              '${record.longitude!.toStringAsFixed(6)}'
                          : 'No coordinates available',
                      style: TextStyle(
                        fontSize: 12,
                        color: record.isGeotagged
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.gpsLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      record.accuracy == null
                          ? 'GPS accuracy: unavailable'
                          : 'GPS accuracy: ±${record.accuracy!.round()} m',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _retake,
                icon: const Icon(Icons.replay_outlined),
                label: const Text('Retake'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: record.isGeotagged ? _save : null,
                icon: const Icon(Icons.check_outlined),
                label: const Text('Use photo'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
