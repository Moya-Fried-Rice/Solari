import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

/// Provider for managing theme state throughout the app
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = AppConstants.defaultFontSize;

  /// Whether the app is in dark mode
  bool get isDarkMode => _isDarkMode;
  
  /// Current font size
  double get fontSize => _fontSize;

  /// Constructor - loads saved theme preferences
  ThemeProvider() {
    _loadTheme();
  }

  /// Toggle between light and dark mode
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveTheme();
    notifyListeners();
  }

  /// Set font size with constraints
  void setFontSize(double size) {
    if (size < AppConstants.minFontSize) size = AppConstants.minFontSize;
    if (size > AppConstants.maxFontSize) size = AppConstants.maxFontSize;
    _fontSize = size;
    _saveFontSize();
    notifyListeners();
  }

  /// Primary color based on theme
  Color get primaryColor => _isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary;
  
  /// Text color based on theme
  Color get textColor => _isDarkMode ? AppColors.darkText : AppColors.lightText;
  
  /// Label color based on theme (contrast with background)
  Color get labelColor => _isDarkMode ? AppColors.darkButtonText : AppColors.lightButtonText;
  
  /// Unselected item color
  Color get unselectedColor => _isDarkMode ? AppColors.darkUnselectedColor : AppColors.lightUnselectedColor;
  
  /// Divider color
  Color get dividerColor => primaryColor;
  
  /// Icon color
  Color get iconColor => labelColor;
  
  /// Button text color
  Color get buttonTextColor => labelColor;

  // --- Text styles ---
  
  /// Header text style - fixed size for app bar, not affected by user font size preferences
  TextStyle get headerStyle => TextStyle(
    fontSize: AppConstants.defaultFontSize + 8, 
    fontWeight: FontWeight.bold, 
    color: labelColor
  );
  
  /// Subheader text style - affected by user font size
  TextStyle get subHeaderStyle => TextStyle(
    fontSize: _fontSize + 8, 
    fontWeight: FontWeight.bold, 
    color: textColor
  );
  
  /// Label text style - affected by user font size
  TextStyle get labelStyle => TextStyle(
    fontSize: _fontSize + 4, 
    color: textColor
  );
  
  /// Button text style - affected by user font size
  TextStyle get buttonTextStyle => TextStyle(
    fontSize: _fontSize + 4, 
    fontWeight: FontWeight.w800, 
    color: buttonTextColor
  );

  // --- Persistence ---
  
  /// Load saved theme preferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    _fontSize = prefs.getDouble('fontSize') ?? AppConstants.defaultFontSize;
    notifyListeners();
  }

  /// Save current theme mode
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  /// Save current font size
  Future<void> _saveFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
  }
}
