import 'package:flutter/material.dart';
import '../core/services/screen_reader_service.dart';

/// Widget that makes its child focusable and readable by the screen reader
class ScreenReaderFocusable extends StatefulWidget {
  final Widget child;
  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final bool enabled;
  final String? context; // Page/screen context for this focusable element

  const ScreenReaderFocusable({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.onTap,
    this.enabled = true,
    this.context,
  });

  @override
  State<ScreenReaderFocusable> createState() => _ScreenReaderFocusableState();
}

class _ScreenReaderFocusableState extends State<ScreenReaderFocusable> with RouteAware {
  final FocusNode _focusNode = FocusNode();
  final ScreenReaderService _screenReaderService = ScreenReaderService();
  bool _isFocused = false;
  bool _isRegistered = false;

  // Expose focus node for manual focusing
  FocusNode get focusNode => _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    
    // Listen to screen reader service changes
    _screenReaderService.addListener(_onScreenReaderChanged);
    
    // Register immediately if screen reader is enabled and this widget is enabled
    _updateRegistration();
  }

  void _updateRegistration() {
    final shouldRegister = _screenReaderService.isEnabled && widget.enabled;
    
    if (shouldRegister && !_isRegistered) {
      // Register this focus node
      _screenReaderService.registerFocusNode(
        _focusNode,
        onTap: widget.onTap,
        context: widget.context,
      );
      _isRegistered = true;
    } else if (!shouldRegister && _isRegistered) {
      // Unregister this focus node
      _screenReaderService.unregisterFocusNode(_focusNode);
      _isRegistered = false;
    }
  }

  void _onScreenReaderChanged() {
    // When screen reader state changes, update registration
    if (mounted) {
      _updateRegistration();
      setState(() {}); // Rebuild to show/hide focus border
    }
  }

  @override
  void didUpdateWidget(ScreenReaderFocusable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled || widget.context != oldWidget.context) {
      // Re-evaluate registration when enabled state or context changes
      if (_isRegistered) {
        _screenReaderService.unregisterFocusNode(_focusNode);
        _isRegistered = false;
      }
      _updateRegistration();
    }
  }

  @override
  void dispose() {
    _screenReaderService.removeListener(_onScreenReaderChanged);
    if (_isRegistered) {
      _screenReaderService.unregisterFocusNode(_focusNode);
      _isRegistered = false;
    }
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      
      if (_isFocused && _screenReaderService.isEnabled) {
        _screenReaderService.announceText(widget.label, hint: widget.hint);
        // Scroll to show the focused element
        _scrollToFocusedElement();
      }
    }
  }

  void _scrollToFocusedElement() {
    // Use a short delay to ensure the widget is built before scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && _focusNode.hasFocus) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5, // Center the element on screen
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_screenReaderService.isEnabled || !widget.enabled) {
      // If screen reader is disabled, return normal child
      return widget.child;
    }

    return Focus(
      focusNode: _focusNode,
      child: Container(
        decoration: _isFocused
            ? BoxDecoration(
                border: Border.all(
                  color: Colors.amber,
                  width: 4,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              )
            : null,
        child: Semantics(
          label: widget.label,
          hint: widget.hint,
          button: widget.onTap != null,
          focusable: true,
          focused: _isFocused,
          child: widget.child,
        ),
      ),
    );
  }
}
