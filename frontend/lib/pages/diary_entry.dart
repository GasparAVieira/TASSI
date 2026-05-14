import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../services/settings_service.dart';
import '../services/diary_service.dart';
import '../widgets/diary_entry_widgets.dart';

class DiaryEntryPage extends StatefulWidget {
  final DiaryEntry entry;

  const DiaryEntryPage({super.key, required this.entry});

  @override
  State<DiaryEntryPage> createState() => _DiaryEntryPageState();
}

class _DiaryEntryPageState extends State<DiaryEntryPage> {
  late DiaryEntry _entry;
  late bool _isPrivate;
  bool _allExpanded = true;
  bool _isRefreshing = false;
  final Map<String, bool> _sectionStates = {};
  final GlobalKey<AudioCarouselState> _audioCarouselKey = GlobalKey<AudioCarouselState>();
  final DiaryService _diaryService = DiaryService();
  int _badgeCount = 0;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _isPrivate = _entry.isPrivate;
    _badgeCount = _entry.badgeCount ?? 0;
    _initSectionStates();

    // React to DiaryService cache changes — fires after fetchEntry,
    // postComment, etc. Lets the chat list update without us having
    // to re-fetch explicitly.
    _diaryService.addListener(_onDiaryServiceChanged);

    // Mark entry as read when viewed
    if (_badgeCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _badgeCount = 0;
        });
        _diaryService.markAsRead(_entry.id);
      });
    }

    // Kick off a refresh in the background so the chat shows the
    // latest admin replies on every open. The cached entry stays
    // visible meanwhile — no blocking spinner.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _diaryService.removeListener(_onDiaryServiceChanged);
    super.dispose();
  }

  void _onDiaryServiceChanged() {
    if (!mounted) return;
    final fresh = _diaryService.entries
        .where((e) => e.id == _entry.id)
        .cast<DiaryEntry?>()
        .firstWhere((e) => true, orElse: () => null);
    if (fresh != null && !identical(fresh, _entry)) {
      setState(() => _entry = fresh);
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    if (mounted) setState(() => _isRefreshing = true);
    try {
      final fresh = await _diaryService.fetchEntry(_entry.id);
      if (!mounted) return;
      setState(() {
        _entry = fresh;
        // Server-side authoritative privacy/badge would override the
        // local state — but right now the server doesn't track either,
        // so we keep the local toggle for _isPrivate untouched.
      });
    } on DiaryServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Couldn't refresh entry: ${e.message}"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _initSectionStates() {
    if (_entry.content.isNotEmpty) _sectionStates['text'] = true;
    if (_entry.audioCount > 0) _sectionStates['audio'] = true;
    if (_entry.imageCount > 0) _sectionStates['image'] = true;
    if (_entry.videoCount > 0) _sectionStates['video'] = true;
    _sectionStates['chat'] = true;
  }

  void _updateSectionState(String key, bool isExpanded) {
    setState(() {
      _sectionStates[key] = isExpanded;
      if (_sectionStates.values.every((state) => state == true)) {
        _allExpanded = true;
      } else if (_sectionStates.values.every((state) => state == false)) {
        _allExpanded = false;
      }
    });
  }

  void _togglePrivacy() {
    setState(() {
      _isPrivate = !_isPrivate;
    });
  }

  void _toggleAllSections() {
    setState(() {
      _allExpanded = !_allExpanded;
      for (var key in _sectionStates.keys) {
        _sectionStates[key] = _allExpanded;
      }
      if (!_allExpanded) {
        _audioCarouselKey.currentState?.stopAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final SettingsService settings = SettingsService();
    
    final currentEntry = DiaryEntry(
      id: _entry.id,
      title: _entry.title,
      date: _entry.date,
      isPrivate: _isPrivate,
      content: _entry.content,
      hasText: _entry.hasText,
      audioRecordings: _entry.audioRecordings,
      images: _entry.images,
      videos: _entry.videos,
      messages: _entry.messages,
      location: _entry.location,
      badgeCount: _badgeCount,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_entry.title),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                _buildStatusChip(
                  theme,
                  Icons.calendar_today,
                  _entry.date,
                  color: theme.colorScheme.primaryContainer,
                  textColor: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _togglePrivacy,
                  child: _buildStatusChip(
                    theme, 
                    _isPrivate ? Icons.lock : Icons.public, 
                    _isPrivate ? 'Private' : 'Public',
                    color: _isPrivate 
                        ? theme.colorScheme.secondaryContainer 
                        : theme.colorScheme.tertiaryContainer,
                    textColor: _isPrivate 
                        ? theme.colorScheme.onSecondaryContainer 
                        : theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleAllSections,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _allExpanded ? 'Collapse All' : 'Expand All', 
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _allExpanded ? Icons.unfold_less : Icons.unfold_more, 
                          size: 14,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_isRefreshing)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: theme.colorScheme.surface,
              color: theme.colorScheme.primary,
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  if (_entry.content.isNotEmpty) ...[
                    CollapsibleSection(
                      title: 'Text Content',
                      isExpanded: _sectionStates['text'],
                      onExpansionChanged: (expanded) => _updateSectionState('text', expanded),
                      child: ScrollableTextSection(content: _entry.content),
                    ),
                    const Divider(height: 8),
                  ],

                  if (_entry.audioCount > 0) ...[
                    CollapsibleSection(
                      title: 'Audio Recordings (${_entry.audioCount})',
                      isExpanded: _sectionStates['audio'],
                      onExpansionChanged: (expanded) {
                        _updateSectionState('audio', expanded);
                        if (!expanded) {
                          _audioCarouselKey.currentState?.stopAll();
                        }
                      },
                      child: AudioCarousel(
                        key: _audioCarouselKey,
                        recordings: _entry.audioRecordings,
                      ),
                    ),
                    const Divider(height: 8),
                  ],

                  if (_entry.imageCount > 0) ...[
                    CollapsibleSection(
                      title: 'Images (${_entry.imageCount})',
                      isExpanded: _sectionStates['image'],
                      onExpansionChanged: (expanded) => _updateSectionState('image', expanded),
                      child: ImageCarousel(images: _entry.images),
                    ),
                    const Divider(height: 8),
                  ],

                  if (_entry.videoCount > 0) ...[
                    CollapsibleSection(
                      title: 'Videos (${_entry.videoCount})',
                      isExpanded: _sectionStates['video'],
                      onExpansionChanged: (expanded) => _updateSectionState('video', expanded),
                      child: VideoCarousel(videos: _entry.videos),
                    ),
                    const Divider(height: 8),
                  ],

                  CollapsibleSection(
                    title: 'Chat Assistance',
                    isExpanded: _sectionStates['chat'],
                    onExpansionChanged: (expanded) => _updateSectionState('chat', expanded),
                    badgeCount: _badgeCount,
                    child: buildChatSection(
                      context,
                      theme,
                      currentEntry,
                      settings,
                      hasUnreadMessages: _badgeCount > 0,
                      onTogglePrivacy: _togglePrivacy,
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  _entry.location,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme, IconData icon, String label, {required Color color, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
