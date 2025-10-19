import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../widgets/feature_card.dart';
import 'settings/device_status.dart';
import 'settings/preference.dart';
import 'settings/about.dart';
import 'settings/terms_of_use.dart';
import 'settings/contact.dart';
import 'settings/faqs.dart';
import 'settings/tutorials.dart';
import '../../core/providers/theme_provider.dart';
import '../../widgets/screen_reader_gesture_detector.dart';
import '../../widgets/screen_reader_focusable.dart';
import '../../core/services/screen_reader_service.dart';

class SettingsTab extends StatelessWidget {
  final BluetoothDevice device;
  final VoidCallback? onDisconnect;
  const SettingsTab({super.key, required this.device, this.onDisconnect});

  /// Restore settings tab context and auto-focus if screen reader is enabled
  void _restoreSettingsContext(BuildContext context) {
    if (context.mounted) {
      final screenReader = ScreenReaderService();
      // Force reset context even if it's the same to clear current focus
      screenReader.setActiveContext('_temp');
      screenReader.setActiveContext('settings_tab');
      // Auto-focus first element if screen reader is enabled
      if (screenReader.isEnabled) {
        // Use longer delay to ensure widgets are fully built and registered
        Future.delayed(const Duration(milliseconds: 300), () {
          screenReader.focusNext();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't set context here - let tab switching handle it
    final themeProvider = Provider.of<ThemeProvider>(context);
    final List<Map<String, dynamic>> items = [
      {'label': 'Device Status', 'icon': Icons.bluetooth},
      {'label': 'Preferences', 'icon': Icons.tune},
      {'label': 'About Solari', 'icon': Icons.info_outline},
      {'label': 'FAQs', 'icon': Icons.question_answer_outlined},
      {'label': 'Tutorials', 'icon': Icons.video_library_outlined},
      {'label': 'Contact', 'icon': Icons.support_agent},
      {'label': 'Terms of Use', 'icon': Icons.description_outlined},
    ];

    return Scaffold(
      body: ScreenReaderGestureDetector(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                
                void handleNavigation() {
                  final label = item['label'];
                  if (label == 'Device Status') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeviceStatusPage(device: device),
                      ),
                    ).then((_) => _restoreSettingsContext(context));
                  } else if (label == 'Preferences') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PreferencePage(),
                      ),
                    ).then((_) => _restoreSettingsContext(context));
                  } else if (label == 'About Solari') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AboutPage(),
                      ),
                    ).then((_) => _restoreSettingsContext(context));
                  } else if (label == 'Contact') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ContactScreen(),
                      ),
                    ).then((_) => _restoreSettingsContext(context));
                  } else if (label == 'FAQs') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FAQsScreen(),
                      ),
                    ).then((_) => _restoreSettingsContext(context));
                  } else if (label == 'Tutorials') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TutorialsScreen(),
                      ),
                    ).then((_) => _restoreSettingsContext(context));
                  } else if (label == 'Terms of Use') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TermsOfUsePage(),
                      ),
                    ).then((_) => _restoreSettingsContext(context));
                  }
                }
                
                return ScreenReaderFocusable(
                  context: 'settings_tab',
                  label: '${item['label']} button',
                  hint: 'Double tap to open ${item['label']}',
                  onTap: handleNavigation,
                  child: FeatureCard(
                    theme: themeProvider,
                    icon: item['icon'] as IconData,
                    label: item['label'] as String,
                    onTap: handleNavigation,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
