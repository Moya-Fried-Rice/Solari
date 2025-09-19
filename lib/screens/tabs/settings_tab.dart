import 'package:flutter/material.dart';


import '../../widgets/settings_button.dart';
import 'settings/device_status.dart';
import 'settings/preference.dart';
import 'settings/help.dart';
import 'settings/about.dart';
import 'settings/terms_of_use.dart';
import 'package:provider/provider.dart';
import '../../core/providers/theme_provider.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class SettingsTab extends StatelessWidget {
  final BluetoothDevice device;
  final VoidCallback? onDisconnect;
  const SettingsTab({super.key, required this.device, this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final List<Map<String, dynamic>> items = [
      {'label': 'Device Status'},
      {'label': 'Preferences'},
      {'label': 'Help'},
      {'label': 'About'},
      {'label': 'Terms of Use'},
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
                  onPressed: () {
                    final label = items[i]["label"];
                    if (label == 'Device Status') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeviceStatusPage(device: device),
                        ),
                      );
                    } else if (label == 'Preferences') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PreferencePage(),
                        ),
                      );
                    } else if (label == 'Help') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const HelpPage(),
                        ),
                      );
                    } else if (label == 'About') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AboutPage(),
                        ),
                      );
                    } else if (label == 'Terms of Use') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const TermsOfUsePage(),
                        ),
                      );
                    }
                  },
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
