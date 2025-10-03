import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Service that handles BLE communication with the connected device
class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  bool _isInitialized = false;

  /// Initialize the BLE service with a connected device
  Future<void> initialize(BluetoothDevice device) async {
    if (_isInitialized && _connectedDevice == device) return;

    try {
      _connectedDevice = device;
      await _discoverWriteCharacteristic();
      _isInitialized = true;
      debugPrint('BleService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing BleService: $e');
      throw Exception('Failed to initialize BleService: $e');
    }
  }

  /// Discover the speaker write characteristic for sending audio data
  Future<void> _discoverWriteCharacteristic() async {
    if (_connectedDevice == null) return;

    const serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
    const speakerCharacteristicUuid = '12345678-1234-1234-1234-123456789abc';

    try {
      debugPrint('🔍 Discovering services for speaker characteristic...');
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      debugPrint('Found ${services.length} services');
      
      for (var service in services) {
        debugPrint('  Service: ${service.uuid}');
        if (service.uuid.toString().toLowerCase() == serviceUuid) {
          debugPrint('  ✅ Found target service!');
          debugPrint('  Characteristics in service: ${service.characteristics.length}');
          for (var characteristic in service.characteristics) {
            debugPrint('    Characteristic: ${characteristic.uuid}');
            debugPrint('      Properties: write=${characteristic.properties.write}, writeWithoutResponse=${characteristic.properties.writeWithoutResponse}');
            if (characteristic.uuid.toString().toLowerCase() == speakerCharacteristicUuid &&
                (characteristic.properties.write || characteristic.properties.writeWithoutResponse)) {
              _writeCharacteristic = characteristic;
              debugPrint('  ✅ Found speaker characteristic: ${characteristic.uuid}');
              return;
            }
          }
        }
      }
      
      if (_writeCharacteristic == null) {
        debugPrint('❌ Speaker characteristic not found!');
        debugPrint('Expected UUID: $speakerCharacteristicUuid');
        throw Exception('Speaker characteristic not found');
      }
    } catch (e) {
      debugPrint('Error discovering speaker characteristic: $e');
      rethrow;
    }
  }

  /// Send audio data to the connected BLE device
  Future<void> sendAudioData(
    Uint8List audioData, {
    Function()? onStart,
    Function()? onComplete,
    Function(String error)? onError,
    Function(int sent, int total)? onProgress,
  }) async {
    if (!_isInitialized) {
      onError?.call('BLE service not initialized');
      return;
    }

    if (_writeCharacteristic == null) {
      onError?.call('Write characteristic not available');
      return;
    }

    if (_connectedDevice?.isConnected != true) {
      onError?.call('Device not connected');
      return;
    }

    try {
      onStart?.call();
      debugPrint('Starting audio data transmission: ${audioData.length} bytes');

      // Determine if we should use writeWithoutResponse or write
      bool useWriteWithoutResponse = _writeCharacteristic!.properties.writeWithoutResponse && 
                                   !_writeCharacteristic!.properties.write;
      debugPrint('Using write method: ${useWriteWithoutResponse ? "writeWithoutResponse" : "write"}');

      // Send audio start header
      String audioHeader = "S_START:${audioData.length}";
      await _writeCharacteristic!.write(audioHeader.codeUnits, withoutResponse: useWriteWithoutResponse);
      await Future.delayed(const Duration(milliseconds: 50));
      debugPrint('Audio header sent: $audioHeader');

      // Get MTU size for chunking (subtract some bytes for BLE overhead)
      int mtu = await _connectedDevice!.mtu.first;
      int chunkSize = mtu - 3; // Leave some room for BLE overhead
      debugPrint('Using chunk size: $chunkSize bytes (MTU: $mtu)');

      // Send audio data in chunks
      int totalSent = 0;
      for (int i = 0; i < audioData.length; i += chunkSize) {
        int endIndex = (i + chunkSize < audioData.length) ? i + chunkSize : audioData.length;
        Uint8List chunk = audioData.sublist(i, endIndex);
        
        await _writeCharacteristic!.write(chunk, withoutResponse: useWriteWithoutResponse);
        totalSent += chunk.length;
        
        onProgress?.call(totalSent, audioData.length);
        
        // Minimal delay - Arduino can handle the throughput
        // await Future.delayed(const Duration(milliseconds: 1));

        // Check if device is still connected
        if (_connectedDevice?.isConnected != true) {
          throw Exception('Device disconnected during transmission');
        }
      }

      // Send audio end header
      String audioEndHeader = "S_END";
      await _writeCharacteristic!.write(audioEndHeader.codeUnits, withoutResponse: useWriteWithoutResponse);
      debugPrint('Audio end header sent');

      debugPrint('Audio data transmission complete: $totalSent bytes sent');
      onComplete?.call();

    } catch (e) {
      debugPrint('Error sending audio data: $e');
      onError?.call(e.toString());
    }
  }

  /// Send a text command to the connected BLE device
  Future<void> sendCommand(String command) async {
    if (!_isInitialized) {
      debugPrint('BLE service not initialized');
      return;
    }

    if (_writeCharacteristic == null) {
      debugPrint('Write characteristic not available');
      return;
    }

    if (_connectedDevice?.isConnected != true) {
      debugPrint('Device not connected');
      return;
    }

    try {
      await _writeCharacteristic!.write(command.codeUnits, withoutResponse: false);
      debugPrint('Command sent: $command');
    } catch (e) {
      debugPrint('Error sending command: $e');
    }
  }

  /// Check if the service is ready to send data
  bool get isReady {
    bool ready = _isInitialized && 
                 _writeCharacteristic != null && 
                 _connectedDevice?.isConnected == true;
    debugPrint('🔍 BLE Service Ready Check:');
    debugPrint('  _isInitialized: $_isInitialized');
    debugPrint('  _writeCharacteristic != null: ${_writeCharacteristic != null}');
    debugPrint('  _connectedDevice?.isConnected: ${_connectedDevice?.isConnected}');
    debugPrint('  Overall ready: $ready');
    return ready;
  }

  /// Get the connected device
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Dispose of resources
  void dispose() {
    _connectedDevice = null;
    _writeCharacteristic = null;
    _isInitialized = false;
    debugPrint('BleService disposed');
  }
}