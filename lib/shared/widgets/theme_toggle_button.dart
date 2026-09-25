import 'package:eventease/core/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool showLabel;
  final EdgeInsets? padding;

  const ThemeToggleButton({
    super.key,
    this.showLabel = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return IconButton(
          onPressed: () {
            themeProvider.toggleTheme();
          },
          icon: Icon(themeProvider.themeIcon),
          tooltip: 'Toggle Theme (${themeProvider.themeModeName})',
          padding: padding,
        );
      },
    );
  }
}
