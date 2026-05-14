import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/diary_entry.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Thrown by DiaryService. The `message` is safe to surface in a snackbar.
class DiaryServiceException implements Exception {
  final String message;
  final int? statusCode;
  DiaryServiceException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

/// Backend-backed diary store. Acts as both a network client and a local
/// cache: methods round-trip to the API and update `_entries` so the UI's
/// `entries` getter stays consistent without a separate refresh step.
///
/// Scope is intentionally narrow: create + list. Delete and "mark read"
/// remain local-only — the UI calls them on a single device session and
/// nothing depends on their server state. Comments/messages are also
/// out of scope for now (parsed from responses where present, but never
/// posted from this client).
class DiaryService extends ChangeNotifier {
  static final DiaryService _instance = DiaryService._internal();
  factory DiaryService() => _instance;
  DiaryService._internal();

  // ---------------------------------------------------------------------
  // Test seams. Swap during tests; production uses the defaults.
  // ---------------------------------------------------------------------
  http.Client _client = http.Client();
  // ignore: avoid_setters_without_getters
  set client(http.Client c) => _client = c;

  AuthService _authService = AuthService();
  // ignore: avoid_setters_without_getters
  set authService(AuthService s) => _authService = s;

  final List<DiaryEntry> _entries = [];

  List<DiaryEntry> get entries => List.unmodifiable(_entries);

  // ---------------------------------------------------------------------
  // Network surface
  // ---------------------------------------------------------------------

