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
  
  /// Perform a light vibration for general UI interaction
  /// Now standardized to medium vibration
  static Future<void> lightFeedback() async {
    if (await isVibrationEnabled() && await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 40, amplitude: 100); // Using medium vibration
    }
  }
  
  /// Perform a medium vibration for confirmations
  static Future<void> mediumFeedback() async {
    if (await isVibrationEnabled() && await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 40, amplitude: 100);
    }
  }
  
  /// Perform a strong vibration for important actions
  /// Now standardized to medium vibration
  static Future<void> strongFeedback() async {
    if (await isVibrationEnabled() && await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 40, amplitude: 100); // Using medium vibration
    }
  }
  
  /// Perform a double vibration for error feedback
  /// Now standardized to medium vibration
  static Future<void> errorFeedback() async {
    if (await isVibrationEnabled() && await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 40, amplitude: 100); // Using medium vibration
    }
  }
  
  /// Perform a success pattern vibration
  /// Now standardized to medium vibration
  static Future<void> successFeedback() async {
    if (await isVibrationEnabled() && await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 40, amplitude: 100); // Using medium vibration
    }
  }
}