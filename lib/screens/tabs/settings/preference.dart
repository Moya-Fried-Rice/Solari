import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/vibration_service.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/toggle.dart';

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
  bool screenReaderEnabled = false;
  bool vibrationEnabled = true; // Default to enabled

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() async {
    final isVibrationEnabled = await VibrationService.isVibrationEnabled();

    if (mounted) {
      setState(() {
        vibrationEnabled = isVibrationEnabled;
        screenReaderEnabled = false; // Default value
        useSystemTheme = true; // Default value
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

  /// Shows a bottom sheet with custom content
  void _showBottomSheet({
    required BuildContext context,
    required ThemeProvider themeProvider,
    required List<Widget> content,
  }) {
    VibrationService.mediumFeedback();
    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.primaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: themeProvider.labelColor,
                displayColor: themeProvider.labelColor,
              ),
        ),
        child: StatefulBuilder(
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
                        color: themeProvider.unselectedColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Content widgets
                  ...content,

                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          VibrationService.mediumFeedback();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.labelColor,
                          foregroundColor: themeProvider.primaryColor,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Done',
                          style: TextStyle(
                            fontSize: themeProvider.fontSize + 4,
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
      ),
    );
  }

  /// Creates a font size slider with 4 discrete values
  Widget _buildFontSizeSlider({
    required ThemeProvider theme,
    required void Function(double) onChanged,
  }) {
    const List<double> fontSizeValues = [28.0, 32.0, 36.0, 40.0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Font Size',
              style: TextStyle(
                fontSize: theme.fontSize + 4,
                color: theme.labelColor,
              ),
            ),
            Text(
              theme.fontSize.toInt().toString(),
              style: TextStyle(
                fontSize: theme.fontSize + 4,
                color: theme.labelColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
          ),
          child: Slider(
            value: theme.fontSize,
            min: fontSizeValues.first,
            max: fontSizeValues.last,
            divisions: fontSizeValues.length - 1,
            onChanged: (value) {
              onChanged(value);
              VibrationService.lightFeedback();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: fontSizeValues.map((val) {
              final bool isCurrentValue = val == theme.fontSize;
              return Semantics(
                label: '${val.toInt()}, double tap to select',
                button: true,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () {
                    onChanged(val);
                    VibrationService.lightFeedback();
                  },
                  // ...existing code...
                  child: Text(
                    val.toInt().toString(),
                    style: TextStyle(
                      fontSize: theme.fontSize,
                      fontWeight: isCurrentValue ? FontWeight.bold : FontWeight.normal,
                      color: theme.labelColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Creates a line height slider with 4 discrete values
  Widget _buildLineHeightSlider({
    required ThemeProvider theme,
    required void Function(double) onChanged,
  }) {
    const List<double> lineHeightValues = [1.0, 1.2, 1.5, 2.0];
    double closestValue = lineHeightValues.reduce((a, b) {
      return (theme.lineHeight - a).abs() < (theme.lineHeight - b).abs()
          ? a
          : b;
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Line Height',
              style: TextStyle(
                fontSize: theme.fontSize + 4,
                color: theme.labelColor,
              ),
            ),
            Text(
              closestValue.toString().replaceAll(RegExp(r'\.?0*$'), ''),
              style: TextStyle(
                fontSize: theme.fontSize + 4,
                color: theme.labelColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
          ),
          child: Slider(
            value: closestValue,
            min: lineHeightValues.first,
            max: lineHeightValues.last,
            divisions: lineHeightValues.length - 1,
            onChanged: (value) {
              onChanged(value);
              VibrationService.lightFeedback();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: lineHeightValues.map((val) {
              final bool isCurrentValue = val == theme.lineHeight;
              return Semantics(
                label: '${val.toStringAsFixed(1)}, double tap to select',
                button: true,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () {
                    onChanged(val);
                    VibrationService.lightFeedback();
                  },
                  child: Text(
                    val.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: theme.fontSize,
                      fontWeight: isCurrentValue ? FontWeight.bold : FontWeight.normal,
                      color: theme.labelColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Shows text format settings
  void _showTextFormatSettings(BuildContext context, ThemeProvider theme) {
    _showBottomSheet(
      context: context,
      themeProvider: theme,
      content: [
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) => DefaultTextStyle(
            style: TextStyle(
              color: themeProvider.labelColor,
              fontSize: themeProvider.fontSize + 4,
            ),
            child: Column(
              children: [
                StatefulBuilder(
                  builder: (context, setModalState) => _buildFontSizeSlider(
                    theme: themeProvider,
                    onChanged: (value) {
                      themeProvider.setFontSize(value);
                      setModalState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 25),
                StatefulBuilder(
                  builder: (context, setModalState) => _buildLineHeightSlider(
                    theme: themeProvider,
                    onChanged: (value) {
                      themeProvider.setLineHeight(value);
                      setModalState(() {});
                    },
                  ),
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
      themeProvider: theme,
      content: [
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) => DefaultTextStyle(
            style: TextStyle(
              color: themeProvider.labelColor,
              fontSize: themeProvider.fontSize + 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  child: Text(
                    'Speed',
                    style: TextStyle(
                      fontSize: themeProvider.fontSize + 8,
                      color: themeProvider.labelColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Semantics(
                  child: Text(
                    'Pitch',
                    style: TextStyle(
                      fontSize: themeProvider.fontSize + 8,
                      color: themeProvider.labelColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
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
                  fontSize: theme.fontSize + 8,
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

  Widget _buildSectionHeader(String title, ThemeProvider theme) => Text(
        title,
        style: TextStyle(
          fontSize: theme.fontSize + 8,
          fontWeight: FontWeight.bold,
        ),
        softWrap: true,
        overflow: TextOverflow.visible,
      );

  Widget _buildDivider(ThemeProvider theme) => Column(
        children: [
          const SizedBox(height: AppConstants.largePadding),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
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
                  Semantics(header: true, child: _buildSectionHeader('Screen Reader', theme)),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Toggle(
                    label: 'Enable',
                    value: screenReaderEnabled,
                    onChanged: (val) =>
                        setState(() => screenReaderEnabled = val),
                    fontSize: theme.fontSize + 4,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Focus(
                    child: InkWell(
                      onTap: () => _showSpeechSettings(context, theme),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Speech Settings",
                                style: TextStyle(
                                  fontSize: theme.fontSize + 4,
                                ),
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
                  ),
                  _buildDivider(theme),
                  Semantics(header: true, child: _buildSectionHeader('Theme', theme)),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Toggle(
                    label: theme.isDarkMode ? 'Dark Mode' : 'Light Mode',
                    value: theme.isDarkMode,
                    onChanged: (val) {
                      theme.toggleTheme();
                      setState(() => useSystemTheme = false);
                    },
                    fontSize: theme.fontSize + 4,
                  ),
                  _buildDivider(theme),
                  Semantics(header: true, child: _buildSettingSection(
                    title: 'Text Format',
                    onTap: () => _showTextFormatSettings(context, theme),
                    theme: theme,
                  )),
                  _buildDivider(theme),
                  Semantics(header: true, child: _buildSectionHeader('Haptic Feedback', theme)),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Toggle(
                    label: 'Enable',
                    value: vibrationEnabled,
                    onChanged: _toggleVibration,
                    fontSize: theme.fontSize + 4,
                  ),
                  _buildDivider(theme),
                  Semantics(header: true, child: _buildSectionHeader('System Sync', theme)),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Toggle(
                    label: 'Theme',
                    value: useSystemTheme,
                    onChanged: (val) {
                      setState(() => useSystemTheme = val);
                      theme.setUseSystemTheme(val);
                    },
                    fontSize: theme.fontSize + 4,
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
