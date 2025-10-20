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
      );

      if (_isInitialized) {
        debugPrint('✅ STT Service initialized');
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
        listenFor: listenFor ?? const Duration(seconds: 5),
        pauseFor: pauseFor ?? const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      debugPrint('🎤 Started listening...');
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
    onError?.call(error);
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
