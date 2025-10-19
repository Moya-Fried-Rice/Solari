import 'dart:async';

import 'package:flutter/material.dart';
import '../../../widgets/select_to_speak_text.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/device_info_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/screen_reader_service.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/screen_reader_gesture_detector.dart';
import '../../../widgets/screen_reader_focusable.dart';

class DeviceStatusPage extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceStatusPage({super.key, required this.device});

  @override
  State<DeviceStatusPage> createState() => _DeviceStatusPageState();
}

class _DeviceStatusPageState extends State<DeviceStatusPage> {
  bool _showDeviceInfo = false;
  StreamSubscription<BluetoothConnectionState>? _stateSub;

  late DeviceInfoProvider _deviceInfoProvider;

  @override
  void initState() {
    super.initState();

    _deviceInfoProvider = DeviceInfoProvider(widget.device);
    _deviceInfoProvider.fetchDeviceInfo();
    
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

  /// Helper method to get text shadows for high contrast mode
  List<Shadow>? _getTextShadows(ThemeProvider theme) {
    if (!theme.isHighContrast) return null;
    final shadowColor = theme.isDarkMode ? Colors.white : Colors.black;
    return [
      Shadow(offset: const Offset(0, -1), blurRadius: 3.0, color: shadowColor),
      Shadow(offset: const Offset(0, 1), blurRadius: 3.0, color: shadowColor),
      Shadow(offset: const Offset(-1, 0), blurRadius: 3.0, color: shadowColor),
      Shadow(offset: const Offset(1, 0), blurRadius: 3.0, color: shadowColor),
    ];
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
        child: ChangeNotifierProvider<DeviceInfoProvider>.value(
          value: _deviceInfoProvider,
          child: Consumer<DeviceInfoProvider>(
            builder: (context, info, _) {
              if (info.isFetching) {
                return const Center(child: CircularProgressIndicator());
              }
              return SafeArea(
                child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        80,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Device Status
                        ScreenReaderFocusable(
                          context: 'device_status',
                          label: 'Device connection status',
                          hint: info.isConnected ? "Device is connected" : "Device is disconnected",
                          child: Builder(
                            builder: (context) {
                              final statusColor = info.isConnected ? Colors.green : Colors.red;
                              return SelectToSpeakText(
                                info.isConnected ? "Connected" : "Disconnected",
                                style: TextStyle(
                                  fontSize: theme.fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                  shadows: theme.isHighContrast ? [
                                    Shadow(offset: const Offset(0, -1), blurRadius: 5.0, color: statusColor),
                                    Shadow(offset: const Offset(0, 1), blurRadius: 5.0, color: statusColor),
                                    Shadow(offset: const Offset(-1, 0), blurRadius: 5.0, color: statusColor),
                                    Shadow(offset: const Offset(1, 0), blurRadius: 5.0, color: statusColor),
                                  ] : null,
                                ),
                              );
                            },
                          ),
                        ),

                        _buildDivider(theme),

                        // Battery Life (placeholder, as in reference)
                        ScreenReaderFocusable(
                          context: 'device_status',
                          label: 'Battery life section',
                          hint: 'Shows device battery level at 100 percent',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: SelectToSpeakText(
                                  "Battery Life",
                                  style: TextStyle(
                                    fontSize: theme.fontSize,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                    shadows: _getTextShadows(theme),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              Center(
                                child: SelectToSpeakText(
                                  "100%", // Placeholder
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: theme.fontSize + 20,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textColor,
                                    shadows: _getTextShadows(theme),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        _buildDivider(theme),

                        // Device Info Section (Show button)
                        ScreenReaderFocusable(
                          context: 'device_status',
                          label: 'Device information',
                          hint: 'Double tap to ${_showDeviceInfo ? "hide" : "show"} device details',
                          onTap: () {
                            setState(() {
                              _showDeviceInfo = !_showDeviceInfo;
                            });
                          },
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _showDeviceInfo = !_showDeviceInfo;
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SelectToSpeakText(
                                  "Device Info",
                                  style: TextStyle(
                                    fontSize: theme.fontSize,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                    shadows: _getTextShadows(theme),
                                  ),
                                ),
                                FaIcon(
                                  _showDeviceInfo
                                      ? FontAwesomeIcons.caretDown
                                      : FontAwesomeIcons.caretRight,
                                  size: 32,
                                  color: theme.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_showDeviceInfo)
                          ScreenReaderFocusable(
                            context: 'device_status',
                            label: 'Device details',
                            hint: 'Device ID ${info.id ?? "unknown"}, Name ${info.name ?? "unknown"}, MTU ${info.mtu ?? "unknown"}, RSSI ${info.rssi ?? "unknown"}, ${info.services?.length ?? 0} services',
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectToSpeakText(
                                    "Device ID:  ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: theme.fontSize,
                                      color: theme.buttonTextColor,
                                      shadows: _getTextShadows(theme),
                                    ),
                                  ),
                                  SelectToSpeakText(
                                    info.id ?? "-",
                                    style: TextStyle(
                                      fontSize: theme.fontSize,
                                      color: theme.buttonTextColor,
                                      shadows: _getTextShadows(theme),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SelectToSpeakText(
                                    "Device Name:  ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: theme.fontSize,
                                      color: theme.buttonTextColor,
                                      shadows: _getTextShadows(theme),
                                    ),
                                  ),
                                  SelectToSpeakText(
                                    info.name ?? "-",
                                    style: TextStyle(
                                      fontSize: theme.fontSize,
                                      color: theme.buttonTextColor,
                                      shadows: _getTextShadows(theme),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SelectToSpeakText(
                                    "MTU:  ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: theme.fontSize,
                                      color: theme.buttonTextColor,
                                      shadows: _getTextShadows(theme),
                                    ),
                                  ),
                                  SelectToSpeakText(
                                    "${info.mtu ?? "-"}",
                                    style: TextStyle(
                                      fontSize: theme.fontSize,
                                      color: theme.buttonTextColor,
                                      shadows: _getTextShadows(theme),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SelectToSpeakText(
                                    "RSSI:  ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: theme.fontSize,
                                      color: theme.buttonTextColor,
                                      shadows: _getTextShadows(theme),
                                    ),
                                  ),
                                  SelectToSpeakText(
                                    "${info.rssi ?? "-"}",
                                    style: TextStyle(
                                      fontSize: theme.fontSize,
                                      color: theme.buttonTextColor,
                                      shadows: _getTextShadows(theme),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SelectToSpeakText(
                                    "Services:  ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: theme.fontSize,
                                      color: theme.buttonTextColor,
                                      shadows: _getTextShadows(theme),
                                    ),
                                  ),
                                  SelectToSpeakText(
                                    "${info.services?.length ?? 0}",
                                    style: TextStyle(
                                      fontSize: theme.fontSize,
                                      color: theme.buttonTextColor,
                                      shadows: _getTextShadows(theme),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        _buildDivider(theme),

                        // Disconnect Section Title
                        ScreenReaderFocusable(
                          context: 'device_status',
                          label: 'Disconnect device section',
                          hint: 'Contains disconnect button',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectToSpeakText(
                                "Disconnect Device",
                                style: TextStyle(
                                  fontSize: theme.fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColor,
                                  shadows: _getTextShadows(theme),
                                ),
                              ),
                              const SizedBox(height: 15),
                              Center(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ScreenReaderFocusable(
                                    context: 'device_status',
                                    label: 'Disconnect button',
                                    hint: 'Double tap to disconnect device and return to previous screen',
                                    onTap: () async {
                                      final navigator = Navigator.of(context);
                                      await widget.device.disconnect();
                                      if (mounted) navigator.pop();
                                    },
                                    child: CustomButton(
                                      label: 'Disconnect',
                                      fontSize: theme.fontSize,
                                      labelAlignment: Alignment.center,
                                      enableVibration: false,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 20,
                                      ),
                                      onPressed: () async {
                                        final navigator = Navigator.of(context);
                                        await widget.device.disconnect();
                                        if (mounted) navigator.pop();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
    );
  }

  Widget _buildDivider(ThemeProvider theme) => Column(
    children: [
      const SizedBox(height: 20),
      Container(
        height: 10,
        decoration: BoxDecoration(
          color: theme.dividerColor,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
}

