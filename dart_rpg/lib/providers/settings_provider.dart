import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = 16.0;
  String _fontFamily = 'Roboto';
  
  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  
  SettingsProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    _fontFamily = prefs.getString('fontFamily') ?? 'Roboto';
    notifyListeners();
  }
  
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }
  
  Future<void> setFontSize(double value) async {
    if (_fontSize == value) return;
    
    _fontSize = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', value);
    notifyListeners();
  }
  
  Future<void> setFontFamily(String value) async {
    if (_fontFamily == value) return;
    
    _fontFamily = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontFamily', value);
    notifyListeners();
  }
  
  ThemeData getTheme(bool isDark) {
    return isDark ? _getDarkTheme() : _getLightTheme();
  }
  
  ThemeData _getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      fontFamily: _fontFamily,
      textTheme: TextTheme(
        bodyMedium: TextStyle(fontSize: _fontSize),
      ),
    );
  }
  
  ThemeData _getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      fontFamily: _fontFamily,
      textTheme: TextTheme(
        bodyMedium: TextStyle(fontSize: _fontSize),
      ),
    );
  }
}
