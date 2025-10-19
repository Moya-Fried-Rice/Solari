import 'package:flutter/material.dart';
import '../core/services/screen_reader_service.dart';

/// Widget that registers the same element with multiple contexts
/// This allows navigation bar buttons to be readable from any tab
class MultiContextFocusable extends StatefulWidget {
  final Widget child;
  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final List<String> contexts; // Multiple contexts to register with

  const MultiContextFocusable({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.onTap,
    required this.contexts,
  });

  @override
  State<MultiContextFocusable> createState() => _MultiContextFocusableState();
}

class _MultiContextFocusableState extends State<MultiContextFocusable> {
  final List<FocusNode> _focusNodes = [];
  final ScreenReaderService _screenReaderService = ScreenReaderService();
  bool _isRegistered = false;
  int? _currentFocusedIndex;

  @override
  void initState() {
    super.initState();
    
    // Create a focus node for each context
    for (int i = 0; i < widget.contexts.length; i++) {
      final node = FocusNode();
      node.addListener(() => _onFocusChange(i));
      _focusNodes.add(node);
    }
    
    // Listen to screen reader service changes
    _screenReaderService.addListener(_onScreenReaderChanged);
    
    // Register immediately if screen reader is enabled
    _updateRegistration();
  }

  void _updateRegistration() {
    final shouldRegister = _screenReaderService.isEnabled;
    
    if (shouldRegister && !_isRegistered) {
      // Register each focus node with its corresponding context
      for (int i = 0; i < _focusNodes.length; i++) {
        _screenReaderService.registerFocusNode(
          _focusNodes[i],
          onTap: widget.onTap,
          context: widget.contexts[i],
        );
      }
      _isRegistered = true;
    } else if (!shouldRegister && _isRegistered) {
      // Unregister all focus nodes
      for (final node in _focusNodes) {
        _screenReaderService.unregisterFocusNode(node);
      }
      _isRegistered = false;
    }
  }

  void _onFocusChange(int index) {
    if (!mounted) return;
    
    final hasFocus = _focusNodes[index].hasFocus;
    final previousIndex = _currentFocusedIndex;
    
    setState(() {
      _currentFocusedIndex = hasFocus ? index : null;
    });
    
    // Announce when focused (only if this is a new focus, not just switching between our own nodes)
    if (hasFocus && previousIndex != index && _screenReaderService.isEnabled) {
      _screenReaderService.announceText(widget.label, hint: widget.hint);
      _scrollToFocusedElement();
    }
  }

  void _scrollToFocusedElement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && _currentFocusedIndex != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    });
  }

  void _onScreenReaderChanged() {
    if (mounted) {
      _updateRegistration();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _screenReaderService.removeListener(_onScreenReaderChanged);
    for (final node in _focusNodes) {
      if (_isRegistered) {
        _screenReaderService.unregisterFocusNode(node);
      }
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_screenReaderService.isEnabled) {
      return widget.child;
    }

    // Wrap with Focus widgets for each focus node (nested)
    // Only the active context's focus node will be accessible
    Widget result = widget.child;
    for (int i = _focusNodes.length - 1; i >= 0; i--) {
      final isFocused = _currentFocusedIndex == i;
      result = Focus(
        focusNode: _focusNodes[i],
        child: i == 0 // Only show decoration on outermost widget
            ? Container(
                decoration: (_currentFocusedIndex != null)
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
                  focused: _currentFocusedIndex != null,
                  child: result,
                ),
              )
            : result,
      );
    }

    return result;
  }
}
