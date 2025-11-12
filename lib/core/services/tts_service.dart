import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:audioplayers/audioplayers.dart';
import 'ble_service.dart';

/// Advanced TTS service using Sherpa ONNX for high-quality neural text-to-speech
/// Provides offline, neural network-based speech synthesis for Solari smart glasses
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final BleService _bleService = BleService();
  sherpa_onnx.OfflineTts? _sherpaEngine;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isInitialized = false;
  bool _isSpeaking = false;
  double _speechSpeed = 0.8;
  bool _useBleTransmission = false; // Default to local playback (mobile device)
  bool _useLocalPlayback = true; // Use mobile device by default

  /// Initialize the Sherpa ONNX TTS engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing Sherpa ONNX TTS engine...');
      
      // Initialize Sherpa ONNX bindings
      sherpa_onnx.initBindings();
      
      // Create the offline TTS engine
      _sherpaEngine = await _createOfflineTts();
      
      _isInitialized = true;
      debugPrint('Sherpa ONNX TTS service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Sherpa ONNX TTS service: $e');
      debugPrint('⚠️ TTS service will not be available. Please ensure Sherpa ONNX models are installed.');
      _isInitialized = false;
      // Don't throw - allow app to continue without TTS
    }
  }

  /// Get current speaking status
  bool get isSpeaking => _isSpeaking;

  /// Get current speech speed
  double get speechSpeed => _speechSpeed;

  /// Set speech speed (0.5x to 2.0x)
  void setSpeechSpeed(double speed) {
    _speechSpeed = speed.clamp(0.5, 2.0);
    debugPrint('Speech speed set to: $_speechSpeed');
  }

  /// Enable or disable BLE transmission (defaults to true for smart glasses)
  void setBleTransmission(bool enabled) {
    _useBleTransmission = enabled;
    _useLocalPlayback = !enabled;
    debugPrint('BLE transmission ${enabled ? "enabled" : "disabled"} - will use ${enabled ? "smart glasses" : "local playback"}');
  }

  /// Enable local playback on mobile device (disables BLE)
  void setLocalPlayback(bool enabled) {
    _useLocalPlayback = enabled;
    _useBleTransmission = !enabled;
    debugPrint('Local playback ${enabled ? "enabled" : "disabled"} - will use ${enabled ? "mobile device" : "smart glasses"}');
  }

  /// Force BLE transmission for VQA responses (overrides user preferences)
  void forceVqaBleTransmission() {
    _useBleTransmission = true;
    _useLocalPlayback = false;
    debugPrint('🎯 VQA: Forcing BLE transmission to Solari device (overrides user preferences)');
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

    // Check if initialization succeeded
    if (!_isInitialized || _sherpaEngine == null) {
      final errorMsg = 'TTS service not available - Sherpa ONNX engine not initialized';
      debugPrint('❌ $errorMsg');
      onError?.call(errorMsg);
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

      // Choose playback method based on settings
      if (_useLocalPlayback) {
        // Play on mobile device
        debugPrint('🔊 Playing audio on mobile device...');
        await _playAudioLocally(audio, onComplete, onError);
      } else if (canUseBle) {
        // Send audio samples directly to smart glasses via BLE
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
            debugPrint('⚠️ Falling back to local playback');
            // Fallback to local playback if BLE fails
            _playAudioLocally(audio, onComplete, onError);
          },
        );
      } else {
        debugPrint('⚠️ BLE not available - falling back to local playback');
        await _playAudioLocally(audio, onComplete, onError);
      }
    } catch (e) {
      debugPrint('Error generating speech: $e');
      _isSpeaking = false;
      onError?.call(e.toString());
    }
  }

  /// Stop current speech transmission
  Future<void> stopSpeaking() async {
    await _audioPlayer.stop();
    _isSpeaking = false;
    debugPrint('Speech transmission stopped');
  }

  /// Play audio locally on mobile device using AudioPlayer
  Future<void> _playAudioLocally(
    sherpa_onnx.GeneratedAudio audio,
    Function()? onComplete,
    Function(String error)? onError,
  ) async {
    try {
      // Convert Float32List samples to WAV file
      final wavFile = await _createWavFile(audio.samples, audio.sampleRate);
      
      debugPrint('🎵 Playing WAV file: ${wavFile.path}');
      
      // Set up completion handler
      _audioPlayer.onPlayerComplete.listen((_) {
        debugPrint('✅ Audio playback completed');
        _isSpeaking = false;
        onComplete?.call();
      });
      
      // Play the audio file
      await _audioPlayer.play(DeviceFileSource(wavFile.path));
      
    } catch (e) {
      debugPrint('❌ Error playing audio locally: $e');
      _isSpeaking = false;
      onError?.call('Local playback failed: $e');
    }
  }

  /// Create a WAV file from audio samples
  Future<File> _createWavFile(Float32List samples, int sampleRate) async {
    final tempDir = await getTemporaryDirectory();
    final wavFile = File('${tempDir.path}/tts_output_${DateTime.now().millisecondsSinceEpoch}.wav');
    
    // Convert Float32 to 16-bit PCM
    final pcmData = <int>[];
    for (final sample in samples) {
      final pcmValue = (sample * 32767).round().clamp(-32768, 32767);
      pcmData.add(pcmValue & 0xFF); // Low byte
      pcmData.add((pcmValue >> 8) & 0xFF); // High byte
    }
    
    // Create WAV header
    final numChannels = 1;
    final bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = pcmData.length;
    
    final wavHeader = <int>[
      // "RIFF" chunk descriptor
      0x52, 0x49, 0x46, 0x46, // "RIFF"
      ..._intToBytes(36 + dataSize, 4), // File size - 8
      0x57, 0x41, 0x56, 0x45, // "WAVE"
      
      // "fmt " sub-chunk
      0x66, 0x6D, 0x74, 0x20, // "fmt "
      0x10, 0x00, 0x00, 0x00, // Subchunk1Size (16 for PCM)
      0x01, 0x00, // AudioFormat (1 for PCM)
      ..._intToBytes(numChannels, 2), // NumChannels
      ..._intToBytes(sampleRate, 4), // SampleRate
      ..._intToBytes(byteRate, 4), // ByteRate
      ..._intToBytes(blockAlign, 2), // BlockAlign
      ..._intToBytes(bitsPerSample, 2), // BitsPerSample
      
      // "data" sub-chunk
      0x64, 0x61, 0x74, 0x61, // "data"
      ..._intToBytes(dataSize, 4), // Subchunk2Size
    ];
    
    // Write WAV file
    await wavFile.writeAsBytes([...wavHeader, ...pcmData]);
    
    debugPrint('📝 Created WAV file: ${wavFile.path} (${wavFile.lengthSync()} bytes)');
    
    return wavFile;
  }

  /// Convert integer to little-endian bytes
  List<int> _intToBytes(int value, int numBytes) {
    final bytes = <int>[];
    for (int i = 0; i < numBytes; i++) {
      bytes.add((value >> (8 * i)) & 0xFF);
    }
    return bytes;
  }



  /// Get performance metrics of the TTS engine
  Map<String, dynamic> getEngineInfo() {
    if (_sherpaEngine == null) return {};
    
    String outputMode;
    if (_useLocalPlayback) {
      outputMode = 'Mobile Device Speaker';
    } else if (canUseBle) {
      outputMode = 'BLE (Smart Glasses) - 22050Hz';
    } else {
      outputMode = 'BLE Unavailable';
    }
    
    return {
      'engine': 'Sherpa ONNX',
      'model': 'VITS-Piper en_US-libritts_r-medium',
      'type': 'Neural TTS',
      'offline': true,
      'speed': _speechSpeed,
      'outputMode': outputMode,
      'transmission': outputMode,
      'sampleRate': '22050Hz (Original Quality)',
    };
  }

  /// Create and configure the Sherpa ONNX offline TTS engine
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
    await _audioPlayer.dispose();
    _sherpaEngine?.free();
    _sherpaEngine = null;
    _isInitialized = false;
    debugPrint('Sherpa ONNX TTS service disposed');
  }
}