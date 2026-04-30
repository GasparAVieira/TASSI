import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../models/diary_entry.dart';
import '../services/settings_service.dart';

class PulsingBadge extends StatefulWidget {
  final String label;
  final Widget? child;
  const PulsingBadge({super.key, required this.label, this.child});

  @override
  State<PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<PulsingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _shadowAnimation;
  final SettingsService _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _shadowAnimation = Tween<double>(begin: 1.0, end: 4.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (_settings.isPulsingEnabled) {
      _animationController.repeat(reverse: true);
    }

    _settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (_settings.isPulsingEnabled) {
      if (!_animationController.isAnimating) {
        _animationController.repeat(reverse: true);
      }
    } else {
      _animationController.stop();
      _animationController.value = 0.0;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.label == '0') {
      return widget.child ?? const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    final badgeElement = AnimatedBuilder(
      animation: _shadowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: _settings.isPulsingEnabled
                ? [
                    BoxShadow(
                      color: theme.colorScheme.error.withValues(alpha: 0.4),
                      blurRadius: _shadowAnimation.value,
                      spreadRadius: _shadowAnimation.value / 2,
                    ),
                  ]
                : null,
          ),
          child: Badge(
            label: Text(widget.label),
            backgroundColor: theme.colorScheme.error,
            textColor: theme.colorScheme.onError,
          ),
        );
      },
    );

    if (widget.child == null) {
      return badgeElement;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child!,
        Positioned(top: -2, right: -2, child: badgeElement),
      ],
    );
  }
}

class CollapsibleSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initialExpanded;
  final bool? isExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final int? badgeCount;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.child,
    this.initialExpanded = false,
    this.isExpanded,
    this.onExpansionChanged,
    this.badgeCount,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  final SettingsService _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded ?? widget.initialExpanded;
    _controller = AnimationController(
      duration: _settings.isAnimationsEnabled
          ? const Duration(milliseconds: 300)
          : Duration.zero,
      vsync: this,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeInOut));
    if (_isExpanded) {
      _controller.value = 1.0;
    }
    _settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    _controller.duration = _settings.isAnimationsEnabled
        ? const Duration(milliseconds: 300)
        : Duration.zero;
  }

  @override
  void didUpdateWidget(CollapsibleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != null && widget.isExpanded != _isExpanded) {
      _isExpanded = widget.isExpanded!;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    if (widget.onExpansionChanged != null) {
      widget.onExpansionChanged!(_isExpanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.badgeCount != null && widget.badgeCount! > 0) ...[
                  const SizedBox(width: 8),
                  PulsingBadge(label: widget.badgeCount! > 9 ? '9+' : widget.badgeCount.toString()),
                ],
                const Spacer(),
                RotationTransition(
                  turns: _controller.drive(Tween(begin: 0.0, end: 0.5)),
                  child: const Icon(
                    Icons.expand_more,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _heightFactor,
          axisAlignment: -1.0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class ScrollableTextSection extends StatefulWidget {
  final String content;
  const ScrollableTextSection({super.key, required this.content});

  @override
  State<ScrollableTextSection> createState() => _ScrollableTextSectionState();
}

class _ScrollableTextSectionState extends State<ScrollableTextSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 140),
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: SizedBox(
            width: double.infinity,
            child: Text(widget.content, style: theme.textTheme.bodyMedium),
          ),
        ),
      ),
    );
  }
}

class AudioCarousel extends StatefulWidget {
  final List<AudioRecording> recordings;
  const AudioCarousel({super.key, required this.recordings});

  @override
  State<AudioCarousel> createState() => AudioCarouselState();
}

class AudioCarouselState extends State<AudioCarousel> {
  final SettingsService _settings = SettingsService();
  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Timer? _timer;
  late Duration _totalDuration;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _playlistScrollController = ScrollController();

  bool _showTranscription = true;
  bool _showPlaylist = true;

  @override
  void initState() {
    super.initState();
    _totalDuration = _parseDuration(widget.recordings[_currentIndex].duration);
  }

