import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'ble_service.dart';

/// Service that handles text-to-speech by converting text to high-quality WAV audio
/// Configurable audio quality for smart glasses - easily adjustable for testing
class SpeakerService {
  static final SpeakerService _instance = SpeakerService._internal();
  factory SpeakerService() => _instance;
  SpeakerService._internal();

  // Audio Quality Configuration - Change these values to test different formats
  // QUALITY PRESETS - Uncomment one set to test:
  
  // === LOW QUALITY (Basic, Small Files) ===
  // static const int _sampleRate = 8000;
  // static const int _bitDepth = 16;
  // static const String _codec = 'pcm_s16le';
  // static const int _bytesPerSample = 2;
  // static const String _qualityName = 'Low Quality';
  // static const String _filePostfix = 'low';
  
  // === STANDARD QUALITY (Good Balance) ===
  static const int _sampleRate = 16000;
  static const int _bitDepth = 16;
  static const String _codec = 'pcm_s16le';
  static const int _bytesPerSample = 2;
  static const String _qualityName = 'Standard';
  static const String _filePostfix = 'std';
  
  // === HIGH QUALITY (Music Quality) ===
  // static const int _sampleRate = 22050;
  // static const int _bitDepth = 16;
  // static const String _codec = 'pcm_s16le';
  // static const int _bytesPerSample = 2;
  // static const String _qualityName = 'High Quality';
  // static const String _filePostfix = 'hq';
  
  // === PROFESSIONAL QUALITY (CD Quality) ===
  // static const int _sampleRate = 44100;
  // static const int _bitDepth = 24;
  // static const String _codec = 'pcm_s24le';
  // static const int _bytesPerSample = 3;
  // static const String _qualityName = 'Professional';
  // static const String _filePostfix = 'pro';
  
  // === STUDIO GRADE (Professional Audio) === CURRENT ACTIVE
  // static const int _sampleRate = 48000;
  // static const int _bitDepth = 24;
  // static const String _codec = 'pcm_s24le';
  // static const int _bytesPerSample = 3;
  // static const String _qualityName = 'Studio Grade';
  // static const String _filePostfix = 'studio';
  
  // === ULTRA HIGH (Audiophile, Very Large Files) ===
  // static const int _sampleRate = 96000;
  // static const int _bitDepth = 32;
  // static const String _codec = 'pcm_s32le';
  // static const int _bytesPerSample = 4;
  // static const String _qualityName = 'Ultra High';
  // static const String _filePostfix = 'ultra';

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final BleService _bleService = BleService();
  
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String _currentFilePath = "";
  bool _useBleTransmission = false;
  bool _isProcessing = false;
  bool _isProcessingSoundActive = false; // Track if processing sound is currently being sent

