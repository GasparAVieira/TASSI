import 'package:flutter/material.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  ThemeMode _themeMode = ThemeMode.system;
  bool _isHighContrast = false;
  bool _useLargeText = false;
  bool _isAnimationsEnabled = true;
  bool _isPulsingEnabled = true;

  ThemeMode get themeMode => _themeMode;
  bool get isHighContrast => _isHighContrast;
  bool get useLargeText => _useLargeText;
  bool get isAnimationsEnabled => _isAnimationsEnabled;
  bool get isPulsingEnabled => _isPulsingEnabled;

  void setThemeMode(String theme) {
    switch (theme) {
      case 'Light':
        _themeMode = ThemeMode.light;
        break;
      case 'Dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  void setHighContrast(bool value) {
    _isHighContrast = value;
    notifyListeners();
  }

  void setLargeText(bool value) {
    _useLargeText = value;
    notifyListeners();
  }

  void setAnimationsEnabled(bool value) {
    _isAnimationsEnabled = value;
    notifyListeners();
  }

  void setPulsingEnabled(bool value) {
    _isPulsingEnabled = value;
    notifyListeners();
  }

  String get themeModeString {
    if (_themeMode == ThemeMode.light) return 'Light';
    if (_themeMode == ThemeMode.dark) return 'Dark';
    return 'System';
  }
}
