import 'package:flutter/material.dart';
import '../core/services/screen_reader_service.dart';

/// Widget that detects screen reader navigation gestures
class ScreenReaderGestureDetector extends StatelessWidget {
  final Widget child;
  final ScreenReaderService _screenReaderService = ScreenReaderService();

  ScreenReaderGestureDetector({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!_screenReaderService.isEnabled) {
      return child;
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (!_screenReaderService.isEnabled) return;

        // Swipe right to go to next element
        if (details.primaryVelocity! > 0) {
          _screenReaderService.focusNext();
        }
        // Swipe left to go to previous element
        else if (details.primaryVelocity! < 0) {
          _screenReaderService.focusPrevious();
        }
      },
      onDoubleTap: () {
        if (_screenReaderService.isEnabled) {
          _screenReaderService.activateFocusedElement();
        }
      },
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
