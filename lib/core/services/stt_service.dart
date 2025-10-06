import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

class SttService {
  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OnlineStream? _stream;
  bool _isInitialized = false;
  final int _sampleRate = 16000; // Sherpa ONNX model expects 16kHz audio
  
  // Text accumulation variables (exactly like reference)
  String _lastResult = '';
  int _segmentIndex = 0;

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

  /// Get the online model configuration for the English Zipformer model
  Future<sherpa_onnx.OnlineModelConfig> _getOnlineModelConfig() async {
    // Using the English model that's already in assets
    final modelDir = 'assets/sherpa-onnx-streaming-zipformer-en-2023-06-26';
    
    return sherpa_onnx.OnlineModelConfig(
      transducer: sherpa_onnx.OnlineTransducerModelConfig(
        encoder: await _copyAssetFile(
            '$modelDir/encoder-epoch-99-avg-1-chunk-16-left-128.int8.onnx'),
        decoder: await _copyAssetFile(
            '$modelDir/decoder-epoch-99-avg-1-chunk-16-left-128.onnx'),
        joiner: await _copyAssetFile(
            '$modelDir/joiner-epoch-99-avg-1-chunk-16-left-128.onnx'),
      ),
      tokens: await _copyAssetFile('$modelDir/tokens.txt'),
      modelType: 'zipformer2',
    );
  }

  /// Create online recognizer configuration for the English model
  Future<sherpa_onnx.OnlineRecognizer> _createOnlineRecognizer() async {
    final modelConfig = await _getOnlineModelConfig();
    final config = sherpa_onnx.OnlineRecognizerConfig(
      model: modelConfig,
      ruleFsts: '',
    );

    return sherpa_onnx.OnlineRecognizer(config);
  }

  /// Initialize the STT service with Sherpa ONNX
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;
      
      debugPrint('🎤 Initializing STT service...');
      debugPrint('⚠️  IMPORTANT: Ensure Arduino microphone is configured for ${_sampleRate}Hz sample rate');
      debugPrint('⚠️  Current Arduino config shows MICROPHONE_SAMPLE_RATE = 8000 (should be $_sampleRate)');
      
      // Initialize Sherpa ONNX bindings
      sherpa_onnx.initBindings();
      
      // Create the online recognizer
      _recognizer = await _createOnlineRecognizer();
      _stream = _recognizer?.createStream();
      
