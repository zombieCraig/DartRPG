import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logging_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = 16.0;
  String _fontFamily = 'Roboto';
  int _logLevel = 1; // Default to INFO level
  bool _enableTutorials = true; // Default to enabled
  
  // Animation settings
  bool _enableAnimations = true;
  double _animationSpeed = 1.0;
  bool _enableGlitchEffects = false; // Disabled by default now
  bool _enableGlowEffects = false; // Disabled by default now
  
  // Get animation duration adjusted by animation speed
  Duration getAnimationDuration(Duration baseDuration) {
    return Duration(
      milliseconds: (baseDuration.inMilliseconds / _animationSpeed).round(),
    );
  }
  
  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  int get logLevel => _logLevel;
  bool get enableTutorials => _enableTutorials;
  
  // Animation settings getters
  bool get enableAnimations => _enableAnimations;
  double get animationSpeed => _animationSpeed;
  bool get enableGlitchEffects => _enableGlitchEffects;
  bool get enableGlowEffects => _enableGlowEffects;
  
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  
  SettingsProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    _fontFamily = prefs.getString('fontFamily') ?? 'Roboto';
    _logLevel = prefs.getInt('logLevel') ?? 0; // Default to DEBUG level for troubleshooting
    _enableTutorials = prefs.getBool('enableTutorials') ?? true;
    
    // Load animation settings
    _enableAnimations = prefs.getBool('enableAnimations') ?? true;
    _animationSpeed = prefs.getDouble('animationSpeed') ?? 1.0;
    _enableGlitchEffects = prefs.getBool('enableGlitchEffects') ?? true;
    _enableGlowEffects = prefs.getBool('enableGlowEffects') ?? true;
    
    // Apply log level to the logging service
    LoggingService().setLogLevel(_logLevel);
    
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
  
  Future<void> setLogLevel(int value) async {
    if (_logLevel == value) return;
    
    _logLevel = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('logLevel', value);
    
    // Apply the new log level to the logging service
    LoggingService().setLogLevel(value);
    
    notifyListeners();
  }
  
  Future<void> setEnableTutorials(bool value) async {
    if (_enableTutorials == value) return;
    
    _enableTutorials = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableTutorials', value);
    notifyListeners();
  }
  
  // Animation settings setters
  Future<void> setEnableAnimations(bool value) async {
    if (_enableAnimations == value) return;
    
    _enableAnimations = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableAnimations', value);
    notifyListeners();
  }
  
  Future<void> setAnimationSpeed(double value) async {
    if (_animationSpeed == value) return;
    
    _animationSpeed = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('animationSpeed', value);
    notifyListeners();
  }
  
  Future<void> setEnableGlitchEffects(bool value) async {
    if (_enableGlitchEffects == value) return;
    
    _enableGlitchEffects = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableGlitchEffects', value);
    notifyListeners();
  }
  
  Future<void> setEnableGlowEffects(bool value) async {
    if (_enableGlowEffects == value) return;
    
    _enableGlowEffects = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableGlowEffects', value);
    notifyListeners();
  }
  
  
  // Get the log level name for display
  String getLogLevelName(int level) {
    switch (level) {
      case 0:
        return 'Debug';
      case 1:
        return 'Info';
      case 2:
        return 'Warning';
      case 3:
        return 'Error';
      default:
        return 'Unknown';
    }
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
