import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/services.dart';
import '../../../widgets/widgets.dart';

/// Screen for user preferences settings
class PreferencePage extends StatefulWidget {
  /// Creates a preferences screen
  const PreferencePage({super.key});

  @override
  State<PreferencePage> createState() => _PreferencePageState();
}

class _PreferencePageState extends State<PreferencePage> {
  // --- User preferences ---
  bool useSystemTheme = true;
  
  // Vision features
  bool screenReaderEnabled = false;
  bool selectToSpeakEnabled = false;
  bool magnificationEnabled = false;
  bool colorInversionEnabled = false;
  bool highContrastEnabled = false;
  
  // Text to Speech settings
  double ttsSpeed = 1.0; // Default speed
  bool ttsOutputToSolari = true; // Default to Solari device
  
  // Audio features
  bool audioDescriptionEnabled = false;
  
  // Local model settings
  bool useLocalModel = false;
  String? localModelPath;
  String? localMmprojPath;
  bool isRefreshingVlm = false;
  String? vlmRefreshStatus;
  
  // VLM parameters
  String systemInstructions = '';
  double temperature = 0.3;
  int topK = 40;
  double topP = 0.9;
  int maxTokens = 50;
  
  // Haptic features
  bool vibrationEnabled = true; // Default to enabled
  // Voice assist
  bool voiceAssistEnabled = false;
  // Persisted features
  static const String _magnificationKey = 'magnification_enabled';
  static const String _voiceAssistKey = 'voice_assist_enabled';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    
    // Listen to service changes for reactive updates
    MagnificationService().addListener(_onMagnificationChanged);
    ScreenReaderService().addListener(_onScreenReaderChanged);
    SelectToSpeakService().addListener(_onSelectToSpeakChanged);
    VoiceAssistService().addListener(_onVoiceAssistChanged);
    
    // Set the active context for screen reader when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenReaderService().setActiveContext('preferences');
      // Auto-focus first element (back button) if screen reader is enabled
      if (ScreenReaderService().isEnabled) {
        Future.delayed(const Duration(milliseconds: 300), () {
          ScreenReaderService().focusNext();
        });
      }
      
