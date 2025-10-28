import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/services.dart';
import '../../../widgets/widgets.dart';

/// Terms and conditions screen with legal information
class TermsOfUsePage extends StatefulWidget {
  /// Creates a terms and conditions screen
  const TermsOfUsePage({super.key});

  @override
  State<TermsOfUsePage> createState() => _TermsOfUsePageState();
}

class _TermsOfUsePageState extends State<TermsOfUsePage> {
  bool _isReady = false;
  
  // Track which sections are expanded
  final Map<String, bool> _expandedSections = {
    'acceptance': false,
    'use_of_products': false,
    'privacy': false,
    'accuracy': false,
    'updates': false,
    'safety': false,
  };

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

  /// Builds an expandable section with a title and content
  Widget _buildExpandableSection({
    required String sectionKey,
    required String title,
    required String content,
    required ThemeProvider theme,
  }) {
    final isExpanded = _expandedSections[sectionKey] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              VibrationService.mediumFeedback();
              setState(() {
                _expandedSections[sectionKey] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.buttonTextColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectToSpeakText(
                      title,
                      style: TextStyle(
                        fontSize: theme.fontSize + 4,
                        fontWeight: FontWeight.bold,
                        color: theme.buttonTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SelectToSpeakText(
                content,
                style: TextStyle(
                  fontSize: theme.fontSize,
                  color: theme.buttonTextColor,
                  height: theme.lineHeight,
                ),
              ),
            ),
        ],
      ),
    );
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

                  // Expandable sections
                  _buildExpandableSection(
                    sectionKey: 'acceptance',
                    title: 'Acceptance of Terms',
                    content: 'By using the Solari product, you acknowledge that you have read, understood, and agreed to be bound by these Terms and Conditions.',
                    theme: theme,
                  ),
                  
                  _buildExpandableSection(
                    sectionKey: 'use_of_products',
                    title: 'Use of Solari Products',
                    content: 'Solari smart glasses are designed to assist individuals with visual impairments by providing real-time scene descriptions. They are not a medical device; it does not diagnose or treat conditions, functioning solely as a non-clinical assistive tool.\n\nProhibited Uses: You agree not to use Solari for any unlawful, harmful, or abusive purposes.',
                    theme: theme,
                  ),
                  
                  _buildExpandableSection(
                    sectionKey: 'privacy',
                    title: 'Privacy and Data Collection',
                    content: 'Solari mitigates privacy issues by processing all visual data offline, without storing or transmitting information, complying with the Philippines\' Data Privacy Act of 2012. It ensures that sensitive visual data remains private and never leaves the device.',
                    theme: theme,
                  ),
                  
                  _buildExpandableSection(
                    sectionKey: 'accuracy',
                    title: 'Accuracy and Limitations',
                    content: 'Solari is limited to offline functionality. Initially, it only supports the English language. The device also has some hardware limitations. Its battery life is limited and needs to be recharged regularly. It has basic processing power, which means it might not perform well with very complex tasks. Additionally, if used for a long term, the smart glasses might get warm; it is recommended to take breaks during extended use.',
                    theme: theme,
                  ),
                  
                  _buildExpandableSection(
                    sectionKey: 'updates',
                    title: 'Software Updates and Changes',
                    content: 'We may update our software, features, or terms from time to time. We\'ll do our best to keep you informed.',
                    theme: theme,
                  ),
                  
                  _buildExpandableSection(
                    sectionKey: 'safety',
                    title: 'Safety Information',
                    content: 'Do not use Solari Smart Glasses while driving or operating heavy machinery. Use of these glasses by children under 13 is not recommended. Consult your doctor if you experience eye strain, headaches, or other discomfort while using the glasses.',
                    theme: theme,
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

