import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../widgets/app_bar.dart';
import '../../../../widgets/settings_button.dart';
import 'help/faqs.dart';
import 'help/tutorials.dart';
import 'help/contact.dart';

/// Help screen with access to FAQs, tutorials and contact support
class HelpPage extends StatelessWidget {
  /// Creates a help screen
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final buttons = [
      {"label": "FAQs", "screen": const FAQsScreen(), "icon": Icons.question_answer_outlined},
      {"label": "Tutorials", "screen": const TutorialsScreen(), "icon": Icons.video_library_outlined},
      {"label": "Contact", "screen": const ContactScreen(), "icon": Icons.support_agent},
    ];

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Help',
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.largePadding, 
                vertical: AppConstants.defaultPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: buttons.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppConstants.largePadding),
                    child: CustomButton(
                      label: item["label"] as String,
                      icon: item["icon"] as IconData,
                      fontSize: themeProvider.fontSize + 4,
                      labelAlignment: Alignment.centerLeft,
                      enableVibration: false, // Disable built-in vibration since we handle it in onPressed
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 20,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => item["screen"] as Widget,
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
