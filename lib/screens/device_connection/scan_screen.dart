import 'dart:async';
import 'dart:io' show Platform;

// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:location/location.dart';
import 'package:flutter_svg/flutter_svg.dart';

// UI and state management
import '../../utils/helpers.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/user_preferences_service.dart';
import '../../widgets/widgets.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}


class _ScanScreenState extends State<ScanScreen> {
  BluetoothDevice? _solariDevice;
  bool _isScanning = false;
  bool _hasStartedFirstScan = false; // Track if we've ever started scanning
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  final String _solariServiceUUID = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';

  @override
  void initState() {
    super.initState();
    // Always reset device when entering scan screen
    _solariDevice = null;

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen(
      (results) {
        if (mounted) {
          for (ScanResult result in results) {
            if (result.advertisementData.serviceUuids.any(
              (uuid) =>
                  uuid.str.toLowerCase() == _solariServiceUUID.toLowerCase(),
            )) {
              setState(() => _solariDevice = result.device);
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
        setState(() {
          _isScanning = state;
          // Mark that we've started scanning when we first see scanning = true
          if (state) {
            _hasStartedFirstScan = true;
          }
        });
      }
    });

    _startSolariDeviceScan();
  }


  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future _startSolariDeviceScan() async {
    try {
      // Always stop previous scan before starting a new one
      await FlutterBluePlus.stopScan();
      await Future.delayed(const Duration(milliseconds: 300));

      bool needsLocation = true;

      // Check if location services and permissions are needed (Android only)
      if (Platform.isAndroid) {
        try {
          final versionString = Platform.operatingSystemVersion;
          final versionMatch = RegExp(r'\d+').firstMatch(versionString);
          final version = versionMatch != null ? int.parse(versionMatch.group(0)!) : 0;
          needsLocation = version < 12;
        } catch (_) {
          needsLocation = true;
        }
      }

      // Request location services and permissions if needed
      if (needsLocation) {
        Location location = Location();
        bool serviceEnabled = await location.serviceEnabled();
        if (!serviceEnabled) serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          Snackbar.show(
            ABC.b,
            "Location services are required for BLE scanning.",
            success: false,
          );
          return;
        }

        // Check location permission
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

      // Reset any previously found device
      setState(() {
        _solariDevice = null;
        // Don't reset _hasStartedFirstScan here - let the subscription handle it
      });

      // Restart scan fresh
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        withServices: [Guid(_solariServiceUUID)],
      );
      
      // No need for delays - the subscription will handle state changes
    } catch (e, backtrace) {
      // No need to reset any initialization state - let the normal flow handle it
      Snackbar.show(
        ABC.b,
        prettyException("Solari Device Scan Error:", e),
        success: false,
      );
      debugPrint("$e");
      debugPrint("backtrace: $backtrace");
    }
  }


  Future _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e, backtrace) {
      Snackbar.show(
        ABC.b,
        prettyException("Stop Scan Error:", e),
        success: false,
      );
      debugPrint("$e");
      debugPrint("backtrace: $backtrace");
    }
  }

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
        .then((_) async {
          // Mark device connection as completed
          await PreferencesService.setDeviceConnectionCompleted();
          
          Navigator.of(context).pushNamed(
            AppRoutes.solari,
            arguments: device,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    String status;
    if (!_hasStartedFirstScan) {
      status = 'Initializing...';
    } else if (_isScanning) {
      status = 'Scanning for Solari...';
    } else if (_solariDevice != null) {
      status = 'Solari Found!';
    } else {
      status = 'Unable to locate Solari';
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                children: [
                  // Centered text and icon
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/glasses.svg',
                            width: 200,
                            height: 200,
                            colorFilter: ColorFilter.mode(
                              isDarkMode ? Colors.white : Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            status,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: AppConstants.titleFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom-aligned connection buttons
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_solariDevice != null)
                        ConnectionButton(
                          label: 'Connect',
                          onPressed: () => onConnectPressed(_solariDevice!),
                          height: 200,
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                      if (!_isScanning && _hasStartedFirstScan && _solariDevice == null)
                        ConnectionButton(
                          label: 'Retry',
                          onPressed: () {
                            setState(() => _hasStartedFirstScan = false);
                            _startSolariDeviceScan();
                          },
                          height: 200,
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Small bypass button on top-left (force SolariScreen with mock device)
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.bolt, size: 28),
                tooltip: "Bypass to SolariScreen",
                onPressed: () async {
                  // stop scanning before navigating
                  await _stopScan();

                  // Mark device connection as completed for development purposes
                  await PreferencesService.setDeviceConnectionCompleted();

                  // Use existing connected/found device if available, otherwise a fake one
                  final deviceToUse = _solariDevice ??
                      BluetoothDevice(
                        remoteId: const DeviceIdentifier('00:11:22:33:44:55'), // Fake MAC
                      );

                  Navigator.of(context).pushNamed(
                    AppRoutes.solari,
                    arguments: {
                      'device': deviceToUse,
                      'isMock': true, // Enable mock mode for bypass
                    },
                  );
                },
              ),
            ),

            // Refresh/Scan again button on top-right
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  _isScanning ? Icons.stop : Icons.refresh,
                  size: 28,
                  color: _isScanning ? Colors.red : null,
                ),
                tooltip: _isScanning ? "Stop scanning" : "Scan again",
                onPressed: _isScanning
                    ? () async {
                        await _stopScan();
                      }
                    : () {
                        setState(() => _hasStartedFirstScan = false);
                        _startSolariDeviceScan();
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}