import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'auth_service.dart';

/// Result of `/api/v1/media/upload-url`. Mirrors the backend's
/// PresignUploadResponse schema.
class PresignedUpload {
  final String key;
  final String uploadUrl;
  final String publicUrl;
  final int expiresIn;
  final Map<String, String> requiredHeaders;

  PresignedUpload({
    required this.key,
    required this.uploadUrl,
    required this.publicUrl,
    required this.expiresIn,
    required this.requiredHeaders,
  });

  factory PresignedUpload.fromJson(Map<String, dynamic> json) {
    final headers = <String, String>{};
    final raw = json['required_headers'];
    if (raw is Map) {
      raw.forEach((k, v) => headers[k.toString()] = v.toString());
    }
    return PresignedUpload(
      key: json['key'] as String,
      uploadUrl: json['upload_url'] as String,
      publicUrl: json['public_url'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
      requiredHeaders: headers,
    );
  }
}

/// Thrown when an upload fails. The message is safe to show in the UI.
class MediaUploadException implements Exception {
  final String message;
  final int? statusCode;
  MediaUploadException(this.message, {this.statusCode});
  @override
  String toString() =>
      'MediaUploadException(${statusCode ?? '-'}): $message';
}

/// Maps the UI-side type chip ('Image' / 'Video' / 'Audio') to the
/// backend's media_type enum. Centralised here so widgets don't keep
/// rolling their own.
String mediaTypeForAttachmentType(String attachmentType) {
  switch (attachmentType.toLowerCase()) {
    case 'image':
      return 'image';
    case 'video':
      return 'video';
    case 'audio':
      return 'audio';
    default:
      throw ArgumentError(
        'Unknown attachment type "$attachmentType" — '
        'expected Image, Video, or Audio.',
      );
  }
}

/// Singleton media-upload service. Pattern matches the other services
/// (DiaryService, AuthService, etc.).
class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  // Override in tests by passing a different client; otherwise we use a
  // single shared client so HTTP keep-alive can kick in across uploads.
  http.Client _client = http.Client();
  // ignore: avoid_setters_without_getters
  set client(http.Client c) => _client = c;

  AuthService _authService = AuthService();
  // ignore: avoid_setters_without_getters
  set authService(AuthService s) => _authService = s;

  /// Step 1 of the upload flow: ask the backend for a presigned PUT URL.
  Future<PresignedUpload> requestUploadUrl({
    required String mediaType,
    required String filenameOrExtension,
    String? entryId,
    String? contentType,
  }) async {
    final token = _authService.token;
    if (token == null || token.isEmpty) {
      throw MediaUploadException('Not signed in.');
    }

    final body = <String, dynamic>{
      'media_type': mediaType,
      'extension': filenameOrExtension,
    };
    if (entryId != null) body['entry_id'] = entryId;
    if (contentType != null) body['content_type'] = contentType;

    final uri = Uri.parse(ApiClient.url('/api/v1/media/upload-url'));
    http.Response resp;
    try {
      resp = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw MediaUploadException(
        'The server took too long to respond. Check your connection and try again.',
      );
    } on SocketException {
      throw MediaUploadException(
        'Could not reach the server. Check your connection and try again.',
      );
    }

    if (resp.statusCode != 200) {
      throw MediaUploadException(
        _extractErrorMessage(resp.body) ??
            'Upload could not be prepared (HTTP ${resp.statusCode}).',
        statusCode: resp.statusCode,
      );
    }
    return PresignedUpload.fromJson(
      jsonDecode(resp.body) as Map<String, dynamic>,
    );
  }

  /// Step 2: PUT the file straight to R2 using the presigned URL. We use
  /// a StreamedRequest so we can report byte-level progress while the
  /// request is in flight.
  ///
  /// The progress here tracks bytes pumped into the request sink, not
  /// strictly the bytes acknowledged by the server. That's a reasonable
  /// approximation for a smooth progress bar — for a few-MB diary file,
  /// the visible jitter is negligible.
  Future<void> uploadBytes({
    required File file,
    required PresignedUpload presign,
    void Function(int sent, int total)? onProgress,
  }) async {
    final length = await file.length();
    final stream = file.openRead();

    final request = http.StreamedRequest('PUT', Uri.parse(presign.uploadUrl));
    presign.requiredHeaders.forEach((k, v) => request.headers[k] = v);
    request.contentLength = length;

    // Kick off the request before pumping bytes — `client.send` returns
    // as soon as headers are written, then drains the sink as bytes arrive.
    final responseFuture = _client.send(request);

    int sent = 0;
    onProgress?.call(0, length);
    final completer = Completer<void>();

    final sub = stream.listen(
      (chunk) {
        request.sink.add(chunk);
        sent += chunk.length;
        onProgress?.call(math.min(sent, length), length);
      },
      onDone: () {
        request.sink.close();
        completer.complete();
      },
      onError: (Object e, StackTrace st) {
        request.sink.addError(e, st);
        completer.completeError(e, st);
      },
      cancelOnError: true,
    );

    try {
      await completer.future;
    } finally {
      await sub.cancel();
    }

    http.StreamedResponse resp;
    try {
      resp = await responseFuture.timeout(const Duration(minutes: 5));
    } on TimeoutException {
      throw MediaUploadException(
        'Upload timed out. Try again on a stronger connection.',
      );
    } on SocketException {
      throw MediaUploadException(
        'Connection dropped while uploading. Try again.',
      );
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      // Drain the body so the connection can be reused; surface the
      // first chunk of the response in the error to aid debugging.
      final body = await resp.stream.bytesToString();
      // Common case: SignatureDoesNotMatch when Content-Type doesn't
      // match what was signed. We hint at that here so the cause is
      // obvious during integration.
      final hint = body.contains('SignatureDoesNotMatch')
          ? ' (Content-Type may not match the value the server signed.)'
          : '';
      throw MediaUploadException(
        'Upload rejected by storage (HTTP ${resp.statusCode}).$hint',
        statusCode: resp.statusCode,
      );
    }
  }

  /// Convenience: presign + upload in one call. Returns the public URL
  /// that should be persisted on the diary entry.
  Future<String> uploadMedia({
    required File file,
    required String attachmentType, // 'Image' | 'Video' | 'Audio'
    String? entryId,
    void Function(int sent, int total)? onProgress,
  }) async {
    final mediaType = mediaTypeForAttachmentType(attachmentType);
    final ext = _extensionFromPath(file.path);
    if (ext.isEmpty) {
      throw MediaUploadException(
        'Could not determine the file extension for "${file.path}".',
      );
    }

    final presign = await requestUploadUrl(
      mediaType: mediaType,
      filenameOrExtension: ext,
      entryId: entryId,
    );
    await uploadBytes(file: file, presign: presign, onProgress: onProgress);
    return presign.publicUrl;
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------
  static String _extensionFromPath(String path) {
    final lastSlash = math.max(path.lastIndexOf('/'), path.lastIndexOf('\\'));
    final filename = lastSlash >= 0 ? path.substring(lastSlash + 1) : path;
    final dot = filename.lastIndexOf('.');
    if (dot <= 0 || dot == filename.length - 1) return '';
    return filename.substring(dot + 1).toLowerCase();
  }

  /// Extract a human-readable message from a FastAPI error body.
  /// Bodies usually look like `{"detail": "..."}` for HTTPException.
  static String? _extractErrorMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] != null) {
        final detail = decoded['detail'];
        if (detail is String) return detail;
        return detail.toString();
      }
    } catch (_) {
      // Fall through and return null.
    }
    return null;
  }
}
