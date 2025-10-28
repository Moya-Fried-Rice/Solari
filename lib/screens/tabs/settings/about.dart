import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/services.dart';
import '../../../widgets/widgets.dart';

/// About screen with information about Solari
class AboutPage extends StatefulWidget {
  /// Creates an about screen
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  bool _isReady = false;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScreenReaderService().setActiveContext('about');
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
    ScreenReaderService().clearContextNodes('about');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'About Solari',
        showBackButton: true,
        screenReaderContext: 'about',
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
                    ScreenReaderFocusable(
                      context: 'about',
                      label: 'About Solari - Introduction',
                      hint: 'Solari is an AI-powered pair of smart glasses designed to support visually impaired individuals by transforming how they perceive the world.',
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
                      context: 'about',
                      label: 'About Solari - Real-time description',
                      hint: 'It describes what\'s happening around the user in real time, such as spotting obstacles, finding paths, or pointing out landmarks.',
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
                      context: 'about',
                      label: 'About Solari - Benefits',
                      hint: 'Whether you\'re at school or exploring a new place, Solari is like having a helpful guide by your side, making daily lives easier and safer.',
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

