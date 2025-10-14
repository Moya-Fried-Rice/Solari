import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../widgets/app_bar.dart';

/// Tutorials screen with guidance on using Solari glasses
class TutorialsScreen extends StatelessWidget {
  /// Creates a tutorials screen
  const TutorialsScreen({super.key});

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
      appBar: const CustomAppBar(title: "Tutorials", showBackButton: true),
      body: SafeArea(
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
            Semantics(
              header: true,
              child: Text(
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

            _buildDivider(theme),

            // Audio Section
            Semantics(
              header: true,
              child: Text(
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

            _buildDivider(theme),

            // Text Section
            Semantics(
              header: true,
              child: Text(
                "Text", 
                style: TextStyle(
                  fontSize: theme.fontSize + 8,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                  shadows: _getTextShadows(theme),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Introduction
                Semantics(
                  child: Text(
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
                Semantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "1. Chat Input (Audio Only)",
                        style: TextStyle(
                          fontSize: theme.fontSize + 4,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                          shadows: _getTextShadows(theme),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Speak directly to your smart glasses to interact using your voice.",
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

                // Settings Section
                Semantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "2. Settings Page",
                        style: TextStyle(
                          fontSize: theme.fontSize + 4,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                          shadows: _getTextShadows(theme),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Customize your experience through the settings page, which contains several sub-pages:",
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

                // Device Connection
                Semantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "• Device Connection",
                        style: TextStyle(
                          fontSize: theme.fontSize + 4,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                          shadows: _getTextShadows(theme),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
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
                Semantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "• Preferences",
                        style: TextStyle(
                          fontSize: theme.fontSize + 4,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                          shadows: _getTextShadows(theme),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
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
                Semantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "• Help",
                        style: TextStyle(
                          fontSize: theme.fontSize + 4,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                          shadows: _getTextShadows(theme),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
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

                // Help Sub-pages
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FAQs
                      Semantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "– FAQs",
                              style: TextStyle(
                                fontSize: theme.fontSize + 4,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                                shadows: _getTextShadows(theme),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
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
                      const SizedBox(height: 16),

                      // Tutorials
                      Semantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "– Tutorials",
                              style: TextStyle(
                                fontSize: theme.fontSize + 4,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                                shadows: _getTextShadows(theme),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
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
                      const SizedBox(height: 16),

                      // Contact
                      Semantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "– Contact",
                              style: TextStyle(
                                fontSize: theme.fontSize + 4,
                                fontWeight: FontWeight.bold,
                                color: theme.textColor,
                                shadows: _getTextShadows(theme),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // About Solari
                Semantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "• About Solari",
                        style: TextStyle(
                          fontSize: theme.fontSize + 4,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                          shadows: _getTextShadows(theme),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
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
                Semantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "• Terms & Conditions",
                        style: TextStyle(
                          fontSize: theme.fontSize + 4,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                          shadows: _getTextShadows(theme),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
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
                Semantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "3. Chat History",
                        style: TextStyle(
                          fontSize: theme.fontSize + 4,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                          shadows: _getTextShadows(theme),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Review past conversations with your smart glasses to keep track of your interactions.",
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

                // Conclusion
                Semantics(
                  child: Text(
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
                ],
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
