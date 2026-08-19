import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/models/app_info.dart';
import 'package:mapbanai/services/update_checker.dart';
import 'package:mapbanai/ui/common/confirm_dialog.dart';
import 'package:mapbanai/ui/common/loading_indicator.dart';
import 'package:mapbanai/ui/common/section_header.dart';
import 'package:mapbanai/ui/common/update_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String _appVersion = '';
  bool _checkingUpdates = false;

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
    var appVersion = '';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (_) {
      // Package info is unavailable in some test environments.
    }
    if (!mounted) return;
    setState(() {
      _nameController.text = name ?? '';
      _language = language;
      _appVersion = appVersion;
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

  Future<void> _checkForUpdates() async {
    setState(() => _checkingUpdates = true);
    try {
      final update = await UpdateChecker.checkForUpdate();
      if (!mounted) return;
      if (update == null) {
        await showUpToDateDialog(context);
      } else {
        await showUpdateDialog(context, update);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not check for updates')),
      );
    } finally {
      if (mounted) setState(() => _checkingUpdates = false);
    }
  }

  Future<void> _resetData() async {
    final userName = (await widget.database.getSetting(_userNameKey)) ?? '';
    if (userName.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Set a user name in Settings first â€” it is required to confirm '
            'a data reset.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showTypeToConfirmDialog(
      context,
      title: 'Final confirmation',
      message: 'This permanently deletes all projects, survey responses, '
          'stored forms and GPS logs. Type your user name exactly as shown '
          'to confirm:',
      typeToConfirm: userName.trim(),
      confirmText: 'Reset data',
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
                  title: 'Updates',
                  subtitle:
                      'Checks the GitHub releases feed for a newer version.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _checkingUpdates ? null : _checkForUpdates,
                  icon: _checkingUpdates
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : const Icon(Icons.update),
                  label: Text(
                    _appVersion.isEmpty
                        ? 'Check for updates'
                        : 'Check for updates \u2014 v$_appVersion installed',
                  ),
                ),
                const Divider(height: 32),
                const SectionHeader(
                  title: 'About',
                  subtitle: AppInfo.tagline,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Image.asset(
                            'assets/logo/MapBanai_logo.png',
                            width: 220,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'Version ${AppInfo.version}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppInfo.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(),
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: Icon(Icons.person_outline, size: 20),
                          title: Text(
                            AppInfo.creator,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.code, size: 20),
                          title: const Text(
                            'GitHub repository',
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            AppInfo.githubUrl,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          onTap: () =>
                              _launchUrl(Uri.parse(AppInfo.githubUrl)),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.mail_outline, size: 20),
                          title: const Text(
                            'Email',
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            AppInfo.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          onTap: () => _launchUrl(
                            Uri(
                              scheme: 'mailto',
                              path: AppInfo.email,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppInfo.updatesNote,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
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

  Future<void> _launchUrl(Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }
}
