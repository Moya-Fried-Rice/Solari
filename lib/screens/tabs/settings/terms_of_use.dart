import 'package:flutter/material.dart';

import '../../../widgets/app_bar.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Terms of Use',
        showBackButton: true,
      ),
      body: const Center(
        child: Text('Terms of use content will appear here.'),
      ),
    );
  }
}
