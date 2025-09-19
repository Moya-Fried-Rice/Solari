
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceInfoProvider extends ChangeNotifier {
  bool _isConnected = false;

  final BluetoothDevice device;
  String? _id;
  String? _name;
  int? _mtu;
  int? _rssi;
  List<BluetoothService>? _services;
  bool _isFetching = false;

  DeviceInfoProvider(this.device);

  String? get id => _id;
  String? get name => _name;
  int? get mtu => _mtu;
  int? get rssi => _rssi;
  List<BluetoothService>? get services => _services;
  bool get isFetching => _isFetching;
  bool get isConnected => _isConnected;

  Future<void> fetchDeviceInfo() async {
    _isFetching = true;
    notifyListeners();
    try {
      _id = device.remoteId.str;
      _name = device.platformName;
      _mtu = await device.mtu.first;
      _rssi = await device.readRssi();
      _services = await device.discoverServices();
      // Listen to connection state
      device.connectionState.listen((state) {
        final connected = state == BluetoothConnectionState.connected;
        if (_isConnected != connected) {
          _isConnected = connected;
          notifyListeners();
        }
      });
      // Set initial connection state
      _isConnected = await device.connectionState.first == BluetoothConnectionState.connected;
    } catch (e) {
      debugPrint('Error fetching device info: $e');
    }
    _isFetching = false;
    notifyListeners();
  }
}
