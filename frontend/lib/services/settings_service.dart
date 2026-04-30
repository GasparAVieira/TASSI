import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/accessibility_profile.dart';

class AnimationsMotionSettings {
  final bool animationsEnabled;
  final bool pulsingEnabled;

  const AnimationsMotionSettings({
    this.animationsEnabled = true,
    this.pulsingEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'animationsEnabled': animationsEnabled,
        'pulsingEnabled': pulsingEnabled,
      };

  factory AnimationsMotionSettings.fromJson(Map<String, dynamic> json) {
    return AnimationsMotionSettings(
      animationsEnabled: json['animationsEnabled'] as bool? ?? true,
      pulsingEnabled: json['pulsingEnabled'] as bool? ?? true,
    );
  }

  AnimationsMotionSettings copyWith({
    bool? animationsEnabled,
    bool? pulsingEnabled,
  }) {
    return AnimationsMotionSettings(
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      pulsingEnabled: pulsingEnabled ?? this.pulsingEnabled,
    );
  }
}

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // Theme and display preference keys
  static const String _kThemeModeKey = 'settings_theme_mode';
  static const String _kHighContrastKey = 'settings_high_contrast';
  static const String _kLargeTextKey = 'settings_large_text';
  static const String _kAnimationsMotionKey = 'settings_animations_motion';

  // Localization and guidance preference keys
  static const String _kPreferredLanguageKey = 'settings_preferred_language';
  static const String _kAudioGuidanceKey = 'settings_audio_guidance';

  // Mobility and notification preference keys
  static const String _kPushNotificationsKey = 'settings_push_notifications';
  static const String _kWheelchairRoutesKey = 'settings_wheelchair_routes';

  // Audio preference keys
  static const String _kAudioFeedbackKey = 'settings_audio_feedback';
  static const String _kAudioNavigationKey = 'settings_audio_navigation';
  static const String _kAudioSpeechRateKey = 'settings_audio_speech_rate';

  // Accessibility preference keys
  static const String _kHapticFeedbackKey = 'settings_haptic_feedback';
  static const String _kAccessibilityProfileKey = 'settings_accessibility_profile';
  static const List<String> accessibilityPreferenceKeys = [
    _kAccessibilityProfileKey,
  ];

  // Runtime preference state
  ThemeMode _themeMode = ThemeMode.system;
  bool _isHighContrast = false;
  bool _useLargeText = false;
  AnimationsMotionSettings _animationsMotionSettings = const AnimationsMotionSettings();

  bool _pushNotificationsEnabled = true;
  bool _wheelchairRoutesEnabled = false;
  bool _audioFeedbackEnabled = true;
  bool _audioNavigationEnabled = false;
  double _audioSpeechRate = 1.0;
  bool _hapticFeedbackEnabled = true;

  String _preferredLanguageCode = 'pt';
  bool _hasPreferredLanguageSetting = false;
  bool _audioGuidance = false;
  AccessibilityProfile _accessibilityProfile = AccessibilityProfile.None;

  // Theme/display getters
  ThemeMode get themeMode => _themeMode;
  bool get isHighContrast => _isHighContrast;
  bool get useLargeText => _useLargeText;
  bool get isAnimationsEnabled => _animationsMotionSettings.animationsEnabled;
  bool get isPulsingEnabled => _animationsMotionSettings.pulsingEnabled;

  // App behavior getters
  bool get hasPreferredLanguageSetting => _hasPreferredLanguageSetting;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get wheelchairRoutesEnabled => _wheelchairRoutesEnabled;

  // Audio preference getters
  bool get audioFeedbackEnabled => _audioFeedbackEnabled;
  bool get audioNavigationEnabled => _audioNavigationEnabled;
  double get audioSpeechRate => _audioSpeechRate;

