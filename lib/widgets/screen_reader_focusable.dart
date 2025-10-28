import 'package:flutter/material.dart';
import '../core/services/screen_reader_service.dart';

/// Widget that makes its child focusable and readable by the screen reader
/// Supports both single context and multiple contexts (for navigation elements)
class ScreenReaderFocusable extends StatefulWidget {
  final Widget child;
  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final bool enabled;
  final String? context; // Single context for this focusable element
  final List<String>? contexts; // Multiple contexts (used for navigation elements)

  const ScreenReaderFocusable({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.onTap,
    this.enabled = true,
    this.context,
    this.contexts,
  });

  @override
  State<ScreenReaderFocusable> createState() => _ScreenReaderFocusableState();
}

class _ScreenReaderFocusableState extends State<ScreenReaderFocusable> with RouteAware {
  // Support both single and multiple focus nodes
  late final List<FocusNode> _focusNodes;
  final ScreenReaderService _screenReaderService = ScreenReaderService();
  bool _isRegistered = false;
  int? _currentFocusedIndex;

  // For backwards compatibility with single focus node access
  FocusNode get focusNode => _focusNodes.first;

  // Track if this is a multi-context widget
  bool get _isMultiContext => widget.contexts != null && widget.contexts!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    
    // Create focus nodes based on whether we have single or multiple contexts
    if (_isMultiContext) {
      _focusNodes = List.generate(
        widget.contexts!.length,
        (i) {
          final node = FocusNode();
          node.addListener(() => _onFocusChange(i));
          return node;
        },
      );
    } else {
      _focusNodes = [FocusNode()];
      _focusNodes.first.addListener(() => _onFocusChange(0));
    }
    
    // Listen to screen reader service changes
    _screenReaderService.addListener(_onScreenReaderChanged);
    
    // Register immediately if screen reader is enabled and this widget is enabled
    _updateRegistration();
  }

  void _updateRegistration() {
    final shouldRegister = _screenReaderService.isEnabled && widget.enabled;
    
    if (shouldRegister && !_isRegistered) {
      if (_isMultiContext) {
        // Register each focus node with its corresponding context
        for (int i = 0; i < _focusNodes.length; i++) {
          _screenReaderService.registerFocusNode(
            _focusNodes[i],
            onTap: widget.onTap,
            context: widget.contexts![i],
          );
        }
      } else {
        // Register single focus node
        _screenReaderService.registerFocusNode(
          _focusNodes.first,
          onTap: widget.onTap,
          context: widget.context,
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
    if (widget.enabled != oldWidget.enabled || 
        widget.context != oldWidget.context ||
        widget.contexts != oldWidget.contexts) {
      // Re-evaluate registration when enabled state or context changes
      if (_isRegistered) {
        for (final node in _focusNodes) {
          _screenReaderService.unregisterFocusNode(node);
        }
        _isRegistered = false;
      }
      _updateRegistration();
    }
  }

  @override
  void dispose() {
    _screenReaderService.removeListener(_onScreenReaderChanged);
    if (_isRegistered) {
      for (final node in _focusNodes) {
        _screenReaderService.unregisterFocusNode(node);
      }
      _isRegistered = false;
    }
    for (final node in _focusNodes) {
      node.removeListener(() => _onFocusChange(_focusNodes.indexOf(node)));
      node.dispose();
    }
    super.dispose();
  }

  void _onFocusChange(int index) {
    if (!mounted) return;
    
    final hasFocus = _focusNodes[index].hasFocus;
    final previousIndex = _currentFocusedIndex;
    
    setState(() {
      _currentFocusedIndex = hasFocus ? index : null;
    });
    
    // Announce when focused (for multi-context, only if this is a new focus)
    if (hasFocus && previousIndex != index && _screenReaderService.isEnabled) {
      _screenReaderService.announceText(widget.label, hint: widget.hint);
      _scrollToFocusedElement();
    }
  }

  void _scrollToFocusedElement() {
    // Use a short delay to ensure the widget is built before scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && _currentFocusedIndex != null) {
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

    if (_isMultiContext) {
      // Build nested Focus widgets for multiple contexts
      Widget result = widget.child;
      for (int i = _focusNodes.length - 1; i >= 0; i--) {
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
    } else {
      // Single context - original behavior
      return Focus(
        focusNode: _focusNodes.first,
        child: Container(
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
            child: widget.child,
          ),
        ),
      );
    }
  }
}
