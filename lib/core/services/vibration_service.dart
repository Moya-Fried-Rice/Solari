import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage vibration feedback throughout the app
class VibrationService {
  /// Key for storing vibration preference status
  static const String _vibrationEnabledKey = 'vibration_enabled';
  
  /// Check if vibration is enabled in preferences
  static Future<bool> isVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationEnabledKey) ?? true; // Enabled by default
  }
  
  /// Toggle vibration feedback setting
  static Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, enabled);
  }
  
  /// Internal method to perform vibration if enabled
  static Future<void> _performVibration() async {
    if (await isVibrationEnabled() && await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 40, amplitude: 100);
    }
  }
  
  /// Perform a light vibration for general UI interaction
  static Future<void> lightFeedback() => _performVibration();
  
  /// Perform a medium vibration for confirmations
  static Future<void> mediumFeedback() => _performVibration();
  
  /// Perform a strong vibration for important actions
  static Future<void> strongFeedback() => _performVibration();
  
  /// Perform an error feedback vibration
  static Future<void> errorFeedback() => _performVibration();
  
  /// Perform a success feedback vibration
  static Future<void> successFeedback() => _performVibration();
}