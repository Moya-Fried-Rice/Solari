import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../utils/punctuation_helper.dart';

class SttService extends ChangeNotifier {
  // Hardware STT (Sherpa ONNX for Arduino microphone)
  sherpa_onnx.OfflineRecognizer? _recognizer;
  bool _isInitialized = false;
  final int _sampleRate = 16000; // Sherpa ONNX model expects 16kHz audio
  
  // Audio collection for offline processing (hardware)
  final List<double> _audioBuffer = [];
  bool _isRecording = false;
  
  // Mobile device STT (speech_to_text package)
  final stt.SpeechToText _mobileSpeech = stt.SpeechToText();
  bool _isMobileInitialized = false;
  bool _isMobileListening = false;
  String _mobileRecognizedText = '';
  bool _useMobileMode = false; // Flag to switch between hardware and mobile
  
  // Callbacks for mobile mode
  Function(String)? onResult;
  Function(String)? onPartialResult;
  Function(String)? onError;
  Function()? onListeningStart;
  Function()? onListeningStop;
  
  // Punctuation enhancement setting
  bool _enhancePunctuation = true;

  // Getters
  bool get isInitialized => _useMobileMode ? _isMobileInitialized : _isInitialized;
  bool get isListening => _useMobileMode ? _isMobileListening : _isRecording;
  String get recognizedText => _mobileRecognizedText;

  /// Copy the asset file from src to dst
  Future<String> _copyAssetFile(String src, [String? dst]) async {
    final Directory directory = await getApplicationSupportDirectory();
    if (dst == null) {
      dst = basename(src);
    }
    final target = join(directory.path, dst);
    bool exists = await File(target).exists();

    final data = await rootBundle.load(src);

    if (!exists || File(target).lengthSync() != data.lengthInBytes) {
      final List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(target).writeAsBytes(bytes);
    }

    return target;
  }

  /// Convert raw audio bytes to Float32List for Sherpa ONNX
  Float32List _convertBytesToFloat32(Uint8List bytes, [Endian endian = Endian.little]) {
    // Validate minimum audio chunk size to prevent processing errors
    if (bytes.length < 4) {
      debugPrint('[STT] ⚠️ Audio chunk too small (${bytes.length} bytes), skipping');
      return Float32List(0);
    }

    final values = Float32List(bytes.length ~/ 2);
    final data = ByteData.view(bytes.buffer);

      // Minimal audio debugging (only log occasionally to avoid performance impact)
      if (bytes.length >= 4 && values.length % 1000 == 0) {
        final firstSample = data.getInt16(0, endian);
        debugPrint('[STT] Audio processing: ${values.length} samples, first: $firstSample');
      }    for (var i = 0; i < bytes.length; i += 2) {
      int short = data.getInt16(i, endian);
      values[i ~/ 2] = short / 32768.0;
    }

    return values;
  }

  /// Get the offline model configuration for the GigaSpeech Zipformer model
  Future<sherpa_onnx.OfflineModelConfig> _getOfflineModelConfig() async {
    // Using the new GigaSpeech model for higher accuracy
    final modelDir = 'assets/sherpa-onnx-zipformer-gigaspeech-2023-12-12';
    
    return sherpa_onnx.OfflineModelConfig(
      transducer: sherpa_onnx.OfflineTransducerModelConfig(
        encoder: await _copyAssetFile(
            '$modelDir/encoder-epoch-30-avg-1.onnx'),
        decoder: await _copyAssetFile(
            '$modelDir/decoder-epoch-30-avg-1.onnx'),
        joiner: await _copyAssetFile(
            '$modelDir/joiner-epoch-30-avg-1.onnx'),
      ),
      tokens: await _copyAssetFile('$modelDir/tokens.txt'),
      modelType: 'zipformer2',
    );
  }

  /// Create offline recognizer configuration for the GigaSpeech model
  Future<sherpa_onnx.OfflineRecognizer> _createOfflineRecognizer() async {
    final modelConfig = await _getOfflineModelConfig();
    final config = sherpa_onnx.OfflineRecognizerConfig(
      model: modelConfig,
      ruleFsts: '',
    );

    return sherpa_onnx.OfflineRecognizer(config);
  }

  /// Initialize the STT service with Sherpa ONNX
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;
      
      debugPrint('🎤 Initializing STT service...');
      debugPrint('🔄 Using offline GigaSpeech model for higher accuracy');
      debugPrint('⚠️  IMPORTANT: Ensure Arduino microphone is configured for ${_sampleRate}Hz sample rate');
      debugPrint('⚠️  Current Arduino config shows MICROPHONE_SAMPLE_RATE = 8000 (should be $_sampleRate)');
      
