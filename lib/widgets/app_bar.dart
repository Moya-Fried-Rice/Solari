import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/theme_provider.dart';
import 'select_to_speak_text.dart';
import 'screen_reader_focusable.dart';

/// Custom app bar widget
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final String? screenReaderContext;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.screenReaderContext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    // Only show shadow in light mode
    final double appBarElevation = theme.isDarkMode ? 0 : 10;

    return AppBar(
      automaticallyImplyLeading: showBackButton,
      centerTitle: true,
      leading: showBackButton
        ? ScreenReaderFocusable(
            context: screenReaderContext,
            label: 'Back button',
            hint: 'Double tap to go back',
            onTap: () => Navigator.pop(context),
            child: Semantics(
              label: 'Back button. Double tap to return.',
              excludeSemantics: true,
              child: IconButton(
                icon: FaIcon(
                  FontAwesomeIcons.caretLeft,
                  size: AppConstants.largeIconSize,
                  color: theme.iconColor,
                ),
                padding: const EdgeInsets.only(left: 16.0),
                onPressed: () {
                  // VibrationService.mediumFeedback();
                  Navigator.pop(context);
                },
              ),
            ),
          )
        : null,

      title: ScreenReaderFocusable(
        context: screenReaderContext,
        label: '$title page',
        hint: 'Current page is $title',
        child: Semantics(
          child: SelectToSpeakText(
            title,
            style: TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
              color: theme.labelColor,
              shadows: theme.isHighContrast ? [
                Shadow(offset: const Offset(0, -1), blurRadius: 5.0, color: theme.isDarkMode ? Colors.black : Colors.white),
                Shadow(offset: const Offset(0, 1), blurRadius: 5.0, color: theme.isDarkMode ? Colors.black : Colors.white),
                Shadow(offset: const Offset(-1, 0), blurRadius: 5.0, color: theme.isDarkMode ? Colors.black : Colors.white),
                Shadow(offset: const Offset(1, 0), blurRadius: 5.0, color: theme.isDarkMode ? Colors.black : Colors.white),
              ] : null,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      backgroundColor: theme.primaryColor,
      elevation: appBarElevation,
      actionsIconTheme: IconThemeData(
        size: AppConstants.smallIconSize,
        color: theme.iconColor,
      ),
      iconTheme: IconThemeData(
        size: AppConstants.smallIconSize,
        color: theme.iconColor,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);
}
