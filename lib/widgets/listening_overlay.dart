import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/theme_provider.dart';
import '../core/services/voice_assist_service.dart';

/// Overlay shown when voice assist is listening
class ListeningOverlay extends StatelessWidget {
  const ListeningOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final voiceAssist = VoiceAssistService();

    return ListenableBuilder(
      listenable: voiceAssist,
      builder: (context, child) {
        if (!voiceAssist.isListening) {
          return const SizedBox.shrink();
        }

        return Container(
          color: Colors.black54,
          child: Center(
            child: Card(
              color: theme.isDarkMode ? Colors.grey[900] : Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated microphone icon
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (value * 0.2),
                          child: Icon(
                            Icons.mic,
                            size: 64,
                            color: Colors.red[400],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Listening text
                    Text(
                      'Listening...',
                      style: TextStyle(
                        fontSize: theme.fontSize + 6,
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Waveform animation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: _WaveformBar(
                            delay: Duration(milliseconds: index * 100),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    
                    // Cancel button
                    TextButton.icon(
                      onPressed: () {
                        voiceAssist.stopListening();
                      },
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: theme.fontSize + 2,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Animated waveform bar for listening visual feedback
class _WaveformBar extends StatefulWidget {
  final Duration delay;

  const _WaveformBar({required this.delay});

  @override
  State<_WaveformBar> createState() => _WaveformBarState();
}

class _WaveformBarState extends State<_WaveformBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 10.0, end: 40.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 4,
          height: _animation.value,
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
