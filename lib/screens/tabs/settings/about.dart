import 'package:flutter/material.dart';

import '../../../widgets/app_bar.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'About',
        showBackButton: true,
      ),
      body: const Center(
        child: Text('About this app.'),
      ),
    );
  }
}
