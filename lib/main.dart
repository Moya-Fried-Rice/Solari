import 'package:flutter/material.dart';
import 'package:solari/theme.dart';
import 'package:flutter/services.dart';

import 'package:solari/screens/home.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);

void main() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const SolariApp());
}

class SolariApp extends StatefulWidget {
  const SolariApp({super.key});

  @override
  State<SolariApp> createState() => _SolariAppState();
}

class _SolariAppState extends State<SolariApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: Home(),
        );
      },
    );
  }
}