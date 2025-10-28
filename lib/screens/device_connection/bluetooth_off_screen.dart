// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// UI and state management
import '../../core/constants/app_constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/widgets.dart';


class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({super.key, this.adapterState});
  final BluetoothAdapterState? adapterState;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                      Icon(
                        Icons.bluetooth_disabled,
                        size: 200,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Bluetooth is disabled',
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

              // Bottom-aligned connection button
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConnectionButton(
                    label: 'Turn On',
                    onPressed: () async {
                      try {
                        await FlutterBluePlus.turnOn();
                      } catch (e, backtrace) {
                        Snackbar.show(
                          ABC.a,
                          prettyException("Error Turning On:", e),
                          success: false,
                        );
                        debugPrint("$e");
                        debugPrint("backtrace: $backtrace");
                      }
                    },
                    height: 200, // same height as before
                    backgroundColor: Theme.of(context).primaryColor,
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