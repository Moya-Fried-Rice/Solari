import 'dart:io';
import 'package:cactus/cactus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class VlmService {
  CactusVLM? _vlm;

  Future<void> initModel({
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
      await vlm.init(
        contextSize: 2048,
        modelFilename: 'SmolVLM-500M-Instruct-Q8_0.gguf',
        mmprojFilename: 'mmproj-SmolVLM-500M-Instruct-Q8_0.gguf',
      );
      _vlm = vlm;
    } catch (e) {
      debugPrint('Error initializing model: $e');
      rethrow;
    }
  }

  Future<String?> processImage(Uint8List imageData, {required String prompt}) async {
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
        [ChatMessage(role: 'user', content: prompt)],
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