  /// GET /api/v1/diary-entries/me — replaces the local cache with the
  /// server's view. Pagination params are exposed in case the UI wants
  /// to scroll back; for now `limit=50` is plenty.
  Future<List<DiaryEntry>> fetchEntries({int limit = 50, int offset = 0}) async {
    final uri = Uri.parse(
      ApiClient.url('/api/v1/diary-entries/me?limit=$limit&offset=$offset'),
    );

    http.Response resp;
    try {
      resp = await _client
          .get(uri, headers: _authHeaders())
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw DiaryServiceException(
        'The server took too long to respond. Try again on a stronger connection.',
      );
    } on SocketException {
      throw DiaryServiceException(
        'Could not reach the server. Check your connection.',
      );
    }

    if (resp.statusCode != 200) {
      throw DiaryServiceException(
        _extractErrorMessage(resp.body) ??
            'Failed to load entries (HTTP ${resp.statusCode}).',
        statusCode: resp.statusCode,
      );
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final items = (body['items'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final parsed = items.map(_diaryEntryFromJson).toList();

    _entries
      ..clear()
      ..addAll(parsed);
    notifyListeners();
    return List<DiaryEntry>.from(parsed);
  }

  /// GET /api/v1/diary-entries/{id} — refresh a single entry (mainly so
  /// the detail page can pull the latest comments without re-fetching
  /// the whole list). Updates the entry in `_entries` if it's cached.
  Future<DiaryEntry> fetchEntry(String id) async {
    final uri = Uri.parse(ApiClient.url('/api/v1/diary-entries/$id'));

    http.Response resp;
    try {
      resp = await _client
          .get(uri, headers: _authHeaders())
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw DiaryServiceException(
        'The server took too long to respond. Try again on a stronger connection.',
      );
    } on SocketException {
      throw DiaryServiceException(
        'Could not reach the server. Check your connection.',
      );
    }

    if (resp.statusCode == 404) {
      throw DiaryServiceException(
        'This entry no longer exists.',
        statusCode: 404,
      );
    }
    if (resp.statusCode != 200) {
      throw DiaryServiceException(
        _extractErrorMessage(resp.body) ??
            'Failed to load entry (HTTP ${resp.statusCode}).',
        statusCode: resp.statusCode,
      );
    }

    final entry = _diaryEntryFromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );

    // Update the cache in place if we have this entry; otherwise leave
    // the list untouched (caller can refresh the list separately if it
    // cares).
    final cachedIndex = _entries.indexWhere((e) => e.id == entry.id);
    if (cachedIndex >= 0) {
      _entries[cachedIndex] = entry;
      notifyListeners();
    }
    return entry;
  }

  /// POST /api/v1/diary-entries — persists a new entry and prepends it
  /// to the local cache. Throws DiaryServiceException if any attachment
  /// hasn't successfully uploaded yet (better to warn than silently drop).
  Future<DiaryEntry> createEntry({
    required String title,
    required String content,
    required bool isPrivate,
    required List<Attachment> attachments,
    String location = '',
  }) async {
    // Guard: any attachment without a public URL means an upload failed
    // or is still in flight. Don't silently drop the user's work.
    final unresolved = attachments
        .where((a) => a.publicUrl == null || a.publicUrl!.isEmpty)
        .toList();
    if (unresolved.isNotEmpty) {
      throw DiaryServiceException(
        unresolved.length == 1
            ? 'One attachment hasn\'t finished uploading. Retry or remove it before saving.'
            : '${unresolved.length} attachments haven\'t finished uploading. Retry or remove them before saving.',
      );
    }

    final mediaItems = attachments
        .map((a) => <String, dynamic>{
              'media_type': a.type.toLowerCase(),
              'url': a.publicUrl,
            })
        .toList();

    final trimmedTitle = title.trim();
    final trimmedBody = content.trim();
    final payload = <String, dynamic>{
      'entry_type': _inferEntryType(trimmedBody, attachments),
      'recorded_at': DateTime.now().toUtc().toIso8601String(),
      'context_notes': <String, dynamic>{
        if (trimmedTitle.isNotEmpty) 'title': trimmedTitle,
        'is_private': isPrivate,
      },
      'is_synced': true,
      'media_items': mediaItems,
    };
    if (trimmedBody.isNotEmpty) payload['body'] = trimmedBody;
    if (location.isNotEmpty) {
      // location_id is a UUID on the backend. The current UI passes a
      // free-form string (e.g. 'loc_001'), so we only forward values
      // that look like UUIDs and drop the rest. A future iteration
      // should let the user pick a real location.
      if (_looksLikeUuid(location)) payload['location_id'] = location;
    }

    final uri = Uri.parse(ApiClient.url('/api/v1/diary-entries/'));
    http.Response resp;
    try {
      resp = await _client
          .post(uri, headers: _authHeaders(), body: jsonEncode(payload))
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw DiaryServiceException(
        'The server took too long to respond. Try again on a stronger connection.',
      );
    } on SocketException {
      throw DiaryServiceException(
        'Could not reach the server. Check your connection.',
      );
    }

    if (resp.statusCode != 201) {
      throw DiaryServiceException(
        _extractErrorMessage(resp.body) ??
            'Failed to create entry (HTTP ${resp.statusCode}).',
        statusCode: resp.statusCode,
      );
    }

    final entry = _diaryEntryFromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
    _entries.insert(0, entry);
    notifyListeners();
    return entry;
  }

  /// POST /api/v1/diary-entries/{entry_id}/comments — the user (entry
  /// owner) posts a reply in their own thread. Returns the new ChatMessage
  /// and appends it to the cached entry's messages so the UI updates
  /// without a refetch.
  Future<ChatMessage> postComment({
    required String entryId,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      throw DiaryServiceException('Comment cannot be empty.');
    }

    final uri = Uri.parse(
      ApiClient.url('/api/v1/diary-entries/$entryId/comments'),
    );

    http.Response resp;
    try {
      resp = await _client
          .post(
            uri,
            headers: _authHeaders(),
            body: jsonEncode({'body': trimmed}),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw DiaryServiceException(
        'The server took too long to respond. Try again on a stronger connection.',
      );
    } on SocketException {
      throw DiaryServiceException(
        'Could not reach the server. Check your connection.',
      );
    }

    if (resp.statusCode == 404) {
      throw DiaryServiceException(
        'This entry no longer exists.',
        statusCode: 404,
      );
    }
    if (resp.statusCode != 201) {
      throw DiaryServiceException(
        _extractErrorMessage(resp.body) ??
            'Failed to send message (HTTP ${resp.statusCode}).',
        statusCode: resp.statusCode,
      );
    }

    final newMessage = _chatMessageFromComment(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );

    // Patch the cached entry so the detail page (and any other listener)
    // sees the new message without a server round-trip.
    final idx = _entries.indexWhere((e) => e.id == entryId);
    if (idx >= 0) {
      final old = _entries[idx];
      _entries[idx] = DiaryEntry(
        id: old.id,
        title: old.title,
        date: old.date,
        isPrivate: old.isPrivate,
        content: old.content,
        hasText: old.hasText,
        audioRecordings: old.audioRecordings,
        images: old.images,
        videos: old.videos,
        messages: [...old.messages, newMessage],
        location: old.location,
        badgeCount: old.badgeCount,
      );
      notifyListeners();
    }
    return newMessage;
  }

  // ---------------------------------------------------------------------
  // Local-only operations
  // ---------------------------------------------------------------------

  /// Local-only delete — not wired to DELETE /api/v1/diary-entries/{id}
  /// because the UI doesn't surface delete anywhere yet. When that lands,
  /// swap this for a real network call.
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((entry) => entry.id == id);
    notifyListeners();
  }

  int get unreadMessageCount => _entries.fold<int>(
        0,
        (count, entry) => count + (entry.badgeCount ?? 0),
      );

  bool get hasUnreadMessages => unreadMessageCount > 0;

  /// Local-only — the server has no concept of "read state" on comments
  /// yet. Survives the current session; a refetch resets it.
  void markAsRead(String id) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final old = _entries[index];
    if (old.badgeCount == null || old.badgeCount! <= 0) return;
    _entries[index] = DiaryEntry(
      id: old.id,
      title: old.title,
      date: old.date,
      isPrivate: old.isPrivate,
      content: old.content,
      hasText: old.hasText,
      audioRecordings: old.audioRecordings,
      images: old.images,
      videos: old.videos,
      messages: old.messages,
      location: old.location,
      badgeCount: 0,
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  Map<String, String> _authHeaders() {
    final token = _authService.token;
    if (token == null || token.isEmpty) {
      throw DiaryServiceException('You need to sign in first.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Smart inference per the agreed scope.
  ///
  /// The backend's validator forbids text entries from carrying media
  /// (`text` + media_items -> 400 "Text entries cannot include media
  /// items"). So whenever there's any attachment, the entry type has to
  /// be a media type — body is allowed on media entries and shows up as
  /// a caption.
  ///
  /// Priority when multiple media kinds are present: video > audio > image.
  /// Fallback (no attachments at all) is 'text'.
  static String _inferEntryType(String trimmedBody, List<Attachment> attachments) {
    final types = attachments.map((a) => a.type.toLowerCase()).toSet();
    if (types.contains('video')) return 'video';
    if (types.contains('audio')) return 'audio';
    if (types.contains('image')) return 'image';
    return 'text';
  }

  /// Cheap UUID-shape check so we don't send '"loc_001"' as a UUID field.
  static final RegExp _uuidRe = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static bool _looksLikeUuid(String s) => _uuidRe.hasMatch(s);

  /// Pull a `detail` message out of a FastAPI error body.
  static String? _extractErrorMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] != null) {
        final detail = decoded['detail'];
        return detail is String ? detail : detail.toString();
      }
    } catch (_) {}
    return null;
  }

  // ---------------------------------------------------------------------
  // JSON → model mapping
  //
  // The Flutter DiaryEntry model is shaped around the UI's needs (split
  // media lists, title/isPrivate as first-class fields, formatted date
  // string). The backend's DiaryEntryResponse is shaped around the
  // schema (unified media_items, context_notes JSONB, ISO timestamps).
  // This is where the two views meet.
  // ---------------------------------------------------------------------

  static DiaryEntry _diaryEntryFromJson(Map<String, dynamic> json) {
    final ctx =
        ((json['context_notes'] as Map?)?.cast<String, dynamic>()) ??
            const {};
    final title = ((ctx['title'] as String?) ?? '').trim();
    final isPrivate = (ctx['is_private'] as bool?) ?? false;

    final body = (json['body'] as String?) ?? '';

    final audio = <AudioRecording>[];
    final images = <String>[];
    final videos = <String>[];
    final mediaItems = ((json['media_items'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    for (final m in mediaItems) {
      final mt = ((m['media_type'] as String?) ?? '').toLowerCase();
      final url = (m['url'] as String?) ?? '';
      if (url.isEmpty) continue;
      switch (mt) {
        case 'audio':
          audio.add(AudioRecording(
            duration: _formatDuration(m['duration_sec']),
            transcription: (m['transcription'] as String?) ?? '',
          ));
          break;
        case 'image':
          images.add(url);
          break;
        case 'video':
          videos.add(url);
          break;
      }
    }

    // Comments are out of scope for write, but we parse them on read so
    // any pre-existing replies show up in the UI.
    final comments = ((json['comments'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final messages = comments.map(_chatMessageFromComment).toList();

    final recordedAt =
        (json['recorded_at'] as String?) ?? (json['created_at'] as String? ?? '');

    return DiaryEntry(
      id: json['id'] as String,
      title: title,
      date: _formatDate(recordedAt),
      isPrivate: isPrivate,
      content: body,
      hasText: body.trim().isNotEmpty,
      audioRecordings: audio,
      images: images,
      videos: videos,
      messages: messages,
      location: (json['location_id'] as String?) ?? '',
      // Unread badge: not tracked server-side yet — start at 0.
      badgeCount: 0,
    );
  }

  static ChatMessage _chatMessageFromComment(Map<String, dynamic> c) {
    // The backend's DiaryEntryCommentResponse now includes a nested
    // `author` summary with full_name + role. Prefer those over the raw
    // author_id when present.
    final author = (c['author'] as Map?)?.cast<String, dynamic>();
    final fullName = (author?['full_name'] as String?)?.trim();
    final role = (author?['role'] as String?)?.toLowerCase();

    final sender = (fullName != null && fullName.isNotEmpty)
        ? fullName
        // Fallbacks: an author_id with no expanded summary, or a system
        // reply with no author at all.
        : ((c['author_id'] as String?) ?? 'Campus Admin');

    final isAdmin = role == 'admin' || role == 'superadmin';

    return ChatMessage(
      sender: sender,
      time: _formatDateTime((c['created_at'] as String?) ?? ''),
      content: (c['body'] as String?) ?? '',
      isAdmin: isAdmin,
    );
  }

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final local = dt.toLocal();
    return '${_monthNames[local.month - 1]} ${local.day}, ${local.year}';
  }

  static String _formatDateTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final local = dt.toLocal();
    final date = _formatDate(iso);
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$date • $hh:$mm';
  }

  static String _formatDuration(dynamic sec) {
    if (sec == null) return '00:00';
    final s = sec is num
        ? sec.toInt()
        : int.tryParse(sec.toString().split('.').first) ?? 0;
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
