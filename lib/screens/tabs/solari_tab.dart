import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class SolariTab extends StatefulWidget {
  final double? temperature;
  final bool speaking;
  final bool processing;
  final Uint8List? image;
  final bool downloadingModel;
  final double? downloadProgress;
  final VoidCallback? onVqaStart;
  final VoidCallback? onVqaEnd;

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
  });

  @override
  State<SolariTab> createState() => _SolariTabState();
}

class _SolariTabState extends State<SolariTab> {
  bool _isVqaActive = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: GestureDetector(
        onLongPressStart: (_) {
          // Start VQA when user holds down
          setState(() {
            _isVqaActive = true;
          });
          widget.onVqaStart?.call();
        },
        onLongPressEnd: (_) {
          // End VQA when user releases
          setState(() {
            _isVqaActive = false;
          });
          widget.onVqaEnd?.call();
        },
        child: Stack(
          children: [
            // VQA active indicator overlay
            if (_isVqaActive)
              Container(
                color: theme.primaryColor.withOpacity(0.1),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'VQA Recording...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            // Centered soundwave or donut progress
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return SizedBox(
                    width: width,
                    height: 360, // Increased height for more noticeable sound wave
                    child: (widget.downloadingModel && (widget.downloadProgress ?? 0) < 1.0)
                        ? _DonutProgress(progress: widget.downloadProgress, size: width, color: theme.primaryColor)
                        : AnimatedSoundWave(speaking: widget.speaking, processing: widget.processing || _isVqaActive, color: theme.primaryColor),
                  );
                },
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
            // VQA instruction hint
            if (!_isVqaActive)
              Positioned(
                left: 0,
                right: 0,
                bottom: 100,
                child: Center(
                  child: Text(
                    'Hold screen to start VQA',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.primaryColor.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
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
                child: (widget.temperature != null)
                    ? Text('Temperature: ${widget.temperature!.toStringAsFixed(1)} °C', style: const TextStyle(fontSize: 24))
                    : const Text('No temperature data.', style: TextStyle(fontSize: 24)),
              ),
            ),
          ],
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
