import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing VQA (Visual Question Answering) settings
/// Controls how VQA processes audio input and microphone source
class VqaSettingsService extends ChangeNotifier {
  static final VqaSettingsService _instance = VqaSettingsService._internal();
  factory VqaSettingsService() => _instance;
  VqaSettingsService._internal();

  bool _isVqaEnabled = true; // Default VQA enabled
  bool _useSolariMicrophone = true; // Default to Solari device microphone

  /// Get whether VQA transcription is enabled
  /// When false, always prompts "Describe the image" instead of transcribing
  bool get isVqaEnabled => _isVqaEnabled;
  
  /// Get whether to use Solari device microphone (true) or phone microphone (false)
  bool get useSolariMicrophone => _useSolariMicrophone;

  /// Initialize the service and load saved preferences
  Future<void> initialize() async {
    await _loadPreferences();
    debugPrint('VQA settings loaded: enabled=$_isVqaEnabled, useSolariMic=$_useSolariMicrophone');
  }

  /// Load saved preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isVqaEnabled = prefs.getBool('vqaEnabled') ?? true;
    _useSolariMicrophone = prefs.getBool('vqaUseSolariMicrophone') ?? true;
  }

  /// Save preferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vqaEnabled', _isVqaEnabled);
    await prefs.setBool('vqaUseSolariMicrophone', _useSolariMicrophone);
    debugPrint('VQA settings saved: enabled=$_isVqaEnabled, useSolariMic=$_useSolariMicrophone');
  }

  /// Enable or disable VQA transcription
  Future<void> setVqaEnabled(bool enabled) async {
    _isVqaEnabled = enabled;
    await _savePreferences();
    notifyListeners(); // Notify widgets of the change
    debugPrint('VQA transcription ${enabled ? "enabled" : "disabled"}');
  }
  
  /// Set microphone source (true for Solari device, false for phone)
  Future<void> setUseSolariMicrophone(bool useSolari) async {
    _useSolariMicrophone = useSolari;
    await _savePreferences();
    notifyListeners(); // Notify widgets of the change
    debugPrint('VQA microphone source set to: ${useSolari ? "Solari device" : "Phone"}');
  }

  /// Get the prompt text based on VQA settings
  String getPromptText() {
    if (_isVqaEnabled) {
      return "Please describe what you see or ask a question about the image.";
    } else {
      return "Describe the image";
    }
  }

  /// Check if audio transcription should be processed
  bool shouldTranscribeAudio() {
    return _isVqaEnabled;
  }
}