import 'package:flutter/material.dart';

import '../../../widgets/app_bar.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Help',
        showBackButton: true,
      ),
      body: const Center(
        child: Text('Help information will appear here.'),
      ),
    );
  }
}
