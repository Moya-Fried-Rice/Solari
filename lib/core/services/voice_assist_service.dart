import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'stt_service.dart';
import 'tts_service.dart';
import 'screen_reader_service.dart';
import 'select_to_speak_service.dart';
import 'magnification_service.dart';
import 'vibration_service.dart';
import '../providers/theme_provider.dart';

/// Voice Assist Service
/// Processes voice commands to control navigation and settings
class VoiceAssistService extends ChangeNotifier {
  static final VoiceAssistService _instance = VoiceAssistService._internal();
  factory VoiceAssistService() => _instance;
  VoiceAssistService._internal();

  final SttService _sttService = SttService();
  final TtsService _ttsService = TtsService();
  bool _isEnabled = false;
  bool _isListening = false;
  String _lastCommand = '';
  
  // Callbacks for UI actions
  Function(int)? _navigationCallback;
  Function(String, bool)? _featureToggleCallback;
  Function(String)? _settingsNavigationCallback;
  VoidCallback? _goBackCallback;
  bool Function()? _canPopCallback;
  ThemeProvider? _themeProvider;

  bool get isEnabled => _isEnabled;
  bool get isListening => _isListening;
  String get lastCommand => _lastCommand;
  
  static const String _voiceAssistKey = 'voice_assist_enabled';

  /// Initialize voice assist service
  Future<void> initialize() async {
    await _ttsService.initialize();
    
    // Enable mobile mode for STT (use device microphone instead of hardware)
    _sttService.setMobileMode(true);
    await _sttService.initializeMobile();
    
    // Load saved state
    await loadEnabledState();
    
    debugPrint('✅ Voice Assist Service initialized (enabled: $_isEnabled, using mobile STT)');
  }
  
