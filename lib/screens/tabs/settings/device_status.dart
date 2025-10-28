import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/services.dart';
import '../../../widgets/widgets.dart';

class DeviceStatusPage extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceStatusPage({super.key, required this.device});

  @override
  State<DeviceStatusPage> createState() => _DeviceStatusPageState();
}

class _DeviceStatusPageState extends State<DeviceStatusPage> {
  StreamSubscription<BluetoothConnectionState>? _stateSub;

  @override
  void initState() {
    super.initState();
    
    // Set context for screen reader
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScreenReaderService().setActiveContext('device_status');
        // Auto-focus first element (back button) if screen reader is enabled
        if (ScreenReaderService().isEnabled) {
          Future.delayed(const Duration(milliseconds: 300), () {
            ScreenReaderService().focusNext();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    ScreenReaderService().clearContextNodes('device_status');
    _stateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Device Status', 
        showBackButton: true,
        screenReaderContext: 'device_status',
      ),
      body: ScreenReaderGestureDetector(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Battery Progress Circle
                  ScreenReaderFocusable(
                    context: 'device_status',
                    label: 'Battery level',
                    hint: '66 percent battery remaining',
                    child: SizedBox(
                      width: 350,
                      height: 350,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 280,
                            height: 280,
                            child: CircularProgressIndicator(
                              value: 0.66,
                              strokeWidth: 24,
                              backgroundColor: theme.primaryColor.withOpacity(0.2),
                              color: theme.primaryColor,
                            ),
                          ),
                          SelectToSpeakText(
                            '66%',
                            style: TextStyle(
                              fontSize: theme.fontSize * 2,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Disconnect Button
                  Center(
                    child: ScreenReaderFocusable(
                      context: 'device_status',
                      label: 'Disconnect button',
                      hint: 'Double tap to disconnect device and return to previous screen',
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        await widget.device.disconnect();
                        if (mounted) navigator.pop();
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 400,
                        ),
                        child: CustomButton(
                          label: 'Disconnect',
                          icon: Icons.bluetooth_disabled,
                          fontSize: AppConstants.titleFontSize,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            await widget.device.disconnect();
                            if (mounted) navigator.pop();
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

