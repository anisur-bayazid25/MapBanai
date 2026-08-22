import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/services/gps_csv_service.dart';
import 'package:mapbanai/services/gps_log_store.dart';
import 'package:mapbanai/ui/webmap_viewer_screen.dart';
import 'package:share_plus/share_plus.dart';

class GpsCsvViewerScreen extends StatefulWidget {
  const GpsCsvViewerScreen({super.key});

  @override
  State<GpsCsvViewerScreen> createState() => _GpsCsvViewerScreenState();
}

class _GpsCsvViewerScreenState extends State<GpsCsvViewerScreen> {
  final AppDatabase _db = AppDatabase();
  final GpsLogStore _store = GpsLogStore();
  List<GpsLog> _logs = [];
  Map<int, int> _counts = {};
  Map<int, DateTime?> _last = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final logs = await _db.getGpsLogs();
    final counts = <int, int>{};
    final last = <int, DateTime?>{};
    for (final log in logs) {
      counts[log.id] = await _store.readingCount(log.id);
      last[log.id] = await _store.lastReadingTime(log.id);
    }
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _counts = counts;
      _last = last;
      _loading = false;
    });
  }

  Future<void> _openDetail(GpsLog log) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GpsCsvDetailScreen(log: log),
      ),
    );
    _load();
  }

  Future<void> _projectOnWebMap(GpsLog log) async {
    final path = await _store.filePath(log.id);
    final readings = await GpsCsvService.parseFile(path);
    if (readings.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No readings in "${log.name}" to project')),
      );
      return;
    }
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final file = await GpsCsvService.writeWebMapToFile(
        readings,
        logName: log.name,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WebmapViewerScreen(htmlFile: file)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('WebMap failed: $e')),
      );
    }
  }

  Future<void> _projectMultipleOnWebMap() async {
    if (_logs.isEmpty) return;
    final selected = await showDialog<Set<int>>(
      context: context,
      builder: (context) => _MultiSelectDialog(logs: _logs, counts: _counts),
    );
    if (selected == null || selected.isEmpty) return;
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final allReadings = <GpsLogReading>[];
      String combinedName = 'GPS logs';
      for (final id in selected) {
        final path = await _store.filePath(id);
        final readings = await GpsCsvService.parseFile(path);
        allReadings.addAll(readings);
        final log = _logs.where((l) => l.id == id).firstOrNull;
        if (log != null) combinedName = '${combinedName}_${log.name}';
      }
      if (allReadings.isEmpty) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No readings in selected logs')),
        );
        return;
      }
      // Sort by timestamp
      allReadings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final file = await GpsCsvService.writeWebMapToFile(
        allReadings,
        logName: 'Combined ${selected.length} logs',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WebmapViewerScreen(htmlFile: file)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('WebMap failed: $e')),
      );
    }
  }

  Future<void> _shareLog(GpsLog log) async {
    final path = await _store.filePath(log.id);
    try {
      await Share.shareXFiles([XFile(path)], text: 'GPS log ${log.name}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS CSV Viewer'),
        actions: [
          if (_logs.length > 1)
            IconButton(
              tooltip: 'Project multiple on WebMap',
              icon: const Icon(Icons.layers_outlined),
              onPressed: _projectMultipleOnWebMap,
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.table_chart_outlined,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No GPS logs yet',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Record GPS tracks in GPS Mode. They will appear here for viewing and WebMap overlay.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final log = _logs[idx];
                    final count = _counts[log.id] ?? 0;
                    final last = _last[log.id];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade50,
                          child: Icon(Icons.description_outlined,
                              color: Colors.teal.shade700),
                        ),
                        title: Text(log.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '$count readings'
                          '${last == null ? '' : ' • last ${_formatTime(last)}'}'
                          '${log.surveyor.trim().isEmpty ? '' : ' • ${log.surveyor}'}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            switch (v) {
                              case 'view':
                                _openDetail(log);
                                break;
                              case 'webmap':
                                _projectOnWebMap(log);
                                break;
                              case 'share':
                                _shareLog(log);
                                break;
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                                value: 'view',
                                child: Row(children: [
                                  Icon(Icons.table_view_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('View CSV')
                                ])),
                            PopupMenuItem(
                                value: 'webmap',
                                child: Row(children: [
                                  Icon(Icons.public_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Project on WebMap')
                                ])),
                            PopupMenuItem(
                                value: 'share',
                                child: Row(children: [
                                  Icon(Icons.ios_share_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Share CSV')
                                ])),
                          ],
                        ),
                        onTap: () => _openDetail(log),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: _logs.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                onPressed: _projectMultipleOnWebMap,
                icon: const Icon(Icons.public_outlined),
                label: const Text('Project multiple logs on WebMap'),
              ),
            ),
    );
  }

  String _formatTime(DateTime t) {
    final l = t.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }
}

