class ChatMessage {
  final String sender;
  final String time;
  final String content;
  final bool isAdmin;

  ChatMessage({
    required this.sender,
    required this.time,
    required this.content,
    required this.isAdmin,
  });
}

class AudioRecording {
  final String duration;
  final String transcription;
  bool isExpanded;

  AudioRecording({
    required this.duration,
    required this.transcription,
    this.isExpanded = false,
  });
}

class Attachment {
  final String name;
  final String type;
  DateTime createdAt;
  int sizeBytes;
  final String? path;
  bool isUploading;
  double uploadProgress;

  Attachment({
    required this.name,
    required this.type,
    required this.createdAt,
    required this.sizeBytes,
    this.path,
    this.isUploading = false,
    this.uploadProgress = 1.0,
  });

  String get readableSize => formatFileSize(sizeBytes);
}

String formatFileSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '$bytes B';
}

class DiaryEntry {
  final String id;
  final String title;
  final String date;
  final bool isPrivate;
  final String content;
  final bool hasText;
  final List<AudioRecording> audioRecordings;
  final List<String> images;
  final List<String> videos;
  final List<ChatMessage> messages;
  final String location;
  final int? badgeCount;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.date,
    required this.isPrivate,
    required this.content,
    required this.hasText,
    required this.audioRecordings,
    required this.images,
    required this.videos,
    required this.messages,
    required this.location,
    this.badgeCount,
  });

  int get audioCount => audioRecordings.length;
  int get imageCount => images.length;
  int get videoCount => videos.length;
}
