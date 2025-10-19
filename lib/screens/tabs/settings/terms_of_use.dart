import 'package:flutter/material.dart';
import '../../../widgets/select_to_speak_text.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/screen_reader_service.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/screen_reader_gesture_detector.dart';
import '../../../widgets/screen_reader_focusable.dart';

/// Terms and conditions screen with legal information
class TermsOfUsePage extends StatefulWidget {
  /// Creates a terms and conditions screen
  const TermsOfUsePage({super.key});

  @override
  State<TermsOfUsePage> createState() => _TermsOfUsePageState();
}

class _TermsOfUsePageState extends State<TermsOfUsePage> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScreenReaderService().setActiveContext('terms_of_use');
        // Delay body content registration to let app bar register first
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _isReady = true;
            });
            // Then focus the first element (back button)
            if (ScreenReaderService().isEnabled) {
              Future.delayed(const Duration(milliseconds: 200), () {
                ScreenReaderService().focusNext();
              });
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    ScreenReaderService().clearContextNodes('terms_of_use');
    super.dispose();
  }

   /// Helper method to get text shadows for high contrast mode
  static List<Shadow>? _getTextShadows(ThemeProvider theme) {
    if (!theme.isHighContrast) return null;
    final shadowColor = theme.isDarkMode ? Colors.white : Colors.black;
    return [
      Shadow(offset: const Offset(0, -1), blurRadius: 5.0, color: shadowColor),
      Shadow(offset: const Offset(0, 1), blurRadius: 5.0, color: shadowColor),
      Shadow(offset: const Offset(-1, 0), blurRadius: 5.0, color: shadowColor),
      Shadow(offset: const Offset(1, 0), blurRadius: 5.0, color: shadowColor),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Terms of Use',
        showBackButton: true,
        screenReaderContext: 'terms_of_use',
      ),
      body: ScreenReaderGestureDetector(
        child: !_isReady
          ? const SizedBox.shrink()
          : SafeArea(
          child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - kToolbarHeight - 80,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  ScreenReaderFocusable(
                    context: 'terms_of_use',
                    label: 'Terms of Use',
                    hint: 'Page title',
                    child: Semantics(
                      header: true,
                      child: SelectToSpeakText(
                        "Terms of Use",
                        style: TextStyle(
                          fontSize: theme.fontSize + 8, 
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                          shadows: _getTextShadows(theme),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Introduction
                  ScreenReaderFocusable(
                    context: 'terms_of_use',
                    label: 'Introduction',
                    hint: 'By using Solari Smart Glasses and the accompanying app, you agree to the following terms and conditions. Kindly read them carefully.',
                    child: SelectToSpeakText(
                      "By using Solari Smart Glasses and the accompanying app, you agree to the following terms and conditions. Kindly read them carefully.",
                      style: TextStyle(
                        fontSize: theme.fontSize + 4,
                        color: theme.textColor,
                        height: theme.lineHeight,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Acceptance of Terms
                  ScreenReaderFocusable(
                    context: 'terms_of_use',
                    label: 'Acceptance of Terms',
                    hint: 'Section header',
                    child: Semantics(
                      header: true,
                      child: SelectToSpeakText(
                        "Acceptance of Terms",
                        style: TextStyle(
                          fontSize: theme.fontSize + 8, 
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                          shadows: _getTextShadows(theme),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ScreenReaderFocusable(
                    context: 'terms_of_use',
                    label: 'Acceptance of Terms content',
                    hint: 'By using the Solari product, you acknowledge that you have read, understood, and agreed to be bound by these Terms and Conditions.',
                    child: SelectToSpeakText(
                      "By using the Solari product, you acknowledge that you have read, understood, and agreed to be bound by these Terms and Conditions.",
                      style: TextStyle(
                        fontSize: theme.fontSize + 4,
                        color: theme.textColor,
                        height: theme.lineHeight,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Use of Solari Products
                  ScreenReaderFocusable(
                    context: 'terms_of_use',
                    label: 'Use of Solari Products',
                    hint: 'Section header',
                    child: Semantics(
                      header: true,
                      child: SelectToSpeakText(
                        "Use of Solari Products",
                        style: TextStyle(
                          fontSize: theme.fontSize + 8, 
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                          shadows: _getTextShadows(theme),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ScreenReaderFocusable(
                    context: 'terms_of_use',
                    label: 'Use of Solari Products content',
                    hint: 'Solari smart glasses are designed to assist individuals with visual impairments by providing real-time scene descriptions. They are not a medical device; it does not diagnose or treat conditions, functioning solely as a non-clinical assistive tool. Prohibited Uses: You agree not to use Solari for any unlawful, harmful, or abusive purposes.',
                    child: SelectToSpeakText(
                      "Solari smart glasses are designed to assist individuals with visual impairments by providing real-time scene descriptions. They are not a medical device; it does not diagnose or treat conditions, functioning solely as a non-clinical assistive tool. "
                      "\n\nProhibited Uses: You agree not to use Solari for any unlawful, harmful, or abusive purposes.",
                      style: TextStyle(
                        fontSize: theme.fontSize + 4,
                        color: theme.textColor,
                        height: theme.lineHeight,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Privacy and Data Collection
                  ScreenReaderFocusable(
                    context: 'terms_of_use',
                    label: 'Privacy and Data Collection',
                    hint: 'Section header',
                    child: Semantics(
                      header: true,
                      child: SelectToSpeakText(
                        "Privacy and Data Collection",
                        style: TextStyle(
                          fontSize: theme.fontSize + 8, 
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                          shadows: _getTextShadows(theme),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ScreenReaderFocusable(
                    context: 'terms_of_use',
                    label: 'Privacy and Data Collection content',
                    hint: 'Solari mitigates privacy issues by processing all visual data offline, without storing or transmitting information, complying with the Philippines\' Data Privacy Act of 2012. It ensures that sensitive visual data remains private and never leaves the device.',
                    child: SelectToSpeakText(
                      "Solari mitigates privacy issues by processing all visual data offline, without storing or transmitting information, complying with the Philippines' Data Privacy Act of 2012. It ensures that sensitive visual data remains private and never leaves the device.",
                      style: TextStyle(
                        fontSize: theme.fontSize + 4,
                        color: theme.textColor,
                        height: theme.lineHeight,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Accuracy and Limitations
                  ScreenReaderFocusable(
                    context: 'terms_of_use',
                    label: 'Accuracy and Limitations',
                    hint: 'Section header',
                    child: Semantics(
                      header: true,
                      child: SelectToSpeakText(
                        "Accuracy and Limitations",
                        style: TextStyle(
                          fontSize: theme.fontSize + 8, 
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                          shadows: _getTextShadows(theme),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ScreenReaderFocusable(
                    context: 'terms_of_use',
                    label: 'Accuracy and Limitations content',
                    hint: 'Solari is limited to offline functionality. Initially, it only supports the English language. The device also has some hardware limitations. Its battery life is limited and needs to be recharged regularly. It has basic processing power, which means it might not perform well with very complex tasks. Additionally, if used for a long term, the smart glasses might get warm; it is recommended to take breaks during extended use.',
                    child: SelectToSpeakText(
                      "Solari is limited to offline functionality. Initially, it only supports the English language. The device also has some hardware limitations. Its battery life is limited and needs to be recharged regularly. It has basic processing power, which means it might not perform well with very complex tasks. Additionally, if used for a long term, the smart glasses might get warm; it is recommended to take breaks during extended use.",
                      style: TextStyle(
                        fontSize: theme.fontSize + 4,
                        color: theme.textColor,
                        height: theme.lineHeight,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Software Updates and Changes
                  ScreenReaderFocusable(
                    context: 'terms_of_use',
                    label: 'Software Updates and Changes',
                    hint: 'Section header',
                    child: Semantics(
                      header: true,
                      child: SelectToSpeakText(
                        "Software Updates and Changes",
                        style: TextStyle(
                          fontSize: theme.fontSize + 8, 
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                          shadows: _getTextShadows(theme),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ScreenReaderFocusable(
                    context: 'terms_of_use',
                    label: 'Software Updates and Changes content',
                    hint: 'We may update our software, features, or terms from time to time. We\'ll do our best to keep you informed.',
                    child: SelectToSpeakText(
                      "We may update our software, features, or terms from time to time. We'll do our best to keep you informed.",
                      style: TextStyle(
                        fontSize: theme.fontSize + 4,
                        color: theme.textColor,
                        height: theme.lineHeight,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Safety Information
                  ScreenReaderFocusable(
                    context: 'terms_of_use',
                    label: 'Safety Information',
                    hint: 'Section header',
                    child: Semantics(
                      header: true,
                      child: SelectToSpeakText(
                        "Safety Information",
                        style: TextStyle(
                          fontSize: theme.fontSize + 8, 
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                          shadows: _getTextShadows(theme),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ScreenReaderFocusable(
                    context: 'terms_of_use',
                    label: 'Safety Information content',
                    hint: 'Do not use Solari Smart Glasses while driving or operating heavy machinery. Use of these glasses by children under 13 is not recommended. Consult your doctor if you experience eye strain, headaches, or other discomfort while using the glasses.',
                    child: SelectToSpeakText(
                      "Do not use Solari Smart Glasses while driving or operating heavy "
                      "machinery. Use of these glasses by children under 13 is not "
                      "recommended. Consult your doctor if you experience eye strain, "
                      "headaches, or other discomfort while using the glasses.",
                      style: TextStyle(
                        fontSize: theme.fontSize + 4,
                        color: theme.textColor,
                        height: theme.lineHeight,
                        shadows: _getTextShadows(theme),
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
}

