# Mobile Mode Implementation Summary

## Overview
Both TTS and STT services now support **dual-mode operation** for development/testing without hardware:
- **Hardware Mode**: BLE communication with Arduino smart glasses
- **Mobile Mode**: Phone/tablet built-in microphone and speaker

---

## TTS Service (lib/core/services/tts_service.dart)

### Implementation Details

**New Fields:**
- `AudioPlayer _audioPlayer` - For local playback
- `bool _useLocalPlayback` - Mode flag (false = BLE, true = mobile)

**New Methods:**
- `setLocalPlayback(bool enabled)` - Switch between BLE and mobile speaker
- `Future<void> _playAudioLocally(Float32List samples)` - Play audio on mobile device
- `Uint8List _createWavFile(Float32List samples)` - Convert Float32 to WAV format
- `List<int> _intToBytes(int value)` - Little-endian byte conversion helper

**Modified Methods:**
- `speakText()` - Routes to mobile or BLE based on `_useLocalPlayback` flag
- `getEngineInfo()` - Shows current output mode
- `dispose()` - Disposes audio player

**Key Features:**
- Uses Sherpa ONNX VITS-Piper model (22050Hz) for consistent voice
- Generates WAV files from Float32List samples
- Proper WAV header with RIFF format
- 16-bit PCM audio conversion
- Seamless mode switching at runtime

---

## STT Service (lib/core/services/stt_service.dart)

### Implementation Details

**Class Changes:**
- Extended `ChangeNotifier` for reactive state updates

**New Imports:**
- `speech_to_text` package (as `stt`)
- `permission_handler` package

**New Fields:**
- `stt.SpeechToText _mobileSpeech` - Mobile speech recognition engine
- `bool _isMobileInitialized` - Mobile initialization state
- `bool _isMobileListening` - Mobile listening state
- `String _mobileRecognizedText` - Mobile transcription buffer
- `bool _useMobileMode` - Mode flag (false = hardware, true = mobile)

**Callbacks (for reactive updates):**
- `Function(String)? onResult` - Final transcription result
- `Function(String)? onPartialResult` - Partial transcription updates
- `Function(String)? onError` - Error notifications
- `VoidCallback? onListeningStart` - Listening started
- `VoidCallback? onListeningStop` - Listening stopped

**New Getters (mode-aware):**
- `bool get isInitialized` - Returns mobile or hardware state
- `bool get isListening` - Returns mobile or hardware state
- `String get recognizedText` - Returns transcription text

**New Methods:**

*Mode Switching:*
- `void setMobileMode(bool enabled)` - Switch between hardware and mobile

*Mobile Initialization:*
- `Future<bool> initializeMobile()` - Initialize speech_to_text package
- `Future<bool> isMobileOnDeviceAvailable()` - Check on-device support

*Permission Management:*
- `Future<bool> hasMicrophonePermission()` - Check permission status
- `Future<bool> requestMicrophonePermission()` - Request permission

*Mobile Listening Control:*
- `Future<void> startMobileListening({Duration? listenFor, Duration? pauseFor})` - Start device mic
- `Future<void> stopMobileListening()` - Stop listening
- `Future<void> cancelMobileListening()` - Cancel and discard results

*Internal Helpers:*
- `void _stopMobileListening()` - Update state and notify listeners
- `void _handleMobileError(String error)` - Error handling and notification

**Modified Methods:**
- `dispose()` - Added `super.dispose()` call (ChangeNotifier requirement)
- `getServiceInfo()` - Shows current mode, engine type, and status

**Key Features:**
- Uses device's built-in speech recognition (on-device mode)
- Automatic locale selection (prioritizes English)
- Partial and final result callbacks
- Automatic punctuation enhancement
- Error handling and status notifications
- Microphone permission management
- Configurable listen/pause durations

---

## Architecture Pattern

Both services follow the same dual-mode pattern:

```
┌─────────────────────────────────────────┐
│         Voice Service (TTS/STT)         │
├─────────────────────────────────────────┤
│  Mode Flag: _useLocalPlayback/_useMobileMode  │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────┐  ┌─────────────────┐ │
│  │ Hardware Mode│  │  Mobile Mode    │ │
│  ├──────────────┤  ├─────────────────┤ │
│  │ BLE Service  │  │ AudioPlayer/    │ │
│  │ + Sherpa ONNX│  │ speech_to_text  │ │
│  │ (offline)    │  │ (on-device)     │ │
│  └──────────────┘  └─────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

---

## Usage Summary

### Quick Start - Mobile Mode

```dart
// TTS
final tts = TtsService();
await tts.initialize();
tts.setLocalPlayback(true);  // Mobile speaker
await tts.speakText("Hello!");

// STT
final stt = SttService();
stt.setMobileMode(true);     // Mobile mic
await stt.initializeMobile();

stt.onResult = (text) => print('Final: $text');
stt.onPartialResult = (text) => print('Partial: $text');

await stt.startMobileListening();
```

### Quick Start - Hardware Mode

```dart
// TTS
final tts = TtsService();
await tts.initialize();
tts.setLocalPlayback(false);  // BLE smart glasses
await tts.speakText("Hello!");

// STT
final stt = SttService();
stt.setMobileMode(false);     // Arduino mic
await stt.initialize();

// Process audio from BLE
stt.processAudioChunk(audioData);
```

---

## Benefits

1. **Development**: Test without hardware
2. **Debugging**: Easier to diagnose issues
3. **Offline**: Both modes work without internet
4. **Consistent**: Same API for both modes
5. **Reactive**: STT extends ChangeNotifier
6. **Flexible**: Switch modes at runtime
7. **Permissions**: Automatic permission handling

---

## Dependencies

### Added to pubspec.yaml:
- `audioplayers` - For mobile speaker playback
- `speech_to_text` - For mobile microphone input
- `permission_handler` - For microphone permissions

### Existing:
- `sherpa_onnx` - Neural TTS/STT models
- `flutter_blue_plus` - BLE communication

---

## Testing Checklist

### TTS Service:
- [ ] Initialize service
- [ ] Switch to mobile mode
- [ ] Speak text on mobile speaker
- [ ] Switch to hardware mode
- [ ] Speak text via BLE
- [ ] Check engine info shows correct mode
- [ ] Dispose service

### STT Service:
- [ ] Initialize mobile mode
- [ ] Check microphone permission
- [ ] Start mobile listening
- [ ] Verify partial results
- [ ] Verify final results
- [ ] Test punctuation enhancement
- [ ] Stop listening
- [ ] Switch to hardware mode
- [ ] Process BLE audio chunks
- [ ] Check service info shows correct mode
- [ ] Dispose service

---

## Next Steps

1. **Integration**: Update `VoiceAssistService` to expose mode switching
2. **UI**: Add settings toggle for mobile/hardware mode
3. **Testing**: Create test screen for voice services
4. **Documentation**: Update main README with mobile mode info
5. **Models**: Ensure Sherpa ONNX models are downloaded for offline use
