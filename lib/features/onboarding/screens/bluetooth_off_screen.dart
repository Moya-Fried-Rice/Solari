import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../utils/snackbar.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/constants/app_strings.dart';

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({super.key, this.adapterState});
  final BluetoothAdapterState? adapterState;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenSize.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bluetooth,
                    size: 200,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.bluetoothOffLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: AppConstants.titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 50),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    child: SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: CustomButton(
                        label: AppStrings.enableButtonLabel,
                        fontSize: 52,
                        labelAlignment: Alignment.center,
                        onPressed: () async {
                          try {
                            await FlutterBluePlus.turnOn();
                          } catch (e, backtrace) {
                            Snackbar.show(
                              ABC.a,
                              prettyException("Error Turning On:", e),
                              success: false,
                            );
                            print("$e");
                            print("backtrace: $backtrace");
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
