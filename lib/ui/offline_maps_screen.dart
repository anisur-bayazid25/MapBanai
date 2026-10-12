import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbanai/services/location_service.dart';
import 'package:mapbanai/services/offline_map_service.dart';

class OfflineMapsScreen extends StatefulWidget {
  const OfflineMapsScreen({super.key});
  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  final _service = OfflineMapService.instance;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service.addListener(_changed);
    _refresh();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_changed);
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!OfflineMapService.supported) {
      setState(() {
        _loading = false;
        _error = 'Offline map downloads are available on Android.';
      });
      return;
    }
    try {
      await _service.refresh();
    } catch (e) {
      _error = 'Could not read offline packages: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _download() async {
    final request = await showDialog<OfflineMapRequest>(
        context: context, builder: (_) => const _DownloadMapDialog());
    if (request == null) return;
    try {
      await _service.download(request);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _delete(OfflineMapPackage package) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text('Delete ${package.name}?'),
                content: const Text(
                    'This removes its offline resources. Your surveyed features and photos stay on the device.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete package'))
                ]));
    if (confirmed != true) return;
    try {
      await _service.delete(package.id);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete package: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Offline maps'), actions: [
        IconButton(
            tooltip: 'Refresh packages',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh))
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              const Text(
                  'Download a bounded field area before leaving internet coverage. Completed packages appear in the Basemap selector on every collection map.'),
              const SizedBox(height: 8),
              const Text(
                  'Use your own server or a provider that permits offline downloads. Built-in OSM, CARTO and Esri basemaps remain online-only. Keep the app open while downloading. Packages are not part of survey backups; re-download them after reinstall.',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (OfflineMapService.supported)
                Text(
                    'Free device storage: ${OfflineMapService.formatBytes(_service.freeBytes)} · Map cache: ${OfflineMapService.formatBytes(_service.cacheBytes)}'),
              const SizedBox(height: 12),
              FilledButton.icon(
                  onPressed: !OfflineMapService.supported || _service.busy
                      ? null
                      : _download,
                  icon: const Icon(Icons.download_for_offline_outlined),
                  label: const Text('Download field area')),
              if (_service.busy) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                    value: _service.downloadStatus?.progress),
                Text(
                    '${_service.downloadStatus?.completed ?? 0} / ${_service.downloadStatus?.required ?? 0} resources · ${OfflineMapService.formatBytes(_service.downloadStatus?.bytes ?? 0)}'),
                TextButton(
                    onPressed: () async {
                      try {
                        await _service.cancel();
                      } catch (e) {
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Cancel failed: $e')));
                      }
                    },
                    child: const Text('Cancel download')),
              ],
              if (_service.message != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_service.message!)),
              if (_service.packages.isEmpty)
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No offline packages downloaded yet.')),
              for (final package in _service.packages)
                Card(
                    child: ListTile(
                  leading: Icon(
                      package.status.complete
                          ? Icons.offline_pin
                          : Icons.warning_amber,
                      color: package.status.complete
                          ? Colors.green
                          : Colors.orange),
                  title: Text(package.name),
                  subtitle: Text(
                      '${package.status.complete ? "Ready offline" : "Incomplete — delete and retry"} · ${OfflineMapService.formatBytes(package.status.bytes)}\n'
                      'Zoom ${package.region.definition.minZoom.round()}–${package.region.definition.maxZoom.round()}\n${package.attribution}'),
                  isThreeLine: true,
                  trailing: IconButton(
                      tooltip: 'Delete package',
                      onPressed: _service.busy ? null : () => _delete(package),
                      icon: const Icon(Icons.delete_outline)),
                )),
            ]));
}

class _DownloadMapDialog extends StatefulWidget {
  const _DownloadMapDialog();
  @override
  State<_DownloadMapDialog> createState() => _DownloadMapDialogState();
}

