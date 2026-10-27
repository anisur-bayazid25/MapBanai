import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbanai/data/app_database.dart';
import 'package:mapbanai/l10n/app_localizations.dart';
import 'package:mapbanai/state/app_settings_provider.dart';
import 'package:mapbanai/ui/settings_screen.dart';
import 'package:mapbanai/ui/common/loading_indicator.dart';
import 'package:provider/provider.dart';

class _UnavailableStorage extends AppDatabase {
  bool unavailable = true;
  _UnavailableStorage() : super.forTesting();
  @override
  Future<String?> getSetting(String key) async {
    if (unavailable) throw StateError('Storage temporarily unavailable');
    return super.getSetting(key);
  }
}

void main() {
  testWidgets(
      'Settings shows a recoverable error instead of an endless spinner',
      (tester) async {
    PackageInfo.setMockInitialValues(
        appName: 'MapBanai',
        packageName: 'com.mapbanai.mapbanai',
        version: '2.7.0',
        buildNumber: '34',
        buildSignature: '');
    final database = _UnavailableStorage();
    await database.customSelect('SELECT 1').get();
    addTearDown(database.close);
    await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => AppSettingsProvider(database: database),
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(database: database))));
    await tester.pumpAndSettle();
    expect(find.text('Could not load settings. Please try again.'),
        findsOneWidget);
    expect(find.byType(AppLoadingIndicator), findsNothing);
    database.unavailable = false;
    await tester.tap(find.text('Retry'));
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pumpAndSettle();
    expect(
        find.text('Could not load settings. Please try again.'), findsNothing);
    expect(find.byType(AppLoadingIndicator), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
    final save = find.byTooltip('Save');
    final saveRect =
        tester.getRect(find.byKey(const ValueKey('settings-save-action')));
    final bar = tester.getRect(find.byType(AppBar));
    final icon = tester.getRect(find.byIcon(Icons.save_outlined));
    expect(saveRect.height, greaterThanOrEqualTo(40));
    expect(bar.contains(icon.topLeft) && bar.contains(icon.bottomRight), true);
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pumpAndSettle();
    expect(await database.getSetting('theme_mode'), 'dark');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