  /// Load enabled state from SharedPreferences
  Future<void> loadEnabledState() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_voiceAssistKey) ?? false;
    notifyListeners();
  }
  
  /// Set enabled state
  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceAssistKey, value);
    _isEnabled = value;
    
    if (!value && _isListening) {
      // Stop listening if disabled while listening
      await _sttService.stopListening();
      _isListening = false;
    }
    
    notifyListeners();
    debugPrint('Voice Assist ${value ? 'enabled' : 'disabled'}');
  }

  /// Set navigation callback (for changing tabs)
  void setNavigationCallback(Function(int) callback) {
    _navigationCallback = callback;
    debugPrint('✅ Navigation callback set');
  }

  /// Set feature toggle callback (for enabling/disabling features)
  void setFeatureToggleCallback(Function(String, bool) callback) {
    _featureToggleCallback = callback;
    debugPrint('✅ Feature toggle callback set');
  }
  
  /// Set settings navigation callback (for navigating to settings pages)
  void setSettingsNavigationCallback(Function(String) callback) {
    _settingsNavigationCallback = callback;
    debugPrint('✅ Settings navigation callback set');
  }
  
  /// Set go back callback (for navigating back)
  void setGoBackCallback(VoidCallback callback) {
    _goBackCallback = callback;
    debugPrint('✅ Go back callback set');
  }
  
  /// Set can pop callback (for checking if navigation can pop)
  void setCanPopCallback(bool Function() callback) {
    _canPopCallback = callback;
    debugPrint('✅ Can pop callback set');
  }

  /// Set theme provider reference
  void setThemeProvider(ThemeProvider provider) {
    _themeProvider = provider;
  }

  /// Start listening for voice commands
  Future<void> startListening() async {
    // Check if voice assist is enabled
    if (!_isEnabled) {
      debugPrint('⚠️ Voice assist is disabled');
      await _speakFeedback('Voice assist is disabled. Please enable it in settings.');
      return;
    }
    
    // Check if on-device speech recognition is available
    final isOnDeviceAvailable = await _sttService.isOnDeviceAvailable();
    if (!isOnDeviceAvailable) {
      debugPrint('⚠️ On-device speech recognition not available');
      await _speakFeedback('Speech recognition requires a one-time internet connection to download on-device models. Please connect to the internet and try again.');
      return;
    }
    
    if (_isListening) {
      debugPrint('⚠️ Already listening');
      return;
    }

    _isListening = true;
    notifyListeners();

    // Set up callbacks
    _sttService.onResult = (text) {
      debugPrint('🎤 Voice command received: $text');
      _lastCommand = text;
      // Process command asynchronously without blocking
      _processCommand(text).catchError((error) {
        debugPrint('❌ Error processing command: $error');
      });
    };

    _sttService.onPartialResult = (text) {
      debugPrint('🎤 Partial: $text');
    };

    _sttService.onError = (error) {
      debugPrint('❌ STT Error: $error');
      
      // Provide specific feedback based on error type
      String feedback;
      if (error.contains('language_unavailable')) {
        feedback = 'On-device speech recognition is not available for your language. '
                  'Please connect to the internet once to download the language pack, '
                  'or change your device language to English in system settings.';
      } else if (error.contains('network_error') || error.contains('error_network')) {
        // Network errors shouldn't happen with on-device mode
        // This likely means the on-device model isn't available
        feedback = 'On-device speech recognition model not found. '
                  'To use voice assist offline, please: '
                  '1. Go to your device Settings > Apps > Google > Speech Recognition & Synthesis. '
                  '2. Download the offline speech pack for English. '
                  '3. After download completes, voice assist will work offline.';
      } else if (error.contains('no_match')) {
        feedback = 'I didn\'t catch that. Please try again.';
      } else {
        feedback = 'Sorry, I didn\'t catch that. Please try again.';
      }
      
      // Use .then() instead of await to avoid blocking
      _speakFeedback(feedback).then((_) {
        _isListening = false;
        notifyListeners();
      });
    };

    _sttService.onListeningStop = () {
      _isListening = false;
      notifyListeners();
    };

    // Start listening
    await _sttService.startListening(
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 2),
    );

    VibrationService.lightFeedback();
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    await _sttService.stopListening();
    _isListening = false;
    notifyListeners();
  }

  /// Process voice command
  Future<void> _processCommand(String command) async {
    final lowerCommand = command.toLowerCase().trim();
    debugPrint('🔍 Processing command: "$lowerCommand"');
    
    // Navigation commands
    if (_matchesPattern(lowerCommand, ['go back', 'back', 'navigate back', 'previous', 'return'])) {
      debugPrint('✅ Matched: go back');
      await _goBack();
    } else if (_matchesPattern(lowerCommand, ['go home', 'show home', 'open solari', 'home'])) {
      debugPrint('✅ Matched: go home');
      await _navigate(0, 'Opening Solari');
    } else if (_matchesPattern(lowerCommand, ['go to settings', 'open settings', 'settings', 'show settings'])) {
      debugPrint('✅ Matched: open settings');
      await _navigate(1, 'Opening settings');
    } else if (_matchesPattern(lowerCommand, ['show history', 'open history', 'history', 'go to history'])) {
      debugPrint('✅ Matched: show history');
      await _navigate(2, 'Opening history');
    }
    
    // Settings page navigation commands
    else if (_matchesPattern(lowerCommand, ['device status', 'open device status', 'show device status', 'check device', 'bluetooth status'])) {
      await _navigateToSettingsPage('device_status', 'Opening device status');
    } else if (_matchesPattern(lowerCommand, ['preferences', 'open preferences', 'show preferences', 'accessibility settings'])) {
      await _navigateToSettingsPage('preferences', 'Opening preferences');
    } else if (_matchesPattern(lowerCommand, ['about', 'about solari', 'open about', 'app info', 'about app'])) {
      await _navigateToSettingsPage('about', 'Opening about');
    } else if (_matchesPattern(lowerCommand, ['faqs', 'open faqs', 'frequently asked questions', 'questions', 'faq'])) {
      await _navigateToSettingsPage('faqs', 'Opening FAQs');
    } else if (_matchesPattern(lowerCommand, ['tutorials', 'open tutorials', 'show tutorials', 'how to', 'guide', 'help tutorials'])) {
      await _navigateToSettingsPage('tutorials', 'Opening tutorials');
    } else if (_matchesPattern(lowerCommand, ['terms of use', 'terms', 'open terms', 'legal', 'terms and conditions'])) {
      await _navigateToSettingsPage('terms', 'Opening terms of use');
    }
    
    // Screen Reader commands
    else if (_matchesPattern(lowerCommand, ['enable screen reader', 'turn on screen reader', 'screen reader on', 'start screen reader'])) {
      await _toggleFeature('screen_reader', true, 'Screen reader enabled');
    } else if (_matchesPattern(lowerCommand, ['disable screen reader', 'turn off screen reader', 'screen reader off', 'stop screen reader'])) {
      await _toggleFeature('screen_reader', false, 'Screen reader disabled');
    }
    
    // Select to Speak commands
    else if (_matchesPattern(lowerCommand, ['enable select to speak', 'turn on select to speak', 'select to speak on'])) {
      await _toggleFeature('select_to_speak', true, 'Select to speak enabled');
    } else if (_matchesPattern(lowerCommand, ['disable select to speak', 'turn off select to speak', 'select to speak off'])) {
      await _toggleFeature('select_to_speak', false, 'Select to speak disabled');
    }
    
    // Magnification commands
    else if (_matchesPattern(lowerCommand, ['enable magnification', 'turn on magnification', 'enable zoom', 'turn on zoom', 'magnify', 'zoom in'])) {
      await _toggleFeature('magnification', true, 'Magnification enabled');
    } else if (_matchesPattern(lowerCommand, ['disable magnification', 'turn off magnification', 'disable zoom', 'turn off zoom', 'zoom out'])) {
      await _toggleFeature('magnification', false, 'Magnification disabled');
    }
    
    // High Contrast commands
    else if (_matchesPattern(lowerCommand, ['enable high contrast', 'turn on high contrast', 'high contrast on'])) {
      await _toggleFeature('high_contrast', true, 'High contrast enabled');
    } else if (_matchesPattern(lowerCommand, ['disable high contrast', 'turn off high contrast', 'high contrast off'])) {
      await _toggleFeature('high_contrast', false, 'High contrast disabled');
    }
    
    // Color Inversion commands
    else if (_matchesPattern(lowerCommand, ['enable color inversion', 'turn on color inversion', 'invert colors', 'color inversion on'])) {
      await _toggleFeature('color_inversion', true, 'Color inversion enabled');
    } else if (_matchesPattern(lowerCommand, ['disable color inversion', 'turn off color inversion', 'color inversion off', 'normal colors'])) {
      await _toggleFeature('color_inversion', false, 'Color inversion disabled');
    }
    
    // Vibration commands
    else if (_matchesPattern(lowerCommand, ['enable vibration', 'turn on vibration', 'enable haptics', 'vibration on'])) {
      await _toggleFeature('vibration', true, 'Vibration enabled');
    } else if (_matchesPattern(lowerCommand, ['disable vibration', 'turn off vibration', 'disable haptics', 'vibration off'])) {
      await _toggleFeature('vibration', false, 'Vibration disabled');
    }
    
    // Voice Assist commands
    else if (_matchesPattern(lowerCommand, ['enable voice assist', 'turn on voice assist', 'voice assist on', 'activate voice assist'])) {
      await _toggleFeature('voice_assist', true, 'Voice assist enabled');
    } else if (_matchesPattern(lowerCommand, ['disable voice assist', 'turn off voice assist', 'voice assist off', 'deactivate voice assist'])) {
      await _toggleFeature('voice_assist', false, 'Voice assist disabled');
    }
    
    // System Sync commands
    else if (_matchesPattern(lowerCommand, ['enable sync', 'turn on sync', 'enable system sync', 'sync on', 'use system theme'])) {
      await _toggleSystemSync(true, 'System sync enabled');
    } else if (_matchesPattern(lowerCommand, ['disable sync', 'turn off sync', 'disable system sync', 'sync off'])) {
      await _toggleSystemSync(false, 'System sync disabled');
    }
    
    // Theme commands
    else if (_matchesPattern(lowerCommand, ['dark mode', 'enable dark mode', 'turn on dark mode', 'dark theme'])) {
      await _setTheme(true, 'Dark mode enabled');
    } else if (_matchesPattern(lowerCommand, ['light mode', 'enable light mode', 'turn on light mode', 'light theme'])) {
      await _setTheme(false, 'Light mode enabled');
    }
    
    // Font size commands
    else if (_matchesPattern(lowerCommand, ['increase text size', 'larger text', 'bigger text', 'text larger'])) {
      await _adjustFontSize(2, 'Text size increased');
    } else if (_matchesPattern(lowerCommand, ['decrease text size', 'smaller text', 'text smaller', 'reduce text size'])) {
      await _adjustFontSize(-2, 'Text size decreased');
    }
    
    // Speech speed commands
    else if (_matchesPattern(lowerCommand, ['speed up', 'faster speech', 'speak faster', 'increase speed'])) {
      await _adjustSpeechSpeed(0.2, 'Speech speed increased');
    } else if (_matchesPattern(lowerCommand, ['slow down', 'slower speech', 'speak slower', 'decrease speed'])) {
      await _adjustSpeechSpeed(-0.2, 'Speech speed decreased');
    } else if (_matchesPattern(lowerCommand, ['normal speed', 'reset speed', 'default speed'])) {
      await _setSpeechSpeed(1.0, 'Speech speed reset to normal');
    }
    
    // Help command
    else if (_matchesPattern(lowerCommand, ['help', 'what can i say', 'commands', 'show commands'])) {
      await _showHelp();
    }
    
    // Unknown command
    else {
      await _speakFeedback('Sorry, I didn\'t understand that command. Say help for available commands.');
    }
  }

  /// Check if command matches any pattern
  bool _matchesPattern(String command, List<String> patterns) {
    return patterns.any((pattern) => command.contains(pattern));
  }

  /// Navigate to a tab
  Future<void> _navigate(int index, String feedback) async {
    debugPrint('📍 Navigating to tab $index');
    debugPrint('   _navigationCallback is ${_navigationCallback == null ? "NULL" : "SET"}');
    debugPrint('   _canPopCallback is ${_canPopCallback == null ? "NULL" : "SET"}');
    
    // First, pop back to main page if we're in a subpage
    final canPop = _canPopCallback?.call() ?? false;
    debugPrint('   canPop: $canPop');
    
    if (canPop) {
      debugPrint('   Popping navigation stack...');
      _goBackCallback?.call();
      // Small delay to allow navigation to complete
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // Then change the tab
    debugPrint('   Calling navigation callback with index $index');
    _navigationCallback?.call(index);
    
    await _speakFeedback(feedback);
    VibrationService.mediumFeedback();
  }
  
  /// Go back (navigate back)
  Future<void> _goBack() async {
    _goBackCallback?.call();
    await _speakFeedback('Going back');
    VibrationService.mediumFeedback();
  }
  
  /// Navigate to a settings page
  Future<void> _navigateToSettingsPage(String page, String feedback) async {
    // Navigate to the specific settings page (callback will handle tab switching)
    _settingsNavigationCallback?.call(page);
    
    await _speakFeedback(feedback);
    VibrationService.mediumFeedback();
  }

  /// Toggle a feature
  Future<void> _toggleFeature(String feature, bool enable, String feedback) async {
    switch (feature) {
      case 'screen_reader':
        final service = ScreenReaderService();
        await service.setEnabled(enable);
        break;
      case 'select_to_speak':
        final service = SelectToSpeakService();
        await service.setEnabled(enable);
        break;
      case 'magnification':
        final service = MagnificationService();
        service.setEnabled(enable);
        break;
      case 'high_contrast':
        if (_themeProvider != null) {
          await _themeProvider!.setHighContrast(enable);
        }
        break;
      case 'color_inversion':
        if (_themeProvider != null) {
          await _themeProvider!.setColorInversion(enable);
        }
        break;
      case 'vibration':
        await VibrationService.setVibrationEnabled(enable);
        // Manually trigger callback for vibration since it's not a ChangeNotifier
        _featureToggleCallback?.call(feature, enable);
        break;
      case 'voice_assist':
        // Don't toggle voice assist on itself to avoid conflicts
        await _speakFeedback('Voice assist cannot be toggled using voice commands. Please use the settings or button.');
        return;
    }
    
    _featureToggleCallback?.call(feature, enable);
    await _speakFeedback(feedback);
    VibrationService.mediumFeedback();
  }
  
  /// Toggle system sync (use system theme)
  Future<void> _toggleSystemSync(bool enable, String feedback) async {
    if (_themeProvider != null) {
      await _themeProvider!.setUseSystemTheme(enable);
      debugPrint('🔄 System sync set to $enable');
    }
    await _speakFeedback(feedback);
    VibrationService.mediumFeedback();
  }

  /// Set theme (dark/light)
  Future<void> _setTheme(bool isDark, String feedback) async {
    if (_themeProvider != null) {
      _themeProvider!.setDarkMode(isDark);
    }
    await _speakFeedback(feedback);
    VibrationService.mediumFeedback();
  }

  /// Adjust font size
  Future<void> _adjustFontSize(double delta, String feedback) async {
    if (_themeProvider != null) {
      const minSize = 28.0;
      const maxSize = 48.0;
      
      final currentSize = _themeProvider!.fontSize;
      final newSize = (currentSize + delta).clamp(minSize, maxSize);
      
      // Check if we're at the limit
      if (newSize == currentSize) {
        final limitMessage = delta > 0 
          ? 'Text size is already at maximum, ${currentSize.toInt()}'
          : 'Text size is already at minimum, ${currentSize.toInt()}';
        await _speakFeedback(limitMessage);
        return;
      }
      
      _themeProvider!.setFontSize(newSize);
      
      // Include current value in feedback
      final feedbackWithValue = delta > 0
        ? 'Text size increased to ${newSize.toInt()}'
        : 'Text size decreased to ${newSize.toInt()}';
      await _speakFeedback(feedbackWithValue);
    } else {
      await _speakFeedback(feedback);
    }
    VibrationService.lightFeedback();
  }

  /// Adjust speech speed
  Future<void> _adjustSpeechSpeed(double delta, String feedback) async {
    const minSpeed = 0.5;
    const maxSpeed = 2.0;
    
    final selectToSpeak = SelectToSpeakService();
    final currentSpeed = selectToSpeak.speechRate;
    final newSpeed = (currentSpeed + delta).clamp(minSpeed, maxSpeed);
    
    // Check if we're at the limit
    if (newSpeed == currentSpeed) {
      final limitMessage = delta > 0
        ? 'Speech speed is already at maximum, ${(currentSpeed * 100).toInt()} percent'
        : 'Speech speed is already at minimum, ${(currentSpeed * 100).toInt()} percent';
      await _speakFeedback(limitMessage);
      return;
    }
    
    await selectToSpeak.setSpeechRate(newSpeed);
    
    // Include current value in feedback
    final feedbackWithValue = delta > 0
      ? 'Speech speed increased to ${(newSpeed * 100).toInt()} percent'
      : 'Speech speed decreased to ${(newSpeed * 100).toInt()} percent';
    await _speakFeedback(feedbackWithValue);
    VibrationService.lightFeedback();
  }

  /// Set speech speed to specific value
  Future<void> _setSpeechSpeed(double speed, String feedback) async {
    final selectToSpeak = SelectToSpeakService();
    await selectToSpeak.setSpeechRate(speed);
    await _speakFeedback(feedback);
    VibrationService.lightFeedback();
  }

  /// Show help with available commands
  Future<void> _showHelp() async {
    final helpText = '''
Available voice commands:
Navigation: Go home, Open settings, Show history, Go back.
Features: Enable screen reader, Disable select to speak, Turn on magnification, Enable high contrast, Invert colors, Enable vibration.
Theme: Dark mode, Light mode, Increase text size, Enable sync.
Speech: Speed up, Slow down, Normal speed.
Say any command to get started.
''';
    await _speakFeedback(helpText);
  }

  /// Speak feedback to user
  Future<void> _speakFeedback(String text) async {
    await _ttsService.speakText(text);
  }

  /// Dispose resources
  @override
  void dispose() {
    _sttService.dispose();
    super.dispose();
  }
}
