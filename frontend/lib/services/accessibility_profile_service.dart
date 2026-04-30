import 'package:flutter/material.dart';

import '../models/accessibility_profile.dart';
import 'settings_service.dart';

class AccessibilityProfileService extends ChangeNotifier {
  static final AccessibilityProfileService _instance = AccessibilityProfileService._internal();

  factory AccessibilityProfileService() => _instance;

  AccessibilityProfileService._internal() {
    _syncFromSettings();
    _settings.addListener(_syncFromSettings);
  }

  final SettingsService _settings = SettingsService();

  bool _wheelchairEnabled = false;
  bool _lowVisionEnabled = false;
  bool _blindEnabled = false;

  bool get wheelchairEnabled => _wheelchairEnabled;
  bool get lowVisionEnabled => _lowVisionEnabled;
  bool get blindEnabled => _blindEnabled;

  AccessibilityProfile get selectedProfile {
    if (_lowVisionEnabled || (_wheelchairEnabled && _blindEnabled)) {
      return AccessibilityProfile.LowVision;
    }
    if (_wheelchairEnabled) return AccessibilityProfile.Wheelchair;
    if (_blindEnabled) return AccessibilityProfile.Blind;
    return AccessibilityProfile.None;
  }

  bool get hasPendingChanges =>
      selectedProfile != _settings.accessibilityProfile.simpleProfile;

  void setWheelchairEnabled(bool enabled, {bool persist = false}) {
    if (_wheelchairEnabled == enabled) return;
    _wheelchairEnabled = enabled;
    _notifyChanged();
    if (persist) {
      applyProfile();
    }
  }

  void setLowVisionEnabled(bool enabled, {bool persist = false}) {
    if (_lowVisionEnabled == enabled) return;
    _lowVisionEnabled = enabled;
    _notifyChanged();
    if (persist) {
      applyProfile();
    }
  }

  void setBlindEnabled(bool enabled, {bool persist = false}) {
    if (_blindEnabled == enabled) return;
    _blindEnabled = enabled;
    _notifyChanged();
    if (persist) {
      applyProfile();
    }
  }

  Future<void> applyProfile() async {
    final profile = selectedProfile;
    await _settings.setAccessibilityProfile(profile);

    switch (profile) {
      case AccessibilityProfile.Wheelchair:
      case AccessibilityProfile.WheelchairBiometric:
        await _settings.setWheelchairRoutesEnabled(true);
        await _settings.setHighContrast(false);
        await _settings.setLargeText(false);
        await _settings.setAudioFeedbackEnabled(false);
        await _settings.setAudioNavigationEnabled(false);
        await _settings.setHapticFeedbackEnabled(false);
        break;
      case AccessibilityProfile.LowVision:
        await _settings.setWheelchairRoutesEnabled(false);
        await _settings.setHighContrast(true);
        await _settings.setLargeText(true);
        await _settings.setAudioFeedbackEnabled(true);
        await _settings.setAudioNavigationEnabled(true);
        await _settings.setHapticFeedbackEnabled(true);
        break;
      case AccessibilityProfile.Blind:
        await _settings.setWheelchairRoutesEnabled(false);
        await _settings.setHighContrast(false);
        await _settings.setLargeText(false);
        await _settings.setAudioFeedbackEnabled(true);
        await _settings.setAudioNavigationEnabled(true);
        await _settings.setHapticFeedbackEnabled(true);
        break;
      case AccessibilityProfile.None:
        await _settings.setWheelchairRoutesEnabled(false);
        await _settings.setHighContrast(false);
        await _settings.setLargeText(false);
        await _settings.setAudioFeedbackEnabled(false);
        await _settings.setAudioNavigationEnabled(false);
        await _settings.setHapticFeedbackEnabled(false);
        break;
    }

    _notifyChanged();
  }

  void resetFromSettings() {
    _syncFromSettings();
  }

  void _syncFromSettings() {
    final current = _settings.accessibilityProfile.simpleProfile;
    final newWheelchair = current.isWheelchair && current != AccessibilityProfile.LowVision;
    final newLowVision = current == AccessibilityProfile.LowVision;
    final newBlind = current == AccessibilityProfile.Blind;

    if (_wheelchairEnabled == newWheelchair &&
        _lowVisionEnabled == newLowVision &&
        _blindEnabled == newBlind) {
      return;
    }

    _wheelchairEnabled = newWheelchair;
    _lowVisionEnabled = newLowVision;
    _blindEnabled = newBlind;
    _notifyChanged();
  }

  void _notifyChanged() {
    notifyListeners();
  }
}
