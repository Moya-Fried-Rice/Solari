import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/vibration_service.dart';
import '../../../core/services/system_preferences_service.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/toggle.dart';

/// Screen for user preferences settings
class PreferencePage extends StatefulWidget {
  /// Creates a preferences screen
  const PreferencePage({super.key});

  @override
  State<PreferencePage> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencePage> {
  // --- User preferences ---
  bool useSystemTheme = true;
  bool useSystemFontSize = true;
  bool useSystemAccessibility = true;
  bool screenReaderEnabled = false;
  int speed = 0; // Default to lowest speed value
  int pitch = 0; // Default to lowest pitch value
  bool vibrationEnabled = true; // Default to enabled

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() async {
    // Load vibration preference
    final isVibrationEnabled = await VibrationService.isVibrationEnabled();
    
    if (mounted) {
      // Load system preferences from instance
      final systemPrefs = SystemPreferencesService.instance.getInitialPreferences(context);
      
      // Get theme provider
      final theme = Provider.of<ThemeProvider>(context, listen: false);
      
      setState(() {
        vibrationEnabled = isVibrationEnabled;
        screenReaderEnabled = systemPrefs['screenReaderEnabled'];
        
        // Initialize system preference flags
        useSystemTheme = !theme.hasUserSetTheme;
        useSystemFontSize = !theme.hasUserSetFontSize;
        useSystemAccessibility = true; // Default to using system accessibility
        
        // Update theme provider with system preferences if using system settings
        if (useSystemTheme) {
          theme.setDarkMode(systemPrefs['isDarkMode']);
        }
        if (useSystemFontSize) {
          theme.setSystemFontSize(systemPrefs['fontSize']);
        }
      });
    }
  }

  Future<void> _toggleVibration(bool value) async {
    await VibrationService.setVibrationEnabled(value);
    setState(() {
      vibrationEnabled = value;
    });

    // Provide feedback when enabling (but not when disabling)
    if (value) {
      VibrationService.mediumFeedback();
    }
  }

  /// Shows a bottom sheet with custom content
  void _showBottomSheet({
    required BuildContext context,
    required ThemeProvider theme,
    required List<Widget> content,
  }) {
    VibrationService.mediumFeedback();
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.primaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header handle
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.unselectedColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Content widgets
                ...content,

                const SizedBox(height: 20),
                // Done Button
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        VibrationService.mediumFeedback();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.labelColor,
                        foregroundColor: theme.primaryColor,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontSize: theme.fontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Creates a generic discrete slider for different setting types
  Widget _buildDiscreteSlider<T>({
    required ThemeProvider theme,
    required String label,
    required List<T> values,
    required T currentValue,
    required void Function(T) onChanged,
    required String Function(T) valueFormatter,
  }) {
    // Find the current value index
    int currentValueIndex = values.indexWhere((value) => value == currentValue);
    if (currentValueIndex == -1) {
      // Find nearest value if exact match not found
      for (int i = 0; i < values.length; i++) {
        if ((currentValue is num) &&
            (values[i] is num) &&
            (currentValue as num) <= (values[i] as num)) {
          currentValueIndex = i;
          break;
        }
      }
      // Default to last value if still not found
      if (currentValueIndex == -1) currentValueIndex = values.length - 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label and current value display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: theme.fontSize,
                color: theme.labelColor,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            Text(
              valueFormatter(currentValue),
              style: TextStyle(
                fontSize: theme.fontSize,
                color: theme.labelColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Slider with discrete values
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: theme.labelColor,
            inactiveTrackColor: theme.unselectedColor,
            thumbColor: theme.labelColor,
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 4),
            activeTickMarkColor: theme.labelColor,
            inactiveTickMarkColor: theme.unselectedColor,
            valueIndicatorColor: theme.labelColor,
            valueIndicatorTextStyle: TextStyle(
              color: theme.primaryColor,
              fontSize: theme.fontSize,
            ),
          ),
          child: Slider(
            value: currentValueIndex.toDouble(),
            min: 0,
            max: values.length - 1,
            divisions: values.length - 1,
            onChanged: (double value) {
              int index = value.round();
              onChanged(values[index]);
              VibrationService.lightFeedback();
            },
          ),
        ),

        // Value labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: values
                .map(
                  (value) => Text(
                    valueFormatter(value),
                    style: TextStyle(
                      fontSize: theme.fontSize,
                      color: theme.labelColor,
                      fontWeight: value == values[currentValueIndex]
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  /// Creates a font size slider with 4 discrete values
  Widget _buildFontSizeSlider({
    required ThemeProvider theme,
    required void Function(double) onChanged,
  }) {
    const List<double> fontSizeValues = [28.0, 32.0, 36.0, 40.0];
    return _buildDiscreteSlider<double>(
      theme: theme,
      label: 'Font Size',
      values: fontSizeValues,
      currentValue: theme.fontSize,
      onChanged: onChanged,
      valueFormatter: (value) => value.toInt().toString(),
    );
  }

  /// Creates a line height slider with 4 discrete values
  Widget _buildLineHeightSlider({
    required ThemeProvider theme,
    required void Function(double) onChanged,
  }) {
    const List<double> lineHeightValues = [1.0, 1.2, 1.5, 2.0];
    // Find the closest available value
    double closestValue = lineHeightValues.reduce((a, b) {
      return (theme.lineHeight - a).abs() < (theme.lineHeight - b).abs() ? a : b;
    });
    return _buildDiscreteSlider<double>(
      theme: theme,
      label: 'Line Height',
      values: lineHeightValues,
      currentValue: closestValue,
      onChanged: onChanged,
      valueFormatter: (value) => value.toString().replaceAll(RegExp(r'\.?0*$'), ''),
    );
  }

  /// Creates a speed slider with 4 discrete values
  Widget _buildSpeedSlider({
    required ThemeProvider theme,
    required int currentValue,
    required void Function(int) onChanged,
  }) {
    const List<int> speedValues = [0, 2, 4, 6];
    // Find the closest available value
    int closestValue = speedValues.reduce((a, b) {
      return (currentValue - a).abs() < (currentValue - b).abs() ? a : b;
    });
    return _buildDiscreteSlider<int>(
      theme: theme,
      label: 'Speed',
      values: speedValues,
      currentValue: closestValue,
      onChanged: onChanged,
      valueFormatter: (value) => value.toString(),
    );
  }

  /// Creates a pitch slider with 4 discrete values
  Widget _buildPitchSlider({
    required ThemeProvider theme,
    required int currentValue,
    required void Function(int) onChanged,
  }) {
    const List<int> pitchValues = [0, 2, 4, 6];
    // Find the closest available value
    int closestValue = pitchValues.reduce((a, b) {
      return (currentValue - a).abs() < (currentValue - b).abs() ? a : b;
    });
    return _buildDiscreteSlider<int>(
      theme: theme,
      label: 'Pitch',
      values: pitchValues,
      currentValue: closestValue,
      onChanged: onChanged,
      valueFormatter: (value) => value.toString(),
    );
  }

  /// Shows text format settings
  void _showTextFormatSettings(BuildContext context, ThemeProvider theme) {
    bool localUseSystemFontSize = useSystemFontSize;
    _showBottomSheet(
      context: context,
      theme: theme,
      content: [
        // Use Consumer to rebuild both sliders when theme changes
        Consumer<ThemeProvider>(
          builder: (context, theme, _) => StatefulBuilder(
            builder: (context, setModalState) => Column(
              children: [
                // System Font Size Toggle
                Toggle(
                  label: 'Use System Font Size',
                  value: localUseSystemFontSize,
                  onChanged: (val) {
                    setModalState(() => localUseSystemFontSize = val);
                    if (val) {
                      // If using system font size, update from system
                      final systemPrefs = SystemPreferencesService.instance.getInitialPreferences(context);
                      theme.setSystemFontSize(systemPrefs['fontSize']);
                    }
                  },
                  fontSize: theme.fontSize,
                  labelColor: theme.labelColor,
                  labelFontWeight: FontWeight.bold,
                ),
                const SizedBox(height: AppConstants.defaultPadding),

                // Font Size Control (only shown if not using system font size)
                if (!localUseSystemFontSize)
                  _buildFontSizeSlider(
                    theme: theme,
                    onChanged: (value) {
                      theme.setFontSize(value);
                      setModalState(() {});
                    },
                  ),
                const SizedBox(height: 25),

                // Line Height Control
                _buildLineHeightSlider(
                  theme: theme,
                  onChanged: (value) {
                    theme.setLineHeight(value);
                    setModalState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Shows speech settings
  void _showSpeechSettings(BuildContext context, ThemeProvider theme) {
    _showBottomSheet(
      context: context,
      theme: theme,
      content: [
        // Speed Control
        StatefulBuilder(
          builder: (context, setModalState) => _buildSpeedSlider(
            theme: theme,
            currentValue: speed,
            onChanged: (value) => setModalState(() {
              setState(() => speed = value);
            }),
          ),
        ),
        const SizedBox(height: 25),

        // Pitch Control
        StatefulBuilder(
          builder: (context, setModalState) => _buildPitchSlider(
            theme: theme,
            currentValue: pitch,
            onChanged: (value) => setModalState(() {
              setState(() => pitch = value);
            }),
          ),
        ),
      ],
    );
  }

  /// Creates a clickable setting section with an arrow
  Widget _buildSettingSection({
    required String title,
    required VoidCallback onTap,
    required ThemeProvider theme,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: theme.fontSize,
                  fontWeight: FontWeight.bold,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 32, color: theme.primaryColor),
          ],
        ),
      ),
    );
  }

  /// Creates a section header or divider
  Widget _buildSectionHeader(String title, ThemeProvider theme) => Text(
    title,
    style: TextStyle(fontSize: theme.fontSize, fontWeight: FontWeight.bold),
    softWrap: true,
    overflow: TextOverflow.visible,
  );

  /// Creates a section divider
  Widget _buildDivider(ThemeProvider theme) => Column(
    children: [
      const SizedBox(height: AppConstants.largePadding),
      Divider(color: theme.dividerColor, thickness: 10),
      const SizedBox(height: AppConstants.largePadding),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Preferences', showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height - kToolbarHeight - 80,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Screen Reader Section
                  _buildSectionHeader('Screen Reader', theme),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Toggle(
                    label: 'Use System Settings',
                    value: useSystemAccessibility,
                    onChanged: (val) async {
                      setState(() => useSystemAccessibility = val);
                      if (val) {
                        // If using system settings, update from system
                        final systemPrefs = SystemPreferencesService.instance.getInitialPreferences(context);
                        setState(() => screenReaderEnabled = systemPrefs['screenReaderEnabled']);
                      }
                    },
                    fontSize: theme.fontSize,
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  if (!useSystemAccessibility) Toggle(
                    label: 'Enable',
                    value: screenReaderEnabled,
                    onChanged: (val) => setState(() => screenReaderEnabled = val),
                    fontSize: theme.fontSize,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // Speech Settings Link
                  InkWell(
                    onTap: () => _showSpeechSettings(context, theme),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Speech Settings",
                              style: TextStyle(fontSize: theme.fontSize),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 32,
                            color: theme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  _buildDivider(theme),

                  // Theme Section
                  _buildSectionHeader('Theme', theme),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Toggle(
                    label: 'Use System Theme',
                    value: useSystemTheme,
                    onChanged: (val) async {
                      setState(() => useSystemTheme = val);
                      if (val) {
                        // If using system theme, update from system
                        final systemPrefs = SystemPreferencesService.instance.getInitialPreferences(context);
                        theme.setDarkMode(systemPrefs['isDarkMode']);
                      }
                    },
                    fontSize: theme.fontSize,
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  if (!useSystemTheme) Toggle(
                    label: theme.isDarkMode ? 'Dark Mode' : 'Light Mode',
                    value: theme.isDarkMode,
                    onChanged: (val) => theme.toggleTheme(),
                    fontSize: theme.fontSize,
                  ),

                  _buildDivider(theme),

                  // Text Format Section
                  _buildSettingSection(
                    title: 'Text Format',
                    onTap: () => _showTextFormatSettings(context, theme),
                    theme: theme,
                  ),

                  _buildDivider(theme),

                  // Haptic Feedback Section
                  _buildSectionHeader('Haptic Feedback', theme),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Toggle(
                    label: 'Enable',
                    value: vibrationEnabled,
                    onChanged: _toggleVibration,
                    fontSize: theme.fontSize,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
