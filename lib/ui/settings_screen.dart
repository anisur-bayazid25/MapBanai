import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/app_info.dart';
import 'package:mapbanai/ui/common/confirm_dialog.dart';
import 'package:mapbanai/ui/common/loading_indicator.dart';
import 'package:mapbanai/ui/common/section_header.dart';

class SettingsScreen extends StatefulWidget {
  final AppDatabase database;

  const SettingsScreen({required this.database, super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _userNameKey = 'user_name';
  static const String _languageKey = 'language';

  static const List<({String code, String label})> _languages = [
    (code: 'system', label: 'System default'),
    (code: 'en', label: 'English'),
    (code: 'bn', label: 'Bangla'),
  ];

  final TextEditingController _nameController = TextEditingController();
  bool _loading = true;
  String _language = 'system';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await widget.database.getSetting(_userNameKey);
    var language = await widget.database.getSetting(_languageKey) ?? 'system';
    if (!_languages.any((l) => l.code == language)) {
      language = 'system';
    }
    if (!mounted) return;
    setState(() {
      _nameController.text = name ?? '';
      _language = language;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.database.setSetting(
      _userNameKey,
      _nameController.text.trim(),
    );
    await widget.database.setSetting(_languageKey, _language);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  Future<void> _resetData() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reset all data?',
      message: 'All projects, survey responses, stored forms and GPS logs will '
          'be permanently deleted. Your user name is kept. Photos on disk are '
          'not removed. This cannot be undone.',
      confirmText: 'Reset data',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    try {
      setState(() => _loading = true);
      await widget.database.resetAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data has been reset')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to reset data')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: FilledButton.icon(
                onPressed: _loading ? null : _save,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save'),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const AppLoadingIndicator()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SectionHeader(
                  title: 'User',
                  subtitle:
                      'Your name is attached to every survey response, GPS log '
                      'entry and export produced by the app.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'User name',
                    hintText: 'e.g., John Doe',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Leave empty to clear.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const Divider(height: 32),
                const SectionHeader(
                  title: 'Language',
                  subtitle:
                      'Applied in the Phase 6 i18n release; the preference is '
                      'stored now.',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _language,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Preferred language',
                  ),
                  items: [
                    for (final language in _languages)
                      DropdownMenuItem(
                        value: language.code,
                        child: Text(language.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _language = value);
                    }
                  },
                ),
                const Divider(height: 32),
                const SectionHeader(
                  title: 'Data',
                  subtitle: 'Delete all locally stored survey data.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onPressed: _resetData,
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Reset data'),
                ),
                const Divider(height: 32),
                const SectionHeader(
                  title: 'About',
                  subtitle: AppInfo.tagline,
                ),
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline),
                            SizedBox(width: 8),
                            Text(
                              AppInfo.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text('Version ${AppInfo.version}'),
                        SizedBox(height: 6),
                        Text(AppInfo.description),
                        SizedBox(height: 10),
                        Divider(),
                        Text(
                          '(c) ${AppInfo.creator}',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          AppInfo.updatesNote,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}