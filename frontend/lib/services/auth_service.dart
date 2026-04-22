import 'dart:async';

import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isLoggedIn = false;
  String? _userName;
  String? _userEmail;

  bool get isLoggedIn => _isLoggedIn;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (email.toLowerCase() == 'error' || !email.contains('@') || password.length < 5) {
      return false;
    }

    _isLoggedIn = true;
    _userEmail = email;
    _userName = email.split('@').first;
    notifyListeners();
    return true;
  }

  Future<bool> signup(
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (name.trim().isEmpty || !email.contains('@') || password.length < 6 || password != confirmPassword) {
      return false;
    }

    _isLoggedIn = true;
    _userName = name.trim();
    _userEmail = email;
    notifyListeners();
    return true;
  }

  Future<bool> resetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 350));

    return email.contains('@');
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _isLoggedIn = false;
    _userName = null;
    _userEmail = null;
    notifyListeners();
  }
}
