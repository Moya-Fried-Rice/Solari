import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../widgets/app_bar.dart';

/// Terms and conditions screen with legal information
class TermsOfUsePage extends StatelessWidget {
  /// Creates a terms and conditions screen
  const TermsOfUsePage({super.key});

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
      ),
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
                  Semantics(
                    header: true,
                    child: Text(
                      "Terms of Use",
                      style: TextStyle(
                        fontSize: theme.fontSize + 8, 
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "By using Solari Smart Glasses and the accompanying app, you agree to the following terms and conditions. Kindly read them carefully.",
                    style: TextStyle(
                      fontSize: theme.fontSize + 4,
                      color: theme.textColor,
                      height: theme.lineHeight,
                      shadows: _getTextShadows(theme),
                    ),
                  ),
                  const SizedBox(height: 30),
  
                  Semantics(
                    header: true,
                    child: Text(
                      "Acceptance of Terms",
                      style: TextStyle(
                        fontSize: theme.fontSize + 8, 
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "By using the Solari product, you acknowledge that you have read, understood, and agreed to be bound by these Terms and Conditions.",
                    style: TextStyle(
                      fontSize: theme.fontSize + 4,
                      color: theme.textColor,
                      height: theme.lineHeight,
                      shadows: _getTextShadows(theme),
                    ),
                  ),
                  const SizedBox(height: 30),
  
                  Semantics(
                    header: true,
                    child: Text(
                      "Use of Solari Products",
                      style: TextStyle(
                        fontSize: theme.fontSize + 8, 
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Solari smart glasses are designed to assist individuals with visual impairments by providing real-time scene descriptions. They are not a medical device; it does not diagnose or treat conditions, functioning solely as a non-clinical assistive tool. "
                    "\n\nProhibited Uses: You agree not to use Solari for any unlawful, harmful, or abusive purposes.",
                    style: TextStyle(
                      fontSize: theme.fontSize + 4,
                      color: theme.textColor,
                      height: theme.lineHeight,
                      shadows: _getTextShadows(theme),
                    ),
                  ),
                  const SizedBox(height: 30),
  
                  Semantics(
                    header: true,
                    child: Text(
                      "Privacy and Data Collection",
                      style: TextStyle(
                        fontSize: theme.fontSize + 8, 
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Solari mitigates privacy issues by processing all visual data offline, without storing or transmitting information, complying with the Philippines' Data Privacy Act of 2012. It ensures that sensitive visual data remains private and never leaves the device.",
                    style: TextStyle(
                      fontSize: theme.fontSize + 4,
                      color: theme.textColor,
                      height: theme.lineHeight,
                      shadows: _getTextShadows(theme),
                    ),
                  ),
                  const SizedBox(height: 30),
  
                  Semantics(
                    header: true,
                    child: Text(
                      "Accuracy and Limitations",
                      style: TextStyle(
                        fontSize: theme.fontSize + 8, 
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Solari is limited to offline functionality. Initially, it only supports the English language. The device also has some hardware limitations. Its battery life is limited and needs to be recharged regularly. It has basic processing power, which means it might not perform well with very complex tasks. Additionally, if used for a long term, the smart glasses might get warm; it is recommended to take breaks during extended use.",
                    style: TextStyle(
                      fontSize: theme.fontSize + 4,
                      color: theme.textColor,
                      height: theme.lineHeight,
                      shadows: _getTextShadows(theme),
                    ),
                  ),
                  const SizedBox(height: 30),
  
                  Semantics(
                    header: true,
                    child: Text(
                      "Software Updates and Changes",
                      style: TextStyle(
                        fontSize: theme.fontSize + 8, 
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "We may update our software, features, or terms from time to time. We'll do our best to keep you informed.",
                    style: TextStyle(
                      fontSize: theme.fontSize + 4,
                      color: theme.textColor,
                      height: theme.lineHeight,
                      shadows: _getTextShadows(theme),
                    ),
                  ),
                  const SizedBox(height: 30),

                  Semantics(
                    header: true,
                    child: Text(
                      "Safety Information",
                      style: TextStyle(
                        fontSize: theme.fontSize + 8, 
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                        shadows: _getTextShadows(theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
