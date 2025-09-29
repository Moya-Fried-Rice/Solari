import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/device_info_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/speaker_service.dart';
import '../../../widgets/app_bar.dart';
import '../../../widgets/settings_button.dart';

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
  }

  @override
  void dispose() {
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
      ),
      body: ChangeNotifierProvider<DeviceInfoProvider>.value(
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
                    minHeight: MediaQuery.of(context).size.height - kToolbarHeight - 80,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Device Status
                        Text(
                          info.isConnected ? "Connected" : "Disconnected",
                          style: TextStyle(
                            fontSize: theme.fontSize,
                            fontWeight: FontWeight.bold,
                            color: info.isConnected ? Colors.green : Colors.red,
                          ),
                        ),

                        _buildDivider(theme),

                        // Battery Life (placeholder, as in reference)
                        Semantics(
                          header: true,
                          child: Text(
                            "Battery Life",
                            style: TextStyle(
                              fontSize: theme.fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Center(
                          child: Text(
                            "100%", // Placeholder
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: theme.fontSize + 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        _buildDivider(theme),

                        // Device Info Section (Show button)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showDeviceInfo = !_showDeviceInfo;
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Device Info",
                                style: TextStyle(
                                  fontSize: theme.fontSize,
                                  fontWeight: FontWeight.bold,
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
                        if (_showDeviceInfo)
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Device ID:  ",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: theme.fontSize),
                                  ),
                                  Text(
                                    info.id ?? "-",
                                    style: TextStyle(fontSize: theme.fontSize),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Device Name:  ",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: theme.fontSize),
                                  ),
                                  Text(
                                    info.name ?? "-",
                                    style: TextStyle(fontSize: theme.fontSize),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "MTU:  ",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: theme.fontSize),
                                  ),
                                  Text(
                                    "${info.mtu ?? "-"}",
                                    style: TextStyle(fontSize: theme.fontSize),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "RSSI:  ",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: theme.fontSize),
                                  ),
                                  Text(
                                    "${info.rssi ?? "-"}",
                                    style: TextStyle(fontSize: theme.fontSize),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Services:  ",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: theme.fontSize),
                                  ),
                                  Text(
                                    "${info.services?.length ?? 0}",
                                    style: TextStyle(fontSize: theme.fontSize),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        _buildDivider(theme),

                        // Disconnect Section Title
                        Text(
                          "Disconnect Device",
                          style: TextStyle(
                            fontSize: theme.fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Center(
                          child: SizedBox(
                            width: double.infinity,
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
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