  /// Initialize the TTS engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure TTS for optimal quality and proper file generation
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.4); // slower for better clarity
      await _flutterTts.setVolume(1.0);     // max volume for better audibility
      await _flutterTts.setPitch(1.0);      // natural pitch (avoid distortion)

      
      // Ensure TTS is ready and not in the middle of any operation
      await _flutterTts.stop();
      
      _isInitialized = true;
      debugPrint('SpeakerService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing SpeakerService: $e');
      throw Exception('Failed to initialize SpeakerService: $e');
    }
  }

  /// Get current speaking status
  bool get isSpeaking => _isSpeaking;

  /// Start playing processing sound loop via BLE (for VLM processing feedback)
  Future<void> startProcessingSound() async {
    if (_useBleTransmission && _bleService.isReady) {
      _isProcessing = true;
      debugPrint('🔄 Starting VLM processing sound loop via BLE...');
      _loopProcessingSound();
    }
  }

  /// Stop processing sound and play done sound via BLE (when VLM processing completes)
  Future<void> playDoneSound() async {
    _isProcessing = false; // Stop processing sound loop
    
    // Wait for any active processing sound transmission to complete before sending done sound
    while (_isProcessingSoundActive) {
      debugPrint('⏳ Waiting for processing sound to complete before sending done sound...');
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    if (_useBleTransmission && _bleService.isReady) {
      debugPrint('✅ Playing VLM done sound via BLE...');
      await _playDoneSound();
    }
  }

  /// Enable BLE transmission mode (sends audio to connected BLE device)
  Future<void> enableBleTransmission(dynamic bleDevice) async {
    try {
      await _bleService.initialize(bleDevice);
      _useBleTransmission = true;
      debugPrint('BLE transmission enabled');
    } catch (e) {
      debugPrint('Error enabling BLE transmission: $e');
      _useBleTransmission = false;
      throw Exception('Failed to enable BLE transmission: $e');
    }
  }

  /// Disable BLE transmission mode (reverts to local audio playback)
  void disableBleTransmission() {
    _useBleTransmission = false;
    _bleService.dispose();
    debugPrint('BLE transmission disabled');
  }

  /// Convert text to high-quality WAV and play it
  /// Uses configurable audio format - currently $_sampleRate Hz $_bitDepth-bit PCM ($_qualityName)
  Future<void> speakText(String text, {
    Function()? onStart,
    Function()? onComplete,
    Function(String error)? onError,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isSpeaking) {
      debugPrint('Already speaking, stopping current speech');
      await stopSpeaking();
    }

    try {
      _isSpeaking = true;
      onStart?.call();

      // Check text length and truncate if too long to prevent TTS corruption
      String processedText = text;
      const int maxTextLength = 500; // Limit to prevent TTS corruption with very long text
      
      if (text.length > maxTextLength) {
        processedText = text.substring(0, maxTextLength);
        debugPrint('⚠️ Text truncated from ${text.length} to $maxTextLength characters to prevent TTS corruption');
      }

      // Generate unique filename to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = "tts_$timestamp";

      await _synthesizeTextToConfiguredQualityWav(processedText, fileName);
      
      if (_currentFilePath.isNotEmpty) {
        debugPrint('🔍 BLE Transmission Debug:');
        debugPrint('  _useBleTransmission: $_useBleTransmission');
        debugPrint('  _bleService.isReady: ${_bleService.isReady}');
        debugPrint('  BLE device connected: ${_bleService.connectedDevice?.isConnected}');
        
        if (_useBleTransmission && _bleService.isReady) {
          // Send the TTS audio via BLE
          debugPrint('📡 Sending TTS audio via BLE...');
          await _playSpokenTts();
        } else {
          debugPrint('🔊 Playing audio locally because:');
          if (!_useBleTransmission) debugPrint('  - BLE transmission disabled');
          if (!_bleService.isReady) debugPrint('  - BLE service not ready');
          await _playCompressedAudio();
        }
        onComplete?.call();
      }
    } catch (e) {
      debugPrint('Error in speakText: $e');
      onError?.call(e.toString());
    } finally {
      _isSpeaking = false;
    }
  }

  /// Stop current speech playback
  Future<void> stopSpeaking() async {
    try {
      _isProcessing = false; // Stop processing sound loop
      _isProcessingSoundActive = false; // Clear processing sound flag
      await _audioPlayer.stop();
      await _flutterTts.stop();
      _isSpeaking = false;
      debugPrint('Speech stopped');
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  /// Validate that the TTS-generated file is a proper WAV file
  Future<void> _validateWavFile(String filePath) async {
    try {
      File wavFile = File(filePath);
      if (!await wavFile.exists()) {
        throw Exception('WAV file does not exist: $filePath');
      }

      int fileSize = await wavFile.length();
      debugPrint('WAV file size: $fileSize bytes');

      // Check if file size is reasonable (not too large which indicates corruption)
      if (fileSize > 5 * 1024 * 1024) { // 5MB limit
        throw Exception('WAV file too large ($fileSize bytes) - likely corrupted by TTS');
      }

      // Read first 44 bytes to check complete WAV header
      final bytes = await wavFile.openRead(0, 44).toList();
      if (bytes.isEmpty) {
        throw Exception('WAV file is empty or unreadable');
      }

      final headerBytes = bytes.expand((x) => x).toList();
      debugPrint('WAV header bytes read: ${headerBytes.length}');
      
      if (headerBytes.length >= 12) {
        // Check for RIFF header (bytes 0-3: "RIFF")
        final riffCheck = String.fromCharCodes(headerBytes.sublist(0, 4));
        // Check for WAVE format (bytes 8-11: "WAVE")  
        final waveCheck = String.fromCharCodes(headerBytes.sublist(8, 12));
        
        debugPrint('RIFF header: "$riffCheck" (expected: "RIFF")');
        debugPrint('WAVE format: "$waveCheck" (expected: "WAVE")');
        
        if (riffCheck == 'RIFF' && waveCheck == 'WAVE') {
          debugPrint('✅ Valid WAV file header detected');
          
          // Additional check: verify file size matches header
          if (headerBytes.length >= 8) {
            // Bytes 4-7 contain file size - 8
            int headerFileSize = (headerBytes[4] | (headerBytes[5] << 8) | 
                                (headerBytes[6] << 16) | (headerBytes[7] << 24)) + 8;
            debugPrint('Header reports file size: $headerFileSize bytes, actual: $fileSize bytes');
            
            if ((headerFileSize - fileSize).abs() > 1000) { // Allow small difference
              debugPrint('⚠️ File size mismatch - possible corruption');
            }
          }
        } else {
          debugPrint('❌ Invalid WAV header detected');
          debugPrint('Header hex: ${headerBytes.take(12).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
          throw Exception('Invalid WAV file format - corrupt TTS output');
        }
      } else {
        throw Exception('WAV file too small to contain valid header (${headerBytes.length} bytes)');
      }
    } catch (e) {
      debugPrint('WAV validation failed: $e');
      rethrow;
    }
  }

  /// Convert text to configurable quality WAV file
  /// Current format: $_sampleRate Hz $_bitDepth-bit PCM ($_qualityName)
  Future<void> _synthesizeTextToConfiguredQualityWav(String text, String fileName) async {
    try {
      // Only Android supported for TTS to file
      if (!Platform.isAndroid) {
        throw UnsupportedError("WAV synthesis only supported on Android");
      }

      // Get temporary directory
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = "${tempDir.path}/${fileName}_temp.wav";
      String finalPath = "${tempDir.path}/${fileName}_$_filePostfix.wav";

      debugPrint('Synthesizing TTS to temporary file: $tempPath');
      debugPrint('Final $_qualityName quality file will be: $finalPath');

      // Clean up any existing files first
      File existingTempFile = File(tempPath);
      File existingFinalFile = File(finalPath);
      if (await existingTempFile.exists()) {
        await existingTempFile.delete();
        debugPrint('Deleted existing temp file');
      }
      if (await existingFinalFile.exists()) {
        await existingFinalFile.delete();
        debugPrint('Deleted existing final file');
      }

      // Synthesize to temporary file with error recovery
      bool ttsSuccess = false;
      int ttsAttempts = 0;
      const int maxTtsAttempts = 2;
      
      while (!ttsSuccess && ttsAttempts < maxTtsAttempts) {
        ttsAttempts++;
        debugPrint('TTS synthesis attempt $ttsAttempts/$maxTtsAttempts');
        
        try {
          // Ensure TTS is stopped before new synthesis
          await _flutterTts.stop();
          await Future.delayed(const Duration(milliseconds: 300));
          
          await _flutterTts.synthesizeToFile(text, tempPath, true);

          // Wait longer to ensure TTS file is fully written and closed
          await Future.delayed(const Duration(milliseconds: 2000));
          
          // Additional check: wait until file size stabilizes
          int previousSize = 0;
          int currentSize = 0;
          int stableCount = 0;
          
          for (int i = 0; i < 15; i++) { // Max 15 attempts (7.5 seconds)
            File checkFile = File(tempPath);
            if (await checkFile.exists()) {
              currentSize = await checkFile.length();
              if (currentSize == previousSize && currentSize > 0) {
                stableCount++;
                if (stableCount >= 3) { // File size stable for 3 checks
                  debugPrint('TTS file size stabilized at $currentSize bytes');
                  ttsSuccess = true;
                  break;
                }
              } else {
                stableCount = 0;
              }
              previousSize = currentSize;
            }
            await Future.delayed(const Duration(milliseconds: 500));
          }
          
          if (!ttsSuccess) {
            debugPrint('⚠️ TTS file size did not stabilize, attempt $ttsAttempts failed');
            // Clean up unstable file
            File unstableFile = File(tempPath);
            if (await unstableFile.exists()) {
              await unstableFile.delete();
            }
          }
          
        } catch (e) {
          debugPrint('TTS synthesis attempt $ttsAttempts failed: $e');
          // Clean up failed file
          File failedFile = File(tempPath);
          if (await failedFile.exists()) {
            await failedFile.delete();
          }
        }
      }
      
      if (!ttsSuccess) {
        throw Exception('TTS synthesis failed after $maxTtsAttempts attempts');
      }

      // Verify the temp file exists and has content
      File tempFile = File(tempPath);
      if (!await tempFile.exists()) {
        throw Exception("TTS file was not created: $tempPath");
      }

      int tempFileSize = await tempFile.length();
      if (tempFileSize == 0) {
        throw Exception("TTS file is empty: $tempPath");
      }

      debugPrint('TTS file created: $tempFileSize bytes');

      // Validate the WAV file header
      await _validateWavFile(tempPath);

      // Convert to $_qualityName PCM WAV ($_sampleRate Hz, mono, $_bytesPerSample bytes per sample)
      await _convertToConfiguredQualityWithRetry(tempPath, finalPath);

      // Clean up temporary file on success
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      _currentFilePath = finalPath;
    } catch (e) {
      debugPrint('Error in _synthesizeTextToConfiguredQualityWav: $e');
      rethrow;
    }
  }

  /// Convert WAV to configurable PCM format - optimized for smart glasses audio
  /// Current: $_sampleRate Hz $_bitDepth-bit PCM ($_qualityName)
  Future<void> _convertToConfiguredQualityWithRetry(
    String tempPath,
    String finalPath, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      debugPrint('Converting to $_qualityName PCM (attempt $attempt/$maxRetries)...');

      // Configurable quality PCM - easily adjustable for testing different formats
      String ffmpegCommand = '-i $tempPath -ar $_sampleRate -ac 1 -acodec $_codec -y $finalPath';
      debugPrint('Using $_sampleRate Hz $_bitDepth-bit PCM ($_qualityName for smart glasses)');
      
      debugPrint('FFmpeg command: $ffmpegCommand');
      
      // Verify input file exists before attempting conversion
      File inputFile = File(tempPath);
      if (!await inputFile.exists()) {
        throw Exception('Input file does not exist: $tempPath');
      }
      debugPrint('Input file verified: ${await inputFile.length()} bytes');

      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // Verify the final file was created
        File finalFile = File(finalPath);
        if (await finalFile.exists()) {
          int fileSize = await finalFile.length();
          
          // Calculate duration for $_bitDepth-bit PCM format: $_bytesPerSample bytes per sample at $_sampleRate Hz
          String duration = _calculateDuration(fileSize, _sampleRate, 1, _bytesPerSample);
          
          debugPrint('✅ $_qualityName PCM WAV created successfully');
          debugPrint('File size: $fileSize bytes (${(fileSize / 1024).toStringAsFixed(1)} KB)');
          debugPrint('Duration: $duration');
          debugPrint('Format: $_sampleRate Hz, $_bitDepth-bit PCM, mono - $_qualityName for smart glasses');
          
          return; // Success!
        }
      }

      // Handle $_qualityName conversion failure
      final logs = await session.getAllLogs();
      final output = await session.getOutput();
      final allLogs = await session.getAllLogsAsString();
      String errorDetails = logs.map((log) => log.getMessage()).join('\n');
      
      debugPrint('$_qualityName conversion attempt $attempt failed with return code: $returnCode');
      debugPrint('FFmpeg output: $output');
      if (allLogs != null) {
        debugPrint('FFmpeg error logs: ${allLogs.length > 1500 ? allLogs.substring(allLogs.length - 1500) : allLogs}');
      } else {
        debugPrint('FFmpeg logs: $errorDetails');
      }
      
      // Clean up any partial output file
      File outputFile = File(finalPath);
      if (await outputFile.exists()) {
        int outputSize = await outputFile.length();
        debugPrint('Removing partial $_qualityName file: $outputSize bytes');
        await outputFile.delete();
      }

      if (attempt < maxRetries) {
        debugPrint('Retrying $_qualityName conversion in ${attempt * 500}ms...');
        await Future.delayed(Duration(milliseconds: attempt * 500));
      } else {
        throw Exception('$_qualityName conversion failed after $maxRetries attempts. Error: $errorDetails');
      }
    }
  }

  /// Calculate audio duration from file size for PCM format
  String _calculateDuration(
    int fileSize,
    int sampleRate,
    int channels,
    int bytesPerSample,
  ) {
    // For $_bitDepth-bit PCM: $_bytesPerSample bytes per sample, mono channel
    int totalSamples = (fileSize - 44) ~/ bytesPerSample; // Subtract WAV header size and divide by bytes per sample
    double durationSeconds = totalSamples / (sampleRate * channels);

    int minutes = (durationSeconds / 60).floor();
    int seconds = (durationSeconds % 60).floor();
    int milliseconds = ((durationSeconds % 1) * 1000).floor();

    if (minutes > 0) {
      return "${minutes}m ${seconds}s";
    } else if (seconds > 0) {
      return "${seconds}.${milliseconds.toString().padLeft(3, '0').substring(0, 1)}s";
    } else {
      return "${milliseconds}ms";
    }
  }



  /// Background method to continuously loop processing sound
  void _loopProcessingSound() async {
    while (_isProcessing) {
      try {
        if (!_isProcessing) break;
        
        // Load processing.wav from assets and send via BLE
        final audioData = await _loadAssetAudio('assets/audio/processing.wav');
        if (audioData != null && _isProcessing) {
          _isProcessingSoundActive = true; // Mark processing sound as active
          
          await _bleService.sendAudioData(
            audioData,
            onStart: () => debugPrint('🔄 Sending processing sound via BLE...'),
            onProgress: (sent, total) {}, // Silent progress for processing sound
            onComplete: () {
              debugPrint('🔄 Processing sound sent');
              _isProcessingSoundActive = false; // Mark processing sound as completed
            },
            onError: (error) {
              debugPrint('Error sending processing sound: $error');
              _isProcessingSoundActive = false; // Mark processing sound as completed even on error
            },
          );
        }
        
        // Longer delay between loops to reduce irritating audio pops/explosions
        if (_isProcessing) {
          await Future.delayed(const Duration(milliseconds: 1000)); // Increased from 100ms to 800ms
        }
      } catch (e) {
        debugPrint('Error in processing sound loop: $e');
        _isProcessingSoundActive = false; // Ensure flag is cleared on exception
        break;
      }
    }
    _isProcessingSoundActive = false; // Ensure flag is cleared when loop ends
    debugPrint('🔄 Processing sound loop ended');
  }

  /// Play done sound via BLE
  Future<void> _playDoneSound() async {
    try {
      final audioData = await _loadAssetAudio('assets/audio/done.wav');
      if (audioData != null) {
        await _bleService.sendAudioData(
          audioData,
          onStart: () => debugPrint('✅ Sending done sound via BLE...'),
          onProgress: (sent, total) {
            int percent = ((sent * 100) / total).round();
            debugPrint('Done sound transmission: $percent%');
          },
          onComplete: () => debugPrint('✅ Done sound sent successfully'),
          onError: (error) => debugPrint('Error sending done sound: $error'),
        );
      }
    } catch (e) {
      debugPrint('Error playing done sound: $e');
    }
  }

  /// Load audio file from assets
  Future<Uint8List?> _loadAssetAudio(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error loading asset audio $assetPath: $e');
      return null;
    }
  }

  /// Send the compressed audio file to BLE device
  Future<void> _playSpokenTts() async {
    if (_currentFilePath.isEmpty) {
      throw Exception('No audio file to send');
    }

    try {
      debugPrint('Sending compressed audio via BLE: $_currentFilePath');
      
      // Read the audio file as bytes
      File audioFile = File(_currentFilePath);
      if (!await audioFile.exists()) {
        throw Exception('Audio file does not exist: $_currentFilePath');
      }

      Uint8List audioData = await audioFile.readAsBytes();
      debugPrint('Audio file loaded: ${audioData.length} bytes');

      // Send audio data via BLE
      await _bleService.sendAudioData(
        audioData,
        onStart: () {
          debugPrint('Started BLE audio transmission');
        },
        onProgress: (sent, total) {
          int percent = ((sent * 100) / total).round();
          debugPrint('BLE audio transmission progress: $percent% ($sent/$total bytes)');
        },
        onComplete: () {
          debugPrint('BLE audio transmission complete');
        },
        onError: (error) {
          debugPrint('BLE audio transmission error: $error');
        },
      );
    } catch (e) {
      debugPrint('Error sending audio via BLE: $e');
      rethrow;
    }
  }

  /// Play the compressed audio file using Audio Player
  Future<void> _playCompressedAudio() async {
    if (_currentFilePath.isEmpty) {
      throw Exception('No audio file to play');
    }

    try {
      debugPrint('Playing compressed audio: $_currentFilePath');
      await _audioPlayer.play(DeviceFileSource(_currentFilePath));
    } catch (e) {
      debugPrint('Error playing audio: $e');
      rethrow;
    }
  }

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      
      for (var file in files) {
        if (file.path.contains('tts_') && file.path.endsWith('_$_filePostfix.wav')) {
          await file.delete();
          debugPrint('Cleaned up temp file: ${file.path}');
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up temp files: $e');
    }
  }

  /// Test FFmpeg with a simple command to debug issues
  Future<void> testFFmpeg() async {
    try {
      debugPrint('Testing FFmpeg...');
      
      // Test 1: Version check
      final versionSession = await FFmpegKit.execute('-version');
      final versionReturnCode = await versionSession.getReturnCode();
      
      if (ReturnCode.isSuccess(versionReturnCode)) {
        debugPrint('FFmpeg version test: SUCCESS');
      } else {
        debugPrint('FFmpeg version test: FAILED');
      }
      
      // Test 2: List available encoders (to check if pcm_alaw is available)
      final encodersSession = await FFmpegKit.execute('-encoders');
      final encodersReturnCode = await encodersSession.getReturnCode();
      final encodersLogs = await encodersSession.getAllLogsAsString();
      
      if (ReturnCode.isSuccess(encodersReturnCode) && encodersLogs != null) {
        bool hasPcmEncoder = encodersLogs.contains('$_codec');
        debugPrint('$_bitDepth-bit PCM encoder available: $hasPcmEncoder');
        if (hasPcmEncoder) {
          debugPrint('✅ $_codec encoder is available');
        } else {
          debugPrint('❌ $_codec encoder is NOT available');
        }
      } else {
        debugPrint('Could not check available encoders');
      }
      
    } catch (e) {
      debugPrint('Error testing FFmpeg: $e');
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await stopSpeaking();
    await _audioPlayer.dispose();
    await cleanupTempFiles();
    _bleService.dispose();
    _isInitialized = false;
    debugPrint('SpeakerService disposed');
  }
}