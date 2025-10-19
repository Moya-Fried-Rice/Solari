import 'package:flutter/material.dart';
import '../../../widgets/select_to_speak_text.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/screen_reader_service.dart';
import '../../../../widgets/app_bar.dart';
import '../../../widgets/screen_reader_gesture_detector.dart';
import '../../../widgets/screen_reader_focusable.dart';

/// FAQs screen with answers to common questions
class FAQsScreen extends StatefulWidget {
  /// Creates an FAQs screen
  const FAQsScreen({super.key});

  @override
  State<FAQsScreen> createState() => _FAQsScreenState();
}

class _FAQsScreenState extends State<FAQsScreen> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScreenReaderService().setActiveContext('faqs');
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
    ScreenReaderService().clearContextNodes('faqs');
    super.dispose();
  }

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

  /// Build a single FAQ item with question and answer
  Widget buildFAQ(BuildContext context, String question, String answer,
      {bool isLast = false}) {
    final theme = Provider.of<ThemeProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question
        ScreenReaderFocusable(
          context: 'faqs',
          label: 'Question',
          hint: question,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectToSpeakText(
                "Question:",
                style: TextStyle(
                  fontSize: theme.fontSize + 8,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                  shadows: _getTextShadows(theme),
                ),
              ),
              const SizedBox(height: 8),
              SelectToSpeakText(
                question,
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
        const SizedBox(height: 20),
        
        // Answer
        ScreenReaderFocusable(
          context: 'faqs',
          label: 'Answer',
          hint: answer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectToSpeakText(
                "Answer:",
                style: TextStyle(
                  fontSize: theme.fontSize + 8,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                  shadows: _getTextShadows(theme),
                ),
              ),
              const SizedBox(height: 8),
              SelectToSpeakText(
                answer,
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
        if (!isLast) 
          _buildDivider(theme),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "FAQs", 
        showBackButton: true,
        screenReaderContext: 'faqs',
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
                  buildFAQ(
                    context, 
                    "What is Solari?", 
                    "Solari is a pair of smart glasses that helps visually impaired individuals by describing their surroundings in real time using AI.",
                  ),
                  buildFAQ(
                    context, 
                    "How does it work?", 
                    "Solari uses built-in cameras and AI to \"see\" what's around and then speaks out descriptions to help users navigate safely.",
                  ),
                  buildFAQ(
                    context, 
                    "Is Solari only for school use?", 
                    "Nope! While it's great for school environments, Solari works in all kinds of places—indoors, outdoors, familiar or new.",
                    isLast: true,
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