class _MultiSelectDialog extends StatefulWidget {
  final List<GpsLog> logs;
  final Map<int, int> counts;
  const _MultiSelectDialog({required this.logs, required this.counts});

  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select logs to project'),
      content: SizedBox(
        width: 320,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final log in widget.logs)
              CheckboxListTile(
                title: Text(log.name),
                subtitle: Text('${widget.counts[log.id] ?? 0} readings'),
                value: _selected.contains(log.id),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selected.add(log.id);
                    } else {
                      _selected.remove(log.id);
                    }
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty ? null : () => Navigator.pop(context, _selected),
          child: Text('Project ${_selected.length} logs'),
        ),
      ],
    );
  }
}

class GpsCsvDetailScreen extends StatefulWidget {
  final GpsLog log;
  const GpsCsvDetailScreen({required this.log, super.key});

  @override
  State<GpsCsvDetailScreen> createState() => _GpsCsvDetailScreenState();
}

class _GpsCsvDetailScreenState extends State<GpsCsvDetailScreen> {
  final GpsLogStore _store = GpsLogStore();
  List<GpsLogReading> _readings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final path = await _store.filePath(widget.log.id);
      final readings = await GpsCsvService.parseFile(path);
      if (!mounted) return;
      setState(() {
        _readings = readings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _projectOnWebMap() async {
    if (_readings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No readings to project')),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final file = await GpsCsvService.writeWebMapToFile(
        _readings,
        logName: widget.log.name,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WebmapViewerScreen(htmlFile: file)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('WebMap failed: $e')),
      );
    }
  }

  Future<void> _share() async {
    final path = await _store.filePath(widget.log.id);
    try {
      await Share.shareXFiles([XFile(path)], text: 'GPS log ${widget.log.name}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _readings.isEmpty
        ? null
        : GpsCsvService.stats(_readings);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.log.name),
        actions: [
          IconButton(
            tooltip: 'Project on WebMap',
            icon: const Icon(Icons.public_outlined),
            onPressed: _readings.isEmpty ? null : _projectOnWebMap,
          ),
          IconButton(
            tooltip: 'Share CSV',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: _share,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Failed to load: $_error',
                        style: TextStyle(color: Colors.red.shade700)),
                  ),
                )
              : Column(
                  children: [
                    _buildStatsBar(stats),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          FilledButton.icon(
                            onPressed: _projectOnWebMap,
                            icon: const Icon(Icons.public_outlined, size: 18),
                            label: const Text('Project on WebMap'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _share,
                            icon: const Icon(Icons.ios_share_outlined, size: 18),
                            label: const Text('Share'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _readings.isEmpty
                          ? Center(
                              child: Text('No readings yet',
                                  style: TextStyle(color: Colors.grey.shade600)),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                      Colors.teal.shade50),
                                  columns: const [
                                    DataColumn(label: Text('ID')),
                                    DataColumn(label: Text('Timestamp')),
                                    DataColumn(label: Text('Latitude')),
                                    DataColumn(label: Text('Longitude')),
                                    DataColumn(label: Text('Alt (m)')),
                                    DataColumn(label: Text('Acc (m)')),
                                    DataColumn(label: Text('Notes')),
                                  ],
                                  rows: [
                                    for (final r in _readings)
                                      DataRow(cells: [
                                        DataCell(Text(r.id.toString())),
                                        DataCell(Text(_fmtTs(r.timestamp))),
                                        DataCell(Text(r.latitude.toStringAsFixed(6))),
                                        DataCell(Text(r.longitude.toStringAsFixed(6))),
                                        DataCell(Text(r.altitude.toStringAsFixed(1))),
                                        DataCell(Text(r.accuracy.toStringAsFixed(1))),
                                        DataCell(SizedBox(
                                          width: 180,
                                          child: Text(
                                            r.notes.isEmpty ? '—' : r.notes,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        )),
                                      ]),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatsBar(Map<String, dynamic>? stats) {
    if (stats == null) return const SizedBox.shrink();
    final dist = stats['distance_m'] as double;
    final distStr = dist < 1000
        ? '${dist.toStringAsFixed(1)} m'
        : '${(dist / 1000).toStringAsFixed(2)} km';
    final count = stats['count'];
    final duration = stats['duration_s'] as int;
    final durStr = duration < 60
        ? '${duration}s'
        : '${duration ~/ 60}m ${duration % 60}s';
    return Container(
      color: Colors.teal.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _statChip(Icons.table_rows_outlined, '$count readings'),
          const SizedBox(width: 8),
          _statChip(Icons.route_outlined, distStr),
          const SizedBox(width: 8),
          _statChip(Icons.timer_outlined, durStr),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.teal.shade700),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  String _fmtTs(DateTime dt) {
    final l = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} '
        '${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
  }
}

extension _FirstWhereOrNullX<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
