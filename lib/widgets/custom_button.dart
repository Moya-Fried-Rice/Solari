import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../core/providers/theme_provider.dart';
import '../../core/services/vibration_service.dart';

/// Custom button widget with animated press effect
class CustomButton extends StatefulWidget {
  /// The text displayed on the button
  final String label;
  
  /// Function to call when button is pressed
  final VoidCallback? onPressed;
  
  /// Border radius of the button
  final double borderRadius;
  
  /// Padding inside the button
  final EdgeInsets padding;
  
  /// Font size for the button text
  final double fontSize;
  
  /// Alignment for the button text
  final AlignmentGeometry labelAlignment;
  
  /// Icon to show on the button (optional)
  final IconData? icon;
  
  /// Icon position (left or right)
  final bool iconOnRight;
  
  /// Whether to trigger vibration feedback when the button is pressed
  /// Set to false when you handle vibration in the onPressed callback
  final bool enableVibration;

  /// Creates a custom button
  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.borderRadius = AppConstants.defaultButtonBorderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    this.fontSize = AppConstants.bodyFontSize,
    this.labelAlignment = Alignment.center,
    this.icon,
    this.iconOnRight = false,
    this.enableVibration = true,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  void _handleTapDown(_) => setState(() => _isPressed = true);
  
  void _handleTapUp(_) {
    setState(() => _isPressed = false);
    if (widget.enableVibration) {
      VibrationService.mediumFeedback();
    }
    widget.onPressed?.call();
  }

  void _handleTapCancel() => setState(() => _isPressed = false);

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final buttonTextStyle = TextStyle(
      fontSize: widget.fontSize,
      fontWeight: FontWeight.w800,
      color: theme.buttonTextColor,
      shadows: theme.isHighContrast ? [
        Shadow(offset: const Offset(0, -1), blurRadius: 3.0, color: theme.isDarkMode ? Colors.black : Colors.white),
        Shadow(offset: const Offset(0, 1), blurRadius: 3.0, color: theme.isDarkMode ? Colors.black : Colors.white),
        Shadow(offset: const Offset(-1, 0), blurRadius: 3.0, color: theme.isDarkMode ? Colors.black : Colors.white),
        Shadow(offset: const Offset(1, 0), blurRadius: 3.0, color: theme.isDarkMode ? Colors.black : Colors.white),
      ] : null,
    );

    Widget content;
    
    if (widget.icon != null) {
      final icon = Icon(
        widget.icon!,
        color: theme.buttonTextColor,
        size: widget.fontSize,
      );
      
      final text = Text(
        widget.label, 
        style: buttonTextStyle,
        softWrap: true,
        overflow: TextOverflow.visible,
      );
      
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: widget.iconOnRight
            ? [Flexible(child: text), const SizedBox(width: 12), icon]
            : [icon, const SizedBox(width: 12), Flexible(child: text)],
      );
    } else {
      content = Text(
        widget.label, 
        style: buttonTextStyle,
        softWrap: true,
        overflow: TextOverflow.visible,
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: AppConstants.buttonAnimationDuration,
        transform: _isPressed
            ? Matrix4.translationValues(0, 2, 0)
            : Matrix4.identity(),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        alignment: widget.labelAlignment,
        child: content,
      ),
    );
  }
}
