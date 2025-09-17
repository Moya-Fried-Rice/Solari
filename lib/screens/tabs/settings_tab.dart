import 'package:flutter/material.dart';


import '../../widgets/settings_button.dart';
import 'package:provider/provider.dart';
import '../../core/providers/theme_provider.dart';

class SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Define your settings items here
    final List<Map<String, dynamic>> items = [
      {
        'label': 'Connection',
      },
      {
        'label': 'Preference',
      },
      {
        'label': 'Help',
      },
      {
        'label': 'About',
      },
      {
        'label': 'Terms of Use',
      },
      {
        'label': 'Disconnect',
      },
    ];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              SizedBox(height: 32),

              for (var i = 0; i < items.length; i++) ...[
                CustomButton(
                  label: items[i]["label"] as String,
                  fontSize: themeProvider.fontSize,
                  labelAlignment: Alignment.center,
                  enableVibration: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 20,
                  ),
                ),

                SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
