import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../widgets/widgets.dart';
import '../../core/services/services.dart';

class SolariTab extends StatefulWidget {
  final double? temperature;
  final bool speaking;
  final bool processing;
  final Uint8List? image;
  final bool downloadingModel;
  final double? downloadProgress;
  final VoidCallback? onVqaStart;
  final VoidCallback? onVqaEnd;
  final BluetoothService? targetService;
  final bool isMockMode;

  const SolariTab({
    super.key,
    this.temperature,
    required this.speaking,
    required this.processing,
    this.image,
    this.downloadingModel = false,
    this.downloadProgress,
    this.onVqaStart,
    this.onVqaEnd,
    this.targetService,
    this.isMockMode = false,
  });

  @override
  State<SolariTab> createState() => _SolariTabState();
}

class _SolariTabState extends State<SolariTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Long press state for VQA control
  bool _isLongPressing = false;
  BluetoothCharacteristic? _vqaCharacteristic;

  // Don't set context in initState - let the tab switching handle it
  // This prevents setting context when tab is built but not visible

  @override
  void initState() {
    super.initState();
    _findVqaCharacteristic();
  }

  // Find the VQA characteristic for sending commands
  void _findVqaCharacteristic() {
    if (widget.targetService == null || widget.isMockMode) return;
    
    const vqaUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
    
    for (var characteristic in widget.targetService!.characteristics) {
      if (characteristic.uuid.toString().toLowerCase() == vqaUuid) {
        _vqaCharacteristic = characteristic;
        debugPrint('🔍 VQA characteristic found for long-press control');
        break;
      }
    }
  }

  // Send VQA command to the main board
  Future<void> _sendVqaCommand(String command) async {
    if (widget.isMockMode) {
      debugPrint('📱 MOCK MODE: Would send VQA command: $command');
      return;
    }

    if (_vqaCharacteristic == null) {
      debugPrint('⚠️ VQA characteristic not found, cannot send command: $command');
      return;
    }

    try {
      final data = command.codeUnits;
      await _vqaCharacteristic!.write(data);
      debugPrint('📡 Sent VQA command to main board: $command');
    } catch (e) {
      debugPrint('❌ Error sending VQA command: $e');
    }
  }

  // Handle long press start - send VQA_START
  void _onLongPressStart() {
    if (_isLongPressing) return; // Prevent duplicate calls
    
    setState(() {
      _isLongPressing = true;
    });
    
    debugPrint('🔥 Long press started - sending VQA_START');
    _sendVqaCommand('VQA_START');
    
    // Trigger haptic feedback
    VibrationService.lightFeedback();
  }

  // Handle long press end - send VQA_STOP (actually VQA_END based on Arduino code)
  void _onLongPressEnd() {
    if (!_isLongPressing) return; // Prevent duplicate calls
    
    setState(() {
      _isLongPressing = false;
    });
    
    debugPrint('🛑 Long press ended - sending VQA_END');
    _sendVqaCommand('VQA_END');
    
    // Trigger haptic feedback
    VibrationService.lightFeedback();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: ScreenReaderGestureDetector(
        child: GestureDetector(
          onLongPressStart: (_) => _onLongPressStart(),
          onLongPressEnd: (_) => _onLongPressEnd(),
          onLongPressCancel: () => _onLongPressEnd(),
          child: Stack(
            children: [
              // Centered soundwave or donut progress
              Center(
                child: ScreenReaderFocusable(
                  context: 'solari_tab',
                  label: widget.processing 
                      ? 'Processing' 
                      : widget.speaking 
                          ? 'Speaking' 
                          : widget.downloadingModel 
                              ? 'Downloading model, ${((widget.downloadProgress ?? 0) * 100).toInt()} percent complete'
                              : _isLongPressing 
                                  ? 'VQA recording in progress - release to stop'
                                  : 'Solari is ready - long press to start VQA',
                  hint: _isLongPressing 
                      ? 'Recording audio and will capture image when released'
                      : 'Long press and hold to start VQA recording',
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      return SizedBox(
                        width: width,
                        height: 360, // Increased height for more noticeable sound wave
                        child: (widget.downloadingModel && (widget.downloadProgress ?? 0) < 1.0)
                            ? _DonutProgress(progress: widget.downloadProgress, size: width, color: theme.primaryColor)
                            : AnimatedSoundWave(
                                speaking: widget.speaking, 
                                processing: widget.processing || _isLongPressing, 
                                color: _isLongPressing ? Colors.red : theme.primaryColor
                              ),
                      );
                    },
                  ),
                ),
              ),
          // Small image in top right corner
          if (widget.image != null)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  border: Border.all(color: theme.primaryColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    widget.image!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          // Temperature at the very bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: ScreenReaderFocusable(
                context: 'solari_tab',
                label: widget.temperature != null
                    ? 'Temperature: ${widget.temperature!.toStringAsFixed(1)} degrees Celsius'
                    : 'No temperature data',
                hint: 'Current temperature reading',
                child: (widget.temperature != null)
                    ? Text('Temperature: ${widget.temperature!.toStringAsFixed(1)} °C', style: const TextStyle(fontSize: 24))
                    : const Text('No temperature data.', style: TextStyle(fontSize: 24)),
              ),
            ),
          ),
            
          // Long press indicator overlay
          if (_isLongPressing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mic,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Recording VQA...',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Release to stop and capture image',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
      ),
    );
  }
}

