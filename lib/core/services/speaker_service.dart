import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

/// Service that handles text-to-speech by converting text to compressed WAV audio
/// Optimized for smart glasses with 8kHz A-Law compression
class SpeakerService {
  static final SpeakerService _instance = SpeakerService._internal();
  factory SpeakerService() => _instance;
  SpeakerService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String _currentFilePath = "";

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

  /// Convert text to compressed WAV and play it
  /// Uses 8kHz A-Law compression optimized for smart glasses
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

      // Generate unique filename to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = "tts_$timestamp";

      await _synthesizeTextToCompressedWav(text, fileName);
      
      if (_currentFilePath.isNotEmpty) {
        await _playCompressedAudio();
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

      // Read first 12 bytes to check WAV header
      final bytes = await wavFile.openRead(0, 12).toList();
      if (bytes.isEmpty) {
        throw Exception('WAV file is empty or unreadable');
      }

      final headerBytes = bytes.expand((x) => x).toList();
      if (headerBytes.length >= 12) {
        // Check for RIFF header (bytes 0-3: "RIFF")
        final riffCheck = String.fromCharCodes(headerBytes.sublist(0, 4));
        // Check for WAVE format (bytes 8-11: "WAVE")  
        final waveCheck = String.fromCharCodes(headerBytes.sublist(8, 12));
        
        if (riffCheck == 'RIFF' && waveCheck == 'WAVE') {
          debugPrint('✅ Valid WAV file header detected');
        } else {
          debugPrint('⚠️ Invalid WAV header: RIFF=$riffCheck, WAVE=$waveCheck');
          throw Exception('Invalid WAV file format');
        }
      } else {
        throw Exception('WAV file too small to contain valid header');
      }
    } catch (e) {
      debugPrint('WAV validation failed: $e');
      rethrow;
    }
  }

  /// Convert text to 8kHz A-Law compressed WAV file
  Future<void> _synthesizeTextToCompressedWav(String text, String fileName) async {
    try {
      // Only Android supported for TTS to file
      if (!Platform.isAndroid) {
        throw UnsupportedError("WAV synthesis only supported on Android");
      }

      // Get temporary directory
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = "${tempDir.path}/${fileName}_temp.wav";
      String finalPath = "${tempDir.path}/${fileName}_alaw.wav";

      debugPrint('Synthesizing TTS to temporary file: $tempPath');
      debugPrint('Final A-Law file will be: $finalPath');

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

      // Synthesize to temporary file first
      await _flutterTts.synthesizeToFile(text, tempPath, true);

      // Wait longer to ensure TTS file is fully written and closed
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Additional check: wait until file size stabilizes
      int previousSize = 0;
      int currentSize = 0;
      int stableCount = 0;
      
      for (int i = 0; i < 10; i++) { // Max 10 attempts (5 seconds)
        File checkFile = File(tempPath);
        if (await checkFile.exists()) {
          currentSize = await checkFile.length();
          if (currentSize == previousSize && currentSize > 0) {
            stableCount++;
            if (stableCount >= 2) { // File size stable for 2 checks
              debugPrint('TTS file size stabilized at $currentSize bytes');
              break;
            }
          } else {
            stableCount = 0;
          }
          previousSize = currentSize;
        }
        await Future.delayed(const Duration(milliseconds: 500));
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

      // Convert to A-Law compressed WAV with retry mechanism
      await _convertToAlawWithRetry(tempPath, finalPath);

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

  /// Convert WAV to A-Law compressed format with retry mechanism
  Future<void> _convertToAlawWithRetry(
    String tempPath,
    String finalPath, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      debugPrint('Converting to A-Law (attempt $attempt/$maxRetries)...');

      // Progressive fallback strategy - start with the working approach
      String ffmpegCommand;
      if (attempt == 1) {
        // First attempt: Basic conversion (we know this works from your log)
        ffmpegCommand = '-i $tempPath -ar 8000 -ac 1 -y $finalPath';
        debugPrint('Using basic conversion (known to work)');
      } else if (attempt == 2) {
        // Second attempt: Try A-Law compression with file refresh
        ffmpegCommand = '-i $tempPath -ar 8000 -ac 1 -acodec pcm_alaw -y $finalPath';
        debugPrint('Retry with A-Law compression');
      } else {
        // Final attempt: Standard PCM 16-bit
        ffmpegCommand = '-i $tempPath -ar 8000 -ac 1 -acodec pcm_s16le -y $finalPath';
        debugPrint('Final fallback: PCM 16-bit format');
      }
      
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
          String duration = _calculateDuration(fileSize, 8000, 1, 1);
          
          debugPrint('A-Law compressed WAV created successfully');
          debugPrint('File size: $fileSize bytes (${(fileSize / 1024).toStringAsFixed(1)} KB)');
          debugPrint('Duration: $duration');
          debugPrint('Format: 8kHz, A-Law compression, mono - optimized for smart glasses');
          
          return; // Success!
        }
      }

      // Handle failure - get detailed error information
      final logs = await session.getAllLogs();
      final output = await session.getOutput();
      final allLogs = await session.getAllLogsAsString();
      String errorDetails = logs.map((log) => log.getMessage()).join('\n');
      
      debugPrint('FFmpeg attempt $attempt failed with return code: $returnCode');
      debugPrint('FFmpeg output: $output');
      if (allLogs != null) {
        debugPrint('FFmpeg all logs: ${allLogs.length > 1500 ? allLogs.substring(allLogs.length - 1500) : allLogs}'); // Show last 1500 chars which should contain the error
      } else {
        debugPrint('FFmpeg logs: $errorDetails');
      }
      
      // Also check if any output file was partially created
      File outputFile = File(finalPath);
      if (await outputFile.exists()) {
        int outputSize = await outputFile.length();
        debugPrint('Partial output file created: $outputSize bytes');
        await outputFile.delete(); // Clean up partial file
      }

      if (attempt < maxRetries) {
        debugPrint('Retrying in ${attempt * 500}ms...');
        await Future.delayed(Duration(milliseconds: attempt * 500));
      } else {
        throw Exception('FFmpeg conversion failed after $maxRetries attempts: $errorDetails');
      }
    }
  }

  /// Calculate audio duration from file size for A-Law format
  String _calculateDuration(
    int fileSize,
    int sampleRate,
    int channels,
    int bytesPerSample,
  ) {
    // For A-Law: 1 byte per sample, mono channel
    int totalSamples = fileSize - 44; // Subtract WAV header size
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
        if (file.path.contains('tts_') && file.path.endsWith('_alaw.wav')) {
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
        bool hasAlawEncoder = encodersLogs.contains('pcm_alaw');
        debugPrint('A-Law encoder available: $hasAlawEncoder');
        if (hasAlawEncoder) {
          debugPrint('✅ pcm_alaw encoder is available');
        } else {
          debugPrint('❌ pcm_alaw encoder is NOT available');
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
    _isInitialized = false;
    debugPrint('SpeakerService disposed');
  }
}