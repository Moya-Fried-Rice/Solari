import 'dart:async';
import 'dart:typed_data';

// Flutter imports
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

// Providers
import '../core/providers/history_provider.dart';
import '../core/providers/theme_provider.dart';

// Tabs
import 'tabs/history_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/solari_tab.dart';

// Services
import '../core/services/vibration_service.dart';
import '../core/services/vlm_service.dart';
import '../core/services/speaker_service.dart';
import '../core/services/tts_service.dart';
import '../core/services/ble_service.dart';
import '../core/services/screen_reader_service.dart';

// Widgets
import '../widgets/screen_reader_gesture_detector.dart';
import '../widgets/screen_reader_focusable.dart';

// Audio
import 'package:audioplayers/audioplayers.dart';

// Other
import '../utils/extra.dart';

class SolariScreen extends StatefulWidget {
  final BluetoothDevice device;
  final bool isMock; // ✅ Add this field properly

  const SolariScreen({
    super.key,
    required this.device,

    // ⚠️ REMOVE SOON - FOR TESTING ONLY ⚠️
    this.isMock = false, // ✅ Initialize default value
    // ⚠️--------------------------------⚠️
  });

  @override
  State<SolariScreen> createState() => _SolariScreenState();
}

class _SolariScreenState extends State<SolariScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
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

  // VLM Service
  final VlmService _vlmService = VlmService();

  // Speaker Service
  final SpeakerService _speakerService = SpeakerService();

  // TTS Service
  final TtsService _ttsService = TtsService();
  
  // BLE Service for audio transmission
  final BleService _bleService = BleService();
  
  // Speaking state tracking
  bool _isSpeaking = false;

  // Downloading state
  bool _downloadingModel = false;
  double? _downloadProgress;
  // =================================================================================================================================

  // =================================================================================================================================
  // Initialize and dispose
  @override
  void initState() {
    super.initState();

    // ⚠️ REMOVE SOON - FOR TESTING ONLY ⚠️
    if (widget.isMock) {
      debugPrint(
        "⚠️ SolariScreen running in MOCK MODE — skipping BLE connect.",
      );
      _initModel();
      _initializeSpeaker();
      // Optionally set mock values so UI looks alive
      setState(() {
        _currentTemp = 25.5; // Fake temperature
        _receivedImage = null; // or load a placeholder asset
      });
      return;
    }
    // ⚠️--------------------------------⚠️

    // 1. Listen for disconnection events
    _connectionStateSubscription = widget.device.connectionState.listen((
      state,
    ) {
      if (state == BluetoothConnectionState.disconnected) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });

    // 2. Wait until connected before subscribing
    widget.device.connectionState
        .firstWhere((state) => state == BluetoothConnectionState.connected)
        .then((_) {
          if (!mounted) return;
          _requestMtu();
          _subscribeToService();
          _initModel();
          _initializeSpeaker();
        });
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
    _vlmService.dispose();
    _speakerService.dispose();
    super.dispose();
  }
  // ================================================================================================================================

  // =================================================================================================================================
  // Initialize the VLM model using the service
  Future<void> _initModel() async {
    try {
      setState(() {
        _downloadingModel = true;
        _downloadProgress = 0;
        debugPrint('Downloading model');
      });
      await _vlmService.initModel(
        onProgress: (progress, status, isError) {
          setState(() {
            _downloadProgress = progress;
            if (isError) _downloadingModel = false;
          });
          debugPrint(
            '$status ${progress != null ? '${(progress * 100).toInt()}%' : ''}',
          );
        },
      );
      setState(() {
        _downloadingModel = false;
        _downloadProgress = 1.0;
        debugPrint('Model loaded!');
      });
    } catch (e) {
      setState(() {
        _downloadingModel = false;
        debugPrint('Error initializing model: $e');
      });
      debugPrint('Error initializing model: $e');
    }
  }

  // =================================================================================================================================

  // =================================================================================================================================
  // Initialize Speaker Service
  Future<void> _initializeSpeaker() async {
    try {
      // Initialize TTS service
      await _ttsService.initialize();
      
      // Initialize BLE service with connected device for audio transmission
      if (widget.device.isConnected) {
        debugPrint('🔗 Initializing BLE service for audio transmission...');
        await _bleService.initialize(widget.device);
        debugPrint('✅ BLE service initialized successfully');
      } else {
        debugPrint('⚠️ Device not connected, BLE audio transmission unavailable');
      }
      
      // Log Sherpa ONNX engine information
      final engineInfo = _ttsService.getEngineInfo();
      debugPrint('✅ TTS service initialized successfully');
      debugPrint('   Engine: ${engineInfo['engine']}');
      debugPrint('   Model: ${engineInfo['model']}');
      debugPrint('   Type: ${engineInfo['type']}');
      debugPrint('   Offline: ${engineInfo['offline']}');
      debugPrint('   Speed: ${engineInfo['speed']}x');
      debugPrint('   Transmission: ${engineInfo['transmission']}');
      debugPrint('   Sample Rate: ${engineInfo['sampleRate']}');
      
    } catch (e) {
      debugPrint('Error initializing speaker service: $e');
    }
  }

  Future<void> _speakText(String text) async {
    try {
      // Play done.wav at the same time as TTS starts speaking
      final player = AudioPlayer();
      await player.play(
        AssetSource('audio/done.wav'),
        volume: 1.0,
      );

      await _speakerService.speakText(
        text,
        onStart: () {
          if (mounted) {
            setState(() {
              _isSpeaking = true; // Explicitly track speaking state
            });
          }
        },
        onComplete: () {
          if (mounted) {
            setState(() {
              _isSpeaking = false;
            });
          }
        },
        onError: (error) {
          debugPrint('Error speaking text: $error');
          if (mounted) {
            setState(() {
              _isSpeaking = false;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Error in _speakText: $e');
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error subscribing: $e')));
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
      debugPrint(
        "[BLE] Image incoming header received, expected size: $_expectedImageSize bytes",
      );
      _imageBuffer.clear();
      _receivingImage = true;
      return;
    }

    if (asString.startsWith("I_END")) {
      debugPrint(
        "[BLE] Image transfer complete. Received: ${_imageBuffer.length} bytes",
      );
      _receivingImage = false;

      setState(() {
        _receivedImage = Uint8List.fromList(_imageBuffer);
      });

      debugPrint("[AI] Passing received image to model for processing...");
      // Process image with model
      _processReceivedImage(_receivedImage!, prompt: 'Describe this image.');

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
      debugPrint(
        "[BLE] Image data chunk received: ${value.length} bytes (total: ${_imageBuffer.length + value.length}/${_expectedImageSize})",
      );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('MTU negotiated: $mtu')));
      }
    } catch (e) {
      debugPrint("MTU request failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('MTU request failed: $e')));
      }
    }
  }
  // ================================================================================================================================

  // ================================================================================================================================
  // Process the received image with the Cactus VLM model
  Future<void> _processReceivedImage(
    Uint8List imageData, {
    required String prompt,
  }) async {
    // ✅ Validate image size before processing
    if (_imageBuffer.length < _expectedImageSize) {
      debugPrint(
        "[AI] ⚠️ Incomplete image received. Expected $_expectedImageSize bytes, got \\${_imageBuffer.length} bytes.",
      );
      return;
    }

    setState(() {
      _processingImage = true;
    });

    try {
      debugPrint('[AI] Passing image to VlmService for processing...');
      final response = await _vlmService.processImage(
        imageData,
        prompt: prompt,
      );
      if (response != null && mounted) {
        debugPrint('[AI] Image description complete: $response');
        _speakText(response);
        // Add to history
        final historyProvider = Provider.of<HistoryProvider>(
          context,
          listen: false,
        );
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
      speaking: _speakerService.isSpeaking,
      processing: _processingImage,
      image: _receivedImage,
      downloadingModel: _downloadingModel,
      downloadProgress: _downloadProgress,
    ),
    SettingsTab(device: widget.device, onDisconnect: _handleDisconnect),
    HistoryTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: ScreenReaderGestureDetector(
        child: SafeArea(
          child: Stack(
            children: [
              // Main content with fade animation
              AnimatedSwitcher(
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

            // Camera button as box, positioned just above bottom nav bar
            if (widget.isMock)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Opacity(
                    opacity: 0.6, // Lower opacity
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: theme.primaryColor),
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () async {
                          final XFile? pickedFile = await _picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (pickedFile != null) {
                            final bytes = await pickedFile.readAsBytes();

                            String? prompt = await showDialog<String>(
                              context: context,
                              builder: (context) {
                                final controller = TextEditingController();

                                return AlertDialog(
                                  title: const Text(
                                    'Ask a question about the image',
                                  ),
                                  content: TextField(
                                    controller: controller,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Describe this image.',
                                    ),
                                    onSubmitted: (value) {
                                      Navigator.of(context).pop(
                                        value.trim().isNotEmpty
                                            ? value
                                            : 'Describe this image.',
                                      );
                                    },
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        final text = controller.text.trim();
                                        Navigator.of(context).pop(
                                          text.isNotEmpty
                                              ? text
                                              : 'Describe this image.',
                                        );
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );

                            // Fallback safeguard if dialog was closed with back button or tap outside
                            if (prompt == null || prompt.trim().isEmpty) {
                              prompt = 'Describe this image.';
                            }

                            await _processReceivedImage(bytes, prompt: prompt);
                          }
                        },
                        tooltip: 'Pick an image',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
      // BOTTOM NAVIGATION BAR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.primaryColor,
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Solari tab
              Expanded(
                child: ScreenReaderFocusable(
                  label: 'Solari tab',
                  hint: 'Double tap to view Solari',
                  onTap: () {
                    VibrationService.mediumFeedback();
                    if (_currentIndex != 0) {
                      ScreenReaderService().clearFocusNodes();
                      setState(() => _currentIndex = 0);
                    }
                  },
                  child: InkWell(
                    onTap: () {
                      VibrationService.mediumFeedback();
                      if (_currentIndex != 0) {
                        ScreenReaderService().clearFocusNodes();
                        setState(() => _currentIndex = 0);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: FaIcon(
                            FontAwesomeIcons.eyeLowVision,
                            size: 64,
                            color: _currentIndex == 0 
                                ? theme.buttonTextColor 
                                : theme.unselectedColor,
                          ),
                        ),
                        Text(
                          'Solari',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: _currentIndex == 0 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                            color: _currentIndex == 0 
                                ? theme.buttonTextColor 
                                : theme.unselectedColor,
                            shadows: theme.isHighContrast ? [
                              Shadow(
                                offset: const Offset(0, -1), 
                                blurRadius: 5.0, 
                                color: _currentIndex == 0 
                                    ? (theme.isDarkMode ? Colors.black : Colors.white)
                                    : theme.unselectedColor,
                              ),
                              Shadow(
                                offset: const Offset(0, 1), 
                                blurRadius: 5.0, 
                                color: _currentIndex == 0 
                                    ? (theme.isDarkMode ? Colors.black : Colors.white)
                                    : theme.unselectedColor,
                              ),
                              Shadow(
                                offset: const Offset(-1, 0), 
                                blurRadius: 5.0, 
                                color: _currentIndex == 0 
                                    ? (theme.isDarkMode ? Colors.black : Colors.white)
                                    : theme.unselectedColor,
                              ),
                              Shadow(
                                offset: const Offset(1, 0), 
                                blurRadius: 5.0, 
                                color: _currentIndex == 0 
                                    ? (theme.isDarkMode ? Colors.black : Colors.white)
                                    : theme.unselectedColor,
                              ),
                            ] : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              // Settings tab
              Expanded(
                child: ScreenReaderFocusable(
                  label: 'Settings tab',
                  hint: 'Double tap to view Settings',
                  onTap: () {
                    VibrationService.mediumFeedback();
                    if (_currentIndex != 1) {
                      ScreenReaderService().clearFocusNodes();
                      setState(() => _currentIndex = 1);
                    }
                  },
                  child: InkWell(
                    onTap: () {
                      VibrationService.mediumFeedback();
                      if (_currentIndex != 1) {
                        ScreenReaderService().clearFocusNodes();
                        setState(() => _currentIndex = 1);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: FaIcon(
                            FontAwesomeIcons.gear,
                            size: 64,
                            color: _currentIndex == 1 
                                ? theme.buttonTextColor 
                                : theme.unselectedColor,
                          ),
                        ),
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: _currentIndex == 1 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                            color: _currentIndex == 1 
                                ? theme.buttonTextColor 
                                : theme.unselectedColor,
                            shadows: theme.isHighContrast ? [
                              Shadow(
                                offset: const Offset(0, -1), 
                                blurRadius: 5.0, 
                                color: _currentIndex == 1 
                                    ? (theme.isDarkMode ? Colors.black : Colors.white)
                                    : theme.unselectedColor,
                              ),
                              Shadow(
                                offset: const Offset(0, 1), 
                                blurRadius: 5.0, 
                                color: _currentIndex == 1 
                                    ? (theme.isDarkMode ? Colors.black : Colors.white)
                                    : theme.unselectedColor,
                              ),
                              Shadow(
                                offset: const Offset(-1, 0), 
                                blurRadius: 5.0, 
                                color: _currentIndex == 1 
                                    ? (theme.isDarkMode ? Colors.black : Colors.white)
                                    : theme.unselectedColor,
                              ),
                              Shadow(
                                offset: const Offset(1, 0), 
                                blurRadius: 5.0, 
                                color: _currentIndex == 1 
                                    ? (theme.isDarkMode ? Colors.black : Colors.white)
                                    : theme.unselectedColor,
                              ),
                            ] : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              // History tab
              Expanded(
                child: ScreenReaderFocusable(
                  label: 'History tab',
                  hint: 'Double tap to view History',
                  onTap: () {
                    VibrationService.mediumFeedback();
                    if (_currentIndex != 2) {
                      ScreenReaderService().clearFocusNodes();
                      setState(() => _currentIndex = 2);
                    }
                  },
                  child: InkWell(
                    onTap: () {
                      VibrationService.mediumFeedback();
                      if (_currentIndex != 2) {
                        ScreenReaderService().clearFocusNodes();
                        setState(() => _currentIndex = 2);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: FaIcon(
                            FontAwesomeIcons.clockRotateLeft,
                            size: 64,
                            color: _currentIndex == 2 
                                ? theme.buttonTextColor 
                                : theme.unselectedColor,
                          ),
                        ),
                        Text(
                          'History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: _currentIndex == 2 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                            color: _currentIndex == 2 
                                ? theme.buttonTextColor 
                                : theme.unselectedColor,
                            shadows: theme.isHighContrast ? [
                              Shadow(
                                offset: const Offset(0, -1), 
                                blurRadius: 5.0, 
                                color: _currentIndex == 2 
                                    ? (theme.isDarkMode ? Colors.black : Colors.white)
                                    : theme.unselectedColor,
                              ),
                              Shadow(
                                offset: const Offset(0, 1), 
                                blurRadius: 5.0, 
                                color: _currentIndex == 2 
                                    ? (theme.isDarkMode ? Colors.black : Colors.white)
                                    : theme.unselectedColor,
                              ),
                              Shadow(
                                offset: const Offset(-1, 0), 
                                blurRadius: 5.0, 
                                color: _currentIndex == 2 
                                    ? (theme.isDarkMode ? Colors.black : Colors.white)
                                    : theme.unselectedColor,
                              ),
                              Shadow(
                                offset: const Offset(1, 0), 
                                blurRadius: 5.0, 
                                color: _currentIndex == 2 
                                    ? (theme.isDarkMode ? Colors.black : Colors.white)
                                    : theme.unselectedColor,
                              ),
                            ] : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================================================================================
}
