import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'settings_service.dart';

enum AudioFeedbackSound { click, alert }

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();

  factory FeedbackService() => _instance;

  FeedbackService._internal() {
    _settings.addListener(_syncSettings);
  }

  final SettingsService _settings = SettingsService();
  final FlutterTts _tts = FlutterTts();

  bool _ttsInitialized = false;
  String? _languageCode;
  double? _speechRate;

  Future<void> init() async {
    await _initializeTts();
  }

  Future<void> _initializeTts() async {
    if (_ttsInitialized) return;

    await _tts.awaitSpeakCompletion(true);
    await _syncSettings();

    _ttsInitialized = true;
  }

  Future<void> _syncSettings() async {
    final languageCode = _settings.preferredLanguageCode;
    final speechRate = _settings.audioSpeechRate.clamp(0.5, 2.0);

    if (_languageCode != languageCode) {
      _languageCode = languageCode;
      await _setLanguage(languageCode);
    }

    if (_speechRate != speechRate) {
      _speechRate = speechRate;
      await _tts.setSpeechRate(_speechRate!);
    }
  }

  Future<void> _setLanguage(String languageCode) async {
    final locale = _mapLanguageCodeToLocale(languageCode);
    await _tts.setLanguage(locale);
  }

  String _mapLanguageCodeToLocale(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'pt':
      case 'pt-br':
      case 'pt-pt':
        return 'pt-PT';
      case 'en':
      case 'en-us':
      case 'en-gb':
      default:
        return 'en-US';
    }
  }

  Future<void> playAudioFeedback({AudioFeedbackSound sound = AudioFeedbackSound.click}) async {
    if (!_settings.audioFeedbackEnabled) return;

    switch (sound) {
      case AudioFeedbackSound.click:
        SystemSound.play(SystemSoundType.click);
        break;
      case AudioFeedbackSound.alert:
        SystemSound.play(SystemSoundType.alert);
        break;
    }
  }

  Future<void> speak(String text) async {
    if (!_settings.audioNavigationEnabled) return;
    if (text.trim().isEmpty) return;

    await _initializeTts();
    await _syncSettings();

    final effectiveLanguageCode = _settings.preferredLanguageCode;
    if (effectiveLanguageCode != _languageCode) {
      _languageCode = effectiveLanguageCode;
      await _setLanguage(effectiveLanguageCode);
    }

    final effectiveRate = _settings.audioNavigationSpeechRate;

    if (effectiveRate != _speechRate) {
      _speechRate = effectiveRate.clamp(0.5, 2.0);
      await _tts.setSpeechRate(_mapSpeechRate(_speechRate!));
    }

    await _tts.stop();
    await _tts.speak(text);
  }

  double _mapSpeechRate(double rate) {
    final normalized = rate.clamp(0.5, 2.0);
    return (normalized * 0.5).clamp(0.25, 1.0);
  }

  Future<void> announce(BuildContext context, String message, TextDirection textDirection) async {
    if (!(_settings.audioNavigationEnabled || MediaQuery.of(context).accessibleNavigation)) return;
    if (message.trim().isEmpty) return;
    if (!MediaQuery.supportsAnnounceOf(context)) {
      await speak(message);
      return;
    }

    final view = View.of(context);
    SemanticsService.sendAnnouncement(view, message, textDirection);
  }

  Future<void> triggerHaptic() async {
    if (!_settings.hapticFeedbackEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {
      // ignore
    }
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // ignore
    }
  }

  Future<void> stopSpeech() async {
    await _tts.stop();
  }
}
