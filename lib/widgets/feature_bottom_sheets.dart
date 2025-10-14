import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/theme_provider.dart';
import '../core/services/vibration_service.dart';
import 'toggle.dart';

/// Bottom sheet methods for feature settings (preferences, accessibility, etc.)
class FeatureBottomSheets {
  /// Shows screen reader settings
  static void showScreenReaderSettings({
    required BuildContext context,
    required ThemeProvider theme,
    required bool value,
    required Function(bool) onChanged,
  }) {
    bool currentValue = value;
    VibrationService.mediumFeedback();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => Container(
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
              builder: (context, setModalState) => Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 10,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Down arrow button at top center
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          VibrationService.mediumFeedback();
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
                    const SizedBox(height: 10),
                    Toggle(
                      label: 'Enable Screen Reader',
                      value: currentValue,
                      onChanged: (val) {
                        setModalState(() {
                          currentValue = val;
                        });
                        onChanged(val);
                      },
                      fontSize: themeProvider.fontSize + 4,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows select to speak settings
  static void showSelectToSpeakSettings({
    required BuildContext context,
    required ThemeProvider theme,
    required bool value,
    required Function(bool) onChanged,
  }) {
    bool currentValue = value;
    VibrationService.mediumFeedback();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => Container(
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
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 10,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () {
                      VibrationService.mediumFeedback();
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
                const SizedBox(height: 10),
                Toggle(
                  label: 'Enable Select to Speak',
                  value: currentValue,
                  onChanged: (val) {
                    setModalState(() {
                      currentValue = val;
                    });
                    onChanged(val);
                  },
                  fontSize: themeProvider.fontSize + 4,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows magnification settings
  static void showMagnificationSettings({
    required BuildContext context,
    required ThemeProvider theme,
    required bool value,
    required Function(bool) onChanged,
  }) {
    bool currentValue = value;
    VibrationService.mediumFeedback();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => Container(
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
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 10,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () {
                      VibrationService.mediumFeedback();
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
                const SizedBox(height: 10),
                Toggle(
                  label: 'Enable Magnification',
                  value: currentValue,
                  onChanged: (val) {
                    setModalState(() {
                      currentValue = val;
                    });
                    onChanged(val);
                  },
                  fontSize: themeProvider.fontSize + 4,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows theme settings
  static void showThemeSettings({
    required BuildContext context,
    required ThemeProvider theme,
    required VoidCallback onToggleTheme,
  }) {
    VibrationService.mediumFeedback();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => Container(
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
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 10,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () {
                      VibrationService.mediumFeedback();
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
                const SizedBox(height: 10),
                Toggle(
                  label: themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
                  value: themeProvider.isDarkMode,
                  onChanged: (val) {
                    setModalState(() {});
                    onToggleTheme();
                  },
                  fontSize: themeProvider.fontSize + 4,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows color inversion settings
  static void showColorInversionSettings({
    required BuildContext context,
    required ThemeProvider theme,
    required bool value,
    required Function(bool) onChanged,
  }) {
    bool currentValue = value;
    VibrationService.mediumFeedback();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => Container(
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
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 10,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () {
                      VibrationService.mediumFeedback();
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
                const SizedBox(height: 10),
                Toggle(
                  label: 'Enable Color Inversion',
                  value: currentValue,
                  onChanged: (val) {
                    setModalState(() {
                      currentValue = val;
                    });
                    onChanged(val);
                  },
                  fontSize: themeProvider.fontSize + 4,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows high contrast settings
  static void showHighContrastSettings({
    required BuildContext context,
    required ThemeProvider theme,
    required VoidCallback onToggleHighContrast,
  }) {
    VibrationService.mediumFeedback();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => Container(
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
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 10,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () {
                      VibrationService.mediumFeedback();
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
                const SizedBox(height: 10),
                Toggle(
                  label: 'Enable High Contrast',
                  value: themeProvider.isHighContrast,
                  onChanged: (val) {
                    setModalState(() {});
                    onToggleHighContrast();
                  },
                  fontSize: themeProvider.fontSize + 4,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows audio description settings
  static void showAudioDescriptionSettings({
    required BuildContext context,
    required ThemeProvider theme,
    required bool value,
    required Function(bool) onChanged,
  }) {
    bool currentValue = value;
    VibrationService.mediumFeedback();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => Container(
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
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 10,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () {
                      VibrationService.mediumFeedback();
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
                const SizedBox(height: 10),
                Toggle(
                  label: 'Enable Audio Description',
                  value: currentValue,
                  onChanged: (val) {
                    setModalState(() {
                      currentValue = val;
                    });
                    onChanged(val);
                  },
                  fontSize: themeProvider.fontSize + 4,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows vibration settings
  static void showVibrationSettings({
    required BuildContext context,
    required ThemeProvider theme,
    required bool value,
    required Future<void> Function(bool) onChanged,
  }) {
    bool currentValue = value;
    VibrationService.mediumFeedback();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => Container(
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
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 10,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () {
                      VibrationService.mediumFeedback();
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
                const SizedBox(height: 10),
                Toggle(
                  label: 'Enable Vibration',
                  value: currentValue,
                  onChanged: (val) async {
                    setModalState(() {
                      currentValue = val;
                    });
                    await onChanged(val);
                  },
                  fontSize: themeProvider.fontSize + 4,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows sync settings
  static void showSyncSettings({
    required BuildContext context,
    required ThemeProvider theme,
    required bool value,
    required Function(bool) onChanged,
  }) {
    bool currentValue = value;
    VibrationService.mediumFeedback();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => Container(
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
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 10,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () {
                      VibrationService.mediumFeedback();
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
                const SizedBox(height: 10),
                Toggle(
                  label: 'Enable Sync',
                  value: currentValue,
                  onChanged: (val) {
                    setModalState(() {
                      currentValue = val;
                    });
                    onChanged(val);
                  },
                  fontSize: themeProvider.fontSize + 4,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows text format settings (font size and line height)
  static void showTextFormatSettings({
    required BuildContext context,
    required ThemeProvider theme,
  }) {
    VibrationService.mediumFeedback();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => Container(
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
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 10,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Down arrow button at top center
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        VibrationService.mediumFeedback();
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
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      _buildFontSizeButtons(
                        theme: themeProvider,
                        onChanged: (value) {
                          themeProvider.setFontSize(value);
                        },
                      ),
                      const SizedBox(height: 30),
                      _buildLineHeightButtons(
                        theme: themeProvider,
                        onChanged: (value) {
                          themeProvider.setLineHeight(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows text to speech settings (speed and pitch)
  static void showTextToSpeechSettings({
    required BuildContext context,
    required ThemeProvider theme,
    required double ttsSpeed,
    required double ttsPitch,
    required Function(double) onSpeedChanged,
    required Function(double) onPitchChanged,
  }) {
    VibrationService.mediumFeedback();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => Container(
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
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 10,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Down arrow button at top center
                Center(
                  child: GestureDetector(
                    onTap: () {
                      VibrationService.mediumFeedback();
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
                const SizedBox(height: 10),
                // Speed Control
                Text(
                  'Speed',
                  style: TextStyle(
                    fontSize: themeProvider.fontSize + 8,
                    color: themeProvider.labelColor,
                    fontWeight: FontWeight.bold,
                    shadows: _getTextShadows(themeProvider),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0.5x',
                      style: TextStyle(
                        fontSize: themeProvider.fontSize,
                        color: themeProvider.labelColor,
                        shadows: _getTextShadows(themeProvider),
                      ),
                    ),
                    Text(
                      '${ttsSpeed.toStringAsFixed(1)}x',
                      style: TextStyle(
                        fontSize: themeProvider.fontSize + 2,
                        color: themeProvider.labelColor,
                        fontWeight: FontWeight.bold,
                        shadows: _getTextShadows(themeProvider),
                      ),
                    ),
                    Text(
                      '2.0x',
                      style: TextStyle(
                        fontSize: themeProvider.fontSize,
                        color: themeProvider.labelColor,
                        shadows: _getTextShadows(themeProvider),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: themeProvider.labelColor,
                    inactiveTrackColor: themeProvider.unselectedColor,
                    thumbColor: themeProvider.labelColor,
                    trackHeight: 8,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                  ),
                  child: Slider(
                    value: ttsSpeed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    onChanged: (value) {
                      setModalState(() {
                        onSpeedChanged(value);
                      });
                      VibrationService.lightFeedback();
                    },
                  ),
                ),
                const SizedBox(height: 30),
                
                // Pitch Control
                Text(
                  'Pitch',
                  style: TextStyle(
                    fontSize: themeProvider.fontSize + 8,
                    color: themeProvider.labelColor,
                    fontWeight: FontWeight.bold,
                    shadows: _getTextShadows(themeProvider),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0.5x',
                      style: TextStyle(
                        fontSize: themeProvider.fontSize,
                        color: themeProvider.labelColor,
                        shadows: _getTextShadows(themeProvider),
                      ),
                    ),
                    Text(
                      '${ttsPitch.toStringAsFixed(1)}x',
                      style: TextStyle(
                        fontSize: themeProvider.fontSize + 2,
                        color: themeProvider.labelColor,
                        fontWeight: FontWeight.bold,
                        shadows: _getTextShadows(themeProvider),
                      ),
                    ),
                    Text(
                      '2.0x',
                      style: TextStyle(
                        fontSize: themeProvider.fontSize,
                        color: themeProvider.labelColor,
                        shadows: _getTextShadows(themeProvider),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: themeProvider.labelColor,
                    inactiveTrackColor: themeProvider.unselectedColor,
                    thumbColor: themeProvider.labelColor,
                    trackHeight: 8,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                  ),
                  child: Slider(
                    value: ttsPitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    onChanged: (value) {
                      setModalState(() {
                        onPitchChanged(value);
                      });
                      VibrationService.lightFeedback();
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method to build font size control buttons
  static Widget _buildFontSizeButtons({
    required ThemeProvider theme,
    required void Function(double) onChanged,
  }) {
    const List<double> fontSizeValues = [28.0, 32.0, 36.0, 40.0];
    final currentIndex = fontSizeValues.indexOf(theme.fontSize);
    final canDecrease = currentIndex > 0;
    final canIncrease = currentIndex < fontSizeValues.length - 1;
    
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
                shadows: _getTextShadows(theme),
              ),
            ),
            Text(
              theme.fontSize.toInt().toString(),
              style: TextStyle(
                fontSize: theme.fontSize + 4,
                color: theme.labelColor,
                fontWeight: FontWeight.bold,
                shadows: _getTextShadows(theme),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // A- button (decrease)
            ElevatedButton(
              onPressed: canDecrease
                  ? () {
                      onChanged(fontSizeValues[currentIndex - 1]);
                      VibrationService.lightFeedback();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.labelColor,
                foregroundColor: theme.primaryColor,
                disabledBackgroundColor: theme.labelColor.withOpacity(0.5),
                disabledForegroundColor: theme.primaryColor.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'A-',
                style: TextStyle(
                  fontSize: theme.fontSize + 6,
                  fontWeight: FontWeight.bold,
                  shadows: _getTextShadows(theme),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // A+ button (increase)
            ElevatedButton(
              onPressed: canIncrease
                  ? () {
                      onChanged(fontSizeValues[currentIndex + 1]);
                      VibrationService.lightFeedback();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.labelColor,
                foregroundColor: theme.primaryColor,
                disabledBackgroundColor: theme.labelColor.withOpacity(0.5),
                disabledForegroundColor: theme.primaryColor.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'A+',
                style: TextStyle(
                  fontSize: theme.fontSize + 8,
                  fontWeight: FontWeight.bold,
                  shadows: _getTextShadows(theme),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Helper method to build line height control buttons
  static Widget _buildLineHeightButtons({
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
                shadows: _getTextShadows(theme),
              ),
            ),
            Text(
              closestValue.toString().replaceAll(RegExp(r'\.?0*$'), ''),
              style: TextStyle(
                fontSize: theme.fontSize + 4,
                color: theme.labelColor,
                fontWeight: FontWeight.bold,
                shadows: _getTextShadows(theme),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: lineHeightValues.map((val) {
            final bool isSelected = val == closestValue;
            // Calculate gap based on line height value
            final double gap = (val - 1.0) * 4 + 2; // 2px to 6px gap
            
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ElevatedButton(
                  onPressed: () {
                    onChanged(val);
                    VibrationService.lightFeedback();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? theme.labelColor : theme.unselectedColor,
                    foregroundColor: isSelected ? theme.primaryColor : theme.labelColor,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Three horizontal lines with varying gaps
                      Container(
                        height: 3,
                        width: 24,
                        decoration: BoxDecoration(
                          color: isSelected ? theme.primaryColor : theme.labelColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: gap),
                      Container(
                        height: 3,
                        width: 24,
                        decoration: BoxDecoration(
                          color: isSelected ? theme.primaryColor : theme.labelColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: gap),
                      Container(
                        height: 3,
                        width: 24,
                        decoration: BoxDecoration(
                          color: isSelected ? theme.primaryColor : theme.labelColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Helper method to get text shadows for high contrast mode
  static List<Shadow>? _getTextShadows(ThemeProvider theme) {
    if (!theme.isHighContrast) return null;

    final Color shadowColor = theme.isDarkMode ? Colors.black : Colors.white;
    return [
      Shadow(offset: const Offset(0, -1), blurRadius: 3.0, color: shadowColor),
      Shadow(offset: const Offset(0, 1), blurRadius: 3.0, color: shadowColor),
      Shadow(offset: const Offset(-1, 0), blurRadius: 3.0, color: shadowColor),
      Shadow(offset: const Offset(1, 0), blurRadius: 3.0, color: shadowColor),
    ];
  }
}






