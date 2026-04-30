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
  late bool _isPrivate;
  bool _allExpanded = true;
  final Map<String, bool> _sectionStates = {};
  final GlobalKey<AudioCarouselState> _audioCarouselKey = GlobalKey<AudioCarouselState>();
  final DiaryService _diaryService = DiaryService();
  int _badgeCount = 0;

  @override
  void initState() {
    super.initState();
    _isPrivate = widget.entry.isPrivate;
    _badgeCount = widget.entry.badgeCount ?? 0;
    _initSectionStates();
    
    // Mark entry as read when viewed
    if (_badgeCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _badgeCount = 0;
        });
        _diaryService.markAsRead(widget.entry.id);
      });
    }
  }

  void _initSectionStates() {
    if (widget.entry.content.isNotEmpty) _sectionStates['text'] = true;
    if (widget.entry.audioCount > 0) _sectionStates['audio'] = true;
    if (widget.entry.imageCount > 0) _sectionStates['image'] = true;
    if (widget.entry.videoCount > 0) _sectionStates['video'] = true;
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
      id: widget.entry.id,
      title: widget.entry.title,
      date: widget.entry.date,
      isPrivate: _isPrivate,
      content: widget.entry.content,
      hasText: widget.entry.hasText,
      audioRecordings: widget.entry.audioRecordings,
      images: widget.entry.images,
      videos: widget.entry.videos,
      messages: widget.entry.messages,
      location: widget.entry.location,
      badgeCount: _badgeCount,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry.title),
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
                  widget.entry.date,
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.entry.content.isNotEmpty) ...[
                    CollapsibleSection(
                      title: 'Text Content',
                      isExpanded: _sectionStates['text'],
                      onExpansionChanged: (expanded) => _updateSectionState('text', expanded),
                      child: ScrollableTextSection(content: widget.entry.content),
                    ),
                    const Divider(height: 8),
                  ],
                  
                  if (widget.entry.audioCount > 0) ...[
                    CollapsibleSection(
                      title: 'Audio Recordings (${widget.entry.audioCount})',
                      isExpanded: _sectionStates['audio'],
                      onExpansionChanged: (expanded) {
                        _updateSectionState('audio', expanded);
                        if (!expanded) {
                          _audioCarouselKey.currentState?.stopAll();
                        }
                      },
                      child: AudioCarousel(
                        key: _audioCarouselKey,
                        recordings: widget.entry.audioRecordings,
                      ),
                    ),
                    const Divider(height: 8),
                  ],

                  if (widget.entry.imageCount > 0) ...[
                    CollapsibleSection(
                      title: 'Images (${widget.entry.imageCount})',
                      isExpanded: _sectionStates['image'],
                      onExpansionChanged: (expanded) => _updateSectionState('image', expanded),
                      child: ImageCarousel(images: widget.entry.images),
                    ),
                    const Divider(height: 8),
                  ],

                  if (widget.entry.videoCount > 0) ...[
                    CollapsibleSection(
                      title: 'Videos (${widget.entry.videoCount})',
                      isExpanded: _sectionStates['video'],
                      onExpansionChanged: (expanded) => _updateSectionState('video', expanded),
                      child: VideoCarousel(videos: widget.entry.videos),
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
                  widget.entry.location,
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
