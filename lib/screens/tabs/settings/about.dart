import 'package:flutter/material.dart';
import '../../../widgets/select_to_speak_text.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/screen_reader_gesture_detector.dart';
import '../../../widgets/screen_reader_focusable.dart';

/// About screen with information about Solari
class AboutPage extends StatelessWidget {
  /// Creates an about screen
  const AboutPage({super.key});

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
        title: 'About Solari',
        showBackButton: true,
      ),
      body: ScreenReaderGestureDetector(
        child: SafeArea(
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
                    ScreenReaderFocusable(
                      label: 'About Solari - Introduction',
                      hint: 'AI-powered smart glasses for visually impaired individuals',
                      child: SelectToSpeakText(
                        "Solari is an AI-powered pair of smart glasses designed to support visually impaired individuals by transforming how they perceive the world.",
                        style: TextStyle(
                          fontSize: theme.fontSize + 4,
                          color: theme.textColor,
                          height: theme.lineHeight,
                          shadows: _getTextShadows(theme),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ScreenReaderFocusable(
                      label: 'About Solari - Real-time description',
                      hint: 'Describes surroundings in real time',
                      child: SelectToSpeakText(
                        "It describes what's happening around the user in real time, such as spotting obstacles, finding paths, or pointing out landmarks.",
                        style: TextStyle(
                          fontSize: theme.fontSize + 4,
                          color: theme.textColor,
                          height: theme.lineHeight,
                          shadows: _getTextShadows(theme),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ScreenReaderFocusable(
                      label: 'About Solari - Benefits',
                      hint: 'Makes daily life easier and safer',
                      child: SelectToSpeakText(
                        "Whether you're at school or exploring a new place, Solari is like having a helpful guide by your side, making daily lives easier and safer.",
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

