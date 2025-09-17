import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/providers/theme_provider.dart';

/// Custom toggle switch with label
class Toggle extends StatelessWidget {
  /// The text label for the toggle
  final String label;
  
  /// Current value (on/off)
  final bool value;
  
  /// Callback when value changes
  final ValueChanged<bool> onChanged;
  
  /// Custom font size for the label
  final double? fontSize;
  
  /// Creates a toggle switch
  const Toggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    
    // Always use row layout with text wrapping
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Flexible text that can wrap
        Expanded(
          child: Text(
            label, 
            style: TextStyle(
              fontSize: fontSize ?? AppConstants.bodyFontSize,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        // Fixed spacing
        const SizedBox(width: 16),
        // Switch is not flexible - always stays at its natural size
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: theme.primaryColor,
          inactiveThumbColor: theme.unselectedColor,
          activeTrackColor: theme.primaryColor.withOpacity(0.4),
          inactiveTrackColor: theme.unselectedColor.withOpacity(0.4),
        ),
      ],
    );
  }
}
