import 'dart:async';

// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

// Core
import 'core/providers/history_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/routes/app_routes.dart';
import 'core/services/services.dart';
import 'core/theme/app_theme.dart';

// Widgets
import 'widgets/widgets.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize accessibility services with error handling
  try {
    await ScreenReaderService().initialize();
  } catch (e) {
    debugPrint('Warning: ScreenReaderService initialization failed: $e');
  }
  
  try {
    await SelectToSpeakService().initialize();
  } catch (e) {
    debugPrint('Warning: SelectToSpeakService initialization failed: $e');
  }
  
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

// Global navigator key for accessing navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
          title: 'Solari',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          navigatorKey: navigatorKey, // Add global navigator key
          initialRoute: AppRoutes.launch,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          navigatorObservers: [
            RouteTracker(), // Track current route for voice assist button
            BluetoothAdapterStateObserver(),
            RouteObserver<ModalRoute<void>>(), // Add RouteObserver
          ],
          builder: (context, child) {
            final content = child ?? const SizedBox.shrink();
            
            // Wrap content with voice assist overlay first
            final contentWithVoiceAssist = GlobalVoiceAssistOverlay(
              child: content,
            );
            
            // Then apply color inversion if enabled
            final colorInvertedContent = themeProvider.isColorInverted
                ? ColorFiltered(
                    colorFilter: ColorFilter.matrix(invertMatrix),
                    child: contentWithVoiceAssist,
                  )
                : contentWithVoiceAssist;
            
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

/// Global overlay that shows voice assist button on all screens except device connection screens
class GlobalVoiceAssistOverlay extends StatefulWidget {
  final Widget child;
  
  const GlobalVoiceAssistOverlay({
    super.key,
    required this.child,
  });

  @override
  State<GlobalVoiceAssistOverlay> createState() => _GlobalVoiceAssistOverlayState();
}

/// Tracks the current route for the voice assist button
class RouteTracker extends NavigatorObserver {
  static final ValueNotifier<String?> currentRouteNotifier = ValueNotifier<String?>(null);
  
  void _updateRoute(Route? route) {
    currentRouteNotifier.value = route?.settings.name;
    debugPrint('RouteTracker: Current route = ${route?.settings.name}');
  }
  
  @override
  void didPush(Route route, Route? previousRoute) {
    _updateRoute(route);
  }
  
  @override
  void didPop(Route route, Route? previousRoute) {
    _updateRoute(previousRoute);
  }
  
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _updateRoute(newRoute);
  }
  
  @override
  void didRemove(Route route, Route? previousRoute) {
    _updateRoute(previousRoute);
  }
}

class _GlobalVoiceAssistOverlayState extends State<GlobalVoiceAssistOverlay> with WidgetsBindingObserver {
  String? _currentRoute;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Listen to route changes
    RouteTracker.currentRouteNotifier.addListener(_onRouteChanged);
    _currentRoute = RouteTracker.currentRouteNotifier.value;
  }

  @override
  void dispose() {
    RouteTracker.currentRouteNotifier.removeListener(_onRouteChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  void _onRouteChanged() {
    if (mounted) {
      setState(() {
        _currentRoute = RouteTracker.currentRouteNotifier.value;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDeviceConnectionScreen = AppRoutes.isDeviceConnectionRoute(_currentRoute);
    
    // Determine position based on current route
    // Main screen (/solari) has bottom nav, so button should be higher
    final isMainScreen = _currentRoute == AppRoutes.solari;
    final buttonBottom = isMainScreen ? 130.0 : 16.0;
    
    // Debug output
    debugPrint('Voice Assist Button - Route: $_currentRoute, IsDeviceConnection: $isDeviceConnectionScreen, IsMainScreen: $isMainScreen, Bottom: $buttonBottom');
    
    return Stack(
      children: [
        widget.child,
        // Voice assist button - hide on device connection screens
        if (!isDeviceConnectionScreen)
          Positioned(
            right: 16,
            bottom: buttonBottom,
            child: const VoiceAssistButton(),
          ),
      ],
    );
  }
}

// This class ensures the app reacts immediately to Bluetooth turning off while connected to a device, without keeping listeners active unnecessarily.
class BluetoothAdapterStateObserver extends NavigatorObserver {
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == AppRoutes.solari) {
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
