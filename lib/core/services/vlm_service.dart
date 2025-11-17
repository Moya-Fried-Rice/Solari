import 'dart:io';
import 'package:cactus/cactus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VlmService {
  CactusVLM? _vlm;
  static const String _useLocalModelKey = 'use_local_vlm_model';
  static const String _localModelPathKey = 'local_vlm_model_path';
  static const String _localMmprojPathKey = 'local_vlm_mmproj_path';

  /// Check if local model is enabled
  static Future<bool> isLocalModelEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useLocalModelKey) ?? false;
  }

  /// Set local model enabled status
  static Future<void> setLocalModelEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useLocalModelKey, enabled);
  }

  /// Get local model path
  static Future<String?> getLocalModelPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localModelPathKey);
  }

  /// Set local model path
  static Future<void> setLocalModelPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localModelPathKey, path);
  }

  /// Get local mmproj path
  static Future<String?> getLocalMmprojPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localMmprojPathKey);
  }

  /// Set local mmproj path
  static Future<void> setLocalMmprojPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localMmprojPathKey, path);
  }

  Future<void> initModel({
    void Function(double? progress, String status, bool isError)? onProgress,
  }) async {
    try {
      final vlm = CactusVLM();
      
      // Check if local model is enabled
      final useLocalModel = await isLocalModelEnabled();
      debugPrint('🔍 VLM Model Loading - UseLocal: $useLocalModel');
      
      if (useLocalModel) {
        debugPrint('📁 Loading VLM model from local files...');
        await _initLocalModel(vlm, onProgress);
      } else {
        debugPrint('⬇️ Loading VLM model from download...');
        await _initDownloadedModel(vlm, onProgress);
      }
      
      _vlm = vlm;
      debugPrint('✅ VLM model initialization completed successfully');
    } catch (e) {
      debugPrint('❌ Error initializing VLM model: $e');
      onProgress?.call(null, 'Error: $e', true);
      rethrow;
    }
  }

  /// Initialize model from downloaded files
  Future<void> _initDownloadedModel(
    CactusVLM vlm,
    void Function(double? progress, String status, bool isError)? onProgress,
  ) async {
    debugPrint('⬇️ Starting downloaded model initialization...');
    onProgress?.call(null, 'Downloading model...', false);
    
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
      final error = 'Model download failed - check internet connection';
      debugPrint('❌ $error');
      throw Exception(error);
    }
    
    debugPrint('✅ Model download completed, initializing...');
    
    await vlm.init(
      contextSize: 2048,
      modelFilename: 'SmolVLM-500M-Instruct-Q8_0.gguf',
      mmprojFilename: 'mmproj-SmolVLM-500M-Instruct-Q8_0.gguf',
    );
    
    debugPrint('🎉 Downloaded VLM model initialized successfully');
  }

  /// Initialize model from local files
  Future<void> _initLocalModel(
    CactusVLM vlm,
    void Function(double? progress, String status, bool isError)? onProgress,
  ) async {
    debugPrint('📁 Starting local model initialization...');
    onProgress?.call(0.1, 'Loading local model...', false);
    
    final modelPath = await getLocalModelPath();
    final mmprojPath = await getLocalMmprojPath();
    
    debugPrint('🔍 Local model paths:');
    debugPrint('   Model: $modelPath');
    debugPrint('   MMProj: $mmprojPath');
    
    if (modelPath == null || mmprojPath == null) {
      final error = 'Local model paths not configured. Please select model files in settings.';
      debugPrint('❌ $error');
      throw Exception(error);
    }
    
    // Verify files exist
    final modelFile = File(modelPath);
    final mmprojFile = File(mmprojPath);
    
    debugPrint('🔍 Checking file existence...');
    if (!await modelFile.exists()) {
      final error = 'Local model file not found: $modelPath';
      debugPrint('❌ $error');
      throw Exception(error);
    }
    
    if (!await mmprojFile.exists()) {
      final error = 'Local mmproj file not found: $mmprojPath';
      debugPrint('❌ $error');
      throw Exception(error);
    }
    
    debugPrint('✅ Both local files exist and are accessible');
    onProgress?.call(0.3, 'Preparing local model files...', false);
    
    // Extract actual filenames from the selected paths
    final modelFileName = modelPath.split('/').last;
    final mmprojFileName = mmprojPath.split('/').last;
    
    debugPrint('📝 Using model filename: $modelFileName');
    debugPrint('📝 Using mmproj filename: $mmprojFileName');
    
    // For CactusVLM, files need to be in the app_flutter directory at the app root
    // CactusVLM looks in app's data directory, not the files subdirectory
    final appDir = await getApplicationSupportDirectory();
    // Go up one level from /files to get to the app's root data directory
    final appRootDir = appDir.parent;
    final vlmDir = Directory('${appRootDir.path}/app_flutter');
    if (!await vlmDir.exists()) {
      await vlmDir.create(recursive: true);
      debugPrint('📁 Created app_flutter directory: ${vlmDir.path}');
    }
    
    final localModelPath = '${vlmDir.path}/$modelFileName';
    final localMmprojPath = '${vlmDir.path}/$mmprojFileName';
    
    debugPrint('📂 VLM directory: ${vlmDir.path}');
    debugPrint('🔄 Copying files to app_flutter directory...');
    debugPrint('   Target model path: $localModelPath');
    debugPrint('   Target mmproj path: $localMmprojPath');
    
    // Copy files if they don't exist in app directory or if they're different
    onProgress?.call(0.5, 'Copying model file...', false);
    await _copyFileIfNeeded(modelPath, localModelPath);
    
    onProgress?.call(0.7, 'Copying projection file...', false);
    await _copyFileIfNeeded(mmprojPath, localMmprojPath);
    
    onProgress?.call(0.9, 'Initializing local model...', false);
    
    await vlm.init(
      contextSize: 2048,
      modelFilename: modelFileName,
      mmprojFilename: mmprojFileName,
    );
    
    onProgress?.call(1.0, 'Local model loaded successfully', false);
    debugPrint('🎉 Local VLM model initialized successfully from user files');
  }
  
  /// Copy file if needed (only if destination doesn't exist or is different)
  Future<void> _copyFileIfNeeded(String sourcePath, String destPath) async {
    final sourceFile = File(sourcePath);
    final destFile = File(destPath);
    
    bool needsCopy = !await destFile.exists();
    
    if (!needsCopy) {
      // Check if files are different by comparing sizes (quick check)
      final sourceStat = await sourceFile.stat();
      final destStat = await destFile.stat();
      needsCopy = sourceStat.size != destStat.size;
      debugPrint('📊 File size comparison - Source: ${sourceStat.size}, Dest: ${destStat.size}, NeedsCopy: $needsCopy');
    }
    
    if (needsCopy) {
      debugPrint('📁 Copying model file: $sourcePath -> $destPath');
      final sourceSize = await sourceFile.length();
      debugPrint('📏 File size: ${(sourceSize / 1024 / 1024).toStringAsFixed(1)} MB');
      await sourceFile.copy(destPath);
      debugPrint('✅ File copied successfully');
    } else {
      debugPrint('⏭️ File already exists and is identical, skipping copy');
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
        maxTokens: 50,
        stopSequences: ["<|im_end|>", "<end_of_turn>", "<end_of_utterance>"],
        onToken: (token) {
          response += token;
          return true;
        },
      );
      await tempFile.delete();
      
      // Additional cleanup: remove any remaining stop tokens that might have been partially generated
      String cleanedResponse = response
          .replaceAll('<end_of_utterance>', '')
          .replaceAll('<|im_end|>', '')
          .replaceAll('<end_of_turn>', '')
          .trim();
      
      return cleanedResponse;
    } catch (e) {
      debugPrint('[AI] Error processing image: $e');
      return null;
    }
  }

  /// Check if model is currently initialized
  bool get isInitialized => _vlm != null;

  /// Refresh/reload the VLM model based on current configuration
  Future<void> refreshModel({
    void Function(double? progress, String status, bool isError)? onProgress,
  }) async {
    try {
      onProgress?.call(0.1, 'Disposing current model...', false);
      debugPrint('🔄 Refreshing VLM model...');
      
      // Dispose current model if exists
      if (_vlm != null) {
        _vlm!.dispose();
        _vlm = null;
        debugPrint('🗑️ Previous VLM model disposed');
      }
      
      onProgress?.call(0.2, 'Reinitializing model...', false);
      
      // Reinitialize with current configuration
      await initModel(onProgress: (progress, status, isError) {
        // Adjust progress to account for the disposal phase (0.2 offset)
        final adjustedProgress = progress != null ? 0.2 + (progress * 0.8) : null;
        onProgress?.call(adjustedProgress, status, isError);
      });
      
      debugPrint('✅ VLM model refreshed successfully');
    } catch (e) {
      debugPrint('❌ Error refreshing VLM model: $e');
      onProgress?.call(null, 'Error: $e', true);
      rethrow;
    }
  }

  /// Get current model configuration info
  Future<Map<String, dynamic>> getModelInfo() async {
    final useLocalModel = await isLocalModelEnabled();
    final localModelPath = await getLocalModelPath();
    final localMmprojPath = await getLocalMmprojPath();
    
    return {
      'isInitialized': isInitialized,
      'useLocalModel': useLocalModel,
      'localModelPath': localModelPath,
      'localMmprojPath': localMmprojPath,
      'modelType': useLocalModel ? 'Local' : 'Downloaded',
    };
  }

  void dispose() {
    _vlm?.dispose();
    _vlm = null;
  }
}
