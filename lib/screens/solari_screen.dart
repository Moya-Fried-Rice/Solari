import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// REMOVE PLAYBACK
// import 'dart:convert'; // for ascii encoding, removed
// import 'package:audioplayers/audioplayers.dart';
// REMOVE PLAYBACK

class SolariScreen extends StatefulWidget {
  final BluetoothDevice device;

  const SolariScreen({Key? key, required this.device}) : super(key: key);

  @override
  State<SolariScreen> createState() => _SolariScreenState();
}

class _SolariScreenState extends State<SolariScreen> {

  final List<int> _audioBuffer = [];
  bool _audioStreaming = false;
  bool _negotiating = false;
  BluetoothService? _targetService;
  List<BluetoothCharacteristic> _subscribedCharacteristics = [];



  Uint8List? _receivedImage;
  int _expectedImageSize = 0;
  final List<int> _imageBuffer = [];
  bool _receivingImage = false;



  @override
  void initState() {
    super.initState();
    _requestMtu();
    _subscribeToService();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _subscribeToService() async {
    const serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
    try {
      List<BluetoothService> services = await widget.device.discoverServices();
      for (var s in services) {
        if (s.uuid.toString().toLowerCase() == serviceUuid) {
          _targetService = s;
          break;
        }
      }

      if (_targetService != null) {
        for (var characteristic in _targetService!.characteristics) {
          if (characteristic.properties.notify) {
            await characteristic.setNotifyValue(true);
            _subscribedCharacteristics.add(characteristic);

            characteristic.lastValueStream.listen((value) {
              _handleIncomingData(value);
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error subscribing: $e");
    }
  }

  void _handleIncomingData(List<int> value) {
    if (value.isEmpty) return;

    String asString = String.fromCharCodes(value);


    if (asString.startsWith("VQA_START")) {
      debugPrint("VQA session started");
      _imageBuffer.clear();
      _audioBuffer.clear();
      _receivedImage = null;
      _receivingImage = false;
      _audioStreaming = false;
      setState(() {});
      return;
    }



    if (asString.startsWith("A_START")) {
      debugPrint("Audio streaming started");
      _audioStreaming = true;
      _audioBuffer.clear();
      return;
    }

    if (asString.startsWith("A_END")) {
      debugPrint("Audio streaming ended");
      _audioStreaming = false;
      setState(() {});
      return;
    }

    if (asString.startsWith("I:")) {
      // Image header with size
      _expectedImageSize = int.tryParse(asString.split(":")[1]) ?? 0;
      debugPrint("Image incoming, expected size: $_expectedImageSize bytes");
      _imageBuffer.clear();
      _receivingImage = true;
      return;
    }

    if (asString.startsWith("I_END")) {
      debugPrint("Image received: ${_imageBuffer.length} bytes");
      _receivingImage = false;
      setState(() {
        _receivedImage = Uint8List.fromList(_imageBuffer);
      });
      return;
    }

    if (asString.startsWith("VQA_END")) {
      debugPrint("VQA session ended");
      return;
    }

    // --- OTHERWISE THIS IS BINARY DATA ---
    if (_audioStreaming) {
      _audioBuffer.addAll(value);
    } else if (_receivingImage) {
      _imageBuffer.addAll(value);
    }
  }



  Future<void> _requestMtu() async {
    setState(() {
      _negotiating = true;
    });
    try {
      int mtu = await widget.device.requestMtu(517);
      debugPrint("MTU negotiated: $mtu");
    } catch (e) {
      debugPrint("MTU request failed: $e");
    } finally {
      setState(() {
        _negotiating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.device_hub, size: 64),
            const SizedBox(height: 16),
            Text(
              'Connected to: ${widget.device.platformName}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (_negotiating)
              const Text('Negotiating MTU...', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            if (_receivedImage != null) ...[
              Image.memory(_receivedImage!, height: 200, fit: BoxFit.contain),
              const SizedBox(height: 8),
              Text('Image size: ${_receivedImage!.lengthInBytes} bytes', style: TextStyle(fontSize: 16)),
              Text('Audio size: ${_audioBuffer.length} bytes', style: TextStyle(fontSize: 16)),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Disconnect'),
              onPressed: () async {
                await widget.device.disconnect();
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
