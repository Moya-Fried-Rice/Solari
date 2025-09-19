import 'package:flutter/material.dart';

class DeviceStatusPage extends StatelessWidget {
  const DeviceStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder for device status info
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Status'),
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
