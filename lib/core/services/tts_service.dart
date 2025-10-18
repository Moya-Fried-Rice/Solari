import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx; // DISABLED - package not available
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'ble_service.dart';

/// Advanced TTS service using Sherpa ONNX for high-quality neural text-to-speech
/// Provides offline, neural network-based speech synthesis for Solari smart glasses
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  // ⚠️ TTS ENGINE SELECTOR - Set to false to use Flutter TTS, true for Sherpa ONNX
  static const bool _useSherpaOnnx = false; // TEMPORARILY DISABLED - using Flutter TTS

  final BleService _bleService = BleService();
  dynamic _sherpaEngine; // sherpa_onnx.OfflineTts? - Disabled until package available
  FlutterTts? _flutterTts;
  
  bool _isInitialized = false;
  bool _isSpeaking = false;
  double _speechSpeed = 0.8;
  bool _useBleTransmission = true; // Prefer BLE over local playback
  
  // Callbacks for current TTS operation
  Function()? _currentOnComplete;
  Function(String)? _currentOnError;

  /// Initialize the Sherpa ONNX TTS engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (_useSherpaOnnx) {
        // DISABLED - Sherpa ONNX package not available
        throw Exception('Sherpa ONNX is disabled. Set _useSherpaOnnx = false to use Flutter TTS');
        /*
        debugPrint('Initializing Sherpa ONNX TTS engine...');
        
        // Initialize Sherpa ONNX bindings
        sherpa_onnx.initBindings();
        
        // Create the offline TTS engine
        _sherpaEngine = await _createOfflineTts();
        
        _isInitialized = true;
        debugPrint('Sherpa ONNX TTS service initialized successfully');
        */
      } else {
        debugPrint('Initializing Flutter TTS engine...');
        
        _flutterTts = FlutterTts();
        
        // Configure Flutter TTS
        await _flutterTts!.setLanguage("en-US");
        await _flutterTts!.setSpeechRate(_speechSpeed);
        await _flutterTts!.setVolume(1.0);
        await _flutterTts!.setPitch(1.0);
        
        // Set up handlers once during initialization
        _flutterTts!.setCompletionHandler(() {
          debugPrint('Flutter TTS finished speaking');
          _isSpeaking = false;
          _currentOnComplete?.call();
          _currentOnComplete = null;
          _currentOnError = null;
        });
        
        _flutterTts!.setErrorHandler((msg) {
          debugPrint('Flutter TTS error: $msg');
          _isSpeaking = false;
          _currentOnError?.call(msg);
          _currentOnComplete = null;
          _currentOnError = null;
        });
        
        _flutterTts!.setCancelHandler(() {
          debugPrint('Flutter TTS cancelled');
          _isSpeaking = false;
          _currentOnComplete = null;
          _currentOnError = null;
        });
        
        _isInitialized = true;
        debugPrint('✅ Flutter TTS service initialized successfully');
      }
    } catch (e) {
      debugPrint('Error initializing TTS service: $e');
      throw Exception('Failed to initialize TTS service: $e');
    }
  }

  /// Get current speaking status
  bool get isSpeaking => _isSpeaking;

  /// Get current speech speed
  double get speechSpeed => _speechSpeed;

  /// Set speech speed (0.5x to 2.0x)
  void setSpeechSpeed(double speed) {
    _speechSpeed = speed.clamp(0.5, 2.0);
    if (_flutterTts != null) {
      _flutterTts!.setSpeechRate(_speechSpeed);
    }
    debugPrint('Speech speed set to: $_speechSpeed');
  }
  
  /// Set speech pitch (0.5x to 2.0x)
  void setSpeechPitch(double pitch) {
    if (_flutterTts != null) {
      _flutterTts!.setPitch(pitch.clamp(0.5, 2.0));
      debugPrint('Speech pitch set to: $pitch');
    }
  }

  /// Enable or disable BLE transmission (defaults to true for smart glasses)
  void setBleTransmission(bool enabled) {
    _useBleTransmission = enabled;
    debugPrint('BLE transmission ${enabled ? "enabled" : "disabled"} - will use ${enabled ? "smart glasses" : "local playback"}');
  }

  /// Check if BLE transmission is enabled and available
  bool get canUseBle => _useBleTransmission && _bleService.isReady;

  /// Generate speech using Sherpa ONNX and play it
  Future<void> speakText(String text, {
    Function()? onStart,
    Function()? onComplete,
    Function(String error)? onError,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_useSherpaOnnx && _sherpaEngine == null) {
      onError?.call('Sherpa ONNX engine not initialized');
      return;
    }

    if (!_useSherpaOnnx && _flutterTts == null) {
      onError?.call('Flutter TTS engine not initialized');
      return;
    }

    if (_isSpeaking) {
      debugPrint('Already speaking, stopping current speech');
      await stopSpeaking();
    }

    try {
      _isSpeaking = true;
      onStart?.call();

      // Limit text length for performance
      String processedText = text;
      const int maxTextLength = 500;
      
      if (text.length > maxTextLength) {
        processedText = text.substring(0, maxTextLength);
        debugPrint('Text truncated from ${text.length} to $maxTextLength characters');
      }

      if (_useSherpaOnnx) {
        // ==================== SHERPA ONNX PATH ====================
        debugPrint('Generating neural speech for: "$processedText" at ${_speechSpeed}x speed');
        
        final stopwatch = Stopwatch();
        stopwatch.start();
        
        // Generate speech using Sherpa ONNX
        final audio = _sherpaEngine!.generate(
          text: processedText, 
          sid: 0, 
          speed: _speechSpeed
        );
        
        stopwatch.stop();
        final elapsed = stopwatch.elapsed.inMilliseconds.toDouble();
        final duration = audio.samples.length.toDouble() / audio.sampleRate.toDouble();
        
        debugPrint('✅ Neural speech generated successfully!');
        debugPrint('   Sample Rate: ${audio.sampleRate}Hz');
        debugPrint('   Samples: ${audio.samples.length}');
        debugPrint('   Duration: ${duration.toStringAsPrecision(2)}s');
        debugPrint('   Generation time: ${(elapsed / 1000).toStringAsPrecision(2)}s');

        // Send audio samples directly to smart glasses via BLE
        if (canUseBle) {
          debugPrint('📡 Sending ${audio.sampleRate}Hz audio to smart glasses via BLE...');
          
          final audioBytes = _convertSamplesToBytes(audio.samples, audio.sampleRate);
          
          await _bleService.sendAudioData(
            audioBytes,
            onStart: () => debugPrint('🎵 Starting BLE audio transmission'),
            onProgress: (sent, total) {
              final progress = (sent / total * 100).toStringAsFixed(1);
              debugPrint('📊 BLE progress: $progress% ($sent/$total bytes)');
            },
            onComplete: () {
              debugPrint('✅ Audio transmitted to smart glasses');
              _isSpeaking = false;
              onComplete?.call();
            },
            onError: (error) {
              debugPrint('❌ BLE transmission failed: $error');
              _isSpeaking = false;
              onError?.call('BLE transmission failed: $error');
            },
          );
        } else {
          debugPrint('❌ BLE not available - cannot transmit audio');
          _isSpeaking = false;
          onError?.call('BLE service not available');
        }
      } else {
        // ==================== FLUTTER TTS PATH ====================
        debugPrint('🔊 Speaking with Flutter TTS: "$processedText"');
        
        // Speak the text (handlers already set during initialization)
        await _flutterTts!.speak(processedText);
        
        // Call the onComplete callback when TTS finishes
        // Note: The actual completion will be handled by the handler set in initialize()
        // We store the callback to call it from the handler
        _currentOnComplete = onComplete;
        _currentOnError = onError;
      }
    } catch (e) {
      debugPrint('Error generating speech: $e');
      _isSpeaking = false;
      onError?.call(e.toString());
    }
  }

  /// Stop current speech transmission
  Future<void> stopSpeaking() async {
    _isSpeaking = false;
    if (_flutterTts != null) {
      await _flutterTts!.stop();
    }
    debugPrint('Speech transmission stopped');
  }



  /// Get performance metrics of the TTS engine
  Map<String, dynamic> getEngineInfo() {
    if (_useSherpaOnnx) {
      if (_sherpaEngine == null) return {};
      
      return {
        'engine': 'Sherpa ONNX',
        'model': 'VITS-Piper en_US-libritts_r-medium',
        'type': 'Neural TTS',
        'offline': true,
        'speed': _speechSpeed,
        'transmission': canUseBle ? 'BLE (Smart Glasses) - 22050Hz' : 'BLE Unavailable',
        'sampleRate': '22050Hz (Original Quality)',
      };
    } else {
      return {
        'engine': 'Flutter TTS',
        'model': 'System TTS',
        'type': 'Platform TTS',
        'offline': false,
        'speed': _speechSpeed,
        'transmission': 'Local Device Speaker',
        'sampleRate': 'System Default',
      };
    }
  }

  /// Create and configure the Sherpa ONNX offline TTS engine
  /// DISABLED - Sherpa ONNX package not available
  /*
  Future<sherpa_onnx.OfflineTts> _createOfflineTts() async {
    // Copy all asset files to local storage (required by Sherpa ONNX)
    await _copyAllAssetFiles();

    // Configure for the vits-piper-en_US-libritts_r-medium model
    String modelDir = 'vits-piper-en_US-libritts_r-medium';
    String modelName = 'en_US-libritts_r-medium.onnx';
    String dataDir = 'vits-piper-en_US-libritts_r-medium/espeak-ng-data';

    final Directory directory = await getApplicationSupportDirectory();
    modelName = p.join(directory.path, modelDir, modelName);
    dataDir = p.join(directory.path, dataDir);
    final tokens = p.join(directory.path, modelDir, 'tokens.txt');

    final vits = sherpa_onnx.OfflineTtsVitsModelConfig(
      model: modelName,
      lexicon: '',
      tokens: tokens,
      dataDir: dataDir,
      dictDir: '',
    );

    final kokoro = sherpa_onnx.OfflineTtsKokoroModelConfig();

    final modelConfig = sherpa_onnx.OfflineTtsModelConfig(
      vits: vits,
      kokoro: kokoro,
      numThreads: 2,
      debug: true,
      provider: 'cpu',
    );

    final config = sherpa_onnx.OfflineTtsConfig(
      model: modelConfig,
      ruleFsts: '',
      ruleFars: '',
      maxNumSenetences: 1,
    );

    final tts = sherpa_onnx.OfflineTts(config);
    debugPrint('✅ Sherpa ONNX TTS engine created successfully');

    return tts;
  }
  */


  /// Get all asset files from the app bundle
  Future<List<String>> _getAllAssetFiles() async {
    final AssetManifest assetManifest =
        await AssetManifest.loadFromAssetBundle(rootBundle);
    final List<String> assets = assetManifest.listAssets();
    return assets;
  }

  /// Strip leading directory from path
  String _stripLeadingDirectory(String src, {int n = 1}) {
    return p.joinAll(p.split(src).sublist(n));
  }

  /// Copy all asset files to local storage
  Future<void> _copyAllAssetFiles() async {
    final allFiles = await _getAllAssetFiles();
    for (final src in allFiles) {
      final dst = _stripLeadingDirectory(src);
      await _copyAssetFile(src, dst);
    }
  }

  /// Copy an asset file from src to dst
  Future<String> _copyAssetFile(String src, [String? dst]) async {
    final Directory directory = await getApplicationSupportDirectory();
    if (dst == null) {
      dst = p.basename(src);
    }
    final target = p.join(directory.path, dst);
    bool exists = await File(target).exists();

    final data = await rootBundle.load(src);
    if (!exists || File(target).lengthSync() != data.lengthInBytes) {
      final List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await (await File(target).create(recursive: true)).writeAsBytes(bytes);
    }

    return target;
  }



  /// Convert Float32List audio samples to bytes for BLE transmission
  /// Creates a simple header with sample rate info + raw audio data
  Uint8List _convertSamplesToBytes(Float32List samples, int sampleRate) {
    // Create a simple header: [sampleRate(4 bytes)] + [numSamples(4 bytes)] + [audio data]
    final ByteData headerData = ByteData(8);
    headerData.setInt32(0, sampleRate, Endian.little);
    headerData.setInt32(4, samples.length, Endian.little);
    
    // Convert Float32 samples to 16-bit PCM for efficient transmission
    final pcmData = ByteData(samples.length * 2); // 2 bytes per sample (16-bit)
    
    for (int i = 0; i < samples.length; i++) {
      // Convert float (-1.0 to 1.0) to 16-bit signed integer (-32768 to 32767)
      int pcmValue = (samples[i] * 32767).round().clamp(-32768, 32767);
      pcmData.setInt16(i * 2, pcmValue, Endian.little);
    }
    
    // Combine header + audio data
    final totalBytes = Uint8List(8 + pcmData.lengthInBytes);
    totalBytes.setRange(0, 8, headerData.buffer.asUint8List());
    totalBytes.setRange(8, totalBytes.length, pcmData.buffer.asUint8List());
    
    final compressionRatio = ((totalBytes.length / (samples.length * 4)) * 100).toStringAsFixed(1);
    debugPrint('✅ Raw audio converted to bytes:');
    debugPrint('   Original: ${samples.length} Float32 samples (${samples.length * 4} bytes)');
    debugPrint('   Converted: ${samples.length} 16-bit PCM samples (${totalBytes.length} bytes)');
    debugPrint('   Compression: ${compressionRatio}% of original size');
    debugPrint('   Format: Custom header + 16-bit PCM data');
    
    return totalBytes;
  }



  /// Dispose of resources
  Future<void> dispose() async {
    await stopSpeaking();
    
    if (_sherpaEngine != null) {
      _sherpaEngine?.free();
      _sherpaEngine = null;
    }
    
    if (_flutterTts != null) {
      _flutterTts = null;
    }
    
    _isInitialized = false;
    debugPrint('TTS service disposed');
  }
}