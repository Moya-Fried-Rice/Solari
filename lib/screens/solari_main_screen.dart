// Dart imports
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

// Flutter imports
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Third-party packages
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:cactus/cactus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Project imports
import '../core/providers/history_provider.dart';
import '../core/providers/theme_provider.dart';
import '../utils/extra.dart';
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
  // Track if TTS is currently speaking
  bool _isSpeaking = false;
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
  bool _processingImage = false;

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
    // 1. Listen for disconnection events (keep this!)
    _connectionStateSubscription = widget.device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });

    // 2. Wait until connected before subscribing
    // widget.device.connectionState.firstWhere(
    //   (state) => state == BluetoothConnectionState.connected,
    // ).then((_) {
    //   if (!mounted) return;
    //   _requestMtu();
    //   _subscribeToService();
    //   _initModel();
    //   _initializeTts();
    // });
  }


  @override
  void dispose() {
    _connectionStateSubscription?.cancel();
    for (var sub in _charSubscriptions) {
      sub.cancel();
    }
    _charSubscriptions.clear();
    _audioBuffer.clear();
    _imageBuffer.clear();
    _vlm?.dispose();
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
      setState(() {
        _isSpeaking = true;
      });
      await _flutterTts.speak(text);
      // Optionally, listen for completion
      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });
      _flutterTts.setCancelHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      });
    } catch (e) {
      debugPrint('Error speaking text: $e');
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
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
  // Handle device disconnection
    Future<void> _handleDisconnect() async {
    try {
      await widget.device.disconnectAndUpdateStream();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
  // ================================================================================================================================
  
  
  
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
      debugPrint("[BLE] Image incoming header received, expected size: $_expectedImageSize bytes");
      _imageBuffer.clear();
      _receivingImage = true;
      return;
    }

    if (asString.startsWith("I_END")) {
      debugPrint("[BLE] Image transfer complete. Received: ${_imageBuffer.length} bytes");
      _receivingImage = false;

      setState(() {
        _receivedImage = Uint8List.fromList(_imageBuffer);
      });

      debugPrint("[AI] Passing received image to model for processing...");
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
      debugPrint("[BLE] Audio data chunk received: ${value.length} bytes");
      _audioBuffer.addAll(value);
    } else if (_receivingImage) {
      debugPrint("[BLE] Image data chunk received: ${value.length} bytes (total: ${_imageBuffer.length + value.length}/${_expectedImageSize})");
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
    if (_vlm == null) {
      debugPrint('[AI] Model not initialized, skipping image processing.');
      return;
    }

    // ✅ Validate image size before processing
    if (_imageBuffer.length < _expectedImageSize) {
      debugPrint("[AI] ⚠️ Incomplete image received. Expected $_expectedImageSize bytes, got ${_imageBuffer.length} bytes.");
      return;
    }

    setState(() {
      _processingImage = true;
    });

    try {
      debugPrint('[AI] Writing received image to temp file for model input...');
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_image.jpg');
      await tempFile.writeAsBytes(imageData, flush: true);

      String response = '';
      debugPrint('[AI] Running VLM model completion on image...');
      await _vlm!.completion(
        [ChatMessage(role: 'user', content: 'Describe this image.')],
        imagePaths: [tempFile.path],
        maxTokens: 200,
        onToken: (token) {
          response += token;
          debugPrint('[AI] Model token: $token');
          return true;
        },
      );

      await tempFile.delete();

      if (mounted) {
        debugPrint('[AI] Image description complete: $response');
        _speakText(response);
        // Add to history
        final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
        historyProvider.addEntry(imageData, response);
      }
    } catch (e) {
      debugPrint('[AI] Error processing image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _processingImage = false;
        });
      }
    }
  }
  // ================================================================================================================================



  // =================================================================================================================================
  // Build the UI
  int _currentIndex = 0;

  List<Widget> get _tabs => [
    SolariTab(
      temperature: _currentTemp,
      speaking: _isSpeaking,
      processing: _processingImage,
      image: _receivedImage,
    ),
    SettingsTab(device: widget.device, onDisconnect: _handleDisconnect),
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

      // BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        iconSize: 60,
        selectedItemColor: theme.iconColor,
        unselectedItemColor: theme.unselectedColor,
        backgroundColor: theme.primaryColor,
        selectedLabelStyle: theme.labelStyle.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: theme.labelStyle.copyWith(
          fontSize: 20,
          color: theme.unselectedColor,
          fontWeight: FontWeight.normal,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: const FaIcon(FontAwesomeIcons.eyeLowVision),
            ),
            label: 'Solari',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: const FaIcon(FontAwesomeIcons.gear),
            ),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: const FaIcon(FontAwesomeIcons.clockRotateLeft),
            ),
            label: 'History',
          ),
        ],
      )
      
    );
  }
  // ================================================================================================================================
}
