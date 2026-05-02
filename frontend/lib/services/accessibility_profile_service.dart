import 'package:flutter/material.dart';

import '../models/accessibility_profile.dart';
import 'auth_service.dart';
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
    if (_wheelchairEnabled) return AccessibilityProfile.Wheelchair;
    if (_blindEnabled) return AccessibilityProfile.Blind;
    if (_lowVisionEnabled) return AccessibilityProfile.LowVision;
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
    await AuthService.instance.updateLocalProfile(
      accessibilityProfile: profile,
    );

    final enableWheelchairRoutes = _wheelchairEnabled;
    final enableLowVision = _lowVisionEnabled;
    final enableBlind = _blindEnabled;
    final enableAudio = enableLowVision || enableBlind;

    await _settings.setWheelchairRoutesEnabled(enableWheelchairRoutes);
    await _settings.setHighContrast(enableLowVision);
    await _settings.setLargeText(enableLowVision);
    await _settings.setAudioFeedbackEnabled(enableAudio);
    await _settings.setAudioNavigationEnabled(enableAudio);
    await _settings.setHapticFeedbackEnabled(enableAudio);

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
