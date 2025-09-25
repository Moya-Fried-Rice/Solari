import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Service for handling audio streaming to the device
class AudioService {
  static const String _serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String _characteristicUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
  
  /// Send audio file to device with smooth transmission
  static Future<bool> sendAudioFile({
    required BluetoothDevice device,
    required String assetPath,
    required Function(double progress) onProgress,
    required Function(String status) onStatus,
    int chunkSize = 180, // Optimized for BLE MTU
    int delayMs = 25, // Smooth transmission delay
  }) async {
    try {
      onStatus('Connecting to device...');
      
      // Discover services and find the target characteristic
      List<BluetoothService> services = await device.discoverServices();
      BluetoothCharacteristic? targetCharacteristic;
      
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == _serviceUuid.toLowerCase()) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == _characteristicUuid.toLowerCase()) {
              targetCharacteristic = characteristic;
              break;
            }
          }
          break;
        }
      }
      
      if (targetCharacteristic == null) {
        onStatus('Error: Could not find BLE characteristic');
        return false;
      }
      
      // Get MTU and optimize chunk size
      int mtu = await device.mtu.first;
      int optimizedChunkSize = (mtu - 3).clamp(20, chunkSize); // 3 bytes for ATT header
      debugPrint('[AudioService] Device MTU: $mtu, optimized chunk size: $optimizedChunkSize');
      
      onStatus('Loading audio file...');
      
      // Load audio file from assets
      ByteData audioData = await rootBundle.load(assetPath);
      Uint8List audioBytes = audioData.buffer.asUint8List();
      
      debugPrint('[AudioService] Loaded audio file: ${audioBytes.length} bytes');
      onStatus('Starting audio transmission...');
      
      // Send start command
      await targetCharacteristic.write(
        Uint8List.fromList('AUDIO_START'.codeUnits),
        withoutResponse: true,
      );
      await Future.delayed(Duration(milliseconds: delayMs));
      
      // Send audio data in chunks using optimized chunk size
      int totalChunks = (audioBytes.length / optimizedChunkSize).ceil();
      for (int i = 0; i < audioBytes.length; i += optimizedChunkSize) {
        int end = (i + optimizedChunkSize < audioBytes.length) ? i + optimizedChunkSize : audioBytes.length;
        Uint8List chunk = audioBytes.sublist(i, end);
        
        // Create chunk with header - ensure we don't exceed MTU
        String header = 'AUDIO_DATA';
        List<int> headerBytes = header.codeUnits;
        
        // If chunk + header exceeds MTU, split the chunk
        if (chunk.length + headerBytes.length > optimizedChunkSize) {
          int maxChunkSize = optimizedChunkSize - headerBytes.length;
          chunk = chunk.sublist(0, maxChunkSize);
        }
        
        List<int> chunkWithHeader = headerBytes + chunk;
        
        await targetCharacteristic.write(
          Uint8List.fromList(chunkWithHeader),
          withoutResponse: true,
        );
        
        // Update progress
        double progress = (i + optimizedChunkSize) / audioBytes.length;
        if (progress > 1.0) progress = 1.0;
        onProgress(progress);
        
        int chunkNumber = (i / optimizedChunkSize).floor() + 1;
        onStatus('Sending chunk $chunkNumber/$totalChunks (${(progress * 100).toInt()}%)');
        
        // Adaptive delay based on chunk size for smooth transmission
        int adaptiveDelay = (delayMs * (chunkWithHeader.length / optimizedChunkSize)).round();
        await Future.delayed(Duration(milliseconds: adaptiveDelay));
        
        debugPrint('[AudioService] Sent chunk $chunkNumber/$totalChunks: ${chunk.length} bytes');
      }
      
      // Send end command
      await targetCharacteristic.write(
        Uint8List.fromList('AUDIO_END'.codeUnits),
        withoutResponse: true,
      );
      
      onStatus('Audio transmission complete!');
      onProgress(1.0);
      debugPrint('[AudioService] Audio transmission completed successfully');
      
      return true;
    } catch (e) {
      debugPrint('[AudioService] Error sending audio: $e');
      onStatus('Error: $e');
      return false;
    }
  }
  
  /// Send test audio pattern (generated sine wave)
  static Future<bool> sendTestAudio({
    required BluetoothDevice device,
    required Function(double progress) onProgress,
    required Function(String status) onStatus,
    int durationSeconds = 3,
    int sampleRate = 8000,
    int chunkSize = 200,
    int delayMs = 15,
  }) async {
    try {
      onStatus('Generating test audio...');
      
      // Generate a simple sine wave
      List<int> audioData = [];
      int totalSamples = sampleRate * durationSeconds;
      double frequency = 440.0; // A4 note
      
      for (int i = 0; i < totalSamples; i++) {
        double t = i / sampleRate;
        double sample = 0.3 * Math.sin(2 * Math.pi * frequency * t); // 30% volume
        int intSample = (sample * 32767).round(); // Convert to 16-bit signed
        
        // Convert to little-endian bytes
        audioData.add(intSample & 0xFF);
        audioData.add((intSample >> 8) & 0xFF);
      }
      
      Uint8List audioBytes = Uint8List.fromList(audioData);
      
      // Use the same transmission logic as sendAudioFile
      return await _sendAudioBytes(
        device: device,
        audioBytes: audioBytes,
        onProgress: onProgress,
        onStatus: onStatus,
        chunkSize: chunkSize,
        delayMs: delayMs,
      );
    } catch (e) {
      debugPrint('[AudioService] Error sending test audio: $e');
      onStatus('Error: $e');
      return false;
    }
  }
  
  /// Internal method to send audio bytes
  static Future<bool> _sendAudioBytes({
    required BluetoothDevice device,
    required Uint8List audioBytes,
    required Function(double progress) onProgress,
    required Function(String status) onStatus,
    int chunkSize = 200,
    int delayMs = 15,
  }) async {
    try {
      onStatus('Finding BLE characteristic...');
      
      List<BluetoothService> services = await device.discoverServices();
      BluetoothCharacteristic? targetCharacteristic;
      
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == _serviceUuid.toLowerCase()) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == _characteristicUuid.toLowerCase()) {
              targetCharacteristic = characteristic;
              break;
            }
          }
          break;
        }
      }
      
      if (targetCharacteristic == null) {
        onStatus('Error: Could not find BLE characteristic');
        return false;
      }
      
      // Get MTU and optimize chunk size
      int mtu = await device.mtu.first;
      int optimizedChunkSize = (mtu - 3).clamp(20, chunkSize); // 3 bytes for ATT header
      debugPrint('[AudioService] Found characteristic, MTU: $mtu, sending ${audioBytes.length} bytes');
      onStatus('Starting transmission...');
      
      // Send start command
      await targetCharacteristic.write(
        Uint8List.fromList('AUDIO_START'.codeUnits),
        withoutResponse: true,
      );
      await Future.delayed(Duration(milliseconds: delayMs));
      
      // Send audio data in chunks using optimized chunk size
      int totalChunks = (audioBytes.length / optimizedChunkSize).ceil();
      for (int i = 0; i < audioBytes.length; i += optimizedChunkSize) {
        int end = (i + optimizedChunkSize < audioBytes.length) ? i + optimizedChunkSize : audioBytes.length;
        Uint8List chunk = audioBytes.sublist(i, end);
        
        // Create chunk with header - ensure we don't exceed MTU
        String header = 'AUDIO_DATA';
        List<int> headerBytes = header.codeUnits;
        
        // If chunk + header exceeds MTU, split the chunk
        if (chunk.length + headerBytes.length > optimizedChunkSize) {
          int maxChunkSize = optimizedChunkSize - headerBytes.length;
          chunk = chunk.sublist(0, maxChunkSize);
        }
        
        List<int> chunkWithHeader = headerBytes + chunk;
        
        await targetCharacteristic.write(
          Uint8List.fromList(chunkWithHeader),
          withoutResponse: true,
        );
        
        // Update progress
        double progress = (i + optimizedChunkSize) / audioBytes.length;
        if (progress > 1.0) progress = 1.0;
        onProgress(progress);
        
        int chunkNumber = (i / optimizedChunkSize).floor() + 1;
        onStatus('Chunk $chunkNumber/$totalChunks (${(progress * 100).toInt()}%)');
        
        // Adaptive delay for smooth transmission
        int adaptiveDelay = (delayMs * (chunkWithHeader.length / optimizedChunkSize)).round();
        await Future.delayed(Duration(milliseconds: adaptiveDelay));
      }
      
      // Send end command
      await targetCharacteristic.write(
        Uint8List.fromList('AUDIO_END'.codeUnits),
        withoutResponse: true,
      );
      
      onStatus('Transmission complete!');
      onProgress(1.0);
      
      return true;
    } catch (e) {
      debugPrint('[AudioService] Error in _sendAudioBytes: $e');
      onStatus('Error: $e');
      return false;
    }
  }
}
