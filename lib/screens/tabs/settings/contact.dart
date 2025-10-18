import 'package:flutter/material.dart';
import '../../../widgets/select_to_speak_text.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/vibration_service.dart';
import '../../../../widgets/app_bar.dart';
import '../../../../widgets/custom_button.dart';
import '../../../widgets/screen_reader_gesture_detector.dart';
import '../../../widgets/screen_reader_focusable.dart';

/// Contact support screen
class ContactScreen extends StatelessWidget {
  /// Creates a contact screen
  const ContactScreen({super.key});

  /// Helper method to get text shadows for high contrast mode
  static List<Shadow>? _getTextShadows(ThemeProvider theme) {
    if (!theme.isHighContrast) return null;
    final shadowColor = theme.isDarkMode ? Colors.white : Colors.black;
    return [
      Shadow(offset: const Offset(0, -1), blurRadius: 3.0, color: shadowColor),
      Shadow(offset: const Offset(0, 1), blurRadius: 3.0, color: shadowColor),
      Shadow(offset: const Offset(-1, 0), blurRadius: 3.0, color: shadowColor),
      Shadow(offset: const Offset(1, 0), blurRadius: 3.0, color: shadowColor),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Local helper to show the thank-you dialog (keeps code DRY)
    void showThankYouDialog() {
      VibrationService.mediumFeedback();
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectToSpeakText(
                  'Thank You!',
                  style: TextStyle(
                    fontSize: themeProvider.fontSize + 8,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.buttonTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SelectToSpeakText(
                  'Feedback submitted successfully.',
                  style: TextStyle(
                    fontSize: themeProvider.fontSize + 4,
                    color: themeProvider.buttonTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    VibrationService.mediumFeedback();
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: themeProvider.buttonTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    minimumSize: const Size(200, 48),
                  ),
                  child: SelectToSpeakText(
                    'OK',
                    style: TextStyle(
                      fontSize: themeProvider.fontSize + 4,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: "Contact", showBackButton: true),
      body: ScreenReaderGestureDetector(
        child: SafeArea(
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
                    // Contact Number
                    ScreenReaderFocusable(
                      label: 'Contact Number section',
                      hint: 'Phone number zero nine X X X X X X X X X',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: SelectToSpeakText(
                              "Contact Number",
                              style: TextStyle(
                                fontSize: themeProvider.fontSize + 8,
                                fontWeight: FontWeight.bold,
                                color: themeProvider.textColor,
                                shadows: _getTextShadows(themeProvider),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          SelectToSpeakText(
                            "09XXXXXXXXX",
                            style: TextStyle(
                              fontSize: themeProvider.fontSize + 4,
                              color: themeProvider.textColor,
                              shadows: _getTextShadows(themeProvider),
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildDivider(themeProvider),

                    // Email
                    ScreenReaderFocusable(
                      label: 'Email section',
                      hint: 'Email support at solari dot com',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: SelectToSpeakText(
                              "Email",
                              style: TextStyle(
                                fontSize: themeProvider.fontSize + 8,
                                fontWeight: FontWeight.bold,
                                color: themeProvider.textColor,
                                shadows: _getTextShadows(themeProvider),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectToSpeakText(
                            "support@solari.com",
                            style: TextStyle(
                              fontSize: themeProvider.fontSize + 4,
                              color: themeProvider.textColor,
                              shadows: _getTextShadows(themeProvider),
                            ),
                          ),
                        ],
                      ),
                    ),

                    _buildDivider(themeProvider),

                    // Feedback
                    Semantics(
                      header: true,
                      child: SelectToSpeakText(
                        "Feedback",
                        style: TextStyle(
                          fontSize: themeProvider.fontSize + 8,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.textColor,
                          shadows: _getTextShadows(themeProvider),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    ScreenReaderFocusable(
                      label: 'Feedback text field',
                      hint: 'Double tap to enter your feedback',
                      child: TextField(
                        maxLines: 5,
                        style: TextStyle(
                          fontSize: themeProvider.fontSize + 4,
                          color: Colors.black,
                          shadows: themeProvider.isHighContrast
                              ? [
                                  const Shadow(
                                    offset: Offset(0, -1),
                                    blurRadius: 3.0,
                                    color: Colors.white,
                                  ),
                                  const Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 3.0,
                                    color: Colors.white,
                                  ),
                                  const Shadow(
                                    offset: Offset(-1, 0),
                                    blurRadius: 3.0,
                                    color: Colors.white,
                                  ),
                                  const Shadow(
                                    offset: Offset(1, 0),
                                    blurRadius: 3.0,
                                    color: Colors.white,
                                  ),
                                ]
                              : null,
                        ),
                        cursorColor: themeProvider.dividerColor,
                        onTap: () {
                          VibrationService.mediumFeedback(); // Add medium vibration when text field is tapped
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: themeProvider.dividerColor,
                              width: 3,
                            ),
                          ),
                          hintText: "Enter your feedback here",
                          hintStyle: TextStyle(
                            fontSize: themeProvider.fontSize + 4,
                            color: Colors.grey,
                            shadows: themeProvider.isHighContrast
                                ? [
                                    const Shadow(
                                      offset: Offset(0, -1),
                                      blurRadius: 3.0,
                                      color: Colors.white,
                                    ),
                                    const Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 3.0,
                                      color: Colors.white,
                                    ),
                                    const Shadow(
                                      offset: Offset(-1, 0),
                                      blurRadius: 3.0,
                                      color: Colors.white,
                                    ),
                                    const Shadow(
                                      offset: Offset(1, 0),
                                      blurRadius: 3.0,
                                      color: Colors.white,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ScreenReaderFocusable(
                      label: 'Save feedback button',
                      hint: 'Double tap to submit your feedback',
                      onTap: () {
                        showThankYouDialog();
                      },
                      child: Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            label: "Save",
                            icon: Icons.send,
                            fontSize: themeProvider.fontSize + 8,
                            labelAlignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 20,
                            ),
                            enableVibration: false,
                            onPressed: () {
                              showThankYouDialog();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeProvider themeProvider) => Column(
    children: [
      const SizedBox(height: 20),
      Container(
        height: 10,
        decoration: BoxDecoration(
          color: themeProvider.dividerColor,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
}