  void stopAll() {
    _stopPlay();
  }

  Duration _parseDuration(String durationStr) {
    final parts = durationStr.split(':');
    if (parts.length == 2) {
      return Duration(
        minutes: int.parse(parts[0]),
        seconds: int.parse(parts[1]),
      );
    }
    return const Duration(minutes: 1);
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  void _playPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _startTimer();
      } else {
        _stopTimer();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          final nextPosition =
              _currentPosition + const Duration(milliseconds: 100);
          if (nextPosition < _totalDuration) {
            _currentPosition = nextPosition;
          } else {
            _isPlaying = false;
            _currentPosition = _totalDuration;
            _stopTimer();
            _nextTrack();
          }
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _stopPlay() {
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
        _stopTimer();
      });
    }
  }

  void _skip(int seconds) {
    setState(() {
      final newPosition = _currentPosition + Duration(seconds: seconds);
      if (newPosition < Duration.zero) {
        _currentPosition = Duration.zero;
      } else if (newPosition > _totalDuration) {
        _currentPosition = _totalDuration;
        _isPlaying = false;
        _stopTimer();
      } else {
        _currentPosition = newPosition;
      }
    });
  }

  void _nextTrack() {
    if (_currentIndex < widget.recordings.length - 1) {
      _changeTrack(_currentIndex + 1);
    }
  }

  void _prevTrack() {
    if (_currentIndex > 0) {
      _changeTrack(_currentIndex - 1);
    }
  }

  void _changeTrack(int index) {
    setState(() {
      _stopPlay();
      _currentIndex = index;
      _totalDuration = _parseDuration(
        widget.recordings[_currentIndex].duration,
      );
    });
  }

  @override
  void dispose() {
    _stopTimer();
    _scrollController.dispose();
    _playlistScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recordings.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final currentRec = widget.recordings[_currentIndex];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Audio Player Container
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Title
                Text(
                  "Audio Recording ${_currentIndex + 1}",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                if (widget.recordings.length > 1)
                  Text(
                    "Track ${_currentIndex + 1} of ${widget.recordings.length}",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 16),

                // Timestamps (Moved above Progress Bar)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_currentPosition),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        currentRec.duration,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress Bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4.0,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6.0,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14.0,
                    ),
                  ),
                  child: Slider(
                    value: _currentPosition.inMilliseconds.toDouble().clamp(
                      0.0,
                      _totalDuration.inMilliseconds > 0
                          ? _totalDuration.inMilliseconds.toDouble()
                          : 1.0,
                    ),
                    min: 0,
                    max: _totalDuration.inMilliseconds > 0
                        ? _totalDuration.inMilliseconds.toDouble()
                        : 1.0,
                    onChanged: (value) {
                      setState(() {
                        _currentPosition = Duration(
                          milliseconds: value.toInt(),
                        );
                      });
                    },
                  ),
                ),

                // Transport Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      color: _currentIndex > 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      iconSize: 32,
                      onPressed: _currentIndex > 0 ? _prevTrack : null,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.replay_5),
                      color: theme.colorScheme.primary,
                      onPressed: () => _skip(-5),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color:
                            (_settings.isHighContrast &&
                                theme.brightness == Brightness.light)
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primaryContainer.withValues(
                                alpha: _isPlaying ? 1.0 : 0.5,
                              ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        color:
                            (_settings.isHighContrast &&
                                theme.brightness == Brightness.light)
                            ? Colors.white
                            : theme.colorScheme.primary,
                        iconSize: 40,
                        onPressed: _playPause,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.forward_5),
                      color: theme.colorScheme.primary,
                      onPressed: () => _skip(5),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      color: _currentIndex < widget.recordings.length - 1
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      iconSize: 32,
                      onPressed: _currentIndex < widget.recordings.length - 1
                          ? _nextTrack
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Transcription Section
          InkWell(
            onTap: () =>
                setState(() => _showTranscription = !_showTranscription),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Transcription',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showTranscription ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_showTranscription)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  currentRec.transcription,
                  textAlign: TextAlign.left,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                ),
              ),
            ),

          if (widget.recordings.length > 1) ...[
            const Divider(height: 1),
            // Playlist Section
            InkWell(
              onTap: () => setState(() => _showPlaylist = !_showPlaylist),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      'Recordings (${widget.recordings.length})',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _showPlaylist ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            if (_showPlaylist)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: SizedBox(
                  height: 120, // Constrains playlist exactly to ~3 items height
                  child: Scrollbar(
                    controller: _playlistScrollController,
                    child: ListView.builder(
                      controller: _playlistScrollController,
                      itemCount: widget.recordings.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _currentIndex;
                        return InkWell(
                          onTap: () => _changeTrack(index),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.3)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.audiotrack
                                      : Icons.audiotrack_outlined,
                                  size: 16,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Audio Recording ${index + 1}",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Text(
                                  widget.recordings[index].duration,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class ImageCarousel extends StatefulWidget {
  final List<String> images;
  const ImageCarousel({super.key, required this.images});

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openPath(BuildContext context, String path) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!File(path).existsSync()) {
      messenger.showSnackBar(SnackBar(content: Text('Unable to open file.')));
      return;
    }

    final result = await OpenFile.open(path);
    if (result.type != ResultType.done) {
      messenger.showSnackBar(SnackBar(content: Text('Unable to open file.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 140,
      child: Scrollbar(
        controller: _scrollController,
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
            4,
            0,
            4,
            12,
          ), // Added side padding to match Audio
          itemCount: widget.images.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final path = widget.images[index];
            final file = File(path);
            final exists = file.existsSync();
            return GestureDetector(
              onTap: exists ? () => _openPath(context, path) : null,
              child: Container(
                width: 180,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: exists
                    ? Image.file(
                        file,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        filterQuality: FilterQuality.high,
                      )
                    : Center(
                        child: Text(
                          path.split(RegExp(r'[\\/]')).last,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class VideoCarousel extends StatefulWidget {
  final List<String> videos;
  const VideoCarousel({super.key, required this.videos});

  @override
  State<VideoCarousel> createState() => _VideoCarouselState();
}

class _VideoCarouselState extends State<VideoCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String?> _thumbnailPaths = [];

  @override
  void initState() {
    super.initState();
    _initThumbnails();
  }

  @override
  void didUpdateWidget(VideoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.videos, widget.videos)) {
      _initThumbnails();
    }
  }

  void _initThumbnails() {
    _thumbnailPaths
      ..clear()
      ..addAll(List<String?>.filled(widget.videos.length, null));
    for (var index = 0; index < widget.videos.length; index++) {
      _generateThumbnail(index, widget.videos[index]);
    }
  }

  Future<void> _generateThumbnail(int index, String path) async {
    final file = File(path);
    if (!file.existsSync()) return;

    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: path,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 720,
      maxWidth: 1280,
      quality: 100,
    );

    if (!mounted || thumbnailPath == null) return;

    setState(() {
      if (index < _thumbnailPaths.length) {
        _thumbnailPaths[index] = thumbnailPath;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openPath(BuildContext context, String path) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!File(path).existsSync()) {
      messenger.showSnackBar(SnackBar(content: Text('Unable to open file.')));
      return;
    }

    final result = await OpenFile.open(path);
    if (result.type != ResultType.done) {
      messenger.showSnackBar(SnackBar(content: Text('Unable to open file.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: widget.videos.length,
            itemBuilder: (context, index) {
              final path = widget.videos[index];
              final file = File(path);
              final exists = file.existsSync();
              final thumbPath = index < _thumbnailPaths.length
                  ? _thumbnailPaths[index]
                  : null;
              final thumbFile = thumbPath != null ? File(thumbPath) : null;
              final hasThumbnail = thumbFile?.existsSync() ?? false;
              final name = path.split(RegExp(r'[\\/]')).last;
              return GestureDetector(
                onTap: exists ? () => _openPath(context, path) : null,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasThumbnail)
                        Image.file(
                          thumbFile!,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.85),
                                theme.colorScheme.surface.withValues(
                                  alpha: 0.95,
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (!exists)
                        Container(
                          color: theme.colorScheme.surface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.8,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: theme.colorScheme.onPrimary,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (!exists)
                        Positioned.fill(
                          child: Container(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.6,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Missing file',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.videos.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.videos.length, (index) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

Widget buildChatSection(
  BuildContext context,
  ThemeData theme,
  DiaryEntry entry,
  SettingsService settings, {
  required bool hasUnreadMessages,
  required VoidCallback onTogglePrivacy,
}) {
  if (entry.isPrivate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            'Set Entry to Public to Message Us!',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onTogglePrivacy,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Turn Entry Public'),
          ),
        ],
      ),
    );
  }

  return Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: entry.messages.isEmpty
            ? _buildEmptyChat(theme)
            : _buildChatList(
                theme,
                entry.messages,
                settings,
                hasUnreadMessages: entry.badgeCount != null && entry.badgeCount! > 0,
              ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Type a message...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _ChatSendButton(settings: settings),
        ],
      ),
    ],
  );
}

class _ChatSendButton extends StatelessWidget {
  final SettingsService settings;
  const _ChatSendButton({required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color buttonColor;
    Color iconColor;

    if (settings.isHighContrast) {
      buttonColor = theme.colorScheme.primary;
      iconColor = theme.colorScheme.onPrimary;
    } else {
      buttonColor = isDark
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.7)
          : theme.colorScheme.primary;
      iconColor = isDark ? theme.colorScheme.onPrimaryContainer : Colors.white;
    }

    return Material(
      color: buttonColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(Icons.send, color: iconColor),
        ),
      ),
    );
  }
}

Widget _buildChatList(
  ThemeData theme,
  List<ChatMessage> messages,
  SettingsService settings, {
  required bool hasUnreadMessages,
}) {
  final oldMessages = hasUnreadMessages && messages.length > 1
      ? messages.sublist(0, messages.length - 1)
      : messages;
  final newMessages = hasUnreadMessages && messages.length > 1
      ? [messages.last]
      : [];

  return Column(
    children: [
      ...oldMessages.map(
        (msg) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildChatMessage(theme, msg, settings),
        ),
      ),
      if (newMessages.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'NEW MESSAGES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
        ),
        ...newMessages.map(
          (msg) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildChatMessage(theme, msg, settings),
          ),
        ),
      ],
    ],
  );
}

Widget _buildEmptyChat(ThemeData theme) {
  return Column(
    children: [
      const SizedBox(height: 8),
      Icon(
        Icons.chat_bubble_outline,
        size: 32,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      const SizedBox(height: 8),
      Text(
        'No messages yet. Tell us something!',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 8),
    ],
  );
}

Widget _buildChatMessage(
  ThemeData theme,
  ChatMessage msg,
  SettingsService settings,
) {
  Color bubbleColor;
  Color textColor;
  Color subTextColor;

  if (msg.isAdmin) {
    bubbleColor = theme.colorScheme.surface;
    textColor = theme.colorScheme.onSurface;
    subTextColor = theme.colorScheme.onSurfaceVariant;
  } else {
    if (settings.isHighContrast) {
      bubbleColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
      subTextColor = theme.colorScheme.onPrimary.withValues(alpha: 0.8);
    } else {
      bubbleColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.7);
      textColor = theme.colorScheme.onPrimaryContainer;
      subTextColor = theme.colorScheme.onPrimaryContainer.withValues(
        alpha: 0.8,
      );
    }
  }

  return Column(
    crossAxisAlignment: msg.isAdmin
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.end,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: msg.isAdmin
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.primary,
                  child: Icon(
                    msg.isAdmin ? Icons.admin_panel_settings : Icons.person,
                    size: 14,
                    color: settings.isHighContrast
                        ? theme.colorScheme.onPrimary
                        : Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.sender,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      msg.time,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              msg.content,
              style: theme.textTheme.bodySmall?.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    ],
  );
}
