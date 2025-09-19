import 'package:flutter/material.dart';

class PreferencePage extends StatelessWidget {
  const PreferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preference')),
      body: const Center(
        child: Text('Preference settings will appear here.'),
      ),
    );
  }
}
