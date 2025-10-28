import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/theme_provider.dart';
import '../core/services/vibration_service.dart';
import '../core/services/screen_reader_service.dart';
import 'screen_reader_gesture_detector.dart';
import 'screen_reader_focusable.dart';

/// Bottom sheet methods for feature settings (text format and text-to-speech only)
class FeatureBottomSheets {
  /// Shows text format settings (font size and line height)
  static void showTextFormatSettings({
    required BuildContext context,
    required ThemeProvider theme,
  }) {
    VibrationService.mediumFeedback();
    // Activate text format sheet context for screen reader
    ScreenReaderService().setActiveContext('text_format_settings');

    showModalBottomSheet(
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
              child: ScreenReaderGestureDetector(
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
                        child: ScreenReaderFocusable(
                          context: 'text_format_settings',
                          label: 'Close button',
                          hint: 'Double tap to close text format settings',
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
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows text to speech settings (speed only)
  static void showTextToSpeechSettings({
    required BuildContext context,
    required ThemeProvider theme,
    required double ttsSpeed,
    required Function(double) onSpeedChanged,
  }) {
    double currentSpeed = ttsSpeed;

    VibrationService.mediumFeedback();
    // Activate text-to-speech sheet context for screen reader
    ScreenReaderService().setActiveContext('text_to_speech_settings');

    showModalBottomSheet(
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
                          child: ScreenReaderFocusable(
                            context: 'text_to_speech_settings',
                            label: 'Close button',
                            hint: 'Double tap to close text to speech settings',
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
                        const SizedBox(height: 10),
                        // Speed Control
                        _buildSpeechSpeedButtons(
                          theme: themeProvider,
                          currentSpeed: currentSpeed,
                          onChanged: (value) {
                            setModalState(() {
                              currentSpeed = value;
                            });
                            onSpeedChanged(value);
                          },
                        ),
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
        ScreenReaderFocusable(
          context: 'text_format_settings',
          label: 'Font size, ${theme.fontSize.toInt()}',
          hint: 'Current font size',
          child: Row(
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
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScreenReaderFocusable(
              context: 'text_format_settings',
              label: 'Reduce font size',
              hint: canDecrease 
                  ? 'Double tap to reduce font size to ${fontSizeValues[currentIndex - 1].toInt()}'
                  : 'Font size is already at minimum',
              onTap: canDecrease
                  ? () {
                      onChanged(fontSizeValues[currentIndex - 1]);
                      VibrationService.mediumFeedback();
                    }
                  : null,
              child: ElevatedButton(
                onPressed: canDecrease
                    ? () {
                        onChanged(fontSizeValues[currentIndex - 1]);
                        VibrationService.mediumFeedback();
                      }
                    : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.labelColor,
                foregroundColor: theme.primaryColor,
                disabledBackgroundColor: theme.labelColor.withOpacity(0.5),
                disabledForegroundColor: theme.primaryColor.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
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
            ),
            const SizedBox(width: 20),
            ScreenReaderFocusable(
              context: 'text_format_settings',
              label: 'Increase font size',
              hint: canIncrease
                  ? 'Double tap to increase font size to ${fontSizeValues[currentIndex + 1].toInt()}'
                  : 'Font size is already at maximum',
              onTap: canIncrease
                  ? () {
                      onChanged(fontSizeValues[currentIndex + 1]);
                      VibrationService.mediumFeedback();
                    }
                  : null,
              child: ElevatedButton(
                onPressed: canIncrease
                    ? () {
                        onChanged(fontSizeValues[currentIndex + 1]);
                        VibrationService.mediumFeedback();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.labelColor,
                  foregroundColor: theme.primaryColor,
                  disabledBackgroundColor: theme.labelColor.withOpacity(0.5),
                  disabledForegroundColor: theme.primaryColor.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
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
      return (theme.lineHeight - a).abs() < (theme.lineHeight - b).abs() ? a : b;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenReaderFocusable(
          context: 'text_format_settings',
          label: 'Line height, $closestValue',
          hint: 'Current line height',
          child: Row(
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
              closestValue.toString().replaceAll(RegExp(r'\.?0* $'), ''),
              style: TextStyle(
                fontSize: theme.fontSize + 4,
                color: theme.labelColor,
                fontWeight: FontWeight.bold,
                shadows: _getTextShadows(theme),
              ),
            ),
          ],
        ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: lineHeightValues.map((val) {
            final bool isSelected = val == closestValue;
            final double gap = (val - 1.0) * 4 + 2;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ScreenReaderFocusable(
                  context: 'text_format_settings',
                  label: isSelected ? 'Line height $val, selected' : 'Line height $val',
                  hint: 'Double tap to set line height to $val',
                  onTap: () {
                    onChanged(val);
                    VibrationService.mediumFeedback();
                  },
                  child: ElevatedButton(
                  onPressed: () {
                    onChanged(val);
                    VibrationService.mediumFeedback();
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
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Helper method to build speech speed control buttons
  static Widget _buildSpeechSpeedButtons({
    required ThemeProvider theme,
    required double currentSpeed,
    required void Function(double) onChanged,
  }) {
    const List<double> speedValues = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final currentIndex = speedValues.indexWhere((v) => (v - currentSpeed).abs() < 0.01);
    final canDecrease = currentIndex > 0;
    final canIncrease = currentIndex < speedValues.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenReaderFocusable(
          context: 'text_to_speech_settings',
          label: 'Speed, ${currentSpeed.toStringAsFixed(2)}',
          hint: 'Current speech speed',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Speed',
                style: TextStyle(
                  fontSize: theme.fontSize + 4,
                  color: theme.labelColor,
                  fontWeight: FontWeight.bold,
                  shadows: _getTextShadows(theme),
                ),
              ),
              Text(
                '${currentSpeed.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: theme.fontSize + 4,
                  color: theme.labelColor,
                  fontWeight: FontWeight.bold,
                  shadows: _getTextShadows(theme),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScreenReaderFocusable(
              context: 'text_to_speech_settings',
              label: 'Reduce speed',
              hint: canDecrease 
                  ? 'Double tap to reduce speed to ${speedValues[currentIndex - 1].toStringAsFixed(2)}'
                  : 'Speed is already at minimum',
              onTap: canDecrease
                  ? () {
                      onChanged(speedValues[currentIndex - 1]);
                      VibrationService.mediumFeedback();
                    }
                  : null,
              child: ElevatedButton(
                onPressed: canDecrease
                    ? () {
                        onChanged(speedValues[currentIndex - 1]);
                        VibrationService.mediumFeedback();
                      }
                    : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.labelColor,
                foregroundColor: theme.primaryColor,
                disabledBackgroundColor: theme.labelColor.withOpacity(0.5),
                disabledForegroundColor: theme.primaryColor.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Icon(Icons.remove, size: theme.fontSize + 6),
            ),
            ),
            const SizedBox(width: 20),
            ScreenReaderFocusable(
              context: 'text_to_speech_settings',
              label: 'Increase speed',
              hint: canIncrease
                  ? 'Double tap to increase speed to ${speedValues[currentIndex + 1].toStringAsFixed(2)}'
                  : 'Speed is already at maximum',
              onTap: canIncrease
                  ? () {
                      onChanged(speedValues[currentIndex + 1]);
                      VibrationService.mediumFeedback();
                    }
                  : null,
              child: ElevatedButton(
                onPressed: canIncrease
                    ? () {
                        onChanged(speedValues[currentIndex + 1]);
                        VibrationService.mediumFeedback();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.labelColor,
                  foregroundColor: theme.primaryColor,
                  disabledBackgroundColor: theme.labelColor.withOpacity(0.5),
                  disabledForegroundColor: theme.primaryColor.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Icon(Icons.add, size: theme.fontSize + 6),
              ),
            ),
          ],
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
