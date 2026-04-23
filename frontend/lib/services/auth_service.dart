import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';
  static const String _userProfileKey = 'user_accessibility_profile';

  bool _isLoggedIn = false;
  String? _userName;
  String? _userEmail;
  String? _token;
  String? _role;
  String? _accessibilityProfile;

  bool get isLoggedIn => _isLoggedIn;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get token => _token;
  String? get role => _role;
  String? get accessibilityProfile => _accessibilityProfile;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _userName = prefs.getString(_userNameKey);
    _userEmail = prefs.getString(_userEmailKey);
    _role = prefs.getString(_userRoleKey);
    _accessibilityProfile = prefs.getString(_userProfileKey);
    _isLoggedIn = _token != null && _token!.isNotEmpty;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
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
      _role = user['role'] as String?;
      _accessibilityProfile = user['accessibility_profile'] as String?;
      _isLoggedIn = _token != null && _token!.isNotEmpty;

      if (!_isLoggedIn) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);
      if (_userName != null) await prefs.setString(_userNameKey, _userName!);
      if (_userEmail != null) await prefs.setString(_userEmailKey, _userEmail!);
      if (_role != null) await prefs.setString(_userRoleKey, _role!);
      if (_accessibilityProfile != null) {
        await prefs.setString(_userProfileKey, _accessibilityProfile!);
      }

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
          'accessibility_profile': 'none',
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
      _role = user['role'] as String?;
      _accessibilityProfile = user['accessibility_profile'] as String?;
      _isLoggedIn = _token != null && _token!.isNotEmpty;

      if (!_isLoggedIn) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);
      if (_userName != null) await prefs.setString(_userNameKey, _userName!);
      if (_userEmail != null) await prefs.setString(_userEmailKey, _userEmail!);
      if (_role != null) await prefs.setString(_userRoleKey, _role!);
      if (_accessibilityProfile != null) {
        await prefs.setString(_userProfileKey, _accessibilityProfile!);
      }

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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userProfileKey);

    _isLoggedIn = false;
    _userName = null;
    _userEmail = null;
    _role = null;
    _accessibilityProfile = null;
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