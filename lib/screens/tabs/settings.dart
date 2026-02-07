import 'package:flutter/material.dart';

import 'package:solari/screens/tabs/settings_pages/status.dart';
import 'package:solari/screens/tabs/settings_pages/editor.dart';
import 'package:solari/screens/tabs/settings_pages/about.dart';
import 'package:solari/screens/tabs/settings_pages/stt.dart';
import 'package:solari/screens/tabs/settings_pages/vision.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final List<_SettingsItem> items = [
      _SettingsItem(icon: Icons.phone_android, color: colorScheme.primary, pageBuilder: () => const StatusPage()),
      _SettingsItem(icon: Icons.tune, color: colorScheme.secondary, pageBuilder: () => const EditorPage()),
      _SettingsItem(icon: Icons.mic, color: Colors.orange, pageBuilder: () => const STTPage()),
      _SettingsItem(icon: Icons.image, color: Colors.purple, pageBuilder: () => const VisionPage()),
      _SettingsItem(icon: Icons.help_outline, color: colorScheme.tertiary, pageBuilder: () => const AboutPage()),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: ValueKey(i),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: items[i].color,
                      ),
                      child: Icon(items[i].icon, size: 72),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => items[i].pageBuilder(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (i < items.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final Color color;
  final Widget Function() pageBuilder;

  const _SettingsItem({
    required this.icon,
    required this.color,
    required this.pageBuilder,
  });
}