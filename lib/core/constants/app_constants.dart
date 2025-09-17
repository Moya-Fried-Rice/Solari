/// App-wide constants used for consistent values throughout the app
class AppConstants {
  // App information
  static const String appName = 'Solari';
  static const String appTagline = 'Smart Glasses';
  
  // Animation durations
  static const Duration splashScreenDuration = Duration(seconds: 5);
  static const Duration buttonAnimationDuration = Duration(milliseconds: 90);
  
  // UI spacing
  static const double defaultPadding = 16.0;
  static const double largePadding = 20.0;
  static const double smallPadding = 8.0;
  
  // UI sizing
  static const double defaultButtonBorderRadius = 16.0;
  static const double defaultIconSize = 36.0;
  static const double smallIconSize = 28.0;
  static const double largeIconSize = 40.0;
  
  // Font sizes
  static const double defaultFontSize = 32.0;
  static const double titleFontSize = 48.0;
  static const double subtitleFontSize = 40.0;
  static const double headerFontSize = 40.0;
  static const double bodyFontSize = 36.0;
  static const double captionFontSize = 20.0;
  
  // Min/Max values
  static const double minFontSize = 28.0;
  static const double maxFontSize = 48.0;
  static const int minSpeedPitch = 0;
  static const int maxSpeedPitch = 10;
  static const int speedPitchStep = 2;
}
