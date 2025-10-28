import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/voice_assist_service.dart';
import '../core/services/vibration_service.dart';
import '../core/providers/theme_provider.dart';
import '../main.dart'; // Import for navigatorKey

/// Floating action button for voice assist
/// Shows pulsing animation when listening
class VoiceAssistButton extends StatefulWidget {
  const VoiceAssistButton({super.key});

  @override
  State<VoiceAssistButton> createState() => _VoiceAssistButtonState();
}

class _VoiceAssistButtonState extends State<VoiceAssistButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    // Safety check - don't proceed if widget is unmounted
    if (!mounted) return;
    
    final voiceAssist = VoiceAssistService();
    
    debugPrint('Voice assist button tapped. Enabled: ${voiceAssist.isEnabled}');
    
    if (!voiceAssist.isEnabled) {
      // Show dialog if not enabled
      if (!mounted) return;
      
      debugPrint('Showing disabled dialog');
      
      // Use global navigator key to show dialog
      final navContext = navigatorKey.currentContext;
      if (navContext == null || !mounted) {
        debugPrint('ERROR: Navigator context is null or widget unmounted');
        return;
      }
      
      // Get theme provider with error handling
      final ThemeProvider themeProvider;
      try {
        themeProvider = Provider.of<ThemeProvider>(navContext, listen: false);
      } catch (e) {
        debugPrint('ERROR: Could not get ThemeProvider: $e');
        return;
      }
      
      if (!mounted) return;
      
      VibrationService.mediumFeedback();
      
      await showDialog(
        context: navContext,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeProvider.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Voice Assist Disabled',
                  style: TextStyle(
                    fontSize: themeProvider.fontSize + 8,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.buttonTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Voice Assist is currently disabled.',
                  style: TextStyle(
                    fontSize: themeProvider.fontSize + 4,
                    color: themeProvider.buttonTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    VibrationService.mediumFeedback();
                    Navigator.of(dialogContext).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: themeProvider.buttonTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    minimumSize: const Size(200, 48),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: themeProvider.fontSize + 4,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      
      debugPrint('🎤 Dialog dismissed');
      return;
    }

    VibrationService.mediumFeedback();

    if (voiceAssist.isListening) {
      await voiceAssist.stopListening();
    } else {
      await voiceAssist.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safety check - don't build if widget is not mounted
    if (!mounted) {
      return const SizedBox.shrink();
    }
    
    final voiceAssist = VoiceAssistService();

    return ListenableBuilder(
      listenable: voiceAssist,
      builder: (context, child) {
        // Additional safety check inside builder
        if (!mounted) {
          return const SizedBox.shrink();
        }
        
        final isListening = voiceAssist.isListening;
        final isEnabled = voiceAssist.isEnabled;

        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isListening ? _pulseAnimation.value : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton.large(
                  heroTag: 'voice_assist_fab',
                  onPressed: _handleTap,
                  backgroundColor: isListening
                      ? Colors.red[400]
                      : isEnabled
                          ? Colors.amber[600]
                          : Colors.grey[600],
                  child: Icon(
                    isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
