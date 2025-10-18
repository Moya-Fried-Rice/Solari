import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tts_service.dart';

/// Service for managing select-to-speak functionality
/// Allows users to tap on text to have it read aloud
class SelectToSpeakService {
  static final SelectToSpeakService _instance = SelectToSpeakService._internal();
  factory SelectToSpeakService() => _instance;
  SelectToSpeakService._internal();

  final TtsService _ttsService = TtsService();
  bool _isEnabled = false;
  double _speechRate = 1.0; // Default speech rate (speed)
  double _pitch = 1.0; // Default pitch

  /// Get whether select-to-speak is currently enabled
  bool get isEnabled => _isEnabled;
  
  /// Get current speech rate
  double get speechRate => _speechRate;
  
  /// Get current pitch
  double get pitch => _pitch;

  /// Initialize the service and load saved preferences
  Future<void> initialize() async {
    await _loadPreferences();
    await _ttsService.initialize();
  }

  /// Load saved preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('selectToSpeakEnabled') ?? false;
    _speechRate = prefs.getDouble('selectToSpeakRate') ?? 1.0;
    _pitch = prefs.getDouble('selectToSpeakPitch') ?? 1.0;
    debugPrint('Select-to-speak loaded: enabled=$_isEnabled, rate=$_speechRate, pitch=$_pitch');
  }

  /// Save preferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('selectToSpeakEnabled', _isEnabled);
    await prefs.setDouble('selectToSpeakRate', _speechRate);
    await prefs.setDouble('selectToSpeakPitch', _pitch);
    debugPrint('Select-to-speak saved: enabled=$_isEnabled, rate=$_speechRate, pitch=$_pitch');
  }

  /// Enable or disable select-to-speak
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _savePreferences();
    debugPrint('Select-to-speak ${enabled ? "enabled" : "disabled"}');
  }
  
  /// Set speech rate (speed)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.5, 2.0);
    _ttsService.setSpeechSpeed(_speechRate);
    await _savePreferences();
    debugPrint('Select-to-speak rate set to: $_speechRate');
  }
  
  /// Set pitch
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    _ttsService.setSpeechPitch(_pitch);
    await _savePreferences();
    debugPrint('Select-to-speak pitch set to: $_pitch');
  }

  /// Speak the given text (used when text is tapped)
  Future<void> speakText(String text) async {
    if (!_isEnabled) return;
    
    try {
      await _ttsService.speakText(
        text,
        onStart: () => debugPrint('Speaking: "$text"'),
        onComplete: () => debugPrint('Finished speaking'),
        onError: (error) => debugPrint('Error speaking: $error'),
      );
    } catch (e) {
      debugPrint('Error in select-to-speak: $e');
    }
  }

  /// Stop any currently playing speech
  Future<void> stopSpeaking() async {
    await _ttsService.stopSpeaking();
  }
}
