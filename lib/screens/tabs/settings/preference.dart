import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/vibration_service.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/feature_bottom_sheets.dart';
import '../../../widgets/feature_card.dart';

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
  double ttsPitch = 1.0; // Default pitch
  
  // Audio features
  bool audioDescriptionEnabled = false;
  
  // Haptic features
  bool vibrationEnabled = true; // Default to enabled

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() async {
    final isVibrationEnabled = await VibrationService.isVibrationEnabled();
    final theme = Provider.of<ThemeProvider>(context, listen: false);

    if (mounted) {
      setState(() {
        vibrationEnabled = isVibrationEnabled;
        // Vision defaults
        screenReaderEnabled = false;
        selectToSpeakEnabled = false;
        magnificationEnabled = false;
        colorInversionEnabled = theme.isColorInverted;
        highContrastEnabled = theme.isHighContrast; // Load from theme provider
        // Audio defaults
        audioDescriptionEnabled = false;
        // Sync defaults
        useSystemTheme = true;
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
          ttsPitch: ttsPitch,
          onSpeedChanged: (val) => setState(() => ttsSpeed = val),
          onPitchChanged: (val) => setState(() => ttsPitch = val),
        ),
      },
      {
        'icon': Icons.accessibility_new,
        'label': 'Screen Reader',
        'onTap': () => FeatureBottomSheets.showScreenReaderSettings(
          context: context,
          theme: theme,
          value: screenReaderEnabled,
          onChanged: (val) => setState(() => screenReaderEnabled = val),
        ),
      },
      {
        'icon': Icons.touch_app,
        'label': 'Select to Speak',
        'onTap': () => FeatureBottomSheets.showSelectToSpeakSettings(
          context: context,
          theme: theme,
          value: selectToSpeakEnabled,
          onChanged: (val) => setState(() => selectToSpeakEnabled = val),
        ),
      },
      {
        'icon': Icons.zoom_in,
        'label': 'Magnification',
        'onTap': () => FeatureBottomSheets.showMagnificationSettings(
          context: context,
          theme: theme,
          value: magnificationEnabled,
          onChanged: (val) => setState(() => magnificationEnabled = val),
        ),
      },
      {
        'icon': theme.isDarkMode ? Icons.dark_mode : Icons.light_mode,
        'label': theme.isDarkMode ? 'Dark Mode' : 'Light Mode',
        'onTap': () => FeatureBottomSheets.showThemeSettings(
          context: context,
          theme: theme,
          onToggleTheme: () {
            theme.toggleTheme();
            setState(() => useSystemTheme = false);
          },
        ),
      },
      {
        'icon': Icons.invert_colors,
        'label': 'Color Inversion',
        'onTap': () => FeatureBottomSheets.showColorInversionSettings(
          context: context,
          theme: theme,
          value: theme.isColorInverted,
          onChanged: (val) async {
            await theme.setColorInversion(val);
            if (mounted) setState(() => colorInversionEnabled = val);
          },
        ),
      },
      {
        'icon': Icons.contrast,
        'label': 'High Contrast',
        'onTap': () => FeatureBottomSheets.showHighContrastSettings(
          context: context,
          theme: theme,
          onToggleHighContrast: () {
            theme.setHighContrast(!theme.isHighContrast);
            setState(() => highContrastEnabled = !highContrastEnabled);
          },
        ),
      },
      {
        'icon': Icons.audiotrack,
        'label': 'Audio Description',
        'onTap': () => FeatureBottomSheets.showAudioDescriptionSettings(
          context: context,
          theme: theme,
          value: audioDescriptionEnabled,
          onChanged: (val) => setState(() => audioDescriptionEnabled = val),
        ),
      },
      {
        'icon': Icons.vibration,
        'label': 'Vibration',
        'onTap': () => FeatureBottomSheets.showVibrationSettings(
          context: context,
          theme: theme,
          value: vibrationEnabled,
          onChanged: _toggleVibration,
        ),
      },
      {
        'icon': Icons.sync,
        'label': 'Enable Sync',
        'onTap': () => FeatureBottomSheets.showSyncSettings(
          context: context,
          theme: theme,
          value: useSystemTheme,
          onChanged: (val) {
            setState(() => useSystemTheme = val);
            theme.setUseSystemTheme(val);
          },
        ),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final allFeatures = _getAllFeatures(theme);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Preferences', showBackButton: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: allFeatures.length,
            itemBuilder: (context, index) {
              final feature = allFeatures[index];
              return FeatureCard(
                theme: theme,
                icon: feature['icon'] as IconData,
                label: feature['label'] as String,
                onTap: feature['onTap'] as VoidCallback,
              );
            },
          ),
        ),
      ),
    );
  }
}
