import 'dart:async';

import '../models/diary_entry.dart';

class DiaryService {
  static final DiaryService _instance = DiaryService._internal();
  factory DiaryService() => _instance;
  DiaryService._internal();

  final List<DiaryEntry> _entries = [
    DiaryEntry(
      id: '1',
      title: 'Second Day on Campus',
      date: 'Mar 18, 2026',
      isPrivate: true,
      content: 'Summary of today\'s lecture focused on quantum mechanics.',
      hasText: true,
      audioRecordings: [
        AudioRecording(
          duration: '01:00',
          transcription:
              'After attending the class today, I\'ve attached an audio note about the construction on the Northern Entrance. Currently, it\'s adding about 12 minutes to wheelchair-accessible routes.',
        ),
        AudioRecording(
          duration: '01:00',
          transcription: 'Short note about the library access.',
        ),
        AudioRecording(
          duration: '01:00',
          transcription: 'Reminder: Check Building C lift status.',
        ),
      ],
      images: ['img1', 'img2', 'img3', 'img4', 'img5'],
      videos: ['vid1', 'vid2'],
      messages: [],
      location: 'Building B • B404',
    ),
    DiaryEntry(
      id: '2',
      title: 'Got Lost on Campus',
      date: 'Mar 19, 2026',
      isPrivate: false,
      content: 'I got lost today heading to the cafeteria.',
      hasText: true,
      audioRecordings: [
        AudioRecording(
          duration: '01:00',
          transcription:
              'I tried to go to the cafeteria right after leaving the last class of the morning. My colleagues told me that it\'s normally packed with people and that the best thing i could.',
        ),
      ],
      images: [],
      videos: [],
      messages: [
        ChatMessage(
          sender: 'Campus Admin',
          time: 'Mar 18, 2026 • 4:45 PM',
          content:
              'Thank you for sharing your experience. We\'re sorry to hear that our navigation feature didn\'t work so well for you.\n\nWe\'ll be in contact with you when possible. In the meantime, tell us more!',
          isAdmin: true,
        ),
        ChatMessage(
          sender: 'Username',
          time: 'Mar 18, 2026 • 6:30 PM',
          content:
              'I tried so many times to search for the cafeteria, but had no luck. Is it even in the app? In the end I got lucky that someone showed me the way.',
          isAdmin: false,
        ),
      ],
      location: 'Building B • B404',
      badgeCount: 1,
    ),
  ];

  Future<List<DiaryEntry>> fetchEntries() async {
    await Future.delayed(const Duration(milliseconds: 450));
    return List<DiaryEntry>.from(_entries);
  }

  Future<DiaryEntry> createEntry({
    required String title,
    required String content,
    required bool isPrivate,
    required List<Attachment> attachments,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final now = DateTime.now();
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final formattedDate = '${monthNames[now.month - 1]} ${now.day}, ${now.year}';

    final entry = DiaryEntry(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      date: formattedDate,
      isPrivate: isPrivate,
      content: content,
      hasText: content.trim().isNotEmpty,
      audioRecordings: [],
      images: attachments.where((attachment) => attachment.type == 'Image').map((attachment) => attachment.path ?? attachment.name).toList(),
      videos: attachments.where((attachment) => attachment.type == 'Video').map((attachment) => attachment.path ?? attachment.name).toList(),
      messages: [],
      location: '',
    );

    _entries.insert(0, entry);
    return entry;
  }

  Future<void> deleteEntry(String id) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _entries.removeWhere((entry) => entry.id == id);
  }

  List<DiaryEntry> get entries => List.unmodifiable(_entries);
}
