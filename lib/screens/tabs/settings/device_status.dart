import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/device_info_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/audio_service.dart';
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

  // Audio streaming state
  bool _isStreamingAudio = false;
  double _audioProgress = 0.0;
  String _audioStatus = '';

  late DeviceInfoProvider _deviceInfoProvider;
  
  // Audio streaming state
  bool _isStreamingAudio = false;
  double _streamingProgress = 0.0;
  String _streamingStatus = '';

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

  // Audio streaming methods
  Future<void> _sendWavesAudio() async {
    if (_isStreamingAudio) return;

    setState(() {
      _isStreamingAudio = true;
      _audioProgress = 0.0;
      _audioStatus = 'Preparing...';
    });

    bool success = await AudioService.sendAudioFile(
      device: widget.device,
      assetPath: 'assets/audio/waves.wav',
      onProgress: (progress) {
        setState(() {
          _audioProgress = progress;
        });
      },
      onStatus: (status) {
        setState(() {
          _audioStatus = status;
        });
      },
      chunkSize: 180, // Smaller chunks for smoother transmission
      delayMs: 25,    // Slightly more delay for stability
    );

    // Show completion message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? 'Audio transmission completed successfully!' 
            : 'Audio transmission failed. Please try again.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }

    setState(() {
      _isStreamingAudio = false;
      if (success) {
        _audioProgress = 1.0;
        _audioStatus = 'Complete!';
      }
    });

    // Reset status after 3 seconds
    if (success) {
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _audioProgress = 0.0;
            _audioStatus = '';
          });
        }
      });
    }
  }

  Future<void> _sendTestAudio() async {
    if (_isStreamingAudio) return;

    setState(() {
      _isStreamingAudio = true;
      _audioProgress = 0.0;
      _audioStatus = 'Generating test audio...';
    });

    bool success = await AudioService.sendTestAudio(
      device: widget.device,
      onProgress: (progress) {
        setState(() {
          _audioProgress = progress;
        });
      },
      onStatus: (status) {
        setState(() {
          _audioStatus = status;
        });
      },
      durationSeconds: 2, // 2-second test tone
      chunkSize: 180,
      delayMs: 25,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? 'Test audio transmission completed!' 
            : 'Test audio transmission failed.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }

    setState(() {
      _isStreamingAudio = false;
      if (success) {
        _audioProgress = 1.0;
        _audioStatus = 'Test complete!';
      }
    });

    if (success) {
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _audioProgress = 0.0;
            _audioStatus = '';
          });
        }
      });
    }
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

                        // Audio Streaming Section
                        Text(
                          "Audio Streaming",
                          style: TextStyle(
                            fontSize: theme.fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        // Progress indicator when streaming
                        if (_isStreamingAudio) ...[
                          LinearProgressIndicator(
                            value: _audioProgress,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _audioStatus,
                            style: TextStyle(
                              fontSize: theme.fontSize - 4,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 15),
                        ],
                        
                        // Audio streaming buttons
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                label: _isStreamingAudio ? 'Streaming...' : 'Send Waves Audio',
                                fontSize: theme.fontSize - 2,
                                labelAlignment: Alignment.center,
                                enableVibration: !_isStreamingAudio,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 15,
                                ),
                                onPressed: _isStreamingAudio ? null : _sendWavesAudio,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CustomButton(
                                label: _isStreamingAudio ? 'Streaming...' : 'Send Test Tone',
                                fontSize: theme.fontSize - 2,
                                labelAlignment: Alignment.center,
                                enableVibration: !_isStreamingAudio,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 15,
                                ),
                                onPressed: _isStreamingAudio ? null : _sendTestAudio,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // Audio info text
                        Text(
                          "Send audio samples to your device for testing. The waves audio is from assets, while the test tone is generated.",
                          style: TextStyle(
                            fontSize: theme.fontSize - 6,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
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

  /// Send audio file to device
  Future<void> _sendAudioFile(String assetPath) async {
    if (_isStreamingAudio) return;
    
    setState(() {
      _isStreamingAudio = true;
      _streamingProgress = 0.0;
      _streamingStatus = 'Preparing...';
    });

    try {
      bool success = await AudioService.sendAudioFile(
        device: widget.device,
        assetPath: assetPath,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _streamingProgress = progress;
            });
          }
        },
        onStatus: (status) {
          if (mounted) {
            setState(() {
              _streamingStatus = status;
            });
          }
        },
        chunkSize: 180, // Smaller chunks for smoother transmission
        delayMs: 25,    // Slightly more delay for stability
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Audio sent successfully!' : 'Failed to send audio'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStreamingAudio = false;
          _streamingProgress = 0.0;
          _streamingStatus = '';
        });
      }
    }
  }

  /// Send test audio (generated sine wave)
  Future<void> _sendTestAudio() async {
    if (_isStreamingAudio) return;
    
    setState(() {
      _isStreamingAudio = true;
      _streamingProgress = 0.0;
      _streamingStatus = 'Generating test audio...';
    });

    try {
      bool success = await AudioService.sendTestAudio(
        device: widget.device,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _streamingProgress = progress;
            });
          }
        },
        onStatus: (status) {
          if (mounted) {
            setState(() {
              _streamingStatus = status;
            });
          }
        },
        durationSeconds: 2, // 2 second test tone
        chunkSize: 180,
        delayMs: 20,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Test audio sent successfully!' : 'Failed to send test audio'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending test audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStreamingAudio = false;
          _streamingProgress = 0.0;
          _streamingStatus = '';
        });
      }
    }
  }
}
