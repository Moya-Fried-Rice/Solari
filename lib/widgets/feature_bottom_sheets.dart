import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/theme_provider.dart';
import '../core/services/vibration_service.dart';
import '../core/services/screen_reader_service.dart';
import 'toggle.dart';
import 'select_to_speak_text.dart';
import 'screen_reader_gesture_detector.dart';
import 'screen_reader_focusable.dart';

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

    // Set screen reader context to this bottom sheet
    ScreenReaderService().setActiveContext('screen_reader_settings');

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
            // Restore preferences context when bottom sheet closes
            ScreenReaderService().setActiveContext('preferences');
            return true;
          },
          child: Container(
            decoration: BoxDecoration(
              color: themeProvider.primaryColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                textTheme: Theme.of(context).textTheme.apply(
                  bodyColor: themeProvider.labelColor,
                  displayColor: themeProvider.labelColor,
                ),
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) =>
                    ScreenReaderGestureDetector(
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
                            context: 'screen_reader_settings',
                            label: 'Close button',
                            hint: 'Double tap to close settings',
                            onTap: () {
                              VibrationService.mediumFeedback();
                              ScreenReaderService().setActiveContext(
                                'preferences',
                              );
                              Navigator.pop(context);
                            },
                            child: GestureDetector(
                              onTap: () {
                                VibrationService.mediumFeedback();
                                ScreenReaderService().setActiveContext(
                                  'preferences',
                                );
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
                        ScreenReaderFocusable(
                          context: 'screen_reader_settings',
                          label: currentValue
                              ? 'Disable Screen Reader toggle'
                              : 'Enable Screen Reader toggle',
                          hint: 'Double tap to toggle screen reader',
                          onTap: () {
                            setModalState(() {
                              currentValue = !currentValue;
                            });
                            onChanged(!currentValue);
                          },
                          child: Toggle(
                            label: currentValue
                                ? 'Disable Screen Reader'
                                : 'Enable Screen Reader',
                            value: currentValue,
                            onChanged: (val) {
                              setModalState(() {
                                currentValue = val;
                              });
                              onChanged(val);
                            },
                            fontSize: themeProvider.fontSize + 4,
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
    ScreenReaderService().setActiveContext('select_to_speak_settings');

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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                textTheme: Theme.of(context).textTheme.apply(
                  bodyColor: themeProvider.labelColor,
                  displayColor: themeProvider.labelColor,
                ),
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) =>
                    ScreenReaderGestureDetector(
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
                        Center(
                          child: ScreenReaderFocusable(
                            context: 'select_to_speak_settings',
                            label: 'Close button',
                            hint: 'Double tap to close settings',
                            onTap: () {
                              VibrationService.mediumFeedback();
                              ScreenReaderService().setActiveContext(
                                'preferences',
                              );
                              Navigator.pop(context);
                            },
                            child: GestureDetector(
                              onTap: () {
                                VibrationService.mediumFeedback();
                                ScreenReaderService().setActiveContext(
                                  'preferences',
                                );
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
                        ScreenReaderFocusable(
                          context: 'select_to_speak_settings',
                          label: currentValue
                              ? 'Disable Select to Speak toggle'
                              : 'Enable Select to Speak toggle',
                          hint: 'Double tap to toggle select to speak',
                          onTap: () {
                            setModalState(() {
                              currentValue = !currentValue;
                            });
                            onChanged(!currentValue);
                          },
                          child: Toggle(
                            label: currentValue
                                ? 'Disable Select to Speak'
                                : 'Enable Select to Speak',
                            value: currentValue,
                            onChanged: (val) {
                              setModalState(() {
                                currentValue = val;
                              });
                              onChanged(val);
                            },
                            fontSize: themeProvider.fontSize + 4,
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
    ScreenReaderService().setActiveContext('magnification_settings');

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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
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
                        Center(
                          child: ScreenReaderFocusable(
                            context: 'magnification_settings',
                            label: 'Close button',
                            hint: 'Double tap to close magnification settings',
                            onTap: () {
                              VibrationService.mediumFeedback();
                              ScreenReaderService().setActiveContext(
                                'preferences',
                              );
                              Navigator.pop(context);
                            },
                            child: GestureDetector(
                              onTap: () {
                                VibrationService.mediumFeedback();
                                ScreenReaderService().setActiveContext(
                                  'preferences',
                                );
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
                        ScreenReaderFocusable(
                          context: 'magnification_settings',
                          label: currentValue
                              ? 'Disable Magnification'
                              : 'Enable Magnification',
                          hint:
                              'Double tap to ${currentValue ? "disable" : "enable"} magnification',
                          onTap: () {
                            final newValue = !currentValue;
                            setModalState(() {
                              currentValue = newValue;
                            });
                            onChanged(newValue);
                          },
                          child: Toggle(
                            label: currentValue
                                ? 'Disable Magnification'
                                : 'Enable Magnification',
                            value: currentValue,
                            onChanged: (val) {
                              setModalState(() {
                                currentValue = val;
                              });
                              onChanged(val);
                            },
                            fontSize: themeProvider.fontSize + 4,
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
    ScreenReaderService().setActiveContext('theme_settings');

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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
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
                        Center(
                          child: ScreenReaderFocusable(
                            context: 'theme_settings',
                            label: 'Close button',
                            hint: 'Double tap to close theme settings',
                            onTap: () {
                              VibrationService.mediumFeedback();
                              ScreenReaderService().setActiveContext(
                                'preferences',
                              );
                              Navigator.pop(context);
                            },
                            child: GestureDetector(
                              onTap: () {
                                VibrationService.mediumFeedback();
                                ScreenReaderService().setActiveContext(
                                  'preferences',
                                );
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
                        ScreenReaderFocusable(
                          context: 'theme_settings',
                          label: themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
                          hint: 'Double tap to switch to ${themeProvider.isDarkMode ? "light" : "dark"} mode',
                          onTap: () {
                            setModalState(() {});
                            onToggleTheme();
                          },
                          child: Toggle(
                            label: themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
                            value: themeProvider.isDarkMode,
                            onChanged: (val) {
                              setModalState(() {});
                              onToggleTheme();
                            },
                            fontSize: themeProvider.fontSize + 4,
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
    ScreenReaderService().setActiveContext('color_inversion_settings');

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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
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
                        Center(
                          child: ScreenReaderFocusable(
                            context: 'color_inversion_settings',
                            label: 'Close button',
                            hint: 'Double tap to close color inversion settings',
                            onTap: () {
                              VibrationService.mediumFeedback();
                              ScreenReaderService().setActiveContext(
                                'preferences',
                              );
                              Navigator.pop(context);
                            },
                            child: GestureDetector(
                              onTap: () {
                                VibrationService.mediumFeedback();
                                ScreenReaderService().setActiveContext(
                                  'preferences',
                                );
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
                        ScreenReaderFocusable(
                          context: 'color_inversion_settings',
                          label: currentValue ? 'Disable Color Inversion' : 'Enable Color Inversion',
                          hint: 'Double tap to ${currentValue ? "disable" : "enable"} color inversion',
                          onTap: () {
                            final newValue = !currentValue;
                            setModalState(() {
                              currentValue = newValue;
                            });
                            onChanged(newValue);
                          },
                          child: Toggle(
                            label: currentValue ? 'Disable Color Inversion' : 'Enable Color Inversion',
                            value: currentValue,
                            onChanged: (val) {
                              setModalState(() {
                                currentValue = val;
                              });
                              onChanged(val);
                            },
                            fontSize: themeProvider.fontSize + 4,
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
    ScreenReaderService().setActiveContext('high_contrast_settings');

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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
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
                        Center(
                          child: ScreenReaderFocusable(
                            context: 'high_contrast_settings',
                            label: 'Close button',
                            hint: 'Double tap to close high contrast settings',
                            onTap: () {
                              VibrationService.mediumFeedback();
                              ScreenReaderService().setActiveContext(
                                'preferences',
                              );
                              Navigator.pop(context);
                            },
                            child: GestureDetector(
                              onTap: () {
                                VibrationService.mediumFeedback();
                                ScreenReaderService().setActiveContext(
                                  'preferences',
                                );
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
                        ScreenReaderFocusable(
                          context: 'high_contrast_settings',
                          label: themeProvider.isHighContrast ? 'Disable High Contrast' : 'Enable High Contrast',
                          hint: 'Double tap to ${themeProvider.isHighContrast ? "disable" : "enable"} high contrast',
                          onTap: () {
                            setModalState(() {});
                            onToggleHighContrast();
                          },
                          child: Toggle(
                            label: themeProvider.isHighContrast ? 'Disable High Contrast' : 'Enable High Contrast',
                            value: themeProvider.isHighContrast,
                            onChanged: (val) {
                              setModalState(() {});
                              onToggleHighContrast();
                            },
                            fontSize: themeProvider.fontSize + 4,
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
    // Activate vibration sheet context for screen reader
    ScreenReaderService().setActiveContext('vibration_settings');

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
            // Restore preferences context when bottom sheet closes
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
                        Center(
                          child: ScreenReaderFocusable(
                            context: 'vibration_settings',
                            label: 'Close button',
                            hint: 'Double tap to close vibration settings',
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
                        ScreenReaderFocusable(
                          context: 'vibration_settings',
                          label: currentValue ? 'Disable Vibration' : 'Enable Vibration',
                          hint: 'Double tap to ${currentValue ? "disable" : "enable"} vibration',
                          onTap: () async {
                            final newValue = !currentValue;
                            setModalState(() {
                              currentValue = newValue;
                            });
                            await onChanged(newValue);
                          },
                          child: Toggle(
                            label: currentValue ? 'Disable Vibration' : 'Enable Vibration',
                            value: currentValue,
                            onChanged: (val) async {
                              setModalState(() {
                                currentValue = val;
                              });
                              await onChanged(val);
                            },
                            fontSize: themeProvider.fontSize + 4,
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
    // Activate sync sheet context for screen reader
    ScreenReaderService().setActiveContext('sync_settings');

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
                        Center(
                          child: ScreenReaderFocusable(
                            context: 'sync_settings',
                            label: 'Close button',
                            hint: 'Double tap to close sync settings',
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
                        ScreenReaderFocusable(
                          context: 'sync_settings',
                          label: currentValue ? 'Disable Sync' : 'Enable Sync',
                          hint: 'Double tap to ${currentValue ? "disable" : "enable"} sync',
                          onTap: () {
                            final newValue = !currentValue;
                            setModalState(() {
                              currentValue = newValue;
                            });
                            onChanged(newValue);
                          },
                          child: Toggle(
                            label: currentValue ? 'Disable Sync' : 'Enable Sync',
                            value: currentValue,
                            onChanged: (val) {
                              setModalState(() {
                                currentValue = val;
                              });
                              onChanged(val);
                            },
                            fontSize: themeProvider.fontSize + 4,
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
                      ScreenReaderFocusable(
                        context: 'text_format_settings',
                        label: 'Font size control',
                        hint: 'Current font size is ${themeProvider.fontSize.toInt()}. Double tap to focus, then swipe to adjust',
                        child: Column(
                          children: [
                            _buildFontSizeButtons(
                              theme: themeProvider,
                              onChanged: (value) {
                                themeProvider.setFontSize(value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      ScreenReaderFocusable(
                        context: 'text_format_settings',
                        label: 'Line height control',
                        hint: 'Current line height is ${themeProvider.lineHeight}. Double tap to focus, then swipe to adjust',
                        child: Column(
                          children: [
                            _buildLineHeightButtons(
                              theme: themeProvider,
                              onChanged: (value) {
                                themeProvider.setLineHeight(value);
                              },
                            ),
                          ],
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
    double currentSpeed = ttsSpeed;
    double currentPitch = ttsPitch;

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
                        ScreenReaderFocusable(
                          context: 'text_to_speech_settings',
                          label: 'Speech speed control',
                          hint: 'Current speed is ${currentSpeed.toStringAsFixed(1)}. Double tap to focus, then swipe to adjust',
                          child: _buildSpeechSpeedButtons(
                            theme: themeProvider,
                            currentSpeed: currentSpeed,
                            onChanged: (value) {
                              setModalState(() {
                                currentSpeed = value;
                              });
                              onSpeedChanged(value);
                            },
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Pitch Control
                        ScreenReaderFocusable(
                          context: 'text_to_speech_settings',
                          label: 'Speech pitch control',
                          hint: 'Current pitch is ${currentPitch.toStringAsFixed(1)}. Double tap to focus, then swipe to adjust',
                          child: _buildSpeechPitchButtons(
                            theme: themeProvider,
                            currentPitch: currentPitch,
                            onChanged: (value) {
                              setModalState(() {
                                currentPitch = value;
                              });
                              onPitchChanged(value);
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
            SelectToSpeakText(
              'Font Size',
              style: TextStyle(
                fontSize: theme.fontSize + 4,
                color: theme.labelColor,
                shadows: _getTextShadows(theme),
              ),
            ),
            SelectToSpeakText(
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
            ElevatedButton(
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
            const SizedBox(width: 20),
            ElevatedButton(
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SelectToSpeakText(
              'Line Height',
              style: TextStyle(
                fontSize: theme.fontSize + 4,
                color: theme.labelColor,
                shadows: _getTextShadows(theme),
              ),
            ),
            SelectToSpeakText(
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
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: lineHeightValues.map((val) {
            final bool isSelected = val == closestValue;
            final double gap = (val - 1.0) * 4 + 2;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SelectToSpeakText(
              'Speed',
              style: TextStyle(
                fontSize: theme.fontSize + 4,
                color: theme.labelColor,
                fontWeight: FontWeight.bold,
                shadows: _getTextShadows(theme),
              ),
            ),
            SelectToSpeakText(
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
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
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
            const SizedBox(width: 20),
            ElevatedButton(
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
          ],
        ),
      ],
    );
  }

  /// Helper method to build speech pitch control buttons
  static Widget _buildSpeechPitchButtons({
    required ThemeProvider theme,
    required double currentPitch,
    required void Function(double) onChanged,
  }) {
    const List<double> pitchValues = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final currentIndex = pitchValues.indexWhere((v) => (v - currentPitch).abs() < 0.01);
    final canDecrease = currentIndex > 0;
    final canIncrease = currentIndex < pitchValues.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SelectToSpeakText(
              'Pitch',
              style: TextStyle(
                fontSize: theme.fontSize + 4,
                color: theme.labelColor,
                fontWeight: FontWeight.bold,
                shadows: _getTextShadows(theme),
              ),
            ),
            SelectToSpeakText(
              '${currentPitch.toStringAsFixed(2)}',
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
            ElevatedButton(
              onPressed: canDecrease
                  ? () {
                      onChanged(pitchValues[currentIndex - 1]);
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
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: canIncrease
                  ? () {
                      onChanged(pitchValues[currentIndex + 1]);
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