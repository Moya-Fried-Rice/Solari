import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// A simple audio player widget for debugging raw audio data
/// This widget creates a temporary WAV file from raw audio data and plays it
class DebugAudioPlayer extends StatefulWidget {
  final Uint8List audioData;
  final String label;

  const DebugAudioPlayer({
    super.key,
    required this.audioData,
    this.label = 'Debug Audio',
  });

  @override
  State<DebugAudioPlayer> createState() => _DebugAudioPlayerState();
}

class _DebugAudioPlayerState extends State<DebugAudioPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _tempFilePath;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _cleanupTempFile();
    super.dispose();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  Future<void> _createTempWavFile() async {
    if (_tempFilePath != null) return; // Already created

    setState(() {
      _isLoading = true;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'debug_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      final tempFile = File(path.join(tempDir.path, fileName));

      // Create a simple WAV file with the raw audio data
      // Assuming 16kHz, 16-bit mono audio (same as STT service)
      final wavData = _createWavHeader(widget.audioData, 16000, 16, 1) + widget.audioData;
      
      await tempFile.writeAsBytes(wavData);
      _tempFilePath = tempFile.path;

      debugPrint('[DebugAudioPlayer] Created temp WAV file: $_tempFilePath');
      debugPrint('[DebugAudioPlayer] Audio data size: ${widget.audioData.length} bytes');
    } catch (e) {
      debugPrint('[DebugAudioPlayer] Error creating temp WAV file: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Create a basic WAV header for the raw audio data
  Uint8List _createWavHeader(Uint8List audioData, int sampleRate, int bitsPerSample, int channels) {
    final dataSize = audioData.length;
    final fileSize = 36 + dataSize;
    final blockAlign = channels * (bitsPerSample ~/ 8);
    final byteRate = sampleRate * blockAlign;

    final header = ByteData(44);
    
    // RIFF header
    header.setUint32(0, 0x46464952, Endian.little); // "RIFF"
    header.setUint32(4, fileSize, Endian.little);
    header.setUint32(8, 0x45564157, Endian.little); // "WAVE"
    
    // fmt chunk
    header.setUint32(12, 0x20746d66, Endian.little); // "fmt "
    header.setUint32(16, 16, Endian.little); // chunk size
    header.setUint16(20, 1, Endian.little); // PCM format
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    
    // data chunk
    header.setUint32(36, 0x61746164, Endian.little); // "data"
    header.setUint32(40, dataSize, Endian.little);

    return header.buffer.asUint8List();
  }

  Future<void> _playPause() async {
    if (_tempFilePath == null) {
      await _createTempWavFile();
      if (_tempFilePath == null) return;
    }

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(_tempFilePath!));
    }
  }

  Future<void> _stop() async {
    await _audioPlayer.stop();
    setState(() {
      _position = Duration.zero;
    });
  }

  void _cleanupTempFile() {
    if (_tempFilePath != null) {
      try {
        File(_tempFilePath!).deleteSync();
        debugPrint('[DebugAudioPlayer] Cleaned up temp file: $_tempFilePath');
      } catch (e) {
        debugPrint('[DebugAudioPlayer] Error cleaning up temp file: $e');
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.audiotrack, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              Text(
                '${(widget.audioData.length / 1024).toStringAsFixed(1)} KB',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Play/Pause button
              SizedBox(
                width: 36,
                height: 36,
                child: _isLoading
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : IconButton(
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        onPressed: _playPause,
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
              ),
              const SizedBox(width: 8),
              // Stop button
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  onPressed: _stop,
                  icon: const Icon(Icons.stop),
                ),
              ),
              const SizedBox(width: 12),
              // Progress indicator
              Expanded(
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _duration.inMilliseconds > 0
                          ? _position.inMilliseconds / _duration.inMilliseconds
                          : 0.0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}