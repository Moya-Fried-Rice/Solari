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

  /// Discover the write characteristic for sending data
  Future<void> _discoverWriteCharacteristic() async {
    if (_connectedDevice == null) return;

    const serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
    const characteristicUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

    try {
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == characteristicUuid &&
                characteristic.properties.write) {
              _writeCharacteristic = characteristic;
              debugPrint('Found write characteristic: ${characteristic.uuid}');
              return;
            }
          }
        }
      }
      
      if (_writeCharacteristic == null) {
        throw Exception('Write characteristic not found');
      }
    } catch (e) {
      debugPrint('Error discovering write characteristic: $e');
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

      // Send audio start header
      String audioHeader = "S_START:${audioData.length}";
      await _writeCharacteristic!.write(audioHeader.codeUnits, withoutResponse: false);
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
        
        await _writeCharacteristic!.write(chunk, withoutResponse: true);
        totalSent += chunk.length;
        
        onProgress?.call(totalSent, audioData.length);
        
        // Small delay between chunks to prevent overwhelming the device
        await Future.delayed(const Duration(milliseconds: 5));

        // Check if device is still connected
        if (_connectedDevice?.isConnected != true) {
          throw Exception('Device disconnected during transmission');
        }
      }

      // Send audio end header
      String audioEndHeader = "S_END";
      await _writeCharacteristic!.write(audioEndHeader.codeUnits, withoutResponse: false);
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
  bool get isReady => _isInitialized && 
                     _writeCharacteristic != null && 
                     _connectedDevice?.isConnected == true;

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