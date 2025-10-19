import 'dart:async';

// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'core/providers/history_provider.dart';
import 'core/services/system_preferences_service.dart';
import 'core/services/screen_reader_service.dart';
import 'core/services/select_to_speak_service.dart';

// Screens
import 'screens/onboarding/launch_screen.dart';

// Widgets
import 'widgets/magnification_wrapper.dart';

// UI and state management
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize accessibility services
  await ScreenReaderService().initialize();
  await SelectToSpeakService().initialize();
  
  // Lock orientation to portrait mode only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Enable verbose logging for Bluetooth
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: const SolariApp(),
    ),
  );
}

// Solari Application main widget
class SolariApp extends StatefulWidget {
  const SolariApp({super.key});

  @override
  State<SolariApp> createState() => _SolariAppState();
}

// This class is the state class for the SolariApp widget that provides the main app structure
class _SolariAppState extends State<SolariApp> {

  // Initialize state
  @override
  void initState() {
    super.initState();
    // We'll initialize the system preferences service after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemPreferencesService.instance.startListening(context);
    });
  }

  // Clean up when the widget is disposed
  @override
  void dispose() {
    SystemPreferencesService.instance.dispose();
    super.dispose();
  }

  // Build the UI - always start with LaunchScreen
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // Standard color inversion matrix (inverts RGB channels)
        final invertMatrix = <double>[
          -1,  0,  0, 0, 255,
           0, -1,  0, 0, 255,
           0,  0, -1, 0, 255,
           0,  0,  0, 1,   0,
        ];

        // Build a single MaterialApp instance and apply the ColorFiltered
        // in the `builder` so toggling inversion doesn't recreate the app
        // (which would reset navigation state).
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppStrings.appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          // navigatorKey: NavigationService.navigatorKey,
          home: const LaunchScreen(),
          navigatorObservers: [BluetoothAdapterStateObserver()],
          builder: (context, child) {
            final content = child ?? const SizedBox.shrink();
            final colorInvertedContent = themeProvider.isColorInverted
                ? ColorFiltered(
                    colorFilter: ColorFilter.matrix(invertMatrix),
                    child: content,
                  )
                : content;
            
            // Wrap with magnification to enable magnifying lens on all pages
            return MagnificationWrapper(
              child: colorInvertedContent,
            );
          },
        );
      },
    );
  }

}

// This class ensures the app reacts immediately to Bluetooth turning off while connected to a device, without keeping listeners active unnecessarily.
class BluetoothAdapterStateObserver extends NavigatorObserver {
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == '/SolariScreen') {
      // Start listening to Bluetooth state changes when connected to smart glasses
      _adapterStateSubscription ??= FlutterBluePlus.adapterState.listen((
        state,
      ) {
        if (state != BluetoothAdapterState.on) {
          // Disconnect from smart glasses if Bluetooth is off
          if (navigator?.canPop() ?? false) {
            navigator?.pop();
          }
        }
      });
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    // Cancel the subscription when disconnecting from smart glasses
    _adapterStateSubscription?.cancel();
    _adapterStateSubscription = null;
  }
}
