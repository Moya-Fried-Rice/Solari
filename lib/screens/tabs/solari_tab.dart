import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class SolariTab extends StatelessWidget {
  final double? temperature;
  final bool speaking;
  final bool processing;
  final Uint8List? image;

  const SolariTab({Key? key, this.temperature, required this.speaking, required this.processing, this.image}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Centered soundwave, full width
          Center(
            child: SizedBox(
              height: 60,
              width: MediaQuery.of(context).size.width,
              child: AnimatedSoundWave(speaking: speaking, processing: processing),
            ),
          ),
          // Small image in top right corner
          if (image != null)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepOrange, width: 2),
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
                    image!,
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
              child: (temperature != null)
                  ? Text('Temperature: ${temperature!.toStringAsFixed(1)} °C', style: const TextStyle(fontSize: 24))
                  : const Text('No temperature data.', style: TextStyle(fontSize: 24)),
            ),
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
  const AnimatedSoundWave({Key? key, required this.speaking, required this.processing}) : super(key: key);

  @override
  State<AnimatedSoundWave> createState() => AnimatedSoundWaveState();
}

class AnimatedSoundWaveState extends State<AnimatedSoundWave> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(covariant AnimatedSoundWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.speaking || widget.processing) && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.speaking && !widget.processing && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double progress = 0.0;
        bool flat = false;
        if (widget.speaking) {
          progress = _controller.value;
          flat = false;
        } else if (widget.processing) {
          progress = _controller.value * 0.25; // subtle, slow movement
          flat = false;
        } else {
          progress = 0.0;
          flat = true;
        }
        return CustomPaint(
          painter: SoundWavePainter(progress, flat: flat),
        );
      },
    );
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
  SoundWavePainter(this.progress, {this.flat = false, this.color = Colors.deepOrange});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final midY = size.height / 2;
    final waveCount = 32;
    final amplitude = flat ? 0.0 : size.height * 0.4;
    final phase = progress * 2 * math.pi;

    for (int i = 0; i < waveCount; i++) {
      final x = i * (size.width / (waveCount - 1));
      // vary phase across the bars so it looks like a flowing wave
      final yOffset = math.sin(phase + i * 0.5) * amplitude;
      final y = midY + yOffset;
      canvas.drawLine(Offset(x, midY), Offset(x, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant SoundWavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.flat != flat || oldDelegate.color != color;
}
