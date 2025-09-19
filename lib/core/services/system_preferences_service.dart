import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'user_preferences_service.dart';

/// Service for handling system preferences and accessibility settings
class SystemPreferencesService extends ChangeNotifier {
  /// Singleton instance
  static final SystemPreferencesService instance = SystemPreferencesService._();

  /// Stream controllers for system preference changes
  final _themeController = StreamController<bool>.broadcast();
  final _fontScaleController = StreamController<double>.broadcast();
  final _accessibilityController = StreamController<bool>.broadcast();

  /// Streams that can be listened to for changes
  Stream<bool> get onThemeChange => _themeController.stream;
  Stream<double> get onFontScaleChange => _fontScaleController.stream;
  Stream<bool> get onAccessibilityChange => _accessibilityController.stream;

  /// Private constructor
  SystemPreferencesService._();

  /// Get system dark mode preference
  bool getSystemDarkMode(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    return brightness == Brightness.dark;
  }

  /// Get system font scale
  double getSystemFontScale(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }

  /// Get system screen reader status
  bool getSystemScreenReaderEnabled(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    return mediaQueryData.accessibleNavigation;
  }

  /// Convert system text scale to app font size
  double mapSystemScaleToFontSize(double scale) {
    // Map the system scale (typically 0.85-1.3) to our font size range (28-40)
    const double minFontSize = 28.0;
    const double maxFontSize = 40.0;
    const double defaultScale = 1.0;
    
    if (scale <= defaultScale) {
      // Below or at default: map 0.85-1.0 to 28-32
      return minFontSize + (scale - 0.85) * (4.0 / 0.15);
    } else {
      // Above default: map 1.0-1.3 to 32-40
      return 32.0 + (scale - 1.0) * ((maxFontSize - 32.0) / 0.3);
    }
  }

  /// Start listening to system preference changes
  void startListening(BuildContext context) {
    // Initial check of system preferences
    handleSystemPreferencesChanged(context);
    WidgetsBinding.instance.addObserver(_SystemPreferencesObserver(this, context));
  }

  /// Stop listening to system preference changes
  @override
  void dispose() {
    _themeController.close();
    _fontScaleController.close();
    _accessibilityController.close();
    super.dispose();
  }

  /// Update app preferences based on system changes
  Future<void> handleSystemPreferencesChanged(BuildContext context) async {
    final useSystemTheme = await PreferencesService.getUseSystemTheme();
    final useSystemFontSize = await PreferencesService.getUseSystemFontSize();
    final useSystemAccessibility = await PreferencesService.getUseSystemAccessibility();

    if (useSystemTheme) {
      final isDarkMode = getSystemDarkMode(context);
      _themeController.add(isDarkMode);
      await PreferencesService.setIsDarkMode(isDarkMode);
    }

    if (useSystemFontSize) {
      final scale = getSystemFontScale(context);
      final fontSize = mapSystemScaleToFontSize(scale);
      _fontScaleController.add(fontSize);
      await PreferencesService.setFontSize(fontSize);
    }

    if (useSystemAccessibility) {
      final screenReaderEnabled = getSystemScreenReaderEnabled(context);
      _accessibilityController.add(screenReaderEnabled);
      await PreferencesService.setScreenReaderEnabled(screenReaderEnabled);
    }
  }

  /// Get initial preferences based on system settings
  Map<String, dynamic> getInitialPreferences(BuildContext context) {
    final systemScale = getSystemFontScale(context);
    
    return {
      'isDarkMode': getSystemDarkMode(context),
      'fontSize': mapSystemScaleToFontSize(systemScale),
      'screenReaderEnabled': getSystemScreenReaderEnabled(context),
    };
  }
}

/// Observer for system preference changes
class _SystemPreferencesObserver extends WidgetsBindingObserver {
  final SystemPreferencesService _service;
  final BuildContext _context;

  _SystemPreferencesObserver(this._service, this._context);

  @override
  void didChangePlatformBrightness() {
    _service.handleSystemPreferencesChanged(_context);
  }

  @override
  void didChangeMetrics() {
    _service.handleSystemPreferencesChanged(_context);
  }

  @override
  void didChangeAccessibilityFeatures() {
    _service.handleSystemPreferencesChanged(_context);

  }
}