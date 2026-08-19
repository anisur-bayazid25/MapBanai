import 'package:flutter/material.dart';
import 'package:mapbanai/state/project_state.dart';
import 'package:mapbanai/ui/home_screen.dart';
import 'package:provider/provider.dart';

class MapBanaiApp extends StatelessWidget {
  const MapBanaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectState(),
      child: MaterialApp(
        title: 'MapBanai',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E88E5),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
