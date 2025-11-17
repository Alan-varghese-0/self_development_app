import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  Color _primary = Colors.blueAccent;
  Color _secondary = Colors.blue;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    loadTheme();
  }

  // Getters
  Color get primary => _primary;
  Color get secondary => _secondary;
  ThemeMode get themeMode => _themeMode;

  // Themes
  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'poppins',
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      secondary: _secondary,
      brightness: Brightness.light,
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'poppins',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      secondary: _secondary,
      brightness: Brightness.dark,
    ),
  );

  // Load saved theme
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _primary = Color(prefs.getInt("primary_color") ?? Colors.blueAccent.value);
    _secondary = Color(prefs.getInt("secondary_color") ?? Colors.blue.value);

    int mode = prefs.getInt("theme_mode") ?? 0;
    _themeMode = ThemeMode.values[mode];

    notifyListeners();
  }

  // Change theme colors
  Future<void> setTheme(Color primary, Color secondary) async {
    _primary = primary;
    _secondary = secondary;

    final prefs = await SharedPreferences.getInstance();
    prefs.setInt("primary_color", primary.value);
    prefs.setInt("secondary_color", secondary.value);

    notifyListeners();
  }

  // Change theme mode (light/dark/system)
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    final prefs = await SharedPreferences.getInstance();
    prefs.setInt("theme_mode", mode.index);

    notifyListeners();
  }
}