      _isInitialized = true;
      debugPrint('✅ STT service initialized successfully');
      
    } catch (e) {
      debugPrint('❌ Error initializing STT service: $e');
      rethrow;
    }
  }

  /// Process real-time audio chunk data received from BLE (EXACT match to reference streaming_asr.dart)
  Future<String?> processAudioChunk(List<int> audioChunk) async {
    if (!_isInitialized || _recognizer == null || _stream == null) {
      debugPrint('❌ STT service not initialized');
      return null;
    }

    try {
      // Convert the raw audio bytes to Float32List (same as reference)
      final audioBytes = Uint8List.fromList(audioChunk);
      final samplesFloat32 = _convertBytesToFloat32(audioBytes);
      
      // Feed the audio chunk to Sherpa ONNX (same as reference)
      _stream!.acceptWaveform(
        samples: samplesFloat32,
        sampleRate: _sampleRate,
      );
      
      // Process the audio chunk (same as reference)
      while (_recognizer!.isReady(_stream!)) {
        _recognizer!.decode(_stream!);
      }
      
      // Get current text result (same as reference)
      final text = _recognizer!.getResult(_stream!).text;
      String textToDisplay = _lastResult;
      
      // EXACTLY like reference - build display text
      if (text != '') {
        if (_lastResult == '') {
          textToDisplay = '$_segmentIndex: $text';
        } else {
          textToDisplay = '$_segmentIndex: $text\n$_lastResult';
        }
      }
      
      // Check for endpoint (sentence completion) - EXACTLY like reference
      if (_recognizer!.isEndpoint(_stream!)) {
        debugPrint('[STT] Endpoint detected! Resetting stream...');
        _recognizer!.reset(_stream!);
        if (text != '') {
          _lastResult = textToDisplay;
          _segmentIndex += 1;
          debugPrint('[STT] Segment completed: "$text"');
        }
      }
      
      // Always return the current display text (like reference does for UI updates)
      return textToDisplay.isNotEmpty ? textToDisplay : null;
      
    } catch (e) {
      debugPrint('[STT] Error processing audio chunk: $e');
      return null;
    }
  }

  /// Finalize the transcription when audio streaming ends
  Future<String?> finalizeTranscription() async {
    if (!_isInitialized || _recognizer == null || _stream == null) {
      debugPrint('❌ STT service not initialized');
      return null;
    }

    try {
      // Get any remaining text and finalize
      final result = _recognizer!.getResult(_stream!);
      final remainingText = result.text.trim();
      
      String finalTranscription = _lastResult;
      
      // Include any remaining partial text
      if (remainingText.isNotEmpty && !_lastResult.contains(remainingText)) {
        if (_lastResult.isEmpty) {
          finalTranscription = '$_segmentIndex: $remainingText';
        } else {
          finalTranscription = '$_segmentIndex: $remainingText\n$_lastResult';
        }
      }
      
      // Extract just the text content without segment numbers for VLM prompt
      final cleanTranscription = _extractCleanText(finalTranscription);
      
      // Reset for next session
      _resetSession();
      
      if (cleanTranscription.isNotEmpty) {
        debugPrint('[STT] Final transcription: "$cleanTranscription"');
        return cleanTranscription;
      } else {
        debugPrint('[STT] No speech detected in session');
        return null;
      }
      
    } catch (e) {
      debugPrint('[STT] Error finalizing transcription: $e');
      return null;
    }
  }
  
  /// Extract clean text without segment numbers in correct chronological order
  String _extractCleanText(String segmentedText) {
    if (segmentedText.isEmpty) return '';
    
    final lines = segmentedText.split('\n');
    final Map<int, String> segmentMap = {};
    
    // Parse segments into a map with their indices
    for (final line in lines) {
      final colonIndex = line.indexOf(': ');
      if (colonIndex != -1) {
        final segmentNumberStr = line.substring(0, colonIndex);
        final segmentNumber = int.tryParse(segmentNumberStr);
        final segmentText = line.substring(colonIndex + 2).trim();
        
        if (segmentNumber != null && segmentText.isNotEmpty) {
          segmentMap[segmentNumber] = segmentText;
        }
      }
    }
    
    // Sort segments by index (0, 1, 2, ...) and join them in correct order
    final sortedKeys = segmentMap.keys.toList()..sort();
    final orderedSegments = sortedKeys.map((key) => segmentMap[key]!).toList();
    
    return orderedSegments.join(' ').trim();
  }
  
  /// Reset session variables
  void _resetSession() {
    _lastResult = '';
    _segmentIndex = 0;
  }

  /// Reset the STT stream and session completely
  void reset() {
    if (_stream != null && _recognizer != null) {
      try {
        // Free the current stream and create a new one for complete reset
        _stream!.free();
        _stream = _recognizer!.createStream();
        _resetSession();
        debugPrint('[STT] Stream recreated and session reset completely');
      } catch (e) {
        debugPrint('[STT] Error during reset: $e');
        // Fallback to simple reset
        _recognizer!.reset(_stream!);
        _resetSession();
      }
    }
  }

  /// Dispose of resources
  void dispose() {
    try {
      _stream?.free();
      _recognizer?.free();
      _isInitialized = false;
      debugPrint('🎤 STT service disposed');
    } catch (e) {
      debugPrint('Error disposing STT service: $e');
    }
  }

  /// Get service status information
  Map<String, dynamic> getServiceInfo() {
    return {
      'initialized': _isInitialized,
      'sampleRate': _sampleRate,
      'engine': 'Sherpa ONNX',
      'modelType': 'zipformer2',
      'online': true,
    };
  }
}