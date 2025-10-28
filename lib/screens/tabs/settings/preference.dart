import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  
  // Audio features
  bool audioDescriptionEnabled = false;
  
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
        selectToSpeakEnabled = SelectToSpeakService().isEnabled;
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
        if (persistedVoiceAssist != null) voiceAssistEnabled = persistedVoiceAssist;
      });
    }
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
          onSpeedChanged: (val) async {
            final selectToSpeakService = SelectToSpeakService();
            await selectToSpeakService.setSpeechRate(val);
            if (mounted) setState(() => ttsSpeed = val);
          },
        ),
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
                  // First row: Text Format and Speech Settings (use Grid so heights match)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: 2,
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
                    itemCount: allFeatures.length - 2,
                    itemBuilder: (context, index) {
                      final feature = allFeatures[index + 2];
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
