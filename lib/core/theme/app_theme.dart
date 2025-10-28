import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide color constants
class AppColors {
  // Light theme colors
  static const Color lightPrimary = Color(0xFF015c8f);
  static const Color lightText = Colors.black;
  static const Color lightBackground = Colors.white;
  static const Color lightButtonText = Colors.white;
  static const Color lightUnselectedColor = Color(0xFF64b5f6);
  
  // Dark theme colors
  static const Color darkPrimary = Color(0xFF0fa9ff);
  static const Color darkText = Colors.white;
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkButtonText = Colors.black;
  static const Color darkUnselectedColor = Color(0xFF80CFFF);
  
  // High contrast light theme colors
  static const Color highContrastLightPrimary = Color(0xFF000000);
  static const Color highContrastLightText = Colors.black;
  static const Color highContrastLightBackground = Colors.white;
  static const Color highContrastLightButtonText = Colors.white;
  static const Color highContrastLightUnselectedColor = Color(0xFF666666);
  
  // High contrast dark theme colors
  static const Color highContrastDarkPrimary = Color(0xFFFFFFFF);
  static const Color highContrastDarkText = Colors.white;
  static const Color highContrastDarkBackground = Color(0xFF000000);
  static const Color highContrastDarkButtonText = Colors.black;
  static const Color highContrastDarkUnselectedColor = Color(0xFFCCCCCC);
}

/// Theme configurations for the app
class AppTheme {
  /// Creates the light theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.lightPrimary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightPrimary,
      ),
      textTheme: GoogleFonts.notoSansTextTheme(
        ThemeData.light().textTheme.apply(bodyColor: AppColors.lightText),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.lightPrimary,
        thickness: 10,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.lightPrimary.withOpacity(0.4)
              : AppColors.lightUnselectedColor.withOpacity(0.4);
        }),
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.lightPrimary
              : AppColors.lightUnselectedColor;
        }),
      ),
    );
  }

  /// Creates the dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.darkPrimary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkPrimary,
      ),
      textTheme: GoogleFonts.notoSansTextTheme(
        ThemeData.dark().textTheme.apply(bodyColor: AppColors.darkText),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.darkPrimary,
        thickness: 10,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.darkPrimary.withOpacity(0.4)
              : AppColors.darkUnselectedColor.withOpacity(0.4);
        }),
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.darkPrimary
              : AppColors.darkUnselectedColor;
        }),
      ),
    );
  }
}