class _DownloadMapDialogState extends State<_DownloadMapDialog> {
  final _name = TextEditingController();
  final _url = TextEditingController();
  final _attribution = TextEditingController();
  final _south = TextEditingController(text: '23.75');
  final _west = TextEditingController(text: '90.35');
  final _north = TextEditingController(text: '23.85');
  final _east = TextEditingController(text: '90.45');
  final _minZoom = TextEditingController(text: '10');
  final _maxZoom = TextEditingController(text: '16');
  bool _permission = false;
  bool _gpsBusy = false;
  int _limitMb = 250;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _url,
      _attribution,
      _south,
      _west,
      _north,
      _east,
      _minZoom,
      _maxZoom
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _useGps() async {
    setState(() => _gpsBusy = true);
    try {
      if (!await LocationService().ensurePermission())
        throw StateError('Allow location permission to centre your download.');
      final fix = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20));
      if (!mounted) return;
      // Approximate 2 km buffer. User can refine all four bounds before download.
      setState(() {
        _south.text = (fix.latitude - 0.02).toStringAsFixed(5);
        _north.text = (fix.latitude + 0.02).toStringAsFixed(5);
        _west.text = (fix.longitude - 0.02).toStringAsFixed(5);
        _east.text = (fix.longitude + 0.02).toStringAsFixed(5);
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _gpsBusy = false);
    }
  }

  void _submit() {
    try {
      final request = OfflineMapRequest(
          name: _name.text,
          styleUrl: _url.text.trim(),
          attribution: _attribution.text,
          permissionAcknowledged: _permission,
          south: double.parse(_south.text),
          west: double.parse(_west.text),
          north: double.parse(_north.text),
          east: double.parse(_east.text),
          minZoom: int.parse(_minZoom.text),
          maxZoom: int.parse(_maxZoom.text),
          maxBytes: _limitMb * 1024 * 1024);
      request.validate();
      Navigator.pop(context, request);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Widget _input(TextEditingController controller, String label,
          {bool numeric = false}) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: TextField(
              controller: controller,
              keyboardType: numeric
                  ? const TextInputType.numberWithOptions(
                      decimal: true, signed: true)
                  : TextInputType.text,
              decoration: InputDecoration(
                  labelText: label, border: const OutlineInputBorder())));

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Download field area'),
          content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                _input(_name, 'Package name'),
                _input(_url, 'Permitted provider HTTPS style.json URL'),
                _input(_attribution, 'Required source attribution / credits'),
                CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _permission,
                    onChanged: (value) =>
                        setState(() => _permission = value ?? false),
                    title: const Text(
                        'I have permission to download this source for offline use.',
                        style: TextStyle(fontSize: 13))),
                OutlinedButton.icon(
                    onPressed: _gpsBusy ? null : _useGps,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use area around my GPS location')),
                Row(children: [
                  Expanded(
                      child: _input(_south, 'South latitude', numeric: true)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _input(_north, 'North latitude', numeric: true))
                ]),
                Row(children: [
                  Expanded(
                      child: _input(_west, 'West longitude', numeric: true)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _input(_east, 'East longitude', numeric: true))
                ]),
                Row(children: [
                  Expanded(
                      child: _input(_minZoom, 'Minimum zoom', numeric: true)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _input(_maxZoom, 'Maximum zoom', numeric: true))
                ]),
                DropdownButtonFormField<int>(
                    value: _limitMb,
                    decoration: const InputDecoration(
                        labelText: 'Maximum download size'),
                    items: [50, 100, 250, 500]
                        .map((size) => DropdownMenuItem(
                            value: size, child: Text('$size MB')))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _limitMb = value ?? 250)),
                const SizedBox(height: 8),
                const Text(
                    'Zoom 18 maximum; 6,000 tiles maximum. Download covers only these bounds and zooms. Larger areas need lower zoom or separate packages.',
                    style: TextStyle(fontSize: 12)),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
              ]))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: _gpsBusy ? null : _submit,
                child: const Text('Download'))
          ]);
}
