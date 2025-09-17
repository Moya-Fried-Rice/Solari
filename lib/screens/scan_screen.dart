import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:location/location.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/snackbar.dart';
import '../utils/extra.dart';
import 'solari_main.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/app_strings.dart';
import '../widgets/button_onboarding.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}


class _ScanScreenState extends State<ScanScreen> {
  BluetoothDevice? _solariDevice;
  bool _isScanning = false;
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
      if (mounted) setState(() => _isScanning = state);
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
      bool needsLocation = true;

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

      setState(() => _solariDevice = null);

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
        .then((_) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => SolariScreen(device: device),
            settings: const RouteSettings(name: '/SolariScreen'),
          ));
        });
  }

  @override
  Widget build(BuildContext context) {
    // final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    String status;
    if (_isScanning) {
      status = AppStrings.scanningLabel;
    } else if (_solariDevice != null) {
      status = AppStrings.deviceFoundLabel;
    } else {
      status = AppStrings.noDeviceLabel;
    }

    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [

              // Centered text and icon in available space
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
                          Colors.white,
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
                )
              ),


              // Bottom-aligned onboarding buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_solariDevice != null)
                    OnboardingButton(
                      label: AppStrings.connectButtonLabel,
                      onPressed: () => onConnectPressed(_solariDevice!),
                      height: 200,
                      backgroundColor: Theme.of(context).primaryColor,
                      textColor: Colors.black,
                    ),
                  if (!_isScanning && _solariDevice == null)
                    OnboardingButton(
                      label: AppStrings.scanAgainButtonLabel,
                      onPressed: _startSolariDeviceScan,
                      height: 200,
                      backgroundColor: Theme.of(context).primaryColor,
                      textColor: Colors.black,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
