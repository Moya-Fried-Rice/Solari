// Flutter imports
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:cactus/cactus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

// UI and state management
import '../core/theme/theme_provider.dart';

// Tabs for bottom navigation
import 'tabs/history_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/solari_tab.dart';

class SolariScreen extends StatefulWidget {
  final BluetoothDevice device;

  const SolariScreen({super.key, required this.device});

  @override
  State<SolariScreen> createState() => _SolariScreenState();
}

class _SolariScreenState extends State<SolariScreen> with SingleTickerProviderStateMixin {
  // Subscription to device connection state
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  // =================================================================================================================================
  // Variables
  
  // Bluetooth service and characteristics
  BluetoothService? _targetService;
  final List<BluetoothCharacteristic> _subscribedCharacteristics = [];
  final List<StreamSubscription<List<int>>> _charSubscriptions = [];

  // Audio streaming
  final List<int> _audioBuffer = [];
  bool _audioStreaming = false;

  // Image receiving
  final List<int> _imageBuffer = [];
  Uint8List? _receivedImage;
  int _expectedImageSize = 0;
  bool _receivingImage = false;

  // Temperature received
  double? _currentTemp;

  // Cactus VLM model
  CactusVLM? _vlm;

  // TTS
  final FlutterTts _flutterTts = FlutterTts();
  // =================================================================================================================================



  // =================================================================================================================================
  // Initialize and dispose
  @override
  void initState() {
  super.initState();
  _requestMtu();
  _subscribeToService();
  _initModel();
  _initializeTts();
  
    // Listen for device disconnection
    _connectionStateSubscription = widget.device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    _connectionStateSubscription?.cancel();
    for (var sub in _charSubscriptions) {
      sub.cancel();
    }
    _charSubscriptions.clear();

    _vlm?.dispose();
    _vlm = null;
    _flutterTts.stop();
    super.dispose();
  }
  // ================================================================================================================================

  

  // =================================================================================================================================
  // Initialize the Cactus VLM model
  Future<void> _initModel() async {
    try {
      final vlm = CactusVLM();

      // Download the smaller 500M model (faster, less memory)
      bool downloadSuccess = await vlm.download(
        modelUrl:
            'https://huggingface.co/ggml-org/SmolVLM-500M-Instruct-GGUF/resolve/main/SmolVLM-500M-Instruct-Q8_0.gguf',
        mmprojUrl:
            'https://huggingface.co/ggml-org/SmolVLM-500M-Instruct-GGUF/resolve/main/mmproj-SmolVLM-500M-Instruct-Q8_0.gguf',
        modelFilename: 'SmolVLM-500M-Instruct-Q8_0.gguf',
        mmprojFilename: 'mmproj-SmolVLM-500M-Instruct-Q8_0.gguf',
        onProgress: (progress, status, isError) {
          debugPrint('$status ${progress != null ? '${(progress * 100).toInt()}%' : ''}');
          if (isError) debugPrint('Download error: $status');
        },
      );

      if (!downloadSuccess) {
        throw Exception('Model download failed - check internet connection');
      }

      // Initialize the model
      await vlm.init(
        contextSize: 2048,
        modelFilename: 'SmolVLM-500M-Instruct-Q8_0.gguf',
        mmprojFilename: 'mmproj-SmolVLM-500M-Instruct-Q8_0.gguf',
      );

      // Store the instance for later use
      _vlm = vlm;

    } catch (e) {
      debugPrint('Error initializing model: $e');
    }
  }

  // =================================================================================================================================


  
  // =================================================================================================================================
  // Initialize TTS
  void _initializeTts() {
    _flutterTts.setLanguage("en-US");
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0);
  }

  Future<void> _speakText(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking text: $e');
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

            final sub = characteristic.lastValueStream.listen((value) {
              if (!mounted) return; // Safety check
              _handleIncomingData(value);
            });
            _charSubscriptions.add(sub);
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
    if (asString.startsWith("T:")) {
      final tempString = asString.substring(2);
      final tempValue = double.tryParse(tempString);
      if (tempValue != null) {
        // debugPrint("🌡️ Temperature received: $tempValue °C");
        setState(() {
          _currentTemp = tempValue;
        });
      }
      return;
    }


    if (asString.startsWith("VQA_START")) {
      debugPrint("VQA session started");
      _imageBuffer.clear();
      _audioBuffer.clear();
      _receivedImage = null;
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
    } 
  }
  // ================================================================================================================================



  // ================================================================================================================================
  // Process the received image with the Cactus VLM model
  Future<void> _processReceivedImage(Uint8List imageData) async {
    if (_vlm == null) return;

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

      if (mounted) {
        debugPrint('Image description: $response');
        _speakText(response);
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } 
  }
  // ================================================================================================================================



  // =================================================================================================================================
  // Build the UI
  int _currentIndex = 0;

  List<Widget> get _tabs => [
    SolariTab(image: _receivedImage, temperature: _currentTemp),
    SettingsTab(),
    HistoryTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(

      // BODY with fade animation
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: IndexedStack(
          key: ValueKey<int>(_currentIndex),
          index: _currentIndex,
          children: _tabs,
        ),
      ),

      // BOTTOM NAVIGATION BAR with theme colors
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        iconSize: 100,
        selectedItemColor: theme.iconColor,
        unselectedItemColor: theme.unselectedColor,
        backgroundColor: theme.primaryColor,
        selectedLabelStyle: theme.labelStyle.copyWith(
          fontSize: 20,
        ),
        unselectedLabelStyle: theme.labelStyle.copyWith(
          fontSize: 20,
          color: theme.unselectedColor,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.memory), label: 'Solari'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      )
    );
  }
  // ================================================================================================================================
}
