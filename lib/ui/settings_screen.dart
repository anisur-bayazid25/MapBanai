import 'package:mapbanai/l10n/ui_text.dart';
import 'package:mapbanai/ui/help_screen.dart';
import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/l10n/app_localizations.dart';
import 'package:mapbanai/models/app_info.dart';
import 'package:mapbanai/services/measure_units.dart';
import 'package:mapbanai/services/update_checker.dart';
import 'package:mapbanai/state/app_settings_provider.dart';
import 'package:mapbanai/ui/common/confirm_dialog.dart';
import 'package:mapbanai/ui/common/loading_indicator.dart';
import 'package:mapbanai/ui/common/section_header.dart';
import 'package:mapbanai/ui/common/update_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  final AppDatabase database;

  const SettingsScreen({required this.database, super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _userNameKey = 'user_name';
  static const String _languageKey = AppSettingsProvider.languageKey;
  static const String _themeKey = AppSettingsProvider.themeKey;
  static const String _distanceUnitKey = 'distance_unit';
  static const String _areaUnitKey = 'area_unit';

  bool _loading = true;
  bool _loadFailed = false;
  String _language = 'system';
  String _themeMode = 'system';
  DistanceUnit _distanceUnit = DistanceUnit.auto;
  AreaUnit _areaUnit = AreaUnit.auto;
  String _appVersion = '';
  bool _checkingUpdates = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    try {
      var language = await widget.database.getSetting(_languageKey) ?? 'system';
      if (!['system', 'en', 'bn'].contains(language)) {
        language = 'system';
      }
      var theme = await widget.database.getSetting(_themeKey) ?? 'system';
      if (!['system', 'light', 'dark'].contains(theme)) {
        theme = 'system';
      }
      _distanceUnit = DistanceUnit.fromSetting(
        await widget.database.getSetting(_distanceUnitKey),
      );
      _areaUnit = AreaUnit.fromSetting(
        await widget.database.getSetting(_areaUnitKey),
      );
      var appVersion = '';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = packageInfo.version;
      } catch (_) {
        // Package info is unavailable in some test environments.
      }
      if (!mounted) return;
      setState(() {
        _language = language;
        _themeMode = theme;
        _appVersion = appVersion;
        _loading = false;
      });
    } catch (error) {
      if (mounted)
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _save() async {
    await widget.database.setSetting(_languageKey, _language);
    await widget.database.setSetting(_themeKey, _themeMode);
    await widget.database.setSetting(_distanceUnitKey, _distanceUnit.name);
    await widget.database.setSetting(_areaUnitKey, _areaUnit.name);

    if (!mounted) return;
    // Push to provider so MaterialApp rebuilds immediately.
    final provider = context.read<AppSettingsProvider>();
    await provider.setLanguage(_language);
    await provider.setThemeModeFromString(_themeMode);

    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsSaved)),
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
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.syncNoInternet)),
      );
    } finally {
      if (mounted) setState(() => _checkingUpdates = false);
    }
  }

  Future<void> _resetData() async {
    final l10n = AppLocalizations.of(context);
    final userName = (await widget.database.getSetting(_userNameKey)) ?? '';
    if (userName.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ui(context,
                'Set a user name in Settings first — it is required to confirm a data reset.'),
          ),
        ),
      );
      return;
    }

    final confirmed = await showTypeToConfirmDialog(
      context,
      title: l10n.resetDataConfirmTitle,
      message: ui(context,
          'This permanently deletes all projects, survey responses, stored forms and GPS logs. Type your user name exactly as shown to confirm:'),
      typeToConfirm: userName.trim(),
      confirmText: l10n.resetData,
    );
    if (!confirmed || !mounted) return;

    try {
      setState(() => _loading = true);
      await widget.database.resetAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.syncNever)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ui(context, 'Failed to reset data'))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _loading ? null : AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.settings ?? 'Settings'),
        actions: [
          IconButton(
              tooltip: ui(context, 'Help & manager setup'),
              icon: const Icon(Icons.help_outline),
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const HelpScreen()))),
          Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                  key: const ValueKey('settings-save-action'),
                  width: 48,
                  height: 48,
                  child: IconButton.filledTonal(
                      tooltip: ui(context, 'Save'),
                      onPressed: _loading ? null : _save,
                      icon: const Icon(Icons.save_outlined)))),
        ],
      ),
      body: _loading || l10n == null
          ? const AppLoadingIndicator()
          : _loadFailed
              ? Center(
                  child: SingleChildScrollView(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(ui(context,
                                'Could not load settings. Please try again.')),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                                onPressed: _load,
                                icon: const Icon(Icons.refresh),
                                label: Text(ui(context, 'Retry'))),
                          ]))))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SectionHeader(
                      title: l10n.languageSection,
                      subtitle: l10n.languageSubtitle,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      itemHeight: null,
                      isExpanded: true,
                      value: _language,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.preferredLanguage,
                      ),
                      items: [
                        DropdownMenuItem(
                            value: 'system', child: Text(l10n.systemDefault)),
                        DropdownMenuItem(
                            value: 'en', child: Text(l10n.english)),
                        DropdownMenuItem(value: 'bn', child: Text(l10n.bangla)),
                      ],
                      onChanged: (value) async {
                        if (value != null) {
                          setState(() => _language = value);
                          // Immediate apply for instant feedback
                          await context
                              .read<AppSettingsProvider>()
                              .setLanguage(value);
                          await widget.database.setSetting(_languageKey, value);
                        }
                      },
                    ),
                    const Divider(height: 32),
                    SectionHeader(
                      title: l10n.themeSection,
                      subtitle: l10n.themeSubtitle,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      itemHeight: null,
                      isExpanded: true,
                      value: _themeMode,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.preferredTheme,
                      ),
                      items: [
                        DropdownMenuItem(
                            value: 'system', child: Text(l10n.themeSystem)),
                        DropdownMenuItem(
                            value: 'light', child: Text(l10n.themeLight)),
                        DropdownMenuItem(
                            value: 'dark', child: Text(l10n.themeDark)),
                      ],
                      onChanged: (value) async {
                        if (value != null) {
                          setState(() => _themeMode = value);
                          final mode = switch (value) {
                            'light' => ThemeMode.light,
                            'dark' => ThemeMode.dark,
                            _ => ThemeMode.system,
                          };
                          await context
                              .read<AppSettingsProvider>()
                              .setThemeMode(mode);
                          await widget.database.setSetting(_themeKey, value);
                        }
                      },
                    ),
                    const Divider(height: 32),
                    SectionHeader(
                      title: l10n.measurementSection,
                      subtitle: l10n.measurementSubtitle,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<DistanceUnit>(
                      itemHeight: null,
                      isExpanded: true,
                      value: _distanceUnit,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.distance,
                      ),
                      items: [
                        for (final unit in DistanceUnit.values)
                          DropdownMenuItem(
                            value: unit,
                            child: Text(ui(context, unit.label)),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _distanceUnit = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AreaUnit>(
                      itemHeight: null,
                      isExpanded: true,
                      value: _areaUnit,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.area,
                      ),
                      items: [
                        for (final unit in AreaUnit.values)
                          DropdownMenuItem(
                            value: unit,
                            child: Text(ui(context, unit.label)),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _areaUnit = value);
                        }
                      },
                    ),
                    const Divider(height: 32),
                    SectionHeader(
                      title: l10n.dataSection,
                      subtitle: l10n.dataSubtitle,
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
                      label: Text(l10n.resetData),
                    ),
                    const Divider(height: 32),
                    SectionHeader(
                      title: l10n.updatesSection,
                      subtitle: l10n.updatesSubtitle,
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
                            ? l10n.checkForUpdates
                            : l10n.checkForUpdatesWithVersion(_appVersion),
                      ),
                    ),
                    const Divider(height: 32),
                    SectionHeader(
                      title: l10n.aboutSection,
                      subtitle: l10n.aboutTagline,
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
                                'assets/logo/app_icon.png',
                                width: 220,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                l10n.versionLabel(AppInfo.version),
                                style: const TextStyle(
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
                            const SizedBox(height: 16),
                            Text(ui(context, 'Acknowledgments'),
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(ui(context,
                                'MapBanai gratefully acknowledges the contributions of the CARE project and BRAC James P Grant School of Public Health, BRAC University, to its development.')),
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
                              title: Text(
                                ui(context, 'GitHub repository'),
                                style: const TextStyle(fontSize: 14),
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
                              title: Text(
                                ui(context, 'Email'),
                                style: const TextStyle(fontSize: 14),
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
          SnackBar(content: Text(ui(context, 'Could not open link'))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ui(context, 'Could not open link'))),
        );
      }
    }
  }
}
