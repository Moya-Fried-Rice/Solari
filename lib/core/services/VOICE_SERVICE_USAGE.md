# Voice Services Usage Guide

## Overview
The STT and TTS services now support **dual-mode operation**:
- **Hardware Mode**: Arduino smart glasses with BLE (microphone/speaker via BLE)
- **Mobile Mode**: Phone/tablet built-in microphone and speaker

This allows development and testing without hardware.

---

## TTS Service (Text-to-Speech)

### Basic Usage

```dart
final ttsService = TtsService();

// Initialize
await ttsService.initialize();

// Speak text (uses current mode)
await ttsService.speakText("Hello, world!");
```

### Mode Switching

```dart
// Use mobile device speaker
ttsService.setLocalPlayback(true);
await ttsService.speakText("Playing on phone speaker");

// Use hardware (BLE smart glasses)
ttsService.setLocalPlayback(false);
await ttsService.speakText("Playing on smart glasses");
```

### Check Status

```dart
final info = ttsService.getEngineInfo();
print('Output: ${info['output']}'); // "Mobile Device Speaker" or "BLE Smart Glasses"
print('Engine: ${info['engine']}'); // "Sherpa ONNX VITS-Piper"
print('Sample Rate: ${info['sampleRate']}'); // "22050Hz"
```

---

## STT Service (Speech-to-Text)

### Basic Usage

```dart
final sttService = SttService();

// Initialize
await sttService.initialize();

// Set up callbacks
sttService.onResult = (finalText) {
  print('Final: $finalText');
};

sttService.onPartialResult = (partialText) {
  print('Partial: $partialText');
};

sttService.onError = (error) {
  print('Error: $error');
};

// Start listening (uses current mode)
await sttService.startListening();

// Stop listening
await sttService.stopListening();
```

### Mode Switching

#### Mobile Device Mode

```dart
// Enable mobile mode (uses phone microphone + on-device speech recognition)
sttService.setMobileMode(true);

// Initialize mobile STT
await sttService.initializeMobile();

// Check on-device availability
final available = await sttService.isMobileOnDeviceAvailable();
if (!available) {
  print('On-device speech recognition not available');
}

// Check/request microphone permission
final hasPermission = await sttService.hasMicrophonePermission();
if (!hasPermission) {
  final granted = await sttService.requestMicrophonePermission();
  if (!granted) {
    print('Microphone permission denied');
    return;
  }
}

// Start listening with mobile device
await sttService.startMobileListening(
  listenFor: Duration(seconds: 5),  // Listen for 5 seconds
  pauseFor: Duration(seconds: 3),   // Stop after 3 seconds of silence
);

// Stop mobile listening
await sttService.stopMobileListening();

// Cancel mobile listening (discards results)
await sttService.cancelMobileListening();
```

#### Hardware Mode

```dart
// Enable hardware mode (uses Arduino mic + BLE + Sherpa ONNX)
sttService.setMobileMode(false);

// Initialize hardware STT
await sttService.initialize();

// Process audio from BLE (called when audio data arrives)
sttService.processAudioChunk(audioData); // Float32List from BLE

// Start/stop recording
await sttService.startListening();
await sttService.stopListening();
```

### Reactive Listeners

The STT service extends `ChangeNotifier`, so you can listen to state changes:

```dart
sttService.addListener(() {
  print('Listening: ${sttService.isListening}');
  print('Text: ${sttService.recognizedText}');
});
```

### Punctuation Enhancement

Both modes support automatic punctuation:

```dart
// Enable punctuation enhancement
sttService.setPunctuationEnhancement(true);

// Now "hello world" becomes "Hello world."
// And "what is your name" becomes "What is your name?"
```

### Check Status

```dart
final info = sttService.getServiceInfo();
print('Mode: ${info['mode']}');           // "Mobile Device" or "Hardware (BLE)"
print('Initialized: ${info['initialized']}');
print('Listening: ${info['listening']}');
print('Engine: ${info['engine']}');       // "Device Speech Recognition" or "Sherpa ONNX"
print('Model: ${info['modelType']}');     // "On-Device" or "zipformer2-gigaspeech"
print('Offline: ${info['offline']}');     // true
```

---

## Voice Assist Service Integration

The `VoiceAssistService` already uses both services. To enable mobile mode:

```dart
final voiceAssist = VoiceAssistService();

// Initialize (loads both services)
await voiceAssist.initialize();

// Enable mobile mode for development/testing
final sttService = SttService();
final ttsService = TtsService();

sttService.setMobileMode(true);
ttsService.setLocalPlayback(true);

await sttService.initializeMobile();

// Now voice commands use phone mic/speaker instead of hardware
```

---

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'core/services/stt_service.dart';
import 'core/services/tts_service.dart';

class VoiceTestScreen extends StatefulWidget {
  @override
  _VoiceTestScreenState createState() => _VoiceTestScreenState();
}

class _VoiceTestScreenState extends State<VoiceTestScreen> {
  final sttService = SttService();
  final ttsService = TtsService();
  
  String _transcription = '';
  bool _useMobileMode = true;
  
  @override
  void initState() {
    super.initState();
    _initVoice();
  }
  
  Future<void> _initVoice() async {
    // Initialize services
    await ttsService.initialize();
    
    if (_useMobileMode) {
      // Mobile mode setup
      sttService.setMobileMode(true);
      ttsService.setLocalPlayback(true);
      await sttService.initializeMobile();
    } else {
      // Hardware mode setup
      sttService.setMobileMode(false);
      ttsService.setLocalPlayback(false);
      await sttService.initialize();
    }
    
    // Set up STT callbacks
    sttService.onResult = (text) {
      setState(() => _transcription = text);
      ttsService.speakText('You said: $text');
    };
    
    sttService.onError = (error) {
      debugPrint('STT Error: $error');
    };
  }
  
  Future<void> _startListening() async {
    if (_useMobileMode) {
      await sttService.startMobileListening();
    } else {
      await sttService.startListening();
    }
  }
  
  Future<void> _stopListening() async {
    if (_useMobileMode) {
      await sttService.stopMobileListening();
    } else {
      await sttService.stopListening();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Voice Test')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Transcription: $_transcription'),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _startListening,
            child: Text('Start Listening'),
          ),
          ElevatedButton(
            onPressed: _stopListening,
            child: Text('Stop Listening'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    sttService.dispose();
    ttsService.dispose();
    super.dispose();
  }
}
```

---

## Key Points

1. **Offline First**: Both modes work offline
   - Mobile: Uses on-device speech recognition
   - Hardware: Uses Sherpa ONNX neural models

2. **Mode Switching**: Can switch modes at runtime
   - No reinitialization needed for TTS
   - STT requires calling `initializeMobile()` or `initialize()` after switching

3. **Permissions**: Mobile mode requires microphone permission
   - Check: `hasMicrophonePermission()`
   - Request: `requestMicrophonePermission()`

4. **Reactive**: STT extends ChangeNotifier
   - Use `addListener()` for state changes
   - Or use callbacks (onResult, onPartialResult, etc.)

5. **Punctuation**: Available in both modes
   - Improves VLM prompt quality
   - Enable with `setPunctuationEnhancement(true)`