      // Initialize Sherpa ONNX bindings
      sherpa_onnx.initBindings();
      
      // Create the offline recognizer
      _recognizer = await _createOfflineRecognizer();
      
      _isInitialized = true;
      debugPrint('✅ STT service initialized successfully with GigaSpeech model');
      
    } catch (e) {
      debugPrint('❌ Error initializing STT service: $e');
      debugPrint('⚠️ STT service will not be available. Please ensure Sherpa ONNX models are installed.');
      _isInitialized = false;
      // Don't rethrow - allow app to continue without hardware STT
    }
  }

  /// Start recording - collect audio chunks for offline processing
  void startRecording() {
    if (!_isInitialized) {
      debugPrint('❌ STT service not initialized');
      return;
    }
    
    _audioBuffer.clear();
    _isRecording = true;
    debugPrint('🎤 Started recording audio for offline transcription');
  }

  /// Process and collect audio chunk data received from BLE
  Future<String?> processAudioChunk(List<int> audioChunk) async {
    if (!_isInitialized || _recognizer == null) {
      debugPrint('❌ STT service not initialized');
      return null;
    }

    if (!_isRecording) {
      debugPrint('❌ Not currently recording');
      return null;
    }

    try {
      // Validate audio chunk size
      if (audioChunk.length < 2) {
        debugPrint('[STT] ⚠️ Received very small audio chunk (${audioChunk.length} bytes), skipping');
        return 'Recording...';
      }

      // Convert the raw audio bytes to Float32List and add to buffer
      final audioBytes = Uint8List.fromList(audioChunk);
      final samplesFloat32 = _convertBytesToFloat32(audioBytes);
      
      // Only add valid samples to buffer
      if (samplesFloat32.isNotEmpty) {
        _audioBuffer.addAll(samplesFloat32);
      }
      
      // Provide feedback that audio is being collected
      final durationSeconds = _audioBuffer.length / _sampleRate;
      if (_audioBuffer.length % (_sampleRate * 2) == 0) { // Log every 2 seconds
        debugPrint('[STT] Collecting audio: ${durationSeconds.toStringAsFixed(1)}s');
      }
      
      // Return status message for UI
      return 'Recording: ${durationSeconds.toStringAsFixed(1)}s';
      
    } catch (e) {
      debugPrint('[STT] Error processing audio chunk: $e');
      return null;
    }
  }

  /// Stop recording and transcribe the collected audio
  Future<String?> stopRecordingAndTranscribe() async {
    if (!_isInitialized || _recognizer == null) {
      debugPrint('❌ STT service not initialized');
      return null;
    }

    if (!_isRecording) {
      debugPrint('❌ Not currently recording');
      return null;
    }

    _isRecording = false;

    try {
      if (_audioBuffer.isEmpty) {
        debugPrint('[STT] No audio data collected');
        return null;
      }

      final durationSeconds = _audioBuffer.length / _sampleRate;
      debugPrint('[STT] Transcribing ${durationSeconds.toStringAsFixed(1)}s of audio...');

      // Check minimum audio length to prevent ONNX shape errors
      const double minAudioDuration = 0.5; // Minimum 0.5 seconds
      if (durationSeconds < minAudioDuration) {
        debugPrint('[STT] ⚠️ Audio too short (${durationSeconds.toStringAsFixed(3)}s < ${minAudioDuration}s)');
        debugPrint('[STT] Samples collected: ${_audioBuffer.length} (need at least ${(_sampleRate * minAudioDuration).toInt()})');
        debugPrint('[STT] Skipping transcription to prevent ONNX Conv node shape errors');
        _audioBuffer.clear();
        return null;
      }

      debugPrint('[STT] ✅ Audio length OK: ${durationSeconds.toStringAsFixed(3)}s (${_audioBuffer.length} samples)');

      // Create an offline stream for processing
      final stream = _recognizer!.createStream();
      
      try {
        // Feed all collected audio to the stream
        stream.acceptWaveform(
          samples: Float32List.fromList(_audioBuffer),
          sampleRate: _sampleRate,
        );
        
        // Process the audio and get the result
        _recognizer!.decode(stream);
        final result = _recognizer!.getResult(stream);
        final transcription = result.text.trim();

        if (transcription.isNotEmpty) {
          String finalText = transcription;
          
          // Add punctuation to improve VLM prompt quality
          if (_enhancePunctuation) {
            finalText = PunctuationHelper.addPunctuationAdvanced(transcription);
            debugPrint('[STT] Raw transcription: "$transcription"');
            debugPrint('[STT] With punctuation: "$finalText"');
          } else {
            debugPrint('[STT] Transcription completed: "$transcription"');
          }
          
          return finalText;
        } else {
          debugPrint('[STT] No speech detected in audio');
          return null;
        }
      } catch (onnxError) {
        debugPrint('[STT] ❌ ONNX processing error: $onnxError');
        debugPrint('[STT] Audio samples: ${_audioBuffer.length}, duration: ${durationSeconds.toStringAsFixed(3)}s');
        return null;
      } finally {
        // Always clean up resources
        try {
          stream.free();
        } catch (e) {
          debugPrint('[STT] Error freeing stream: $e');
        }
        _audioBuffer.clear();
      }

    } catch (e) {
      debugPrint('[STT] Error during transcription: $e');
      _audioBuffer.clear();
      return null;
    }
  }


  // ============================================================================
  // UNIFIED API (Works with both modes)
  // ============================================================================

  /// Start listening (delegates to appropriate mode)
  Future<void> startListening({
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (_useMobileMode) {
      await startMobileListening(
        listenFor: listenFor,
        pauseFor: pauseFor,
      );
    } else {
      startRecording();
    }
  }

  /// Stop listening (delegates to appropriate mode)
  Future<void> stopListening() async {
    if (_useMobileMode) {
      await stopMobileListening();
    } else {
      await stopRecordingAndTranscribe();
    }
  }

  /// Check if on-device processing is available
  Future<bool> isOnDeviceAvailable() async {
    if (_useMobileMode) {
      return await isMobileOnDeviceAvailable();
    } else {
      // Hardware mode always uses Sherpa ONNX (on-device)
      return _isInitialized;
    }
  }

  // ============================================================================
  // MOBILE DEVICE STT (Using device microphone with speech_to_text)
  // ============================================================================

  /// Enable mobile device mode (uses phone microphone instead of hardware)
  void setMobileMode(bool enabled) {
    _useMobileMode = enabled;
    debugPrint('[STT] ${enabled ? "Mobile" : "Hardware"} mode enabled');
  }

  /// Initialize mobile speech recognition
  Future<bool> initializeMobile() async {
    if (_isMobileInitialized) return true;

    try {
      debugPrint('🎤 Initializing mobile STT service...');
      
      _isMobileInitialized = await _mobileSpeech.initialize(
        onError: (error) {
          debugPrint('❌ Mobile STT Error: ${error.errorMsg}');
          _handleMobileError(error.errorMsg);
        },
        onStatus: (status) {
          debugPrint('🎤 Mobile STT Status: $status');
          if (status == 'done' || status == 'notListening') {
            _stopMobileListening();
          }
        },
        options: [
          stt.SpeechToText.androidIntentLookup,
          stt.SpeechToText.webDoNotAggregate,
        ],
      );

      if (_isMobileInitialized) {
        debugPrint('✅ Mobile STT Service initialized (on-device mode)');
      } else {
        debugPrint('❌ Mobile STT Service failed to initialize');
      }

      return _isMobileInitialized;
    } catch (e) {
      debugPrint('❌ Mobile STT Initialization error: $e');
      _isMobileInitialized = false;
      return false;
    }
  }

  /// Check if on-device mobile speech recognition is available
  Future<bool> isMobileOnDeviceAvailable() async {
    if (!_isMobileInitialized) {
      await initializeMobile();
    }
    
    if (!_isMobileInitialized) return false;
    
    try {
      final locales = await _mobileSpeech.locales();
      debugPrint('📱 Available mobile speech locales: ${locales.length}');
      return locales.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking mobile on-device availability: $e');
      return false;
    }
  }

  /// Check microphone permission
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Start listening with mobile device microphone
  Future<void> startMobileListening({
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_isMobileInitialized) {
      await initializeMobile();
    }

    if (!_isMobileInitialized) {
      debugPrint('❌ Mobile STT not initialized');
      onError?.call('Mobile STT not initialized');
      return;
    }

    // Check permission
    if (!await hasMicrophonePermission()) {
      final granted = await requestMicrophonePermission();
      if (!granted) {
        debugPrint('❌ Microphone permission denied');
        onError?.call('Microphone permission denied');
        return;
      }
    }

    if (_isMobileListening) {
      debugPrint('⚠️ Already listening with mobile device');
      return;
    }

    try {
      _mobileRecognizedText = '';
      _isMobileListening = true;
      onListeningStart?.call();
      notifyListeners();

      // Get available locales and select English
      final locales = await _mobileSpeech.locales();
      final englishLocales = locales.where((l) => 
        l.localeId.startsWith('en_')
      ).toList();
      
      String? selectedLocale;
      if (englishLocales.isNotEmpty) {
        selectedLocale = englishLocales.first.localeId;
        debugPrint('🌐 Using mobile locale: $selectedLocale');
      }

      await _mobileSpeech.listen(
        onResult: (result) {
          _mobileRecognizedText = result.recognizedWords;
          
          if (result.finalResult) {
            String finalText = _mobileRecognizedText.trim();
            
            // Add punctuation if enabled
            if (_enhancePunctuation && finalText.isNotEmpty) {
              finalText = PunctuationHelper.addPunctuationAdvanced(finalText);
              debugPrint('[STT Mobile] Raw: "${_mobileRecognizedText}"');
              debugPrint('[STT Mobile] With punctuation: "$finalText"');
            }
            
            debugPrint('🎤 Mobile final result: "$finalText"');
            onResult?.call(finalText);
          } else {
            debugPrint('🎤 Mobile partial: "${_mobileRecognizedText}"');
            onPartialResult?.call(_mobileRecognizedText);
          }
          
          notifyListeners();
        },
        localeId: selectedLocale,
        listenFor: listenFor ?? const Duration(seconds: 5),
        pauseFor: pauseFor ?? const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
        onDevice: true, // Force on-device for offline
      );

      debugPrint('🎤 Started mobile listening (on-device mode)...');
    } catch (e) {
      debugPrint('❌ Error starting mobile listening: $e');
      _handleMobileError('Failed to start listening: $e');
      _stopMobileListening();
    }
  }

  /// Stop mobile listening
  Future<void> stopMobileListening() async {
    if (!_isMobileListening) return;

    try {
      await _mobileSpeech.stop();
      _stopMobileListening();
      debugPrint('🛑 Stopped mobile listening');
    } catch (e) {
      debugPrint('❌ Error stopping mobile listening: $e');
      _stopMobileListening();
    }
  }

  /// Cancel mobile listening
  Future<void> cancelMobileListening() async {
    if (!_isMobileListening) return;

    try {
      await _mobileSpeech.cancel();
      _stopMobileListening();
      debugPrint('❌ Cancelled mobile listening');
    } catch (e) {
      debugPrint('❌ Error cancelling mobile listening: $e');
      _stopMobileListening();
    }
  }

  /// Internal method to update mobile listening state
  void _stopMobileListening() {
    _isMobileListening = false;
    onListeningStop?.call();
    notifyListeners();
  }

  /// Internal error handler for mobile mode
  void _handleMobileError(String error) {
    onError?.call(error);
    notifyListeners();
  }

  // ============================================================================
  // END MOBILE DEVICE STT
  // ============================================================================


  /// Reset the audio buffer and recording state
  void reset() {
    _audioBuffer.clear();
    _isRecording = false;
    debugPrint('[STT] Audio buffer cleared and recording state reset');
  }

  /// Dispose of resources
  void dispose() {
    try {
      // Dispose hardware STT
      _recognizer?.free();
      _audioBuffer.clear();
      _isInitialized = false;
      
      // No need to dispose mobile STT - speech_to_text handles cleanup
      _isMobileInitialized = false;
      _isMobileListening = false;
      
      debugPrint('🎤 STT service disposed');
    } catch (e) {
      debugPrint('Error disposing STT service: $e');
    }
    
    // Must call super.dispose() when extending ChangeNotifier
    super.dispose();
  }

  /// Enable or disable punctuation enhancement
  /// This improves VLM prompt quality by adding appropriate punctuation
  void setPunctuationEnhancement(bool enabled) {
    _enhancePunctuation = enabled;
    debugPrint('[STT] Punctuation enhancement ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Get service status information
  Map<String, dynamic> getServiceInfo() {
    return {
      'mode': _useMobileMode ? 'Mobile Device' : 'Hardware (BLE)',
      'initialized': _useMobileMode ? _isMobileInitialized : _isInitialized,
      'listening': _useMobileMode ? _isMobileListening : _isRecording,
      'sampleRate': _useMobileMode ? 'Device Default' : '${_sampleRate}Hz',
      'engine': _useMobileMode ? 'Device Speech Recognition' : 'Sherpa ONNX',
      'modelType': _useMobileMode ? 'On-Device' : 'zipformer2-gigaspeech',
      'offline': true,
      'punctuationEnhancement': _enhancePunctuation,
    };
  }
}