import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';
import '../models/diary_entry.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'diary_service.dart';
import 'settings_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  List<NotificationData> _notifications = [];
  bool _isLoading = false;
  Timer? _pollTimer;
  static const Duration _pollInterval = Duration(seconds: 30);
  static const String _cacheKey = 'notifications_cache';

  List<NotificationData> get notifications => _notifications.where((n) => n.type != 'chat_message').toList();
  bool get isLoading => _isLoading;

  bool _sessionExpiredLogout = false;

  int get unreadCount => notifications.where((n) => n.isUnread).length;

  String get unreadCountDisplay {
    int count = unreadCount;
    return count > 9 ? '9+' : count.toString();
  }

  bool get sessionExpiredLogout => _sessionExpiredLogout;

  void clearSessionExpiredLogout() {
    _sessionExpiredLogout = false;
  }

  Future<void> init() async {
    await _loadCache();
    AuthService.instance.addListener(_handleAuthChange);
    _handleAuthChange();
  }

  void _handleAuthChange() {
    if (AuthService.instance.isLoggedIn) {
      fetchNotifications();
      _startPolling();
    } else {
      _stopPolling();
      _notifications = [];
      _saveCache();
      Future.microtask(() => notifyListeners());
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (AuthService.instance.isLoggedIn) {
        fetchNotifications();
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _showLocalPushNotification(NotificationData notification) {
    // In a real app, you'd use flutter_local_notifications here.
    // Since we don't have it in pubspec, we'll simulate the intent.
    debugPrint('PUSH NOTIFICATION: ${notification.title} - ${notification.message}');
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      final List<dynamic> data = jsonDecode(cached);
      _notifications = data.map((json) => NotificationData.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _notifications.map((n) => {
      'id': n.id,
      'type': n.type,
      'title': n.title,
      'message': n.message,
      'priority': n.priority,
      'action': n.action,
      'shown_at': n.shownAt?.toIso8601String(),
      'read_at': n.readAt?.toIso8601String(),
      'dismissed_at': n.dismissedAt?.toIso8601String(),
      'expires_at': n.expiresAt?.toIso8601String(),
    }).toList();
    await prefs.setString(_cacheKey, jsonEncode(data));
  }

  Future<bool> _handleUnauthorizedResponse(http.Response response) async {
    if (response.statusCode == 401 || response.statusCode == 403) {
      debugPrint('Unauthorized notification request, logging out user.');
      _sessionExpiredLogout = true;
      await AuthService.instance.logout();
      return true;
    }
    return false;
  }

  Future<void> fetchNotifications() async {
    if (!AuthService.instance.isLoggedIn) return;
    
    if (_isLoading) return;
    _isLoading = true;
    
    Future.microtask(() => notifyListeners());

    try {
      // Fetch only unread notifications to sync with server
      final response = await http.get(
        Uri.parse(ApiClient.url('/api/v1/notifications?unread_only=true')),
        headers: AuthService.instance.authHeaders(),
      );

      if (await _handleUnauthorizedResponse(response)) {
        _isLoading = false;
        Future.microtask(() => notifyListeners());
        return;
      }

      if (response.statusCode == 200) {
        final List<dynamic> serverUnread = jsonDecode(response.body);
        final List<NotificationData> unreadNotifs = serverUnread.map((json) => NotificationData.fromJson(json)).toList();
        final Set<String> serverUnreadIds = unreadNotifs.map((n) => n.id).toSet();

        bool changed = false;
        final List<NotificationData> updatedList = [];

        // 1. Process existing notifications
        for (var n in _notifications) {
          if (n.isUnread && !serverUnreadIds.contains(n.id)) {
            // No longer unread on server, mark as read locally
            updatedList.add(NotificationData(
              id: n.id,
              type: n.type,
              title: n.title,
              message: n.message,
              priority: n.priority,
              action: n.action,
              shownAt: n.shownAt,
              readAt: DateTime.now(),
              dismissedAt: n.dismissedAt,
              expiresAt: n.expiresAt,
            ));
            changed = true;
          } else {
            // Keep as is, or update if it's in serverUnread (next step)
            updatedList.add(n);
          }
        }

        // 2. Add new notifications or update existing unread ones
        final existingIds = _notifications.map((n) => n.id).toSet();
        for (var n in unreadNotifs) {
          if (!existingIds.contains(n.id)) {
            updatedList.add(n);
            changed = true;
            if (SettingsService().pushNotificationsEnabled) {
              _showLocalPushNotification(n);
            }
          } else {
            // Update existing unread with latest data from server
            int idx = updatedList.indexWhere((en) => en.id == n.id);
            if (idx != -1) {
              // Only update if server has new read status or if we haven't marked it read locally yet
              if (updatedList[idx].readAt == null && n.readAt != null) {
                 updatedList[idx] = n;
                 changed = true;
              }
            }
          }
        }

        if (changed) {
          _notifications = updatedList;
          _notifications.sort((a, b) => (b.shownAt ?? DateTime.now()).compareTo(a.shownAt ?? DateTime.now()));
          await _saveCache();
        }
      } else {
        debugPrint('Failed to fetch notifications: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final response = await http.patch(
        Uri.parse(ApiClient.url('/api/v1/notifications/$id/read')),
        headers: AuthService.instance.authHeaders(),
      );

      if (await _handleUnauthorizedResponse(response)) {
        return;
      }

      if (response.statusCode == 200) {
        int index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          final updated = NotificationData.fromJson(jsonDecode(response.body));
          _notifications[index] = updated;
          await _saveCache();
          Future.microtask(() => notifyListeners());
        }
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> dismiss(String id) async {
    try {
      final response = await http.patch(
        Uri.parse(ApiClient.url('/api/v1/notifications/$id/dismiss')),
        headers: AuthService.instance.authHeaders(),
      );

      if (await _handleUnauthorizedResponse(response)) {
        return;
      }

      if (response.statusCode == 200) {
        _notifications.removeWhere((n) => n.id == id);
        await _saveCache();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error dismissing notification: $e');
    }
  }
}
