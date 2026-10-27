import 'package:mapbanai/l10n/ui_text.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:mapbanai/services/map_service.dart';
import 'package:mapbanai/services/offline_map_service.dart';

class MapStyleChoice {
  const MapStyleChoice(
      {required this.id,
      required this.name,
      required this.style,
      required this.attribution,
      this.offline = false,
      this.bounds,
      this.minZoom,
      this.maxZoom});
  final String id, name, style, attribution;
  final bool offline;
  final LatLngBounds? bounds;
  final double? minZoom, maxZoom;
  factory MapStyleChoice.online(Basemap basemap) => MapStyleChoice(
      id: basemap.id,
      name: basemap.name,
      attribution: basemap.attribution,
      style: jsonEncode({
        'version': 8,
        'sources': {
          if (basemap.url.isNotEmpty)
            'basemap': {
              'type': 'raster',
              'tiles': [basemap.url],
              'tileSize': 256,
              'maxzoom': basemap.maxNativeZoom,
              'attribution': basemap.attribution
            }
        },
        'layers': [
          if (basemap.url.isEmpty)
            {
              'id': 'paper',
              'type': 'background',
              'paint': {'background-color': '#f6f8f3'}
            },
          if (basemap.url.isNotEmpty)
            {'id': 'basemap', 'type': 'raster', 'source': 'basemap'}
        ]
      }));
  factory MapStyleChoice.package(OfflineMapPackage package) => MapStyleChoice(
      id: 'offline_${package.id}',
      name: package.name,
      style: package.region.definition.mapStyleUrl,
      attribution: package.attribution,
      offline: true,
      bounds: package.region.definition.bounds,
      minZoom: package.region.definition.minZoom,
      maxZoom: package.region.definition.maxZoom);
}

Future<MapStyleChoice?> showBasemapPicker(BuildContext context,
    {required String selectedId}) async {
  final choices = Basemap.defaults.map(MapStyleChoice.online).toList();
  String? error;
  if (OfflineMapService.supported) {
    try {
      await OfflineMapService.instance.refresh();
      choices.addAll(OfflineMapService.instance.packages
          .where((p) => p.status.complete)
          .map(MapStyleChoice.package));
    } catch (_) {
      error =
          'Offline packages could not be read. Open Offline maps to check downloads.';
    }
  }
  if (!context.mounted) return null;
  return showDialog<MapStyleChoice>(
      context: context,
      builder: (dialogContext) =>
          SimpleDialog(title: Text(ui(context, 'Select basemap')), children: [
            if (error != null)
              Padding(padding: const EdgeInsets.all(12), child: Text(error)),
            for (final choice in choices)
              ListTile(
                  leading: Icon(choice.id == selectedId
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off),
                  title: Text(choice.name),
                  subtitle: Text(choice.offline
                      ? ui(context, 'Offline · zoom {v0}–{v1}\n{v2}', [
                          choice.minZoom!.round(),
                          choice.maxZoom!.round(),
                          choice.attribution
                        ])
                      : ui(context, 'Online · {v0}', [choice.attribution])),
                  onTap: () => Navigator.pop(dialogContext, choice)),
          ]));
}

/// Keep provider attribution visible even when offline style assets are cached.
class OfflineBasemapNotice extends StatelessWidget {
  const OfflineBasemapNotice({super.key, required this.choice});
  final MapStyleChoice? choice;
  @override
  Widget build(BuildContext context) {
    final selected = choice;
    if (selected == null || !selected.offline) return const SizedBox.shrink();
    return IgnorePointer(
        child: Container(
            padding: const EdgeInsets.all(5),
            color: Colors.white.withOpacity(0.9),
            child: Text(
                ui(context, 'Offline: {v0} · zoom {v1}–{v2}\n{v3}', [
                  selected.name,
                  selected.minZoom!.round(),
                  selected.maxZoom!.round(),
                  selected.attribution
                ]),
                style: const TextStyle(fontSize: 10, color: Colors.black))));
  }
}
