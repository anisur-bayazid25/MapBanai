import 'package:flutter/material.dart';
import 'package:mapbanai/data/app_database.dart';

/// Persists and exposes app-wide locale and theme preferences.
///
/// Values are stored in the `app_settings` table (via [AppDatabase]) so they
/// survive reinstall restores that move the database file, and so the whole
/// app has a single source of truth (SettingsScreen writes to the same keys).
class AppSettingsProvider extends ChangeNotifier {
  static const String languageKey = 'language';
  static const String themeKey = 'theme_mode';

  static const List<String> supportedLanguages = ['system', 'en', 'bn'];
  static const List<String> supportedThemes = ['system', 'light', 'dark'];

  String _language = 'system';
  ThemeMode _themeMode = ThemeMode.system;
  bool _loaded = false;

  AppDatabase? _database;
  final bool _ownsDatabase;

  AppDatabase get _db => _database ??= AppDatabase();

  String get language => _language;
  ThemeMode get themeMode => _themeMode;
  bool get isLoaded => _loaded;

  /// `null` means System default — MaterialApp will follow the device locale.
  Locale? get locale {
    if (_language == 'system') return null;
    if (_language == 'bn') return const Locale('bn');
    return const Locale('en');
  }

  String get themeModeString => switch (_themeMode) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };

  AppSettingsProvider({AppDatabase? database})
      : _database = database,
        _ownsDatabase = database == null {
    _load();
  }

  Future<void> _load() async {
    try {
      final lang = await _db.getSetting(languageKey);
      if (lang != null && supportedLanguages.contains(lang)) {
        _language = lang;
      }
      final theme = await _db.getSetting(themeKey);
      if (theme != null) {
        _themeMode = _themeFromString(theme);
      }
      _loaded = true;
      notifyListeners();
    } catch (_) {
      // Best-effort: defaults remain system.
      _loaded = true;
      notifyListeners();
    }
  }

  /// Reload from DB (useful after SettingsScreen writes directly).
  Future<void> reload() => _load();

  Future<void> setLanguage(String code) async {
    if (!supportedLanguages.contains(code)) return;
    _language = code;
    notifyListeners();
    try {
      await _db.setSetting(languageKey, code);
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      await _db.setSetting(themeKey, _themeModeToString(mode));
    } catch (_) {}
  }

  Future<void> setThemeModeFromString(String value) async {
    final mode = _themeFromString(value);
    await setThemeMode(mode);
  }

  static ThemeMode _themeFromString(String value) {
    return switch (value.toLowerCase()) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String _themeModeToString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  static String themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System default',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  static String languageLabel(String code) => switch (code) {
        'en' => 'English',
        'bn' => 'Bangla',
        _ => 'System default',
      };

  @override
  void dispose() {
    if (_ownsDatabase && _database != null) {
      try {
        _database!.close();
      } catch (_) {}
    }
    super.dispose();
  }
}
