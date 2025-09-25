import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/theme_provider.dart';

/// Custom app bar widget
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
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
        ? Semantics(
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
          )
        : null,

      title: Semantics(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
            color: theme.labelColor,
          ),
          textAlign: TextAlign.center,
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
