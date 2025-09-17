import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class OnboardingButton extends StatelessWidget {
  final String label;
  final double height;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;

  const OnboardingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 200,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final buttonTextStyle = TextStyle(
      fontSize: AppConstants.titleFontSize,
      fontWeight: FontWeight.bold,
      color: textColor ?? theme.buttonTextColor,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
              foregroundColor: textColor ?? Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(75),
                  topRight: Radius.circular(75),
                ),
              ),
              elevation: 6,
              padding: const EdgeInsets.symmetric(vertical: 30),
            ),
            onPressed: onPressed,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: buttonTextStyle,
            ),
          ),
        ),
      ],
    );
  }
}
