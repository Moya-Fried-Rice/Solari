import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/providers/theme_provider.dart';
import '../../../../../widgets/app_bar.dart';

/// FAQs screen with answers to common questions
class FAQsScreen extends StatelessWidget {
  /// Creates an FAQs screen
  const FAQsScreen({super.key});

  /// Build a single FAQ item with question and answer
  Widget buildFAQ(BuildContext context, String question, String answer,
      {bool isLast = false}) {
    final theme = Provider.of<ThemeProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "Question: ", 
                style: TextStyle(
                  fontSize: theme.fontSize + 8,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              TextSpan(
                text: question, 
                style: TextStyle(
                  fontSize: theme.fontSize + 4,
                  color: theme.textColor,
                  height: theme.lineHeight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "Answer: ", 
                style: TextStyle(
                  fontSize: theme.fontSize + 8,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              TextSpan(
                text: answer, 
                style: TextStyle(
                  fontSize: theme.fontSize + 4,
                  color: theme.textColor,
                  height: theme.lineHeight,
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
      appBar: const CustomAppBar(title: "FAQs", showBackButton: true),
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
