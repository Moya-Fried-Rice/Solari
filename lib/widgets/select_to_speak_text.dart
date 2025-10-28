import 'package:flutter/material.dart';
import '../core/services/select_to_speak_service.dart';
import '../core/services/screen_reader_service.dart';
import '../core/services/vibration_service.dart';

/// Global notifier to track which text widget is currently selected
final ValueNotifier<String?> _activeTextId = ValueNotifier<String?>(null);

/// Widget that makes text selectable for text-to-speech
/// When select-to-speak is enabled, tapping this widget will read the text aloud
class SelectToSpeakText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const SelectToSpeakText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  State<SelectToSpeakText> createState() => _SelectToSpeakTextState();
}

class _SelectToSpeakTextState extends State<SelectToSpeakText> {
  late final String _id;

  @override
  void initState() {
    super.initState();
    _id = '${widget.text}_${widget.hashCode}';
  }

  @override
  void dispose() {
    // If this widget was the active selection when disposed, stop speaking
    if (_activeTextId.value == _id) {
      SelectToSpeakService().stopSpeaking();
      clearSelectToSpeakSelection();
    }
    super.dispose();
  }

  void _handleTap() {
    // Set this text as active
    _activeTextId.value = _id;
    VibrationService.mediumFeedback();
    SelectToSpeakService().speakText(widget.text);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SelectToSpeakService(),
      builder: (context, _) {
        final selectToSpeakService = SelectToSpeakService();

        if (!selectToSpeakService.isEnabled) {
          // If select-to-speak is disabled, just show normal text
          return Text(
            widget.text,
            style: widget.style,
            textAlign: widget.textAlign,
            maxLines: widget.maxLines,
            overflow: widget.overflow,
          );
        }

        // If enabled, make it tappable with visual feedback that persists
        return ValueListenableBuilder<String?>(
          valueListenable: _activeTextId,
          builder: (context, activeId, _) {
            final isActive = activeId == _id;
            
            return GestureDetector(
              onTap: _handleTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: isActive
                    ? BoxDecoration(
                        color: Colors.amber.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      )
                    : null,
                child: Text(
                  widget.text,
                  style: widget.style,
                  textAlign: widget.textAlign,
                  maxLines: widget.maxLines,
                  overflow: widget.overflow,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Helper function to clear active selection (call when tapping outside)
void clearSelectToSpeakSelection() {
  _activeTextId.value = null;
}

/// Widget that wraps a Semantics child with select-to-speak functionality
class SelectToSpeakSemantics extends StatefulWidget {
  final Widget child;
  final String text;

  const SelectToSpeakSemantics({
    super.key,
    required this.child,
    required this.text,
  });

  @override
  State<SelectToSpeakSemantics> createState() => _SelectToSpeakSemanticsState();
}

class _SelectToSpeakSemanticsState extends State<SelectToSpeakSemantics> {
  late final String _id;

  @override
  void initState() {
    super.initState();
    _id = '${widget.text}_${widget.hashCode}';
  }

  @override
  void dispose() {
    if (_activeTextId.value == _id) {
      SelectToSpeakService().stopSpeaking();
      clearSelectToSpeakSelection();
    }
    super.dispose();
  }

  void _handleTap() {
    _activeTextId.value = _id;
    VibrationService.mediumFeedback();
    SelectToSpeakService().speakText(widget.text);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SelectToSpeakService(),
      builder: (context, _) {
        final selectToSpeakService = SelectToSpeakService();
        final screenReaderService = ScreenReaderService();

        // If screen reader is enabled, it takes priority
        if (screenReaderService.isEnabled) {
          return widget.child;
        }

        if (!selectToSpeakService.isEnabled) {
          return widget.child;
        }

        return ValueListenableBuilder<String?>(
          valueListenable: _activeTextId,
          builder: (context, activeId, _) {
            final isActive = activeId == _id;

            return GestureDetector(
              onTap: _handleTap,
              behavior: HitTestBehavior.opaque,
                child: Container(
                decoration: isActive
                    ? BoxDecoration(
                        color: Colors.amber.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      )
                    : null,
                padding: const EdgeInsets.all(4),
                child: widget.child,
              ),
            );
          },
        );
      },
    );
  }
}
