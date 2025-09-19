import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../services/system_preferences_service.dart';
import '../theme/app_colors.dart';

/// Provider for managing theme state throughout the app
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  bool _hasUserSetTheme = false;
  double _fontSize = AppConstants.defaultFontSize;
  bool _hasUserSetFontSize = false;
  double _lineHeight = 1.2; // Default line height

  /// Whether the app is in dark mode
  bool get isDarkMode => _isDarkMode;

  /// Whether the user has manually set the theme
  bool get hasUserSetTheme => _hasUserSetTheme;
  
  /// Current font size
  double get fontSize => _fontSize;

  /// Whether the user has manually set the font size
  bool get hasUserSetFontSize => _hasUserSetFontSize;
  
  /// Current line height
  double get lineHeight => _lineHeight;

  /// Constructor - loads saved theme preferences and sets up system listeners
  ThemeProvider() {
    _loadTheme();
    _setupSystemListeners();
  }

  /// Set up system preference listeners
  void _setupSystemListeners() {
    // Listen for system theme changes
    SystemPreferencesService.instance.onThemeChange.listen((isDark) {
      if (!_hasUserSetTheme) {
        _isDarkMode = isDark;
        _saveTheme();
        notifyListeners();
      }
    });

    // Listen for system font scale changes
    SystemPreferencesService.instance.onFontScaleChange.listen((fontSize) {
      if (!_hasUserSetFontSize) {
        setSystemFontSize(fontSize);
      }
    });
  }

  /// Toggle between light and dark mode
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _hasUserSetTheme = true;
    _saveTheme();
    notifyListeners();
  }

  /// Set dark mode from system preference
  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
    _saveTheme();
    notifyListeners();
  }

  /// Set font size with constraints
  void setFontSize(double size) {
    if (size < AppConstants.minFontSize) size = AppConstants.minFontSize;
    if (size > AppConstants.maxFontSize) size = AppConstants.maxFontSize;
    _fontSize = size;
    _hasUserSetFontSize = true;
    _saveFontSize();
    notifyListeners();
  }

  /// Set the font size from system preference (won't mark as user set)
  void setSystemFontSize(double size) {
    if (!_hasUserSetFontSize) {
      if (size < AppConstants.minFontSize) size = AppConstants.minFontSize;
      if (size > AppConstants.maxFontSize) size = AppConstants.maxFontSize;
      _fontSize = size;
      _saveFontSize();
      notifyListeners();
    }
  }
  
  /// Set line height with constraints
  void setLineHeight(double height) {
    // Constrain line height between min and max values
    if (height < AppConstants.minLineHeight) height = AppConstants.minLineHeight;
    if (height > AppConstants.maxLineHeight) height = AppConstants.maxLineHeight;
    _lineHeight = height;
    _saveLineHeight();
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
  
  /// Subheader text style - affected by user font size and line height
  TextStyle get subHeaderStyle => TextStyle(
    fontSize: _fontSize + 8, 
    fontWeight: FontWeight.bold, 
    color: textColor,
    height: _lineHeight
  );
  
  /// Label text style - affected by user font size and line height
  TextStyle get labelStyle => TextStyle(
    fontSize: _fontSize + 4, 
    color: textColor,
    height: _lineHeight
  );
  
  /// Button text style - affected by user font size
  TextStyle get buttonTextStyle => TextStyle(
    fontSize: _fontSize + 4, 
    fontWeight: FontWeight.w800, 
    color: buttonTextColor,
    height: _lineHeight
  );

  // --- Persistence ---
  
  /// Load saved theme preferences
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    _hasUserSetTheme = prefs.getBool('hasUserSetTheme') ?? false;
    _fontSize = prefs.getDouble('fontSize') ?? AppConstants.defaultFontSize;
    _hasUserSetFontSize = prefs.getBool('hasUserSetFontSize') ?? false;
    _lineHeight = prefs.getDouble('lineHeight') ?? 1.2; // Default is 1.2
    notifyListeners();
  }

  /// Save current theme mode
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('hasUserSetTheme', _hasUserSetTheme);
  }

  /// Save current font size
  Future<void> _saveFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setBool('hasUserSetFontSize', _hasUserSetFontSize);
  }
  
  /// Save current line height
  Future<void> _saveLineHeight() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lineHeight', _lineHeight);
  }
}
