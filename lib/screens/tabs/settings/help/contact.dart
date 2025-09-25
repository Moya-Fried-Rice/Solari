import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/providers/theme_provider.dart';
import '../../../../../core/services/vibration_service.dart';
import '../../../../../widgets/app_bar.dart';
import '../../../../../widgets/settings_button.dart';

/// Contact support screen
class ContactScreen extends StatelessWidget {
  /// Creates a contact screen
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(title: "Contact", showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height - kToolbarHeight - 80,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact Number
                  Semantics(
                    header: true,
                    child: Text(
                      "Contact Number",
                      style: TextStyle(
                        fontSize: themeProvider.fontSize + 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "09XXXXXXXXX",
                    style: TextStyle(fontSize: themeProvider.fontSize + 4),
                  ),

                  _buildDivider(themeProvider),

                  // Email
                  Semantics(
                    header: true,
                    child: Text(
                      "Email",
                      style: TextStyle(
                        fontSize: themeProvider.fontSize + 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "support@solari.com",
                    style: TextStyle(fontSize: themeProvider.fontSize + 4),
                  ),

                  _buildDivider(themeProvider),

                  // Feedback
                  Semantics(
                    header: true,
                    child: Text(
                      "Feedback",
                      style: TextStyle(
                        fontSize: themeProvider.fontSize + 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    maxLines: 5,
                    style: TextStyle(
                      fontSize: themeProvider.fontSize + 4,
                      color: Colors.black,
                    ),
                    cursorColor: themeProvider.dividerColor,
                    onTap: () {
                      VibrationService.mediumFeedback(); // Add medium vibration when text field is tapped
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: themeProvider.dividerColor,
                          width: 3,
                        ),
                      ),
                      hintText: "Enter your feedback here",
                      hintStyle: TextStyle(
                        fontSize: themeProvider.fontSize + 4,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    label: "Save",
                    icon: Icons.send,
                    fontSize: themeProvider.fontSize + 8,
                    labelAlignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 50),
                    enableVibration:
                        false, // Disable built-in vibration since we handle it in onPressed
                    onPressed: () {
                      VibrationService.mediumFeedback(); // Add medium vibration when feedback is submitted
                      // Show custom message dialog
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: Container(
                            width: 400, // Standard dialog width
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: themeProvider.primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Thank You!',
                                  style: TextStyle(
                                    fontSize: themeProvider.fontSize + 8,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.labelColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Feedback submitted successfully.',
                                  style: TextStyle(
                                    fontSize: themeProvider.fontSize + 4,
                                    color: themeProvider.labelColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                TextButton(
                                  onPressed: () {
                                    VibrationService.lightFeedback();
                                    Navigator.of(context).pop();
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: themeProvider.labelColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 12,
                                    ),
                                    minimumSize: const Size(200, 48), // Standard button size
                                  ),
                                  child: Text(
                                    'OK',
                                    style: TextStyle(
                                      fontSize: themeProvider.fontSize + 4,
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeProvider themeProvider) => Column(
        children: [
          const SizedBox(height: 20),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: themeProvider.dividerColor,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
}
