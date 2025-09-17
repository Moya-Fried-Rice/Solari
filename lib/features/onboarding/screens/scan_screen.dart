import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:location/location.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../utils/snackbar.dart';
import '../../../utils/extra.dart';
import '../../chat/screens/solari_main.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
// import '../../../core/navigation/navigation_service.dart';
import '../../../shared/widgets/custom_button.dart';
// import '../../../features/chat/screens/chat_input_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

// This class displays a screen to scan for Solari Smart Glasses using Bluetooth. It shows an icon, the current scanning status, and buttons to connect to the device or rescan. It uses streams to listen for scan results and updates the UI accordingly.
class _ScanScreenState extends State<ScanScreen> {
  BluetoothDevice? _solariDevice;
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  // Solari service UUID
  final String _solariServiceUUID = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';

  // Initialize state and start scanning for Solari devices
  @override
  void initState() {
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen(
      (results) {
        if (mounted) {
          // Look for the Solari Smart Glasses device
          for (ScanResult result in results) {
            if (result.advertisementData.serviceUuids.any(
              (uuid) =>
                  uuid.str.toLowerCase() == _solariServiceUUID.toLowerCase(),
            )) {
              setState(() => _solariDevice = result.device);
              // Stop scanning once device is found
              _stopScan();
              break;
            }
          }
        }
      },
      onError: (e) {
        Snackbar.show(
          ABC.b,
          prettyException("Smart Glasses Scan Error:", e),
          success: false,
        );
      },
    );

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      if (mounted) {
        setState(() => _isScanning = state);
      }
    });

    // Start scanning automatically
    _startSolariDeviceScan();
  }

  // Clean up subscriptions when the widget is disposed
  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  // Start scanning for Solari devices
  Future _startSolariDeviceScan() async {
    try {
      bool needsLocation = true;

      if (Platform.isAndroid) {
        // Parse Android version from OS string
        // Example: "11" or "12" or "12.1.0"
        try {
          final versionString = Platform.operatingSystemVersion;
          final versionMatch = RegExp(r'\d+').firstMatch(versionString);
          final version = versionMatch != null ? int.parse(versionMatch.group(0)!) : 0;

          if (version >= 12) {
            // Android 12+ (API 31+): no location permission required for BLE scan
            needsLocation = false;
          }
        } catch (_) {
          // fallback if parsing fails
          needsLocation = true;
        }
      } else if (Platform.isIOS) {
        needsLocation = true;
      }

      // If location requirement applies
      if (needsLocation) {
        Location location = Location();

        // 1. Check if location service is enabled
        bool serviceEnabled = await location.serviceEnabled();
        if (!serviceEnabled) {
          serviceEnabled = await location.requestService(); // Android shows system prompt
          if (!serviceEnabled) {
            Snackbar.show(
              ABC.b,
              "Location services are required for BLE scanning.",
              success: false,
            );
            return;
          }
        }

        // 2. Check and request location permission
        PermissionStatus permissionGranted = await location.hasPermission();
        if (permissionGranted == PermissionStatus.denied) {
          permissionGranted = await location.requestPermission();
          if (permissionGranted != PermissionStatus.granted) {
            Snackbar.show(
              ABC.b,
              "Location permission is required for BLE scanning.",
              success: false,
            );
            return;
          }
        }
      }

      // 3. Reset device state when starting new scan
      setState(() => _solariDevice = null);

      // 4. Start BLE scan
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        withServices: [Guid(_solariServiceUUID)],
      );
    } catch (e, backtrace) {
      Snackbar.show(
        ABC.b,
        prettyException("Solari Device Scan Error:", e),
        success: false,
      );
      print(e);
      print("backtrace: $backtrace");
    }
  }

  // Stop scanning for devices
  Future _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e, backtrace) {
      Snackbar.show(
        ABC.b,
        prettyException("Stop Scan Error:", e),
        success: false,
      );
      print(e);
      print("backtrace: $backtrace");
    }
  }

  // Handle connect button press
  void onConnectPressed(BluetoothDevice device) {
    device
        .connectAndUpdateStream()
        .catchError((e) {
          Snackbar.show(
            ABC.c,
            prettyException("Connect Error:", e),
            success: false,
          );
        })
        .then((_) {
          // Navigate to Solari screen after successful connection
          MaterialPageRoute route = MaterialPageRoute(
            builder: (context) => SolariScreen(device: device),
            settings: const RouteSettings(name: '/SolariScreen'),
          );
          Navigator.of(context).push(route);
        });
  }

  // Solari glasses icon
  Widget buildSolariIcon(BuildContext context, bool isDarkMode) {
    return FaIcon(
      _solariDevice != null ? FontAwesomeIcons.glasses : FontAwesomeIcons.glasses,
      size: 200,
      color: Colors.white,
    );
  }

  // Title indicating device status
  Widget buildTitle(BuildContext context) {
    String status;
    if (_isScanning) {
      status = AppStrings.scanningLabel;
    } else if (_solariDevice != null) {
      status = AppStrings.deviceFoundLabel;
    } else {
      status = AppStrings.noDeviceLabel;
    }

    return Text(
      status,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: AppConstants.titleFontSize,
            fontWeight: FontWeight.bold,
          ),
      textAlign: TextAlign.center,
    );
  }


  // Connect button
  Widget buildConnectButton(BuildContext context) {
    // Hide button if no device is found
    if (_solariDevice == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 40,
        vertical: 15,
      ),
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: CustomButton(
          label: AppStrings.connectButtonLabel,
          fontSize: 52,
          labelAlignment: Alignment.center,
          onPressed: () => onConnectPressed(_solariDevice!),
        ),
      ),
    );
  }


  // Scan button
  Widget buildScanButton(BuildContext context) {
    // Hide button while scanning or when a device is found
    if (_isScanning || _solariDevice != null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 40,
        vertical: 15,
      ),
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: CustomButton(
          label: AppStrings.scanAgainButtonLabel,
          fontSize: 52,
          labelAlignment: Alignment.center,
          onPressed: _startSolariDeviceScan,
        ),
      ),
    );
  }




  // Build the main UI
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              buildSolariIcon(context, isDarkMode),
              const SizedBox(height: 24),
              buildTitle(context),
              const SizedBox(height: 24),
              if (_solariDevice != null) buildConnectButton(context),
              const SizedBox(height: 16),
              buildScanButton(context),
            ],
          )
        ),
      ),
    );
  }
}
