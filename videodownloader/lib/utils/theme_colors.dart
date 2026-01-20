import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

class ThemeColors {
  static Color getOrangeColor(BuildContext context, ThemeProvider themeProvider) {
    switch (themeProvider.currentTheme) {
      case AppTheme.light:
        return const Color(0xFFFF8C00); // Bright orange
      case AppTheme.dark:
        return const Color(0xFFFFB366); // Warm peach orange for dark theme
      case AppTheme.ocean:
        return const Color(0xFFFF8C42); // Vibrant orange that works with ocean theme
    }
  }

  static Color getOrangeBackgroundColor(BuildContext context, ThemeProvider themeProvider) {
    switch (themeProvider.currentTheme) {
      case AppTheme.light:
        return const Color(0xFFFF8C00).withOpacity(0.15);
      case AppTheme.dark:
        return const Color(0xFFFFB366).withOpacity(0.25);
      case AppTheme.ocean:
        return const Color(0xFFFF8C42).withOpacity(0.25);
    }
  }

  static Color getIconOrangeColor(BuildContext context, ThemeProvider themeProvider) {
    switch (themeProvider.currentTheme) {
      case AppTheme.light:
        return const Color(0xFFFF8C00); // Bright orange
      case AppTheme.dark:
        return const Color(0xFFFFB366); // Warm peach orange for dark theme
      case AppTheme.ocean:
        return const Color(0xFFFF8C42); // Vibrant orange that works with ocean theme
    }
  }

  static Color getGreenColor(BuildContext context, ThemeProvider themeProvider) {
    switch (themeProvider.currentTheme) {
      case AppTheme.light:
        return const Color(0xFF10B981); // Emerald green
      case AppTheme.dark:
        return const Color(0xFF4ADE80); // Lighter green for dark theme
      case AppTheme.ocean:
        return const Color(0xFF34D399); // Bright green that works with ocean theme
    }
  }

  static Color getRedColor(BuildContext context, ThemeProvider themeProvider) {
    switch (themeProvider.currentTheme) {
      case AppTheme.light:
        return const Color(0xFFDC2626); // Strong red
      case AppTheme.dark:
        return const Color(0xFFF87171); // Lighter red for dark theme
      case AppTheme.ocean:
        return const Color(0xFFEF4444); // Bright red that works with ocean theme
    }
  }

  static Color getAmberColor(BuildContext context, ThemeProvider themeProvider) {
    switch (themeProvider.currentTheme) {
      case AppTheme.light:
        return const Color(0xFFF59E0B); // Rich amber
      case AppTheme.dark:
        return const Color(0xFFFBBF24); // Bright amber for dark theme
      case AppTheme.ocean:
        return const Color(0xFFFCD34D); // Vibrant amber that works with ocean theme
    }
  }

  static Color getBlueColor(BuildContext context, ThemeProvider themeProvider) {
    switch (themeProvider.currentTheme) {
      case AppTheme.light:
        return const Color(0xFF2563EB); // Strong blue
      case AppTheme.dark:
        return const Color(0xFF60A5FA); // Lighter blue for dark theme
      case AppTheme.ocean:
        return const Color(0xFF3B82F6); // Vibrant blue that works with ocean theme
    }
  }
}