class _DonutProgress extends StatelessWidget {
  final double? progress;
  final double size;
  final Color color;
  const _DonutProgress({this.progress, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: 360,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size * 0.7,
            height: size * 0.7,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 18,
              backgroundColor: color.withOpacity(0.2),
              color: color,
            ),
          ),
          Text(
            progress != null ? '${((progress ?? 0) * 100).toInt()}%' : '',
            style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

/// Animated widget for the sound wave
class AnimatedSoundWave extends StatefulWidget {
  final bool speaking;
  final bool processing;
  final Color color;
  const AnimatedSoundWave({Key? key, required this.speaking, required this.processing, required this.color}) : super(key: key);

  @override
  State<AnimatedSoundWave> createState() => AnimatedSoundWaveState();
}

class AnimatedSoundWaveState extends State<AnimatedSoundWave> with SingleTickerProviderStateMixin {

  @override
  void didUpdateWidget(covariant AnimatedSoundWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.speaking || widget.processing) && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.speaking && !widget.processing && _controller.isAnimating) {
      _controller.stop();
    }
  }
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.speaking || widget.processing) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.processing && !widget.speaking) {
      // Show pulsing sphere while processing and not speaking
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double scale = 1.1 + 0.3 * math.sin(_controller.value * 2 * math.pi); // Larger and more pronounced
          return Center(
            child: Container(
              width: 160 * scale,
              height: 160 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.4),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.7),
                    blurRadius: 24 * scale,
                    spreadRadius: 5 * scale,
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // Show animated sound waves
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          double progress = 0.0;
          bool flat = false;
          if (widget.speaking) {
            progress = _controller.value;
            flat = false;
          } else {
            progress = 0.0;
            flat = true;
          }
          return CustomPaint(
            painter: SoundWavePainter(progress, flat: flat, color: widget.color),
          );
        },
      );
    }
  }
}

/// Custom painter that draws animated sound waves
class SoundWavePainter extends CustomPainter {
  /// Animation progress value (0.0 to 1.0)
  final double progress;
  /// If true, draw a flat wave
  final bool flat;
  /// Color of the sound wave
  final Color color;

  /// Creates a sound wave painter
  SoundWavePainter(this.progress, {this.flat = false, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 20.0
        ..strokeCap = StrokeCap.round;

    final midY = size.height / 2;
      final waveCount = 10;
  final amplitude = flat ? 0.0 : size.height * 0.4;
    final phase = progress * 2 * math.pi;

    final barAreaWidth = size.width * 0.7;
    final startX = (size.width - barAreaWidth) / 2;
    for (int i = 0; i < waveCount; i++) {
      final x = startX + i * (barAreaWidth / (waveCount - 1));
      final yOffset = math.sin(phase + i * 0.5) * amplitude;
      final y = midY + yOffset;
      canvas.drawLine(Offset(x, midY), Offset(x, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant SoundWavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.flat != flat || oldDelegate.color != color;
}
