import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tts_service.dart';

/// Service for managing select-to-speak functionality
/// Allows users to tap on text to have it read aloud
class SelectToSpeakService extends ChangeNotifier {
  static final SelectToSpeakService _instance = SelectToSpeakService._internal();
  factory SelectToSpeakService() => _instance;
  SelectToSpeakService._internal();

  final TtsService _ttsService = TtsService();
  bool _isEnabled = false;
  double _speechRate = 1.0; // Default speech rate (speed)
  bool _outputToSolari = true; // Default to Solari device output

  /// Get whether select-to-speak is currently enabled
  bool get isEnabled => _isEnabled;
  
  /// Get current speech rate
  double get speechRate => _speechRate;
  
  /// Get whether output should go to Solari device (true) or phone (false)
  bool get outputToSolari => _outputToSolari;

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
    _outputToSolari = prefs.getBool('selectToSpeakOutputToSolari') ?? true;
    debugPrint('Select-to-speak loaded: enabled=$_isEnabled, rate=$_speechRate, outputToSolari=$_outputToSolari');
  }

  /// Save preferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('selectToSpeakEnabled', _isEnabled);
    await prefs.setDouble('selectToSpeakRate', _speechRate);
    await prefs.setBool('selectToSpeakOutputToSolari', _outputToSolari);
    debugPrint('Select-to-speak saved: enabled=$_isEnabled, rate=$_speechRate, outputToSolari=$_outputToSolari');
  }

  /// Enable or disable select-to-speak
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _savePreferences();
    notifyListeners(); // Notify widgets of the change
    debugPrint('Select-to-speak ${enabled ? "enabled" : "disabled"}');
  }
  
  /// Set speech rate (speed)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.5, 2.0);
    _ttsService.setSpeechSpeed(_speechRate);
    await _savePreferences();
    notifyListeners(); // Notify widgets of the change
    debugPrint('Select-to-speak rate set to: $_speechRate');
  }
  
  /// Set output device (true for Solari device, false for phone)
  Future<void> setOutputToSolari(bool outputToSolari) async {
    _outputToSolari = outputToSolari;
    
    // Configure TTS service accordingly
    if (outputToSolari) {
      _ttsService.setBleTransmission(true);
    } else {
      _ttsService.setLocalPlayback(true);
    }
    
    await _savePreferences();
    notifyListeners(); // Notify widgets of the change
    debugPrint('Select-to-speak output device set to: ${outputToSolari ? "Solari device" : "Phone"}');
  }

  /// Speak the given text (used when text is tapped)
  Future<void> speakText(String text) async {
    if (!_isEnabled) return;
    
    try {
      // Ensure output device setting is applied
      if (_outputToSolari) {
        _ttsService.setBleTransmission(true);
      } else {
        _ttsService.setLocalPlayback(true);
      }
      
      await _ttsService.speakText(
        text,
        onStart: () => debugPrint('Speaking: "$text" via ${_outputToSolari ? "Solari device" : "Phone"}'),
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
