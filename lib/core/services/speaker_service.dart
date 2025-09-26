import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'ble_service.dart';

/// Service that handles text-to-speech by converting text to high-quality WAV audio
/// Optimized for smart glasses with 16kHz 16-bit PCM for superior audio quality
class SpeakerService {
  static final SpeakerService _instance = SpeakerService._internal();
  factory SpeakerService() => _instance;
  SpeakerService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final BleService _bleService = BleService();
  
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String _currentFilePath = "";
  bool _useBleTransmission = false;

  /// Initialize the TTS engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure TTS for optimal quality and proper file generation
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(0.8);
      await _flutterTts.setPitch(1.0);
      
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
  /// Uses 16kHz 16-bit PCM optimized for superior smart glasses audio
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

      await _synthesizeTextToHighQualityWav(processedText, fileName);
      
      if (_currentFilePath.isNotEmpty) {
        debugPrint('🔍 BLE Transmission Debug:');
        debugPrint('  _useBleTransmission: $_useBleTransmission');
        debugPrint('  _bleService.isReady: ${_bleService.isReady}');
        debugPrint('  BLE device connected: ${_bleService.connectedDevice?.isConnected}');
        
        if (_useBleTransmission && _bleService.isReady) {
          debugPrint('📡 Sending audio via BLE...');
          await _sendAudioViaBle();
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

  /// Convert text to 16kHz 16-bit PCM high-quality WAV file
  Future<void> _synthesizeTextToHighQualityWav(String text, String fileName) async {
    try {
      // Only Android supported for TTS to file
      if (!Platform.isAndroid) {
        throw UnsupportedError("WAV synthesis only supported on Android");
      }

      // Get temporary directory
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = "${tempDir.path}/${fileName}_temp.wav";
      String finalPath = "${tempDir.path}/${fileName}_hq.wav";

      debugPrint('Synthesizing TTS to temporary file: $tempPath');
      debugPrint('Final high-quality file will be: $finalPath');

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

      // Convert to high-quality PCM WAV (16kHz, mono, 2 bytes per sample)
      await _convertToHighQualityWithRetry(tempPath, finalPath);

      // Clean up temporary file on success
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      _currentFilePath = finalPath;
    } catch (e) {
      debugPrint('Error in _synthesizeTextToCompressedWav: $e');
      rethrow;
    }
  }

  /// Convert WAV to high-quality PCM format (16kHz, mono) - optimized for superior smart glasses audio
  Future<void> _convertToHighQualityWithRetry(
    String tempPath,
    String finalPath, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      debugPrint('Converting to high-quality PCM (attempt $attempt/$maxRetries)...');

      // High-quality 16-bit PCM - superior audio for smart glasses
      String ffmpegCommand = '-i $tempPath -ar 16000 -ac 1 -acodec pcm_s16le -y $finalPath';
      debugPrint('Using 16kHz 16-bit PCM (superior quality for smart glasses)');
      
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
          
          // Calculate duration for 16-bit PCM format: 2 bytes per sample at 16kHz
          String duration = _calculateDuration(fileSize, 16000, 1, 2);
          
          debugPrint('✅ High-quality PCM WAV created successfully');
          debugPrint('File size: $fileSize bytes (${(fileSize / 1024).toStringAsFixed(1)} KB)');
          debugPrint('Duration: $duration');
          debugPrint('Format: 16kHz, 16-bit PCM, mono - superior quality for smart glasses');
          
          return; // Success!
        }
      }

      // Handle high-quality conversion failure
      final logs = await session.getAllLogs();
      final output = await session.getOutput();
      final allLogs = await session.getAllLogsAsString();
      String errorDetails = logs.map((log) => log.getMessage()).join('\n');
      
      debugPrint('High-quality conversion attempt $attempt failed with return code: $returnCode');
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
        debugPrint('Removing partial high-quality file: $outputSize bytes');
        await outputFile.delete();
      }

      if (attempt < maxRetries) {
        debugPrint('Retrying high-quality conversion in ${attempt * 500}ms...');
        await Future.delayed(Duration(milliseconds: attempt * 500));
      } else {
        throw Exception('High-quality conversion failed after $maxRetries attempts. Error: $errorDetails');
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
    // For 16-bit PCM: 2 bytes per sample, mono channel
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

  /// Send the compressed audio file to BLE device
  Future<void> _sendAudioViaBle() async {
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

  /// Play the compressed audio file
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
        if (file.path.contains('tts_') && file.path.endsWith('_hq.wav')) {
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
        bool hasPcmEncoder = encodersLogs.contains('pcm_s16le');
        debugPrint('16-bit PCM encoder available: $hasPcmEncoder');
        if (hasPcmEncoder) {
          debugPrint('✅ pcm_s16le encoder is available');
        } else {
          debugPrint('❌ pcm_s16le encoder is NOT available');
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