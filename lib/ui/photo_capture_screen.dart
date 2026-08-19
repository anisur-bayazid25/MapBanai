import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mapbanai/services/location_service.dart';
import 'package:mapbanai/services/photo_store.dart';

/// Camera/gallery capture that geotags the photo when a GPS fix is available
/// and the image format allows it (JPEG). Pops with the saved [PhotoRecord].
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

  Future<Position?> _captureLocation() async {
    final granted = await _locationService.ensurePermission();
    if (!granted) return null;
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _capture(ImageSource source) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'Getting GPS fix…';
      _accuracy = null;
    });

    final position = await _captureLocation();
    if (position != null) {
      setState(() {
        _accuracy = position.accuracy;
      });
    }
    if (position == null) {
      setState(() {
        _status = 'No GPS fix — photo will not be geotagged';
      });
    }

    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 92,
        requestFullMetadata: true,
      );
    } catch (_) {
      picked = null;
    }

    if (picked == null) {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = null;
        });
      }
      return;
    }

    try {
      final bytes = await picked.readAsBytes();
      final record = await PhotoStore.save(
        bytes,
        latitude: position?.latitude,
        longitude: position?.longitude,
        altitude: position?.altitude,
      );
      if (!mounted) return;
      setState(() {
        _record = record;
        _busy = false;
        _status = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _record = null;
        _status = 'Failed to store photo: $e';
      });
    }
  }

  Future<void> _retake() async {
    setState(() {
      _record = null;
    });
  }

  Future<void> _save() async {
    final record = _record;
    if (record == null) return;
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
                  _status ?? 'The photo is saved with GPS coordinates '
                      'embedded in the image when possible.',
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
                        color: record.isGeotagged ? Colors.green.shade800 : Colors.orange.shade800,
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
                        color: record.isGeotagged ? Colors.green.shade700 : Colors.orange.shade700,
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
                onPressed: _save,
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