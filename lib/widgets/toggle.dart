import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/vibration_service.dart';

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

  String get semanticLabel {
    // Special handling for theme toggle
    if (label.contains('Mode')) {
      final bool isDarkMode = value;
      return isDarkMode
          ? 'Dark Mode enabled. Double tap to enable Light Mode'
          : 'Light Mode enabled. Double tap to enable Dark Mode';
    }

    // For Screen Reader and Haptic Feedback toggles
    final String baseLabel = label;
    final String currentState = value ? 'enabled' : 'disabled';
    final String targetState = value ? 'disable' : 'enable';

    return '$baseLabel toggle... $currentState... Double tap to $targetState';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    
    final textShadows = theme.isHighContrast
        ? [
            Shadow(offset: const Offset(0, -1), blurRadius: 5.0, color: theme.isDarkMode ? Colors.black : Colors.white),
            Shadow(offset: const Offset(0, 1), blurRadius: 5.0, color: theme.isDarkMode ? Colors.black : Colors.white),
            Shadow(offset: const Offset(-1, 0), blurRadius: 5.0, color: theme.isDarkMode ? Colors.black : Colors.white),
            Shadow(offset: const Offset(1, 0), blurRadius: 5.0, color: theme.isDarkMode ? Colors.black : Colors.white),
          ]
        : null;
    
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: MergeSemantics(
        child: InkWell(
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: fontSize ?? AppConstants.bodyFontSize,
                      color: theme.buttonTextColor,
                      shadows: textShadows,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
                ExcludeSemantics(
                  child: Switch(
                    value: value,
                    onChanged: (newValue) {
                      if (newValue != value) {
                        VibrationService.mediumFeedback();
                      }
                      onChanged(newValue);
                    },
                    activeColor: theme.buttonTextColor,
                    inactiveThumbColor: theme.unselectedColor,
                    activeTrackColor: theme.buttonTextColor.withOpacity(0.4),
                    inactiveTrackColor: theme.unselectedColor.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
