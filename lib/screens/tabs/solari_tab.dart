import 'dart:typed_data';

import 'package:flutter/material.dart';

class SolariTab extends StatelessWidget {
  final Uint8List? image;
  final double? temperature;

  const SolariTab({Key? key, this.image, this.temperature}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image != null)
              Image.memory(image!, fit: BoxFit.contain),
            if (image == null)
              const Text('No image received.'),
            const SizedBox(height: 24),
            if (temperature != null)
              Text('Temperature: ${temperature!.toStringAsFixed(1)} °C', style: const TextStyle(fontSize: 24)),
            if (temperature == null)
              const Text('No temperature data.', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
