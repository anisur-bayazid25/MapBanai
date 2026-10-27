import 'package:mapbanai/l10n/ui_text.dart';
import 'package:mapbanai/ui/common/responsive.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mapbanai/services/geometry_service.dart';
import 'package:mapbanai/services/photo_store.dart';
import 'package:mapbanai/ui/photo_capture_screen.dart';

/// Result of the post-capture feature detail sheet.
class FeatureDetailResult {
  final String id;
  final String name;
  final String notes;
  final PhotoRecord? photo;
  final Map<String, String> fieldValues;

  const FeatureDetailResult({
    required this.id,
    required this.name,
    required this.notes,
    this.photo,
    this.fieldValues = const {},
  });
}

/// Bottom sheet shown after a point/line/polygon is finished drawing.
///
/// Shows the captured geometry summary plus camera options and ID/name/notes
/// fields the user can fill in before the feature is persisted.
Future<FeatureDetailResult?> showFeatureDetailSheet(
  BuildContext context, {
  required String featureType,
  double? latitude,
  double? longitude,
  double? accuracyM,
  List<({double lat, double lon})>? vertices,
  List<String> fields = const [],
  String? initialId,
  String? initialName,
  String? initialNotes,
  Map<String, String> initialFieldValues = const {},
}) {
  final suggestedId = initialId ?? _suggestId(featureType);
  return showModalBottomSheet<FeatureDetailResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _FeatureDetailSheet(
        featureType: featureType,
        latitude: latitude,
        longitude: longitude,
        accuracyM: accuracyM,
        vertices: vertices,
        suggestedId: suggestedId,
        fields: fields,
        initialName: initialName,
        initialNotes: initialNotes,
        initialFieldValues: initialFieldValues,
      ),
    ),
  );
}

String _suggestId(String featureType) {
  final now = DateTime.now();
  final prefix = switch (featureType) {
    'line' => 'LN',
    'polygon' => 'PG',
    _ => 'PT',
  };
  final date = '${now.year}${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}';
  final time = '${now.hour.toString().padLeft(2, '0')}'
      '${now.minute.toString().padLeft(2, '0')}';
  return '$prefix-$date-$time';
}

class _FeatureDetailSheet extends StatefulWidget {
  final String featureType;
  final double? latitude;
  final double? longitude;
  final double? accuracyM;
  final List<({double lat, double lon})>? vertices;
  final String suggestedId;
  final List<String> fields;
  final String? initialName;
  final String? initialNotes;
  final Map<String, String> initialFieldValues;

  const _FeatureDetailSheet({
    required this.featureType,
    required this.suggestedId,
    this.latitude,
    this.longitude,
    this.accuracyM,
    this.vertices,
    this.fields = const [],
    this.initialName,
    this.initialNotes,
    this.initialFieldValues = const {},
  });

  @override
  State<_FeatureDetailSheet> createState() => _FeatureDetailSheetState();
}

class _FeatureDetailSheetState extends State<_FeatureDetailSheet> {
  late final TextEditingController _id;
  late final TextEditingController _name;
  late final TextEditingController _notes;
  late final Map<String, TextEditingController> _fieldControllers;
  PhotoRecord? _photo;

  @override
  void initState() {
    super.initState();
    _id = TextEditingController(text: widget.suggestedId);
    _name = TextEditingController(text: widget.initialName ?? '');
    _notes = TextEditingController(text: widget.initialNotes ?? '');
    _fieldControllers = {
      for (final field in widget.fields)
        field: TextEditingController(
          text: widget.initialFieldValues[field] ?? '',
        ),
    };
  }

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _notes.dispose();
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    final record = await Navigator.of(context).push<PhotoRecord>(
      MaterialPageRoute(builder: (_) => const PhotoCaptureScreen()),
    );
    if (record != null && mounted) {
      setState(() {
        _photo = record;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ui(context, '{v0}{v1} details', [
                widget.featureType[0].toUpperCase(),
                widget.featureType.substring(1)
              ]),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            _buildGeometrySummary(),
            const SizedBox(height: 16),
            _buildPhotoSection(),
            const SizedBox(height: 16),
            TextField(
              controller: _id,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: ui(context, 'ID'),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: ui(context, 'Name (optional)'),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: ui(context, 'Notes (optional)'),
                alignLabelWithHint: true,
              ),
            ),
            if (widget.fields.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                ui(context, 'Custom fields'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              for (final field in widget.fields) ...[
                TextField(
                  controller: _fieldControllers[field],
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: field,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
            const SizedBox(height: 16),
            ResponsiveGrid(
              minChildWidth: 180,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(ui(context, 'Discard')),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(
                    FeatureDetailResult(
                      id: _id.text.trim(),
                      name: _name.text.trim(),
                      notes: _notes.text.trim(),
                      photo: _photo,
                      fieldValues: {
                        for (final field in widget.fields)
                          if (_fieldControllers[field]!.text.trim().isNotEmpty)
                            field: _fieldControllers[field]!.text.trim(),
                      },
                    ),
                  ),
                  icon: const Icon(Icons.check),
                  label: Text(ui(context, 'Save feature')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeometrySummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: switch (widget.featureType) {
        'line' => _lineSummary(),
        'polygon' => _polygonSummary(),
        _ => _pointSummary(),
      },
    );
  }

  Widget _pointSummary() {
    final lat = widget.latitude;
    final lon = widget.longitude;
    if (lat == null || lon == null) {
      return Text(
        ui(context, 'Point'),
        style: TextStyle(color: Colors.teal.shade800),
      );
    }
    return Text(
      ui(context, 'Point\n{v0}, {v1}{v2}', [
        lat,
        lon,
        widget.accuracyM == null
            ? ''
            : '\naccuracy: ±${widget.accuracyM!.toStringAsFixed(1)} m'
      ]),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.teal.shade800,
      ),
    );
  }

  Widget _lineSummary() {
    final vertices = widget.vertices ?? const [];
    if (vertices.length < 2) {
      return Text(
        ui(context, 'Line'),
        style: TextStyle(color: Colors.teal.shade800),
      );
    }
    final length = GeometryService.polylineLengthM(vertices);
    return Text(
      ui(context, 'Line  •  {v0} vertices  •  {v1}',
          [vertices.length, GeometryService.formatDistance(length)]),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.teal.shade800,
      ),
    );
  }

  Widget _polygonSummary() {
    final vertices = widget.vertices ?? const [];
    if (vertices.length < 3) {
      return Text(
        ui(context, 'Polygon'),
        style: TextStyle(color: Colors.teal.shade800),
      );
    }
    final area = GeometryService.polygonAreaM2(vertices);
    final perimeter = GeometryService.polygonPerimeterM(vertices);
    return Text(
      ui(context, 'Polygon  •  {v0} vertices\narea: {v1}  •  perimeter: {v2}', [
        vertices.length,
        GeometryService.formatArea(area),
        GeometryService.formatDistance(perimeter)
      ]),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.teal.shade800,
      ),
    );
  }

  Widget _buildPhotoSection() {
    final photo = _photo;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (photo != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Image.file(
                File(photo.thumbPath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ],
        OutlinedButton.icon(
          onPressed: _capturePhoto,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(photo == null
              ? ui(context, 'Add photo')
              : ui(context, 'Replace photo')),
        ),
        if (photo != null) ...[
          IconButton(
            tooltip: ui(context, 'Remove photo'),
            onPressed: () => setState(() {
              _photo = null;
            }),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ],
    );
  }
}
