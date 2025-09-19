import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage user preferences
class PreferencesService {
  /// Keys for storing preferences
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _useSystemThemeKey = 'use_system_theme';
  static const String _isDarkModeKey = 'is_dark_mode';
  static const String _useSystemFontSizeKey = 'use_system_font_size';
  static const String _fontSizeKey = 'font_size';
  static const String _useSystemAccessibilityKey = 'use_system_accessibility';
  static const String _screenReaderEnabledKey = 'screen_reader_enabled';
  
  /// Check if the user has completed onboarding
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }
  
  /// Mark onboarding as completed
  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  /// Get whether to use system theme
  static Future<bool> getUseSystemTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useSystemThemeKey) ?? true; // Default to using system theme
  }

  /// Set whether to use system theme
  static Future<void> setUseSystemTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useSystemThemeKey, value);
  }

  /// Get dark mode setting
  static Future<bool> getIsDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isDarkModeKey) ?? false; // Default to light theme
  }

  /// Set dark mode setting
  static Future<void> setIsDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDarkModeKey, value);
  }

  /// Get whether to use system font size
  static Future<bool> getUseSystemFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useSystemFontSizeKey) ?? true; // Default to using system font size
  }

  /// Set whether to use system font size
  static Future<void> setUseSystemFontSize(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useSystemFontSizeKey, value);
  }

  /// Get font size setting
  static Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 32.0; // Default font size
  }

  /// Set font size setting
  static Future<void> setFontSize(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, value);
  }

  /// Get whether to use system accessibility settings
  static Future<bool> getUseSystemAccessibility() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useSystemAccessibilityKey) ?? true; // Default to using system accessibility
  }

  /// Set whether to use system accessibility settings
  static Future<void> setUseSystemAccessibility(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useSystemAccessibilityKey, value);
  }

  /// Get screen reader enabled setting
  static Future<bool> getScreenReaderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_screenReaderEnabledKey) ?? false;
  }

  /// Set screen reader enabled setting
  static Future<void> setScreenReaderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_screenReaderEnabledKey, value);
  }

  /// Reset all preferences (for testing purposes)
  static Future<void> resetAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Reset onboarding status
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompletedKey);
  }
}