      // Periodically check vibration state (since it's not a ChangeNotifier)
      _startVibrationStateChecker();
    });
  }
  
  void _startVibrationStateChecker() {
    // Check vibration state every 500ms while mounted
    Future.doWhile(() async {
      if (!mounted) return false;
      
      final isEnabled = await VibrationService.isVibrationEnabled();
      if (mounted && vibrationEnabled != isEnabled) {
        setState(() {
          vibrationEnabled = isEnabled;
        });
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      return mounted;
    });
  }
  
  void _onMagnificationChanged() {
    if (mounted) {
      setState(() {
        magnificationEnabled = MagnificationService().isEnabled;
      });
    }
  }
  
  void _onScreenReaderChanged() {
    if (mounted) {
      setState(() {
        screenReaderEnabled = ScreenReaderService().isEnabled;
      });
    }
  }
  
  void _onSelectToSpeakChanged() {
    if (mounted) {
      setState(() {
        final service = SelectToSpeakService();
        selectToSpeakEnabled = service.isEnabled;
        ttsSpeed = service.speechRate;
        ttsOutputToSolari = service.outputToSolari;
      });
    }
  }
  
  void _onVoiceAssistChanged() {
    if (mounted) {
      setState(() {
        voiceAssistEnabled = VoiceAssistService().isEnabled;
      });
    }
  }
  
  void _onThemeChanged() async {
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    final systemTheme = await PreferencesService.getUseSystemTheme();
    if (mounted) {
      setState(() {
        colorInversionEnabled = theme.isColorInverted;
        highContrastEnabled = theme.isHighContrast;
        useSystemTheme = systemTheme;
      });
    }
  }

  @override
  void dispose() {
    // Remove listeners when disposing
    MagnificationService().removeListener(_onMagnificationChanged);
    ScreenReaderService().removeListener(_onScreenReaderChanged);
    SelectToSpeakService().removeListener(_onSelectToSpeakChanged);
    VoiceAssistService().removeListener(_onVoiceAssistChanged);
    
    // Remove theme listener
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    theme.removeListener(_onThemeChanged);
    
    // Clear focus nodes for this page when leaving
    ScreenReaderService().clearContextNodes('preferences');
    super.dispose();
  }

  void _loadPreferences() async {
    final isVibrationEnabled = await VibrationService.isVibrationEnabled();
    final theme = Provider.of<ThemeProvider>(context, listen: false);
    
    // Add listener for theme changes
    theme.addListener(_onThemeChanged);
    
    final selectToSpeakService = SelectToSpeakService();
    await selectToSpeakService.initialize();
    final screenReaderService = ScreenReaderService();
    await screenReaderService.initialize();
    // Load persisted toggles
    final prefs = await SharedPreferences.getInstance();
    final persistedMagnification = prefs.getBool(_magnificationKey);
    final persistedVoiceAssist = prefs.getBool(_voiceAssistKey);

    // Initialize magnification service
    final magnificationService = MagnificationService();
    if (persistedMagnification == true) {
      magnificationService.setEnabled(true);
    }

    if (mounted) {
      setState(() {
        vibrationEnabled = isVibrationEnabled;
        // Vision defaults
        screenReaderEnabled = screenReaderService.isEnabled;
        selectToSpeakEnabled = selectToSpeakService.isEnabled;
        magnificationEnabled = false;
  if (persistedMagnification != null) magnificationEnabled = persistedMagnification;
        colorInversionEnabled = theme.isColorInverted;
        highContrastEnabled = theme.isHighContrast; // Load from theme provider
        // Sync defaults
        useSystemTheme = true;
        // Load speech settings from SelectToSpeakService
        ttsSpeed = selectToSpeakService.speechRate;
        ttsOutputToSolari = selectToSpeakService.outputToSolari;
        if (persistedVoiceAssist != null) voiceAssistEnabled = persistedVoiceAssist;
      });
    }
    
    // Load local model settings
    _loadLocalModelSettings();
  }

  Future<void> _toggleVibration(bool value) async {
    await VibrationService.setVibrationEnabled(value);
    setState(() {
      vibrationEnabled = value;
    });

    if (value) {
      VibrationService.mediumFeedback();
    }
  }

  Future<void> _setMagnificationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_magnificationKey, value);
    
    final magnificationService = MagnificationService();
    magnificationService.setEnabled(value);
    
    if (mounted) setState(() => magnificationEnabled = value);
  }

  Future<void> _setVoiceAssistEnabled(bool value) async {
    final voiceAssistService = VoiceAssistService();
    
    if (value) {
      // Initialize voice assist service when enabled
      await voiceAssistService.initialize();
      
      // Set theme provider reference
      if (mounted) {
        final theme = Provider.of<ThemeProvider>(context, listen: false);
        voiceAssistService.setThemeProvider(theme);
      }
    }
    
    // Set enabled state (saves to SharedPreferences)
    await voiceAssistService.setEnabled(value);
    
    if (mounted) setState(() => voiceAssistEnabled = value);
  }

  /// Load local model settings
  Future<void> _loadLocalModelSettings() async {
    final isLocalEnabled = await VlmService.isLocalModelEnabled();
    final modelPath = await VlmService.getLocalModelPath();
    final mmprojPath = await VlmService.getLocalMmprojPath();
    final sysInstructions = await VlmService.getSystemInstructions();
    final temp = await VlmService.getTemperature();
    final tk = await VlmService.getTopK();
    final tp = await VlmService.getTopP();
    final mt = await VlmService.getMaxTokens();
    
    if (mounted) {
      setState(() {
        useLocalModel = isLocalEnabled;
        localModelPath = modelPath;
        localMmprojPath = mmprojPath;
        systemInstructions = sysInstructions;
        temperature = temp;
        topK = tk;
        topP = tp;
        maxTokens = mt;
      });
    }
  }

  /// Show local model settings bottom sheet
  Future<void> _showLocalModelSettings() async {
    VibrationService.mediumFeedback();
    ScreenReaderService().setActiveContext('local_model_settings');

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => WillPopScope(
          onWillPop: () async {
            ScreenReaderService().setActiveContext('preferences');
            return true;
          },
          child: Container(
            decoration: BoxDecoration(
              color: themeProvider.primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                textTheme: Theme.of(context).textTheme.apply(
                  bodyColor: themeProvider.labelColor,
                  displayColor: themeProvider.labelColor,
                ),
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) => ScreenReaderGestureDetector(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                      top: 10,
                      left: 20,
                      right: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        // Close button
                        Center(
                          child: ScreenReaderFocusable(
                            context: 'local_model_settings',
                            label: 'Close button',
                            hint: 'Double tap to close local model settings',
                            onTap: () {
                              VibrationService.mediumFeedback();
                              ScreenReaderService().setActiveContext('preferences');
                              Navigator.pop(context);
                            },
                            child: GestureDetector(
                              onTap: () {
                                VibrationService.mediumFeedback();
                                ScreenReaderService().setActiveContext('preferences');
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 48,
                                  color: themeProvider.buttonTextColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Title
                        Text(
                          'Local VLM Model Settings',
                          style: TextStyle(
                            fontSize: themeProvider.fontSize + 8,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.labelColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // Use Local Model toggle
                        _buildToggleRow(
                          themeProvider,
                          'Use Local Model',
                          useLocalModel,
                          (value) async {
                            await VlmService.setLocalModelEnabled(value);
                            setModalState(() {
                              useLocalModel = value;
                            });
                            setState(() {
                              useLocalModel = value;
                            });
                            
                            // Show restart app message
                            if (mounted) {
                              _showRestartMessage(themeProvider);
                            }
                          },
                        ),
                        if (useLocalModel) ...[
                          const SizedBox(height: 20),
                          _buildFileSelectionSection(themeProvider, setModalState),
                        ],
                        const SizedBox(height: 20),
                        // VLM Parameters Section
                        _buildVlmParametersSection(themeProvider, setModalState),
                        const SizedBox(height: 20),
                        // VLM Refresh Section
                        _buildVlmRefreshSection(themeProvider, setModalState),
                        const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    
    // Reload the settings after the modal closes
    await _loadLocalModelSettings();
  }

  /// Build toggle row widget
  Widget _buildToggleRow(
    ThemeProvider theme,
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: theme.fontSize + 4,
            color: theme.labelColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: theme.labelColor,
          inactiveThumbColor: theme.unselectedColor,
        ),
      ],
    );
  }

  /// Build file selection section
  Widget _buildFileSelectionSection(ThemeProvider theme, StateSetter setModalState) {
    return Column(
      children: [
        // Model file selection
        _buildFileSelectionRow(
          theme,
          'Model File (.gguf)',
          localModelPath,
          () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.any,
            );
            if (result != null && result.files.single.path != null) {
              final path = result.files.single.path!;
              // Validate that it's a .gguf file
              if (!path.toLowerCase().endsWith('.gguf')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please select a .gguf model file',
                      style: TextStyle(color: theme.labelColor),
                    ),
                    backgroundColor: theme.primaryColor.withOpacity(0.9),
                  ),
                );
                return;
              }
              await VlmService.setLocalModelPath(path);
              setModalState(() {
                localModelPath = path;
              });
              setState(() {
                localModelPath = path;
              });
              _showRestartMessage(theme);
            }
          },
        ),
        const SizedBox(height: 15),
        // MMProj file selection
        _buildFileSelectionRow(
          theme,
          'MMProj File (.gguf)',
          localMmprojPath,
          () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.any,
            );
            if (result != null && result.files.single.path != null) {
              final path = result.files.single.path!;
              // Validate that it's a .gguf file
              if (!path.toLowerCase().endsWith('.gguf')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please select a .gguf MMProj file',
                      style: TextStyle(color: theme.labelColor),
                    ),
                    backgroundColor: theme.primaryColor.withOpacity(0.9),
                  ),
                );
                return;
              }
              await VlmService.setLocalMmprojPath(path);
              setModalState(() {
                localMmprojPath = path;
              });
              setState(() {
                localMmprojPath = path;
              });
              _showRestartMessage(theme);
            }
          },
        ),
      ],
    );
  }

  /// Build file selection row
  Widget _buildFileSelectionRow(
    ThemeProvider theme,
    String label,
    String? filePath,
    VoidCallback onTap,
  ) {
    final fileName = filePath?.split('/').last ?? 'No file selected';
    final isFileSelected = filePath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: theme.fontSize + 2,
            color: theme.labelColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ScreenReaderFocusable(
          context: 'local_model_settings',
          label: '$label file picker',
          hint: isFileSelected 
              ? 'Current file: $fileName. Double tap to select a different file'
              : 'No file selected. Double tap to select $label',
          onTap: onTap,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.unselectedColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: theme.primaryColor.withOpacity(0.1),
              ),
              child: Row(
                children: [
                  Icon(
                    isFileSelected ? Icons.description : Icons.folder_open,
                    color: isFileSelected ? theme.labelColor : theme.unselectedColor,
                    size: theme.fontSize + 2,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fileName,
                      style: TextStyle(
                        fontSize: theme.fontSize,
                        color: isFileSelected ? theme.labelColor : theme.unselectedColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    color: theme.unselectedColor,
                    size: theme.fontSize,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build VLM parameters section
  Widget _buildVlmParametersSection(ThemeProvider theme, StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VLM Parameters',
          style: TextStyle(
            fontSize: theme.fontSize + 6,
            fontWeight: FontWeight.bold,
            color: theme.labelColor,
          ),
        ),
        const SizedBox(height: 15),
        // System Instructions
        _buildTextInputRow(
          theme,
          'System Instructions',
          systemInstructions,
          'Enter system instructions for the VLM model',
          (value) async {
            await VlmService.setSystemInstructions(value);
            setModalState(() {
              systemInstructions = value;
            });
            setState(() {
              systemInstructions = value;
            });
          },
          maxLines: 3,
        ),
        const SizedBox(height: 15),
        // Temperature
        _buildSliderRow(
          theme,
          'Temperature',
          temperature,
          0.0,
          2.0,
          0.1,
          'Controls randomness. Lower = more focused, Higher = more creative',
          (value) async {
            await VlmService.setTemperature(value);
            setModalState(() {
              temperature = value;
            });
            setState(() {
              temperature = value;
            });
          },
        ),
        const SizedBox(height: 15),
        // Top K
        _buildSliderRow(
          theme,
          'Top K',
          topK.toDouble(),
          1.0,
          100.0,
          1.0,
          'Limits token selection to top K most likely tokens',
          (value) async {
            final intValue = value.toInt();
            await VlmService.setTopK(intValue);
            setModalState(() {
              topK = intValue;
            });
            setState(() {
              topK = intValue;
            });
          },
        ),
        const SizedBox(height: 15),
        // Top P
        _buildSliderRow(
          theme,
          'Top P',
          topP,
          0.0,
          1.0,
          0.05,
          'Nucleus sampling. Considers tokens until cumulative probability reaches P',
          (value) async {
            await VlmService.setTopP(value);
            setModalState(() {
              topP = value;
            });
            setState(() {
              topP = value;
            });
          },
        ),
        const SizedBox(height: 15),
        // Max Tokens
        _buildSliderRow(
          theme,
          'Max Tokens',
          maxTokens.toDouble(),
          10.0,
          500.0,
          10.0,
          'Maximum number of tokens to generate in response',
          (value) async {
            final intValue = value.toInt();
            await VlmService.setMaxTokens(intValue);
            setModalState(() {
              maxTokens = intValue;
            });
            setState(() {
              maxTokens = intValue;
            });
          },
        ),
      ],
    );
  }

  /// Build text input row
  Widget _buildTextInputRow(
    ThemeProvider theme,
    String label,
    String value,
    String hint,
    Function(String) onChanged, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: theme.fontSize + 2,
            color: theme.labelColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value),
          maxLines: maxLines,
          style: TextStyle(
            fontSize: theme.fontSize,
            color: theme.labelColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: theme.unselectedColor,
              fontSize: theme.fontSize,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.unselectedColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.unselectedColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.labelColor),
            ),
            filled: true,
            fillColor: theme.primaryColor.withOpacity(0.1),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Build slider row
  Widget _buildSliderRow(
    ThemeProvider theme,
    String label,
    double value,
    double min,
    double max,
    double divisions,
    String description,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: theme.fontSize + 2,
                color: theme.labelColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value.toStringAsFixed(divisions < 1 ? 2 : 0),
              style: TextStyle(
                fontSize: theme.fontSize + 2,
                color: theme.labelColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: theme.fontSize - 2,
            color: theme.unselectedColor,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / divisions).toInt(),
          activeColor: theme.labelColor,
          inactiveColor: theme.unselectedColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Show restart app message
  void _showRestartMessage(ThemeProvider theme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: theme.labelColor,
              size: theme.fontSize + 2,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Model settings changed. Restart the app to apply changes.',
                style: TextStyle(
                  color: theme.labelColor,
                  fontSize: theme.fontSize,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: theme.primaryColor.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Build VLM refresh section
  Widget _buildVlmRefreshSection(ThemeProvider theme, StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VLM Model Management',
          style: TextStyle(
            fontSize: theme.fontSize + 2,
            color: theme.labelColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        // Refresh button
        ScreenReaderFocusable(
          context: 'local_model_settings',
          label: 'Refresh VLM Model button',
          hint: isRefreshingVlm 
              ? 'VLM model is currently refreshing. Please wait.'
              : 'Double tap to refresh the VLM model with current settings',
          onTap: isRefreshingVlm ? null : () => _refreshVlmModel(theme, setModalState),
          child: GestureDetector(
            onTap: isRefreshingVlm ? null : () => _refreshVlmModel(theme, setModalState),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isRefreshingVlm ? theme.unselectedColor : theme.labelColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isRefreshingVlm 
                    ? theme.unselectedColor.withOpacity(0.1)
                    : theme.primaryColor.withOpacity(0.1),
              ),
              child: Row(
                children: [
                  if (isRefreshingVlm) ...[
                    SizedBox(
                      width: theme.fontSize + 2,
                      height: theme.fontSize + 2,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.labelColor,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.refresh,
                      color: theme.labelColor,
                      size: theme.fontSize + 2,
                    ),
                  ],
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRefreshingVlm ? 'Refreshing Model...' : 'Refresh VLM Model',
                          style: TextStyle(
                            fontSize: theme.fontSize,
                            color: isRefreshingVlm ? theme.unselectedColor : theme.labelColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (vlmRefreshStatus != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            vlmRefreshStatus!,
                            style: TextStyle(
                              fontSize: theme.fontSize - 2,
                              color: theme.unselectedColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Refresh the VLM model to apply new settings or recover from errors.',
          style: TextStyle(
            fontSize: theme.fontSize - 2,
            color: theme.unselectedColor,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /// Refresh VLM model
  Future<void> _refreshVlmModel(ThemeProvider theme, StateSetter setModalState) async {
    if (isRefreshingVlm) return;
    
    VibrationService.mediumFeedback();
    
    setModalState(() {
      isRefreshingVlm = true;
      vlmRefreshStatus = 'Initializing refresh...';
    });
    
    setState(() {
      isRefreshingVlm = true;
      vlmRefreshStatus = 'Initializing refresh...';
    });

    try {
      // Get VLM service instance - you might need to adjust this based on how you access it
      // For now, I'll create a new instance, but ideally you'd get the existing one
      final vlmService = VlmService();
      
      await vlmService.refreshModel(
        onProgress: (progress, status, isError) {
          if (mounted) {
            setModalState(() {
              vlmRefreshStatus = status;
            });
            setState(() {
              vlmRefreshStatus = status;
            });
            
            if (isError) {
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.labelColor,
                        size: theme.fontSize + 2,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'VLM Refresh Error: $status',
                          style: TextStyle(
                            color: theme.labelColor,
                            fontSize: theme.fontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red.withOpacity(0.9),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  duration: const Duration(seconds: 6),
                ),
              );
            }
          }
        },
      );
      
      // Success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: theme.labelColor,
                  size: theme.fontSize + 2,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'VLM model refreshed successfully!',
                    style: TextStyle(
                      color: theme.labelColor,
                      fontSize: theme.fontSize,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        
        setModalState(() {
          vlmRefreshStatus = 'Refresh completed successfully';
        });
        setState(() {
          vlmRefreshStatus = 'Refresh completed successfully';
        });
      }
      
    } catch (e) {
      // Error handling
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.labelColor,
                  size: theme.fontSize + 2,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to refresh VLM model: $e',
                    style: TextStyle(
                      color: theme.labelColor,
                      fontSize: theme.fontSize,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 6),
          ),
        );
        
        setModalState(() {
          vlmRefreshStatus = 'Refresh failed: ${e.toString()}';
        });
        setState(() {
          vlmRefreshStatus = 'Refresh failed: ${e.toString()}';
        });
      }
    } finally {
      // Reset refresh state after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setModalState(() {
            isRefreshingVlm = false;
            vlmRefreshStatus = null;
          });
          setState(() {
            isRefreshingVlm = false;
            vlmRefreshStatus = null;
          });
        }
      });
    }
  }

  /// Gets all features as a list
  List<Map<String, dynamic>> _getAllFeatures(ThemeProvider theme) {
    return [
      {
        'icon': Icons.text_fields,
        'label': 'Text Format',
        'onTap': () => FeatureBottomSheets.showTextFormatSettings(
          context: context,
          theme: theme,
        ),
      },
      {
        'icon': Icons.record_voice_over,
        'label': 'Speech Settings',
        'onTap': () => FeatureBottomSheets.showTextToSpeechSettings(
          context: context,
          theme: theme,
          ttsSpeed: ttsSpeed,
          outputToSolari: ttsOutputToSolari,
          onSpeedChanged: (val) async {
            final selectToSpeakService = SelectToSpeakService();
            await selectToSpeakService.setSpeechRate(val);
            if (mounted) setState(() => ttsSpeed = val);
          },
          onOutputDeviceChanged: (val) async {
            final selectToSpeakService = SelectToSpeakService();
            await selectToSpeakService.setOutputToSolari(val);
            if (mounted) setState(() => ttsOutputToSolari = val);
          },
        ),
      },
      {
        'icon': Icons.memory,
        'label': 'Local Model Settings',
        'onTap': () => _showLocalModelSettings(),
      },
      {
        'icon': Icons.accessibility_new,
        'label': 'Screen Reader',
        'onTap': () async {
          final screenReaderService = ScreenReaderService();
          final newVal = !screenReaderEnabled;
          await screenReaderService.setEnabled(newVal);
          if (mounted) {
            setState(() => screenReaderEnabled = newVal);
          }
        },
      },
      {
        'icon': Icons.touch_app,
        'label': 'Select to Speak',
        'onTap': () async {
          final selectToSpeakService = SelectToSpeakService();
          final newVal = !selectToSpeakEnabled;
          await selectToSpeakService.setEnabled(newVal);
          if (mounted) setState(() => selectToSpeakEnabled = newVal);
        },
      },
      {
        'icon': Icons.zoom_in,
        'label': 'Magnification',
        'onTap': () async {
          final newVal = !magnificationEnabled;
          await _setMagnificationEnabled(newVal);
        },
      },
      {
        'icon': theme.isDarkMode ? Icons.dark_mode : Icons.light_mode,
        'label': theme.isDarkMode ? 'Dark Mode' : 'Light Mode',
        'onTap': () async {
          // toggle theme directly
          theme.toggleTheme();
          if (mounted) setState(() => useSystemTheme = false);
        },
      },
      {
        'icon': Icons.invert_colors,
        'label': 'Color Inversion',
        'onTap': () async {
          final newVal = !theme.isColorInverted;
          await theme.setColorInversion(newVal);
          if (mounted) setState(() => colorInversionEnabled = newVal);
        },
      },
      {
        'icon': Icons.contrast,
        'label': 'High Contrast',
        'onTap': () async {
          final newVal = !theme.isHighContrast;
          await theme.setHighContrast(newVal);
          if (mounted) setState(() => highContrastEnabled = newVal);
        },
      },
      {
        'icon': Icons.vibration,
        'label': 'Vibration',
        'onTap': () async {
          await _toggleVibration(!vibrationEnabled);
        },
      },
      {
        'icon': Icons.record_voice_over,
        'label': 'Voice Assist',
        'onTap': () async {
          final newVal = !voiceAssistEnabled;
          await _setVoiceAssistEnabled(newVal);
          if (newVal) VibrationService.mediumFeedback();
        },
      },
      {
        'icon': Icons.sync,
        'label': 'Enable Sync',
        'onTap': () async {
          final newVal = !useSystemTheme;
          await theme.setUseSystemTheme(newVal);
          if (mounted) setState(() => useSystemTheme = newVal);
        },
      },
    ];
  }

  bool _isFeatureEnabled(String label) {
    switch (label) {
      case 'Screen Reader':
        return screenReaderEnabled;
      case 'Select to Speak':
        return selectToSpeakEnabled;
      case 'Magnification':
        return magnificationEnabled;
      case 'Dark Mode':
      case 'Light Mode':
        return Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
      case 'Color Inversion':
        return colorInversionEnabled;
      case 'High Contrast':
        return highContrastEnabled;
      case 'Vibration':
        return vibrationEnabled;
      case 'Voice Assist':
        return voiceAssistEnabled;
      case 'Enable Sync':
        return useSystemTheme;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final allFeatures = _getAllFeatures(theme);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Preferences', 
        showBackButton: true,
        screenReaderContext: 'preferences',
      ),
      body: SafeArea(
        child: ScreenReaderGestureDetector(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // First row: Text Format, Speech Settings, and Local Model Settings
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: 3, // Now includes Local Model Settings
                    itemBuilder: (context, i) {
                      final feature = allFeatures[i];
                      return ScreenReaderFocusable(
                        context: 'preferences',
                        label: '${feature['label']} button',
                        hint: 'Double tap to open ${feature['label']} settings',
                        onTap: feature['onTap'] as VoidCallback,
                        child: FeatureCard(
                          theme: theme,
                          icon: feature['icon'] as IconData,
                          label: feature['label'] as String,
                          onTap: feature['onTap'] as VoidCallback,
                        ),
                      );
                    },
                  ),
                  // Use same divider style as DeviceStatus
                  _buildDivider(theme),
                  // Remaining features as toggles
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: allFeatures.length - 3, // Adjusted for 3 feature cards
                    itemBuilder: (context, index) {
                      final feature = allFeatures[index + 3]; // Adjusted for 3 feature cards
                      final label = feature['label'] as String;
                      final hint = 'Double tap to enable or disable $label';
                      final isThemeTile = label.toLowerCase().contains('mode');
                      return ScreenReaderFocusable(
                        context: 'preferences',
                        label: '$label button',
                        hint: hint,
                        onTap: feature['onTap'] as VoidCallback,
                        child: FeatureCard(
                          theme: theme,
                          icon: feature['icon'] as IconData,
                          label: label,
                          onTap: feature['onTap'] as VoidCallback,
                          isSelected: _isFeatureEnabled(label),
                          useToggleStyle: !isThemeTile,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

   Widget _buildDivider(ThemeProvider theme) => Column(
    children: [
      const SizedBox(height: 20),
      Container(
        height: 10,
        decoration: BoxDecoration(
          color: theme.dividerColor,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
}
