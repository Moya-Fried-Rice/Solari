import 'dart:io';
import 'package:cactus/cactus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class VisionPage extends StatefulWidget {
  const VisionPage({super.key});

  @override
  State<VisionPage> createState() => _VisionPageState();
}

class _VisionPageState extends State<VisionPage> {
  final lm = CactusLM();
  bool isModelDownloaded = false;
  bool isModelLoaded = false;
  bool isDownloading = false;
  bool isInitializing = false;
  bool isGenerating = false;
  bool isStreaming = false;
  String outputText = 'Ready to start. Select a vision model and pick an image.';
  String? lastResponse;
  double lastTPS = 0;
  double lastTTFT = 0;
  String? model;
  List<CactusModel> availableModels = [];
  String? selectedImagePath;
  late TextEditingController _promptController;
  // Additional editable completion parameters
  late TextEditingController _topKController;
  late TextEditingController _stopSeqController;
  late TextEditingController _cactusTokenController;
  double _temperature = 0.2;
  int _maxTokens = 200;
  int? _topK;
  double _topP = 1.0;
  CompletionMode _completionMode = CompletionMode.local;
  bool _forceTools = false;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: 'Describe this image');
    _topKController = TextEditingController();
    _stopSeqController = TextEditingController(text: '<|im_end|>,<end_of_turn>');
    _cactusTokenController = TextEditingController();
    getAvailableModels();
  }

  Future<void> getAvailableModels() async {
    try {
      final models = await lm.getModels();
      // Filter only vision-capable models
      final visionModels = models.where((m) => m.supportsVision).toList();
      debugPrint("Available vision models: ${visionModels.map((m) => "${m.slug}: ${m.sizeMb}MB").join(", ")}");
      setState(() {
        availableModels = visionModels;
        if (visionModels.isNotEmpty && model == null) {
          model = visionModels.first.slug;
        }
      });
    } catch (e) {
      debugPrint("Error fetching models: $e");
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _topKController.dispose();
    _stopSeqController.dispose();
    _cactusTokenController.dispose();
    lm.unload();
    super.dispose();
  }

  Future<String?> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      // Copy to app directory for permanent storage
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'gallery_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = p.join(appDir.path, 'images', fileName);

      // Create images directory if it doesn't exist
      final imageDir = Directory(p.dirname(savedPath));
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      // Copy the image file
      await File(image.path).copy(savedPath);
      return savedPath;
    }

    return null;
  }

  Future<void> handleImagePick() async {
    final path = await pickImageFromGallery();
    if (path != null) {
      setState(() {
        selectedImagePath = path;
        outputText = 'Image selected! Click "Download Model" if needed, then "Analyze Image".';
      });
    }
  }

  Future<void> downloadModel() async {
    if (model == null) {
      setState(() {
        outputText = 'Please select a vision model first.';
      });
      return;
    }

    setState(() {
      isDownloading = true;
      outputText = 'Downloading model...';
    });

    try {
      await lm.downloadModel(
        model: model!,
        downloadProcessCallback: (progress, status, isError) {
          setState(() {
            if (isError) {
              outputText = 'Error: $status';
            } else {
              outputText = status;
              if (progress != null) {
                outputText += ' (${(progress * 100).toStringAsFixed(1)}%)';
              }
            }
          });
        },
      );
      setState(() {
        isModelDownloaded = true;
        outputText = 'Model downloaded successfully! Click "Initialize Model" to load it.';
      });
    } catch (e) {
      setState(() {
        outputText = 'Error downloading model: $e';
      });
    } finally {
      setState(() {
        isDownloading = false;
      });
    }
  }

  Future<void> initializeModel() async {
    if (model == null) {
      setState(() {
        outputText = 'Please select a vision model first.';
      });
      return;
    }

    setState(() {
      isInitializing = true;
      outputText = 'Initializing model...';
    });

    try {
      await lm.initializeModel(
        params: CactusInitParams(model: model!)
      );
      setState(() {
        isModelLoaded = true;
        outputText = 'Model initialized successfully! Pick an image to analyze.';
      });
    } catch (e) {
      setState(() {
        outputText = 'Error initializing model: $e';
      });
    } finally {
      setState(() {
        isInitializing = false;
      });
    }
  }

  Future<void> analyzeImage() async {
    if (!isModelLoaded) {
      setState(() {
        outputText = 'Please download and initialize model first.';
      });
      return;
    }

    if (selectedImagePath == null) {
      setState(() {
        outputText = 'Please pick an image first.';
      });
      return;
    }

    setState(() {
      isGenerating = true;
      isStreaming = false;
      outputText = 'Analyzing image...';
      lastResponse = '';
      lastTPS = 0;
      lastTTFT = 0;
    });

    try {
      final streamedResult = await lm.generateCompletionStream(
        params: CactusCompletionParams(
          maxTokens: _maxTokens,
          temperature: _temperature,
          topK: _topK,
          topP: _topP,
          stopSequences: _stopSeqController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
          completionMode: _completionMode,
          cactusToken: _cactusTokenController.text.isEmpty ? null : _cactusTokenController.text,
          forceTools: _forceTools,
        ),
        messages: [
          ChatMessage(
            content: """
                You are a visual agent and should provide concise answers.
                Analyze the image carefully.
                Answer the following question based on the image provided.
                Response only in one to three sentences.
              """,
            role: "system"
          ),
          ChatMessage(
            content: _promptController.text,
            role: "user",
            images: [selectedImagePath!]
          )
        ],
      );

      await for (final chunk in streamedResult.stream) {
        setState(() {
          // Hide processing indicator once streaming starts
          if (!isStreaming) {
            isGenerating = false;
            isStreaming = true;
            outputText = 'Streaming response...';
          }
          lastResponse = (lastResponse ?? '') + chunk;
        });
      }

      final resp = await streamedResult.result;
      if (resp.success) {
        setState(() {
          lastResponse = resp.response;
          lastTPS = resp.tokensPerSecond;
          lastTTFT = resp.timeToFirstTokenMs;
          outputText = 'Image analysis completed successfully!';
          isStreaming = false;
        });
      } else {
        setState(() {
          outputText = 'Failed to analyze image.';
          lastResponse = null;
          lastTPS = 0;
          lastTTFT = 0;
          isStreaming = false;
        });
      }
    } catch (e) {
      setState(() {
        outputText = 'Error analyzing image: $e';
        lastResponse = null;
        lastTPS = 0;
        lastTTFT = 0;
        isStreaming = false;
      });
    } finally {
      setState(() {
        isGenerating = false;
        isStreaming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Vision Example'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 56),
                  const SizedBox(height: 10),

                // Download Model and Initialize Model in same row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isDownloading || model == null ? null : downloadModel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: isDownloading
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Downloading...'),
                              ],
                            )
                          : Text(isModelDownloaded ? 'Downloaded ✓' : 'Download Model'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isInitializing || model == null ? null : initializeModel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: isInitializing
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Initializing...'),
                              ],
                            )
                          : Text(isModelLoaded ? 'Initialized ✓' : 'Initialize Model'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Pick/Change Image and Analyze Image in same row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: handleImagePick,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(selectedImagePath == null ? 'Pick Image' : 'Change Image'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (isDownloading || isInitializing || isGenerating || !isModelLoaded || selectedImagePath == null)
                          ? null
                          : analyzeImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: isGenerating && !isStreaming
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Processing...'),
                              ],
                            )
                          : const Text('Analyze Image'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Text prompt input
                Card(
                  elevation: 0,
                  color: Colors.grey[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _promptController,
                      decoration: InputDecoration(
                        labelText: 'Text Prompt',
                        hintText: 'Enter your prompt for image analysis',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black26),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Advanced parameters section (collapsible)
                Card(
                  elevation: 0,
                  color: Colors.grey[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ExpansionTile(
                    title: const Row(
                      children: [
                        Icon(Icons.tune, size: 20),
                        SizedBox(width: 8),
                        Text('Advanced Parameters', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            // Temperature
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Temperature', style: TextStyle(fontWeight: FontWeight.w500)),
                                    Text(_temperature.toStringAsFixed(2), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                  ],
                                ),
                                Slider(
                                  value: _temperature,
                                  min: 0.0,
                                  max: 2.0,
                                  divisions: 20,
                                  label: _temperature.toStringAsFixed(2),
                                  onChanged: (v) => setState(() => _temperature = v),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Max tokens
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Max Tokens', style: TextStyle(fontWeight: FontWeight.w500)),
                                    Text('$_maxTokens', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                  ],
                                ),
                                Slider(
                                  value: _maxTokens.toDouble(),
                                  min: 1,
                                  max: 2048,
                                  divisions: 204,
                                  label: _maxTokens.toString(),
                                  onChanged: (v) => setState(() => _maxTokens = v.toInt()),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Top P and Top K
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Top P', style: TextStyle(fontWeight: FontWeight.w500)),
                                          Text(_topP.toStringAsFixed(2), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                        ],
                                      ),
                                      Slider(
                                        value: _topP,
                                        min: 0.0,
                                        max: 1.0,
                                        divisions: 100,
                                        label: _topP.toStringAsFixed(2),
                                        onChanged: (v) => setState(() => _topP = v),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 100,
                                  child: TextField(
                                    controller: _topKController,
                                    decoration: InputDecoration(
                                      labelText: 'Top K',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) {
                                      setState(() {
                                        final parsed = int.tryParse(v);
                                        _topK = parsed;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Stop sequences
                            TextField(
                              controller: _stopSeqController,
                              decoration: InputDecoration(
                                labelText: 'Stop Sequences',
                                hintText: 'Comma-separated, e.g: <|im_end|>,<end_of_turn>',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              maxLines: 2,
                              minLines: 1,
                            ),
                            const SizedBox(height: 16),

                            // Completion mode
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Completion Mode', style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: DropdownButton<CompletionMode>(
                                    value: _completionMode,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    items: const [
                                      DropdownMenuItem(value: CompletionMode.local, child: Text('Local')),
                                      DropdownMenuItem(value: CompletionMode.hybrid, child: Text('Hybrid')),
                                    ],
                                    onChanged: (mode) {
                                      if (mode != null) setState(() => _completionMode = mode);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Cactus token
                            TextField(
                              controller: _cactusTokenController,
                              decoration: InputDecoration(
                                labelText: 'Cactus Token (optional)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 16),

                            // Force tools
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Force Tools', style: TextStyle(fontWeight: FontWeight.w500)),
                                  Switch(
                                    value: _forceTools,
                                    onChanged: (v) => setState(() => _forceTools = v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Image preview section
                if (selectedImagePath != null)
                  Container(
                    height: 150,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(selectedImagePath!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                // Output section
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Output:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                      ),
                      const SizedBox(height: 8),
                      Text(outputText, style: const TextStyle(color: Colors.black)),
                      if (lastResponse != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Response:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(lastResponse!, style: const TextStyle(color: Colors.black)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('Model', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                Text(model ?? '', style: const TextStyle(color: Colors.black, fontSize: 11)),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('TTFT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                Text('${lastTTFT.toStringAsFixed(2)} ms', style: const TextStyle(color: Colors.black)),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('TPS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                Text(lastTPS.toStringAsFixed(2), style: const TextStyle(color: Colors.black)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16), // Bottom padding for scroll
              ],
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: DropdownMenu(
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: availableModels
                .map((model) => DropdownMenuEntry(
                    value: model.slug,
                    label: '${model.slug} (${model.sizeMb}MB)'))
                .toList(),
            initialSelection: model,
            onSelected: (String? value) {
              if (value != null) {
                setState(() {
                  model = value;
                  // Reset states when model changes
                  isModelDownloaded = false;
                  isModelLoaded = false;
                });
              }
            },
          ),
        ),
      ],
    ),
    );
  }
}
