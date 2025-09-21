import 'dart:io';
import 'package:cactus/cactus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class VlmService {
  CactusVLM? _vlm;

  /// Downloads the model and mmproj files. Returns true if successful.
  Future<bool> downloadModel({
    void Function(double? progress, String status, bool isError)? onProgress,
  }) async {
    try {
      final vlm = CactusVLM();
      bool downloadSuccess = await vlm.download(
        modelUrl:
            'https://huggingface.co/ggml-org/SmolVLM-500M-Instruct-GGUF/resolve/main/SmolVLM-500M-Instruct-Q8_0.gguf',
        mmprojUrl:
            'https://huggingface.co/ggml-org/SmolVLM-500M-Instruct-GGUF/resolve/main/mmproj-SmolVLM-500M-Instruct-Q8_0.gguf',
        modelFilename: 'SmolVLM-500M-Instruct-Q8_0.gguf',
        mmprojFilename: 'mmproj-SmolVLM-500M-Instruct-Q8_0.gguf',
        onProgress: onProgress,
      );
      if (!downloadSuccess) {
        throw Exception('Model download failed - check internet connection');
      }
      _vlm = vlm;
      return true;
    } catch (e) {
      debugPrint('Error downloading model: $e');
      rethrow;
    }
  }

  /// Loads the model into memory. Assumes model files are already downloaded.
  Future<void> loadModel() async {
    try {
      _vlm ??= CactusVLM();
      await _vlm!.init(
        contextSize: 2048,
        modelFilename: 'SmolVLM-500M-Instruct-Q8_0.gguf',
        mmprojFilename: 'mmproj-SmolVLM-500M-Instruct-Q8_0.gguf',
      );
    } catch (e) {
      debugPrint('Error loading model: $e');
      rethrow;
    }
  }

  /// For backward compatibility: downloads and loads the model.
  Future<void> initModel({
    void Function(double? progress, String status, bool isError)? onProgress,
  }) async {
    await downloadModel(onProgress: onProgress);
    await loadModel();
  }

  Future<String?> processImage(Uint8List imageData) async {
    if (_vlm == null) {
      debugPrint('[AI] Model not initialized, skipping image processing.');
      return null;
    }
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_image.jpg');
      await tempFile.writeAsBytes(imageData, flush: true);
      String response = '';
      await _vlm!.completion(
        [ChatMessage(role: 'user', content: 'Describe this image.')],
        imagePaths: [tempFile.path],
        maxTokens: 200,
        onToken: (token) {
          response += token;
          return true;
        },
      );
      await tempFile.delete();
      return response;
    } catch (e) {
      debugPrint('[AI] Error processing image: $e');
      return null;
    }
  }

  void dispose() {
    _vlm?.dispose();
  }
}
