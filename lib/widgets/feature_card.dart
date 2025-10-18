import 'package:flutter/material.dart';
import '../core/providers/theme_provider.dart';
import '../core/services/vibration_service.dart';

/// A reusable card widget for feature grids (settings, preferences, etc.)
class FeatureCard extends StatelessWidget {
  final ThemeProvider theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;
  final bool useToggleStyle;

  const FeatureCard({
    super.key,
    required this.theme,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.useToggleStyle = false,
  });

  /// Returns text shadows for high contrast mode
  List<Shadow>? _getTextShadows() {
    if (!theme.isHighContrast) return null;

    // Shadow should contrast with background:
    // Dark mode (dark bg, light text) -> white shadows
    // Light mode (light bg, dark text) -> black shadows
    final shadowColor = theme.isDarkMode ? Colors.black : Colors.white;
    return [
      Shadow(offset: const Offset(0, -1), blurRadius: 5.0, color: shadowColor),
      Shadow(offset: const Offset(0, 1), blurRadius: 5.0, color: shadowColor),
      Shadow(offset: const Offset(-1, 0), blurRadius: 5.0, color: shadowColor),
      Shadow(offset: const Offset(1, 0), blurRadius: 5.0, color: shadowColor),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // If useToggleStyle is enabled, change appearance based on isSelected.
    // Otherwise, preserve original filled card appearance for backward compatibility.
    final containerDecoration = useToggleStyle
        ? BoxDecoration(
            color: isSelected ? theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.primaryColor),
          )
        : BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(12),
          );

    // When useToggleStyle is true:
    // - If selected: use buttonTextColor (white/light on colored background)
    // - If not selected: use primaryColor (colored text on transparent background)
    // When useToggleStyle is false: always use buttonTextColor (original behavior)
    final effectiveIconColor = useToggleStyle
        ? (isSelected ? theme.buttonTextColor : theme.primaryColor)
        : theme.buttonTextColor;

    final effectiveTextColor = useToggleStyle
        ? (isSelected ? theme.buttonTextColor : theme.primaryColor)
        : theme.buttonTextColor;

    return Container(
      decoration: containerDecoration,
      child: InkWell(
        onTap: () {
          VibrationService.mediumFeedback();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 56,
                color: effectiveIconColor,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: (theme.fontSize - 4).clamp(12.0, 20.0),
                    color: effectiveTextColor,
                    fontWeight: FontWeight.w500,
                    shadows: _getTextShadows(),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
