import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

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
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          return states.contains(MaterialState.selected)
              ? AppColors.lightPrimary.withOpacity(0.4)
              : AppColors.lightUnselectedColor.withOpacity(0.4);
        }),
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          return states.contains(MaterialState.selected)
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
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          return states.contains(MaterialState.selected)
              ? AppColors.darkPrimary.withOpacity(0.4)
              : AppColors.darkUnselectedColor.withOpacity(0.4);
        }),
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          return states.contains(MaterialState.selected)
              ? AppColors.darkPrimary
              : AppColors.darkUnselectedColor;
        }),
      ),
    );
  }
}
