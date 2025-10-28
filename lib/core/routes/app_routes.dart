import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../screens/device_connection/launch_screen.dart';
import '../../screens/device_connection/bluetooth_router_screen.dart';
import '../../screens/solari_main_screen.dart';
import '../../screens/tabs/settings/about.dart';
import '../../screens/tabs/settings/device_status.dart';
import '../../screens/tabs/settings/faqs.dart';
import '../../screens/tabs/settings/preference.dart';
import '../../screens/tabs/settings/terms_of_use.dart';
import '../../screens/tabs/settings/tutorials.dart';

/// Central route management for the app
class AppRoutes {
  // Route names
  static const String launch = '/';
  static const String bluetoothRouter = '/bluetooth-router';
  static const String solari = '/solari';
  static const String deviceStatus = '/device-status';
  static const String preferences = '/preferences';
  static const String about = '/about';
  static const String faqs = '/faqs';
  static const String tutorials = '/tutorials';
  static const String terms = '/terms';
  
  // Device connection screens (where voice assist button should be hidden)
  static const List<String> deviceConnectionRoutes = [
    launch,
    bluetoothRouter,
  ];
  
  // Main app screens (where voice assist button should be shown)
  static const List<String> mainAppRoutes = [
    solari,
    deviceStatus,
    preferences,
    about,
    faqs,
    tutorials,
    terms,
  ];
  
  /// Check if a route is a device connection screen
  static bool isDeviceConnectionRoute(String? routeName) {
    if (routeName == null) {
      return false; // Show button if route is null
    }
    return deviceConnectionRoutes.contains(routeName);
  }
  
  /// Check if a route is in the main app
  static bool isMainAppRoute(String? routeName) {
    return routeName != null && mainAppRoutes.contains(routeName);
  }
  
  /// Generate routes
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case launch:
        return MaterialPageRoute(
          builder: (_) => const LaunchScreen(),
          settings: settings,
        );
        
      case bluetoothRouter:
        return MaterialPageRoute(
          builder: (_) => const BluetoothRouterScreen(),
          settings: settings,
        );
        
      case solari:
        // Support both BluetoothDevice directly and Map with device + isMock
        BluetoothDevice? device;
        bool isMock = false;
        
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          device = args['device'] as BluetoothDevice?;
          isMock = args['isMock'] as bool? ?? false;
        } else if (settings.arguments is BluetoothDevice) {
          device = settings.arguments as BluetoothDevice;
        }
        
        if (device == null) {
          // Fallback to bluetooth router if no device provided
          return MaterialPageRoute(
            builder: (_) => const BluetoothRouterScreen(),
            settings: const RouteSettings(name: bluetoothRouter),
          );
        }
        return MaterialPageRoute(
          builder: (_) => SolariScreen(device: device!, isMock: isMock),
          settings: settings,
        );
        
      case deviceStatus:
        final device = settings.arguments as BluetoothDevice?;
        if (device == null) return null;
        return MaterialPageRoute(
          builder: (_) => DeviceStatusPage(device: device),
          settings: settings,
        );
        
      case preferences:
        return MaterialPageRoute(
          builder: (_) => const PreferencePage(),
          settings: settings,
        );
        
      case about:
        return MaterialPageRoute(
          builder: (_) => const AboutPage(),
          settings: settings,
        );
        
      case faqs:
        return MaterialPageRoute(
          builder: (_) => const FAQsScreen(),
          settings: settings,
        );
        
      case tutorials:
        return MaterialPageRoute(
          builder: (_) => const TutorialsScreen(),
          settings: settings,
        );
        
      case terms:
        return MaterialPageRoute(
          builder: (_) => const TermsOfUsePage(),
          settings: settings,
        );
        
      default:
        return null;
    }
  }
}