  // Accessibility getters
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  String get preferredLanguageCode => _preferredLanguageCode;
  bool get audioGuidance => _audioGuidance;
  AccessibilityProfile get accessibilityProfile => _accessibilityProfile;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final themeValue = prefs.getString(_kThemeModeKey);
    if (themeValue == 'Light') {
      _themeMode = ThemeMode.light;
    } else if (themeValue == 'Dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    _isHighContrast = prefs.getBool(_kHighContrastKey) ?? false;
    _useLargeText = prefs.getBool(_kLargeTextKey) ?? false;
    _animationsMotionSettings = _loadAnimationsMotionSettings(prefs);

    _pushNotificationsEnabled = prefs.getBool(_kPushNotificationsKey) ?? true;
    _wheelchairRoutesEnabled = prefs.getBool(_kWheelchairRoutesKey) ?? false;
    _audioFeedbackEnabled = prefs.getBool(_kAudioFeedbackKey) ?? true;
    _audioNavigationEnabled = prefs.getBool(_kAudioNavigationKey) ?? false;
    _audioSpeechRate = prefs.getDouble(_kAudioSpeechRateKey) ?? 1.0;
    _hapticFeedbackEnabled = prefs.getBool(_kHapticFeedbackKey) ?? true;

    _hasPreferredLanguageSetting = prefs.containsKey(_kPreferredLanguageKey);
    _preferredLanguageCode = prefs.getString(_kPreferredLanguageKey) ?? 'pt';
    _audioGuidance = prefs.getBool(_kAudioGuidanceKey) ?? false;
    _accessibilityProfile = AccessibilityProfile.fromServerValue(
      prefs.getString(_kAccessibilityProfileKey),
    );

    notifyListeners();
  }

  AnimationsMotionSettings _loadAnimationsMotionSettings(SharedPreferences prefs) {
    final jsonString = prefs.getString(_kAnimationsMotionKey);
    if (jsonString == null || jsonString.isEmpty) {
      return const AnimationsMotionSettings();
    }

    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return AnimationsMotionSettings.fromJson(decoded);
    } catch (_) {
      return const AnimationsMotionSettings();
    }
  }

  Future<void> setThemeMode(String theme) async {
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, theme);
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    _isHighContrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHighContrastKey, value);
    notifyListeners();
  }

  Future<void> setLargeText(bool value) async {
    _useLargeText = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLargeTextKey, value);
    notifyListeners();
  }

  Future<void> _saveAnimationsMotionSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAnimationsMotionKey, jsonEncode(_animationsMotionSettings.toJson()));
    notifyListeners();
  }

  Future<void> setAnimationsEnabled(bool value) async {
    _animationsMotionSettings = _animationsMotionSettings.copyWith(animationsEnabled: value);
    await _saveAnimationsMotionSettings();
  }

  Future<void> setPulsingEnabled(bool value) async {
    _animationsMotionSettings = _animationsMotionSettings.copyWith(pulsingEnabled: value);
    await _saveAnimationsMotionSettings();
  }

  Future<void> setPushNotificationsEnabled(bool value) async {
    _pushNotificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPushNotificationsKey, value);
    notifyListeners();
  }

  Future<void> setWheelchairRoutesEnabled(bool value) async {
    _wheelchairRoutesEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWheelchairRoutesKey, value);
    notifyListeners();
  }

  Future<void> setAudioFeedbackEnabled(bool value) async {
    _audioFeedbackEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAudioFeedbackKey, value);
    notifyListeners();
  }

  Future<void> setAudioNavigationEnabled(bool value) async {
    _audioNavigationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAudioNavigationKey, value);
    notifyListeners();
  }

  Future<void> setAudioSpeechRate(double value) async {
    _audioSpeechRate = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kAudioSpeechRateKey, value);
    notifyListeners();
  }

  Future<void> setHapticFeedbackEnabled(bool value) async {
    _hapticFeedbackEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHapticFeedbackKey, value);
    notifyListeners();
  }

  Future<void> setPreferredLanguageCode(String languageCode) async {
    _preferredLanguageCode = languageCode;
    _hasPreferredLanguageSetting = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPreferredLanguageKey, languageCode);
    notifyListeners();
  }

  Future<void> setAudioGuidance(bool value) async {
    _audioGuidance = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAudioGuidanceKey, value);
    notifyListeners();
  }

  Future<void> setAccessibilityProfile(AccessibilityProfile profile) async {
    _accessibilityProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessibilityProfileKey, profile.serverValue);
    notifyListeners();
  }

  String get themeModeString {
    if (_themeMode == ThemeMode.light) return 'Light';
    if (_themeMode == ThemeMode.dark) return 'Dark';
    return 'System';
  }
}
