import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../widgets/app_bar.dart';

class DeviceStatusPage extends StatelessWidget {
  const DeviceStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    // App bar
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Device Status',
        showBackButton: true,
      ),

      
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.devices, size: 80, color: Colors.blueGrey),
            SizedBox(height: 24),
            Text(
              'Connected Device Status',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Device is connected and functioning properly.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),




    );
  }
}
