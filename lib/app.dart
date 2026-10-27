import 'package:mapbanai/ui/common/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:mapbanai/l10n/app_localizations.dart';
import 'package:mapbanai/state/app_settings_provider.dart';
import 'package:mapbanai/state/project_state.dart';
import 'package:mapbanai/ui/home_screen.dart';
import 'package:provider/provider.dart';

class MapBanaiApp extends StatelessWidget {
  const MapBanaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectState()),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'MapBanai',
            debugShowCheckedModeBanner: false,
            theme: MapBanaiTheme.create(Brightness.light),
            darkTheme: MapBanaiTheme.create(Brightness.dark),
            themeMode: settings.themeMode,
            locale: settings.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
