import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Service for Speech-to-Text recognition
/// Handles voice input for voice assist commands
class SttService extends ChangeNotifier {
  static final SttService _instance = SttService._internal();
  factory SttService() => _instance;
  SttService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _recognizedText = '';
  String _partialText = '';
  double _confidence = 0.0;

  // Callbacks
  Function(String)? onResult;
  Function(String)? onPartialResult;
  Function(String)? onError;
  Function()? onListeningStart;
  Function()? onListeningStop;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;
  String get partialText => _partialText;
  double get confidence => _confidence;

  /// Check if on-device speech recognition is available
  Future<bool> isOnDeviceAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (!_isInitialized) return false;
    
    try {
      // Check if on-device recognition is supported
      final locales = await _speech.locales();
      debugPrint('📱 Available speech locales: ${locales.length}');
      
      // If we have locales and initialization succeeded, on-device should be available
      return locales.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking on-device availability: $e');
      return false;
    }
  }

  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('❌ STT Error: ${error.errorMsg}');
          _handleError(error.errorMsg);
        },
        onStatus: (status) {
          debugPrint('🎤 STT Status: $status');
          if (status == 'done' || status == 'notListening') {
            _stopListening();
          }
        },
        // Enable on-device speech recognition for offline usage
        // These options tell Android to prefer on-device recognition
        options: [
          stt.SpeechToText.androidIntentLookup,
          stt.SpeechToText.webDoNotAggregate,
        ],
      );

      if (_isInitialized) {
        debugPrint('✅ STT Service initialized (on-device mode)');
      } else {
        debugPrint('❌ STT Service failed to initialize');
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('❌ STT Initialization error: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Start listening for voice input
  Future<void> startListening({
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) {
      _handleError('Speech recognition not available');
      return;
    }

    // Check permission
    if (!await hasPermission()) {
      final granted = await requestPermission();
      if (!granted) {
        _handleError('Microphone permission denied');
        return;
      }
    }

    try {
      _isListening = true;
      _recognizedText = '';
      _partialText = '';
      _confidence = 0.0;
      notifyListeners();
      
      onListeningStart?.call();

      // Get available locales and try to find English if no locale specified
      String? selectedLocale = localeId;
      if (selectedLocale == null) {
        final locales = await _speech.locales();
        debugPrint('📱 Available locales: ${locales.map((l) => l.localeId).toList()}');
        
        // Try to find en_US or any English locale
        final enLocale = locales.firstWhere(
          (l) => l.localeId.startsWith('en_'),
          orElse: () => locales.isNotEmpty ? locales.first : stt.LocaleName('', ''),
        );
        
        if (enLocale.localeId.isNotEmpty) {
          selectedLocale = enLocale.localeId;
          debugPrint('🌐 Using locale: $selectedLocale');
        }
      }

      await _speech.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          _confidence = result.confidence;
          
          if (result.finalResult) {
            debugPrint('✅ Final result: $_recognizedText (confidence: $_confidence)');
            onResult?.call(_recognizedText);
          } else {
            _partialText = result.recognizedWords;
            debugPrint('🎤 Partial: $_partialText');
            onPartialResult?.call(_partialText);
          }
          
          notifyListeners();
        },
        localeId: selectedLocale,
        listenFor: listenFor ?? const Duration(seconds: 5),
        pauseFor: pauseFor ?? const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
        onDevice: true, // Force on-device speech recognition for offline usage
      );

      debugPrint('🎤 Started listening (on-device mode with locale: $selectedLocale)...');
    } catch (e) {
      debugPrint('❌ Error starting listening: $e');
      _handleError('Failed to start listening: $e');
      _stopListening();
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _stopListening();
      debugPrint('🛑 Stopped listening');
    } catch (e) {
      debugPrint('❌ Error stopping listening: $e');
      _stopListening();
    }
  }

  /// Cancel listening
  Future<void> cancel() async {
    if (!_isListening) return;

    try {
      await _speech.cancel();
      _stopListening();
      debugPrint('❌ Cancelled listening');
    } catch (e) {
      debugPrint('❌ Error cancelling listening: $e');
      _stopListening();
    }
  }

  /// Internal method to update listening state
  void _stopListening() {
    _isListening = false;
    onListeningStop?.call();
    notifyListeners();
  }

  /// Handle errors
  void _handleError(String error) {
    _isListening = false;
    
    // Provide more specific error messages for common issues
    String userFriendlyError = error;
    if (error.contains('error_language_unavailable')) {
      userFriendlyError = 'language_unavailable';
    } else if (error.contains('error_network')) {
      userFriendlyError = 'network_error';
    } else if (error.contains('error_no_match')) {
      userFriendlyError = 'no_match';
    }
    
    onError?.call(userFriendlyError);
    notifyListeners();
  }

  /// Get available locales for speech recognition
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _speech.locales();
  }

  /// Dispose resources
  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
