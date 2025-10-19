import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/screen_reader_service.dart';
import '../../../../widgets/app_bar.dart';
import '../../../../widgets/select_to_speak_text.dart';
import '../../../../widgets/screen_reader_gesture_detector.dart';
import '../../../../widgets/screen_reader_focusable.dart';

/// Tutorials screen with guidance on using Solari glasses
class TutorialsScreen extends StatefulWidget {
  /// Creates a tutorials screen
  const TutorialsScreen({super.key});

  @override
  State<TutorialsScreen> createState() => _TutorialsScreenState();
}

class _TutorialsScreenState extends State<TutorialsScreen> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScreenReaderService().setActiveContext('tutorials');
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
    ScreenReaderService().clearContextNodes('tutorials');
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
        title: "Tutorials", 
        showBackButton: true,
        screenReaderContext: 'tutorials',
      ),
      body: ScreenReaderGestureDetector(
        child: !_isReady
          ? const SizedBox.shrink()
          : GestureDetector(
          onTap: () {
            clearSelectToSpeakSelection();
          },
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
            // Video Section
            ScreenReaderFocusable(
              context: 'tutorials',
              label: 'Video tutorial section',
              hint: 'Video tutorial placeholder',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: SelectToSpeakText(
                      "Video", 
                      style: TextStyle(
                        fontSize: theme.fontSize + 8,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Placeholder(fallbackHeight: 200),
                ],
              ),
            ),

            _buildDivider(theme),

            // Audio Section
            ScreenReaderFocusable(
              context: 'tutorials',
              label: 'Audio tutorial section',
              hint: 'Audio tutorial placeholder',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: SelectToSpeakText(
                      "Audio", 
                      style: TextStyle(
                        fontSize: theme.fontSize + 8,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Placeholder(fallbackHeight: 100),
                ],
              ),
            ),

            _buildDivider(theme),

            // Text Section
            ScreenReaderFocusable(
              context: 'tutorials',
              label: 'Text tutorial section header',
              hint: 'Text',
              child: Semantics(
                header: true,
                child: SelectToSpeakText(
                  "Text", 
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
              context: 'tutorials',
              label: 'Introduction',
              hint: 'To get started with your smart glasses, first connect them via Bluetooth.',
              child: SelectToSpeakText(
                "To get started with your smart glasses, first connect them via Bluetooth.",
                style: TextStyle(
                  fontSize: theme.fontSize + 4,
                  color: theme.textColor,
                  height: theme.lineHeight,
                  shadows: _getTextShadows(theme),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Chat Input Section
            ScreenReaderFocusable(
              context: 'tutorials',
              label: 'Chat Input heading',
              hint: '1. Chat Input (Audio Only)',
              child: SelectToSpeakText(
                "1. Chat Input (Audio Only)",
                style: TextStyle(
                  fontSize: theme.fontSize + 4,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                  shadows: _getTextShadows(theme),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ScreenReaderFocusable(
              context: 'tutorials',
              label: 'Chat Input description',
              hint: 'Speak directly to your smart glasses to interact using your voice.',
              child: SelectToSpeakText(
                "Speak directly to your smart glasses to interact using your voice.",
                style: TextStyle(
                  fontSize: theme.fontSize + 4,
                  color: theme.textColor,
                  height: theme.lineHeight,
                  shadows: _getTextShadows(theme),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Settings Section
            ScreenReaderFocusable(
              context: 'tutorials',
              label: 'Settings Page heading',
              hint: '2. Settings Page',
              child: SelectToSpeakText(
                "2. Settings Page",
                style: TextStyle(
                  fontSize: theme.fontSize + 4,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                  shadows: _getTextShadows(theme),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ScreenReaderFocusable(
              context: 'tutorials',
              label: 'Settings Page description',
              hint: 'Customize your experience through the settings page, which contains several sub-pages:',
              child: SelectToSpeakText(
                "Customize your experience through the settings page, which contains several sub-pages:",
                style: TextStyle(
                  fontSize: theme.fontSize + 4,
                  color: theme.textColor,
                  height: theme.lineHeight,
                  shadows: _getTextShadows(theme),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Device Connection
            ScreenReaderFocusable(
              context: 'tutorials',
              label: 'Device Connection',
              hint: 'Manage Bluetooth connections and pair new devices.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectToSpeakText(
                    "• Device Connection",
                    style: TextStyle(
                      fontSize: theme.fontSize + 4,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                      shadows: _getTextShadows(theme),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectToSpeakText(
                    "Manage Bluetooth connections and pair new devices.",
                    style: TextStyle(
                      fontSize: theme.fontSize + 4,
                      color: theme.textColor,
                      height: theme.lineHeight,
                      shadows: _getTextShadows(theme),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preferences
            ScreenReaderFocusable(
              context: 'tutorials',
              label: 'Preferences',
              hint: 'Adjust features like voice speed, pitch, and accessibility options.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectToSpeakText(
                    "• Preferences",
                    style: TextStyle(
                      fontSize: theme.fontSize + 4,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                      shadows: _getTextShadows(theme),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectToSpeakText(
                    "Adjust features like voice speed, pitch, and accessibility options.",
                    style: TextStyle(
                      fontSize: theme.fontSize + 4,
                      color: theme.textColor,
                      height: theme.lineHeight,
                      shadows: _getTextShadows(theme),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Help Section
            ScreenReaderFocusable(
              context: 'tutorials',
              label: 'Help',
              hint: 'Access support resources. The Help page has its own sub-pages:',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectToSpeakText(
                    "• Help",
                    style: TextStyle(
                      fontSize: theme.fontSize + 4,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                      shadows: _getTextShadows(theme),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectToSpeakText(
                    "Access support resources. The Help page has its own sub-pages:",
                    style: TextStyle(
                      fontSize: theme.fontSize + 4,
                      color: theme.textColor,
                      height: theme.lineHeight,
                      shadows: _getTextShadows(theme),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // FAQs sub-page
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: ScreenReaderFocusable(
                context: 'tutorials',
                label: 'FAQs sub-page',
                hint: 'Find answers to common questions.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectToSpeakText(
                      "– FAQs",
                      style: TextStyle(
                        fontSize: theme.fontSize + 4,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectToSpeakText(
                      "Find answers to common questions.",
                      style: TextStyle(
                        fontSize: theme.fontSize + 4,
                        color: theme.textColor,
                        height: theme.lineHeight,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tutorials sub-page
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: ScreenReaderFocusable(
                context: 'tutorials',
                label: 'Tutorials sub-page',
                hint: 'Step-by-step guides for using your smart glasses.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectToSpeakText(
                      "– Tutorials",
                      style: TextStyle(
                        fontSize: theme.fontSize + 4,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectToSpeakText(
                      "Step-by-step guides for using your smart glasses.",
                      style: TextStyle(
                        fontSize: theme.fontSize + 4,
                        color: theme.textColor,
                        height: theme.lineHeight,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contact sub-page
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: ScreenReaderFocusable(
                context: 'tutorials',
                label: 'Contact sub-page',
                hint: 'Reach out to support for personalized help.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectToSpeakText(
                      "– Contact",
                      style: TextStyle(
                        fontSize: theme.fontSize + 4,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectToSpeakText(
                      "Reach out to support for personalized help.",
                      style: TextStyle(
                        fontSize: theme.fontSize + 4,
                        color: theme.textColor,
                        height: theme.lineHeight,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // About Solari
            ScreenReaderFocusable(
              context: 'tutorials',
              label: 'About Solari',
              hint: 'Learn more about Solari Smart Glasses.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectToSpeakText(
                    "• About Solari",
                    style: TextStyle(
                      fontSize: theme.fontSize + 4,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                      shadows: _getTextShadows(theme),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectToSpeakText(
                    "Learn more about Solari Smart Glasses.",
                    style: TextStyle(
                      fontSize: theme.fontSize + 4,
                      color: theme.textColor,
                      height: theme.lineHeight,
                      shadows: _getTextShadows(theme),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Terms & Conditions
            ScreenReaderFocusable(
              context: 'tutorials',
              label: 'Terms and Conditions',
              hint: 'Read the legal information and usage policies.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectToSpeakText(
                    "• Terms & Conditions",
                    style: TextStyle(
                      fontSize: theme.fontSize + 4,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                      shadows: _getTextShadows(theme),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectToSpeakText(
                    "Read the legal information and usage policies.",
                    style: TextStyle(
                      fontSize: theme.fontSize + 4,
                      color: theme.textColor,
                      height: theme.lineHeight,
                      shadows: _getTextShadows(theme),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Chat History
            ScreenReaderFocusable(
              context: 'tutorials',
              label: 'Chat History heading',
              hint: '3. Chat History',
              child: SelectToSpeakText(
                "3. Chat History",
                style: TextStyle(
                  fontSize: theme.fontSize + 4,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                  shadows: _getTextShadows(theme),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ScreenReaderFocusable(
              context: 'tutorials',
              label: 'Chat History description',
              hint: 'Review past conversations with your smart glasses to keep track of your interactions.',
              child: SelectToSpeakText(
                "Review past conversations with your smart glasses to keep track of your interactions.",
                style: TextStyle(
                  fontSize: theme.fontSize + 4,
                  color: theme.textColor,
                  height: theme.lineHeight,
                  shadows: _getTextShadows(theme),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Conclusion
            ScreenReaderFocusable(
              context: 'tutorials',
              label: 'Conclusion',
              hint: 'Follow these steps to ensure a smooth and seamless experience with your smart glasses.',
              child: SelectToSpeakText(
                "Follow these steps to ensure a smooth and seamless experience with your smart glasses.",
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

