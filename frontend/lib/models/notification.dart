import 'package:flutter/material.dart';

class NotificationData {
  final String id;
  final String type;
  final String title;
  final String message;
  final String priority;
  final String? action;
  final DateTime? shownAt;
  final DateTime? readAt;
  final DateTime? dismissedAt;
  final DateTime? expiresAt;

  NotificationData({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    this.action,
    this.shownAt,
    this.readAt,
    this.dismissedAt,
    this.expiresAt,
  });

  bool get isUnread => readAt == null;

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      priority: json['priority'],
      action: json['action'],
      shownAt: json['shown_at'] != null ? DateTime.parse(json['shown_at']) : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      dismissedAt: json['dismissed_at'] != null ? DateTime.parse(json['dismissed_at']) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    );
  }

  IconData get icon {
    switch (type) {
      case 'diary_daily_reminder':
        return Icons.edit_note;
      case 'system_update':
        return Icons.system_update_outlined;
      case 'location_reminder':
        return Icons.location_on_outlined;
      case 'share':
        return Icons.share_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
