import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/services.dart';
import '../../../../widgets/widgets.dart';

/// FAQs screen with answers to common questions
class FAQsScreen extends StatefulWidget {
  /// Creates an FAQs screen
  const FAQsScreen({super.key});

  @override
  State<FAQsScreen> createState() => _FAQsScreenState();
}

class _FAQsScreenState extends State<FAQsScreen> {
  bool _isReady = false;
  
  // Track which FAQ sections are expanded
  final Map<String, bool> _expandedSections = {
    'what_is_solari': false,
    'how_does_it_work': false,
    'school_use_only': false,
  };

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

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

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
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.largePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExpandableFAQ(
                      theme,
                      'what_is_solari',
                      'What is Solari?',
                      'Solari is a pair of smart glasses that helps visually impaired individuals by describing their surroundings in real time using AI.',
                    ),
                    _buildExpandableFAQ(
                      theme,
                      'how_does_it_work',
                      'How does Solari work?',
                      'Solari uses built-in cameras and AI to "see" what\'s around and then speaks out descriptions to help users navigate safely.',
                    ),
                    _buildExpandableFAQ(
                      theme,
                      'school_use_only',
                      'Is Solari only for school use?',
                      'Nope! While it\'s great for school environments, Solari works in all kinds of places—indoors, outdoors, familiar or new.',
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

  Widget _buildExpandableFAQ(
    ThemeProvider theme,
    String key,
    String question,
    String answer,
  ) {
    final isExpanded = _expandedSections[key] ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenReaderFocusable(
          context: 'faqs',
          label: '$question, ${isExpanded ? 'expanded' : 'collapsed'}',
          hint: 'Double tap to ${isExpanded ? 'collapse' : 'expand'}',
          onTap: () {
            VibrationService.mediumFeedback();
            setState(() {
              _expandedSections[key] = !isExpanded;
            });
          },
          child: InkWell(
            onTap: () {
              VibrationService.mediumFeedback();
              setState(() {
                _expandedSections[key] = !isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.buttonTextColor,
                    size: theme.fontSize + 4,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectToSpeakText(
                      question,
                      style: TextStyle(
                        fontSize: theme.fontSize + 2,
                        fontWeight: FontWeight.bold,
                        color: theme.buttonTextColor,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: ScreenReaderFocusable(
              context: 'faqs',
              label: '$question answer',
              hint: answer,
              child: SelectToSpeakText(
                answer,
                style: TextStyle(
                  fontSize: theme.fontSize,
                  color: theme.textColor,
                  height: theme.lineHeight,
                  shadows: _getTextShadows(theme),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

