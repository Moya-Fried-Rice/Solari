/// Model class for user preferences
class UserPreferences {
  /// Whether screen reader is enabled
  final bool screenReaderEnabled;
  
  /// Screen reader speech speed (0-10)
  final int speed;
  
  /// Screen reader pitch (0-10)
  final int pitch;
  
  /// Whether dark mode is enabled
  final bool isDarkMode;
  
  /// Font size for UI
  final double fontSize;

  /// Creates a new user preferences object
  const UserPreferences({
    this.screenReaderEnabled = false,
    this.speed = 1,
    this.pitch = 1,
    this.isDarkMode = true,
    this.fontSize = 32.0,
  });
  
  /// Create a copy with some values changed
  UserPreferences copyWith({
    bool? screenReaderEnabled,
    int? speed,
    int? pitch,
    bool? isDarkMode,
    double? fontSize,
  }) {
    return UserPreferences(
      screenReaderEnabled: screenReaderEnabled ?? this.screenReaderEnabled,
      speed: speed ?? this.speed,
      pitch: pitch ?? this.pitch,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}
