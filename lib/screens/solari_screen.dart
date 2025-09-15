import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:cactus/cactus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SolariScreen extends StatefulWidget {
  final BluetoothDevice device;

  const SolariScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<SolariScreen> createState() => _SolariScreenState();
}

class _SolariScreenState extends State<SolariScreen> {
  // =================================================================================================================================
  // Variables

  // Bluetooth service and characteristics
  BluetoothService? _targetService;
  final List<BluetoothCharacteristic> _subscribedCharacteristics = [];

  // Audio streaming
  final List<int> _audioBuffer = [];
  bool _audioStreaming = false;

  // Image receiving
  final List<int> _imageBuffer = [];
  Uint8List? _receivedImage;
  int _expectedImageSize = 0;
  bool _receivingImage = false;

  // Negotiation state
  bool _negotiating = false;

  // Cactus VLM model
  CactusVLM? _vlm;
  String? _imageDescription;
  bool _isProcessing = false;
  // =================================================================================================================================



  // =================================================================================================================================
  // Initialize and dispose
  @override
  void initState() {
  super.initState();
  _requestMtu();
  _subscribeToService();
  _initModel();
  }

  @override
  void dispose() {
  _vlm?.dispose();
  _vlm = null;
  super.dispose();
  }
  // ================================================================================================================================

  

  // =================================================================================================================================
  // Initialize the Cactus VLM model
  Future<void> _initModel() async {
    try {
      _vlm = CactusVLM();
      await _vlm!.download(
        modelUrl: 'https://huggingface.co/ggml-org/SmolVLM-500M-Instruct-GGUF/resolve/main/SmolVLM-500M-Instruct-Q8_0.gguf',
        mmprojUrl: 'https://huggingface.co/ggml-org/SmolVLM-500M-Instruct-GGUF/resolve/main/mmproj-SmolVLM-500M-Instruct-Q8_0.gguf',
      );
      await _vlm!.init(contextSize: 2048);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model initialized successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error initializing model: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing model: $e')),
        );
      }
    }
  }
  // =================================================================================================================================



  // =================================================================================================================================
  // Subscribe to the Solari service and its characteristics
  Future<void> _subscribeToService() async {
    const serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
    try {
      List<BluetoothService> services = await widget.device.discoverServices();
      for (var s in services) {
        if (s.uuid.toString().toLowerCase() == serviceUuid) {
          _targetService = s;
          break;
        }
      }

      if (_targetService != null) {
        for (var characteristic in _targetService!.characteristics) {
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            _subscribedCharacteristics.add(characteristic);

            characteristic.lastValueStream.listen((value) {
              _handleIncomingData(value);
            });
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully subscribed to service')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error subscribing: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error subscribing: $e')),
        );
      }
    }
  }
  // =================================================================================================================================



  // =================================================================================================================================
  // Handle incoming data from characteristics
  void _handleIncomingData(List<int> value) {
    if (value.isEmpty) return;

    String asString = String.fromCharCodes(value);

    if (asString.startsWith("VQA_START")) {
      debugPrint("VQA session started");
      _imageBuffer.clear();
      _audioBuffer.clear();
      _receivedImage = null;
      _imageDescription = null;
      _receivingImage = false;
      _audioStreaming = false;
      setState(() {});
      return;
    }

    if (asString.startsWith("A_START")) {
      debugPrint("Audio streaming started");
      _audioStreaming = true;
      _audioBuffer.clear();
      return;
    }

    if (asString.startsWith("A_END")) {
      debugPrint("Audio streaming ended");
      _audioStreaming = false;
      setState(() {});
      return;
    }

    if (asString.startsWith("I:")) {
      // Image header with size
      _expectedImageSize = int.tryParse(asString.split(":")[1]) ?? 0;
      debugPrint("Image incoming, expected size: $_expectedImageSize bytes");
      _imageBuffer.clear();
      _receivingImage = true;
      return;
    }

    if (asString.startsWith("I_END")) {
      debugPrint("Image received: ${_imageBuffer.length} bytes");
      _receivingImage = false;

      setState(() {
        _receivedImage = Uint8List.fromList(_imageBuffer);
      });

      // Process image with model
      _processReceivedImage(_receivedImage!);

      return;
    }

    if (asString.startsWith("VQA_END")) {
      debugPrint("VQA session ended");
      return;
    }

    // --- OTHERWISE THIS IS BINARY DATA ---
    if (_audioStreaming) {
      _audioBuffer.addAll(value);
    } else if (_receivingImage) {
      _imageBuffer.addAll(value);
    }
  }
  // =================================================================================================================================



  // ================================================================================================================================
  // Request a larger MTU for better performance
  Future<void> _requestMtu() async {
    setState(() {
      _negotiating = true;
    });
    try {
      int mtu = await widget.device.requestMtu(517);
      debugPrint("MTU negotiated: $mtu");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MTU negotiated: $mtu')),
        );
      }
    } catch (e) {
      debugPrint("MTU request failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('MTU request failed: $e')),
        );
      }
    } finally {
      setState(() {
        _negotiating = false;
      });
    }
  }
  // ================================================================================================================================



  // ================================================================================================================================
  // Process the received image with the Cactus VLM model
  Future<void> _processReceivedImage(Uint8List imageData) async {
    if (_vlm == null) return;

    try {
      setState(() => _isProcessing = true); // start indicator

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

      if (mounted) {
        setState(() => _imageDescription = response);
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false); // stop indicator
    }
  }
  // ================================================================================================================================



  // =================================================================================================================================
  // Build the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.device_hub, size: 64),
            const SizedBox(height: 16),
            Text(
              'Connected to: ${widget.device.platformName}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (_negotiating)
              const Text('Negotiating MTU...', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),

            if (_receivedImage != null) ...[
              Image.memory(_receivedImage!, height: 200, fit: BoxFit.contain),
              const SizedBox(height: 8),
              Text('Image size: ${_receivedImage!.lengthInBytes} bytes', style: const TextStyle(fontSize: 16)),
              Text('Audio size: ${_audioBuffer.length} bytes', style: const TextStyle(fontSize: 16)),
              if (_imageDescription != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Description: $_imageDescription',
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ],

             // Simple processing indicator
            if (_isProcessing)
              Column(
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Processing response...', style: TextStyle(fontSize: 14)),
                  SizedBox(height: 16),
                ],
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Disconnect'),
              onPressed: () async {
                await widget.device.disconnect();
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
  // ================================================================================================================================
}
