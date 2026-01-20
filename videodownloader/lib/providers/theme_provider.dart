import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { dark, light, ocean }

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme';
  AppTheme _currentTheme = AppTheme.dark; // Default to dark theme instead of light

  AppTheme get currentTheme => _currentTheme;

  ThemeMode get themeMode {
    switch (_currentTheme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
      case AppTheme.ocean:
        return ThemeMode.dark;
    }
  }

  bool get isDark => _currentTheme == AppTheme.dark;
  bool get isLight => _currentTheme == AppTheme.light;
  bool get isOcean => _currentTheme == AppTheme.ocean;

  String get themeName {
    switch (_currentTheme) {
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.light:
        return 'Light';
      case AppTheme.ocean:
        return 'Ocean';
    }
  }

  IconData get themeIcon {
    switch (_currentTheme) {
      case AppTheme.dark:
        return Icons.dark_mode;
      case AppTheme.light:
        return Icons.light_mode;
      case AppTheme.ocean:
        return Icons.waves;
    }
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? 'dark'; // Default to dark instead of light

    _currentTheme = AppTheme.values.firstWhere(
      (theme) => theme.name == themeString,
      orElse: () => AppTheme.dark, // Default fallback to dark
    );

    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
    notifyListeners();
  }

  void cycleTheme() {
    final themes = AppTheme.values;
    final currentIndex = themes.indexOf(_currentTheme);
    final nextIndex = (currentIndex + 1) % themes.length;
    setTheme(themes[nextIndex]);
  }

  ThemeData getTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return lightTheme;
      case AppTheme.dark:
        return darkTheme;
      case AppTheme.ocean:
        return oceanTheme;
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB), // Beautiful blue
        brightness: Brightness.light,
      ).copyWith(
        primary: const Color(0xFF2563EB),
        secondary: const Color(0xFF06B6D4),
        tertiary: const Color(0xFF10B981),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        elevation: 16,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6), // Bright blue for dark theme
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF3B82F6),
        secondary: const Color(0xFF06B6D4),
        tertiary: const Color(0xFF10B981),
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardTheme: CardThemeData(
        elevation: 4,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF121212),
        foregroundColor: Colors.white,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 16,
      ),
    );
  }

  static ThemeData get oceanTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0891B2), // Cyan-600
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF0891B2),
        secondary: const Color(0xFF0EA5E9),
        tertiary: const Color(0xFF06B6D4),
        surface: const Color(0xFF0F1419),
        background: const Color(0xFF0C1116),
      ),
      scaffoldBackgroundColor: const Color(0xFF0C1116),
      cardTheme: CardThemeData(
        elevation: 4,
        color: const Color(0xFF0F1419),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF0C1116),
        foregroundColor: Colors.white,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF0F1419),
        elevation: 16,
      ),
    );
  }
}