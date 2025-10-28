import 'dart:async';

// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Screens
import 'bluetooth_off_screen.dart';
import 'scan_screen.dart';

// Routes
import '../../core/routes/app_routes.dart';

/// Screen that handles Bluetooth state routing logic
class BluetoothRouterScreen extends StatefulWidget {
  const BluetoothRouterScreen({super.key});

  @override
  State<BluetoothRouterScreen> createState() => _BluetoothRouterScreenState();
}

// This class is the state class for the BluetoothRouterScreen widget that monitors the device's Bluetooth state and updates the UI. It shows ScanScreen if Bluetooth is on, otherwise BluetoothOffScreen. It listens for changes with a stream subscription and cleans up when the widget is removed.
class _BluetoothRouterScreenState extends State<BluetoothRouterScreen> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  // Solari service UUID to identify Solari devices
  final String _solariServiceUUID = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';

  // Initialize state and start listening to Bluetooth state changes
  @override
  void initState() {
    super.initState();
    _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((
      state,
    ) {
      _adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });

    // Check for already connected Solari devices
    _checkForConnectedSolariDevice();
  }

  // Clean up the subscription when the widget is disposed
  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }

  // Check if there's already a connected Solari device
  void _checkForConnectedSolariDevice() async {
    List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;

    for (BluetoothDevice device in connectedDevices) {
      if (device.isConnected) {
        try {
          // Discover services to check for Solari service UUID
          List<BluetoothService> services = await device.discoverServices();
          bool hasSolariService = services.any(
            (service) =>
                service.uuid.str.toLowerCase() ==
                _solariServiceUUID.toLowerCase(),
          );

          if (hasSolariService) {
            // Navigate to Solari screen with the connected device
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.solari,
                arguments: device,
              );
            }
            break;
          }
        } catch (e) {
          // If we can't discover services, skip this device
          continue;
        }
      }
    }
  }

  // Build the UI based on the current Bluetooth state and connection status
  @override
  Widget build(BuildContext context) {
    if (_adapterState != BluetoothAdapterState.on) {
      // Show BluetoothOffScreen if Bluetooth is off
      return BluetoothOffScreen(adapterState: _adapterState);
    } else {
      // Show ScanScreen if Bluetooth is on
      // (If connected to Solari device, navigation happens in _checkForConnectedSolariDevice)
      return const ScanScreen();
    }
  }
}