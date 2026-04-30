import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/accessibility_profile.dart';
import 'api_client.dart';
import 'settings_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static AuthService get instance => _instance;

  static const String _tokenKey = 'auth_token';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';
  static const String _userBioKey = 'user_bio';
  static const String _userRoleKey = 'user_role';
  static const String _userProfileKey = 'user_accessibility_profile';
  static const String _userPreferredLanguageKey = 'user_preferred_language';
  static const String _userAudioGuidanceKey = 'user_audio_guidance';

  static const String dummyEmail = 'd@e.com';
  static const String dummyPassword = 'password';

  bool _isLoggedIn = false;
  String? _userName;
  String? _userEmail;
  String? _phone;
  String? _bio;
  String? _token;
  String? _role;
  AccessibilityProfile? _accessibilityProfile;
  String _preferredLanguageCode = 'pt';
  bool _audioGuidance = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get phone => _phone;
  String? get bio => _bio;
  String? get token => _token;
  String? get role => _role;
  AccessibilityProfile? get accessibilityProfile => _accessibilityProfile;
  String get preferredLanguageCode => _preferredLanguageCode;
  bool get audioGuidance => _audioGuidance;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _userName = prefs.getString(_userNameKey);
    _userEmail = prefs.getString(_userEmailKey);
    _phone = prefs.getString(_userPhoneKey);
    _bio = prefs.getString(_userBioKey);
    _role = prefs.getString(_userRoleKey);
    _accessibilityProfile = AccessibilityProfile.fromServerValue(prefs.getString(_userProfileKey));
    _preferredLanguageCode = prefs.getString(_userPreferredLanguageKey) ?? 'pt';
    _audioGuidance = prefs.getBool(_userAudioGuidanceKey) ?? false;
    _isLoggedIn = _token != null && _token!.isNotEmpty;
    if (_accessibilityProfile != null) {
      await SettingsService().setAccessibilityProfile(_accessibilityProfile!);
    }
    notifyListeners();
  }

  Future<void> setPreferredLanguageCode(String languageCode) async {
    _preferredLanguageCode = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPreferredLanguageKey, languageCode);
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      if (email == dummyEmail && password == dummyPassword) {
        _token = 'dummy_token';
        _userName = 'Demo User';
        _userEmail = email;
        _role = 'user';
        _accessibilityProfile = AccessibilityProfile.None;
        _phone = '+351 900 000 000';
        _bio = 'Welcome to your demo profile. Toggle editing to customize this information.';
        _preferredLanguageCode = 'pt';
        _audioGuidance = false;
        _isLoggedIn = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _token!);
        await prefs.setString(_userNameKey, _userName!);
        await prefs.setString(_userEmailKey, _userEmail!);
        await prefs.setString(_userPhoneKey, _phone!);
        await prefs.setString(_userBioKey, _bio!);
        await prefs.setString(_userRoleKey, _role!);
        await prefs.setString(
          _userProfileKey,
          _accessibilityProfile!.serverValue,
        );
        await prefs.setString(_userPreferredLanguageKey, _preferredLanguageCode);
        await prefs.setBool(_userAudioGuidanceKey, _audioGuidance);
        await SettingsService().setAccessibilityProfile(_accessibilityProfile!);
        notifyListeners();
        return true;
      }

      final response = await http.post(
        Uri.parse(ApiClient.url('/api/v1/auth/login')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Login failed: ${response.body}');
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;

      _token = data['access_token'] as String?;
      _userName = user['full_name'] as String?;
      _userEmail = user['email'] as String?;
      _phone = user['phone'] as String?;
      _bio = user['bio'] as String?;
      _role = user['role'] as String?;
      _accessibilityProfile = AccessibilityProfile.fromServerValue(
        user['accessibility_profile'] as String?,
      );
      _preferredLanguageCode = (user['preferred_language'] as String?) ?? 'pt';
      _audioGuidance = user['audio_guidance'] as bool? ?? false;
      _isLoggedIn = _token != null && _token!.isNotEmpty;

      if (_accessibilityProfile != null) {
        await SettingsService().setAccessibilityProfile(_accessibilityProfile!);
      }

      if (!_isLoggedIn) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);
      if (_userName != null) await prefs.setString(_userNameKey, _userName!);
      if (_userEmail != null) await prefs.setString(_userEmailKey, _userEmail!);
      if (_phone != null) await prefs.setString(_userPhoneKey, _phone!);
      if (_bio != null) await prefs.setString(_userBioKey, _bio!);
      if (_role != null) await prefs.setString(_userRoleKey, _role!);
      await prefs.setString(
        _userProfileKey,
        _accessibilityProfile?.serverValue ?? AccessibilityProfile.None.serverValue,
      );
      await prefs.setString(_userPreferredLanguageKey, _preferredLanguageCode);
      await prefs.setBool(_userAudioGuidanceKey, _audioGuidance);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> signup(
    String name,
    String email,
    String password,
    String confirmPassword,
    AccessibilityProfile accessibilityProfile,
  ) async {
    if (password != confirmPassword) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiClient.url('/api/v1/auth/register')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': name.trim(),
          'email': email,
          'password': password,
          'phone': null,
          'bio': null,
          'role': 'user',
          'accessibility_profile': accessibilityProfile.serverValue,
          'preferred_language': 'pt',
          'audio_guidance': false,
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        debugPrint('Signup failed: ${response.body}');
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;

      _token = data['access_token'] as String?;
      _userName = user['full_name'] as String?;
      _userEmail = user['email'] as String?;
      _phone = user['phone'] as String?;
      _bio = user['bio'] as String?;
      _role = user['role'] as String?;
      _accessibilityProfile = AccessibilityProfile.fromServerValue(
        user['accessibility_profile'] as String?,
      );
      _preferredLanguageCode = (user['preferred_language'] as String?) ?? 'pt';
      _audioGuidance = user['audio_guidance'] as bool? ?? false;
      _isLoggedIn = _token != null && _token!.isNotEmpty;

      if (_accessibilityProfile != null) {
        await SettingsService().setAccessibilityProfile(_accessibilityProfile!);
      }

      if (!_isLoggedIn) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);
      if (_userName != null) await prefs.setString(_userNameKey, _userName!);
      if (_userEmail != null) await prefs.setString(_userEmailKey, _userEmail!);
      if (_phone != null) await prefs.setString(_userPhoneKey, _phone!);
      if (_bio != null) await prefs.setString(_userBioKey, _bio!);
      if (_role != null) await prefs.setString(_userRoleKey, _role!);
      await prefs.setString(
        _userProfileKey,
        _accessibilityProfile?.serverValue ?? AccessibilityProfile.None.serverValue,
      );
      await prefs.setString(_userPreferredLanguageKey, _preferredLanguageCode);
      await prefs.setBool(_userAudioGuidanceKey, _audioGuidance);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Signup error: $e');
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    return email.contains('@');
  }

  Future<void> updateLocalProfile({
    String? fullName,
    String? phone,
    String? bio,
  }) async {
    _userName = fullName ?? _userName;
    _phone = phone ?? _phone;
    _bio = bio ?? _bio;

    final prefs = await SharedPreferences.getInstance();
    if (_userName != null) await prefs.setString(_userNameKey, _userName!);
    if (_phone != null) await prefs.setString(_userPhoneKey, _phone!);
    if (_bio != null) await prefs.setString(_userBioKey, _bio!);

    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userProfileKey);
    await prefs.remove(_userPreferredLanguageKey);
    await prefs.remove(_userAudioGuidanceKey);

    _isLoggedIn = false;
    _userName = null;
    _userEmail = null;
    _phone = null;
    _bio = null;
    _role = null;
    _accessibilityProfile = null;
    _preferredLanguageCode = 'pt';
    _audioGuidance = false;
    _token = null;
    notifyListeners();
  }

  Map<String, String> authHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }
}

class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({super.key, required AuthService authService, required super.child})
      : super(notifier: authService);

  static AuthService of(BuildContext context) {
    final AuthScope? scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found in context');
    return scope!.notifier!;
  }
}