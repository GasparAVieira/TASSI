import 'package:flutter/material.dart';
import '../widgets/notification_popup.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/diary_service.dart';
import '../services/notification_service.dart';
import '../models/diary_entry.dart';
import 'diary_entry.dart';
import '../widgets/diary_entry_widgets.dart';
import '../widgets/diary_entry_creation_section.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  String? _dateFilter;
  String? _privacyFilter;
  bool _isCreatingEntry = false;

  final GlobalKey _tabBarKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();
  final GlobalKey _newEntryKey = GlobalKey();
  final SettingsService _settings = SettingsService();
  final DiaryService _diaryService = DiaryService();
  final NotificationService _notificationService = NotificationService();
  final bool _isAttachmentProcessing = false;
  bool _isLoadingEntries = true;

  List<DiaryEntry> _allEntries = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
    _settings.addListener(_onSettingsChanged);
    _notificationService.addListener(_onNotificationChanged);
    _diaryService.addListener(_onDiaryServiceChanged);
    _loadDiaryEntries();
    if (AuthService.instance.isLoggedIn) {
      _notificationService.fetchNotifications();
    }
  }

  void _onNotificationChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadDiaryEntries() async {
    if (!mounted) return;
    setState(() {
      _isLoadingEntries = true;
    });

    try {
      final entries = await _diaryService.fetchEntries();
      if (!mounted) return;
      setState(() {
        _allEntries = entries;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEntries = false;
        });
      }
    }
  }

  void _showMediaChoice(String type) {
    // Create section handles attachments. This stub keeps the old page-level
    // branch compile-safe until the create section is fully decoupled.
  }

  @override
  void dispose() {
    _tabController.dispose();
    _settings.removeListener(_onSettingsChanged);
    _notificationService.removeListener(_onNotificationChanged);
    _diaryService.removeListener(_onDiaryServiceChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  void _onDiaryServiceChanged() {
    if (!mounted) return;
    setState(() {
      _allEntries = _diaryService.entries;
    });
  }

  List<DiaryEntry> get _filteredEntries {
    Iterable<DiaryEntry> entries = _allEntries;

    if (_selectedTabIndex != 0) {
      entries = entries.where((entry) {
        switch (_selectedTabIndex) {
          case 1:
            return entry.hasText;
          case 2:
            return entry.audioCount > 0;
          case 3:
            return entry.imageCount > 0;
          case 4:
            return entry.videoCount > 0;
          default:
            return true;
        }
      });
    }

    if (_dateFilter != null) {
      entries = entries.where((entry) => entry.date == _dateFilter);
    }

    if (_privacyFilter != null) {
      entries = entries.where(
        (entry) => (entry.isPrivate ? 'Private' : 'Public') == _privacyFilter,
      );
    }

    return entries.toList();
  }

  Future<void> _deleteEntry(String id) async {
    await _diaryService.deleteEntry(id);
    if (!mounted) return;
    setState(() {
      _allEntries = _diaryService.entries;
    });
  }

  void _showDeleteConfirmation(DiaryEntry entry) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierColor: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.5),
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 360,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: ShapeDecoration(
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                side: _settings.isHighContrast
                    ? BorderSide(color: theme.colorScheme.onSurface, width: 2.0)
                    : BorderSide(
                        width: 1,
                        color: theme.colorScheme.outlineVariant,
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Are You Sure?',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          height: 1.50,
                          letterSpacing: 0.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Deleting Entry: ',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w400,
                                height: 1.43,
                                letterSpacing: 0.25,
                              ),
                            ),
                            TextSpan(
                              text: entry.title,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w700,
                                height: 1.43,
                                letterSpacing: 0.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Deleting An Entry Is Irreversible!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                        height: 1.43,
                        letterSpacing: 0.25,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: theme.colorScheme.outline,
                              ),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w500,
                              height: 1.43,
                              letterSpacing: 0.10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          _deleteEntry(entry.id);
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          decoration: ShapeDecoration(
                            color: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                              side: _settings.isHighContrast
                                  ? BorderSide(
                                      color: theme.colorScheme.onSurface,
                                      width: 1,
                                    )
                                  : BorderSide.none,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 14,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w500,
                              height: 1.43,
                              letterSpacing: 0.10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardWidth = MediaQuery.of(context).size.width - 20;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: isLandscape
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (_dateFilter != null) ...[
                          _buildFilterExtendedFab(
                            theme,
                            _dateFilter!,
                            () => setState(() => _dateFilter = null),
                            'dateFilter',
                          ),
                          if (_privacyFilter != null) const SizedBox(width: 8),
                        ],
                        if (_privacyFilter != null)
                          _buildFilterExtendedFab(
                            theme,
                            _privacyFilter!,
                            () => setState(() => _privacyFilter = null),
                            'privacyFilter',
                          ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_dateFilter != null)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: _privacyFilter != null ? 8.0 : 0.0,
                            ),
                            child: _buildFilterExtendedFab(
                              theme,
                              _dateFilter!,
                              () => setState(() => _dateFilter = null),
                              'dateFilter',
                            ),
                          ),
                        if (_privacyFilter != null)
                          _buildFilterExtendedFab(
                            theme,
                            _privacyFilter!,
                            () => setState(() => _privacyFilter = null),
                            'privacyFilter',
                          ),
                      ],
                    ),
            ),
            const SizedBox(width: 16),
            AnimatedSlide(
              offset: _settings.isAnimationsEnabled && _isCreatingEntry
                  ? const Offset(2.0, 0.0)
                  : Offset.zero,
              duration: _settings.isAnimationsEnabled
                  ? const Duration(milliseconds: 300)
                  : Duration.zero,
              curve: Curves.easeInOut,
              child: AnimatedOpacity(
                opacity: _isCreatingEntry ? 0.0 : 1.0,
                duration: _settings.isAnimationsEnabled
                    ? const Duration(milliseconds: 300)
                    : Duration.zero,
                child: FloatingActionButton(
                  key: _fabKey,
                  onPressed: _isCreatingEntry
                      ? null
                      : () => showNotificationPopup(
                          context,
                          tabBarKey: _tabBarKey,
                          fabKey: _fabKey,
                          newEntryKey: _newEntryKey,
                        ),
                  elevation: 2,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PulsingBadge(
                    label: _notificationService.unreadCountDisplay,
                    child: const Icon(Icons.notifications_outlined, size: 32),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Column(
            children: [
              // New Entry Card / Header
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: AnimatedSize(
                  duration: _settings.isAnimationsEnabled
                      ? const Duration(milliseconds: 300)
                      : Duration.zero,
                  curve: Curves.easeInOut,
                  child: Card(
                    key: _newEntryKey,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    color: _isCreatingEntry
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => setState(() {
                        if (_isCreatingEntry) {
                          _tabController.index = 0;
                          _selectedTabIndex = 0;
                        }
                        _isCreatingEntry = !_isCreatingEntry;
                      }),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isCreatingEntry ? Icons.close : Icons.add,
                                color: _isCreatingEntry
                                    ? theme.colorScheme.onSecondaryContainer
                                    : theme.colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isCreatingEntry ? 'Cancel Entry' : 'New Entry',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: _isCreatingEntry
                                      ? theme.colorScheme.onSecondaryContainer
                                      : theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (!_isCreatingEntry)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Card(
                    key: _tabBarKey,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    color: theme.colorScheme.surface,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        height: 56,
                        child: _isCreatingEntry
                            ? LayoutBuilder(
                                builder: (context, constraints) {
                                  final hiddenWidth =
                                      constraints.maxWidth * 0.4;
                                  return Stack(
                                    children: [
                                      AbsorbPointer(
                                        absorbing: _isAttachmentProcessing,
                                        child: AnimatedOpacity(
                                          opacity: _isAttachmentProcessing
                                              ? 0.65
                                              : 1.0,
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: TabBar(
                                            controller: _tabController,
                                            onTap: (index) {
                                              if (_isAttachmentProcessing) {
                                                return;
                                              }
                                              switch (index) {
                                                case 2:
                                                  _showMediaChoice('Audio');
                                                  break;
                                                case 3:
                                                  _showMediaChoice('Image');
                                                  break;
                                                case 4:
                                                  _showMediaChoice('Video');
                                                  break;
                                                default:
                                                  break;
                                              }
                                            },
                                            indicator: const BoxDecoration(
                                              color: Colors.transparent,
                                            ),
                                            overlayColor:
                                                WidgetStateProperty.all(
                                                  Colors.transparent,
                                                ),
                                            splashBorderRadius:
                                                BorderRadius.circular(8),
                                            indicatorSize:
                                                TabBarIndicatorSize.tab,
                                            dividerColor: Colors.transparent,
                                            labelColor: _isAttachmentProcessing
                                                ? theme
                                                      .colorScheme
                                                      .onSurfaceVariant
                                                      .withValues(alpha: 0.5)
                                                : theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            unselectedLabelColor:
                                                _isAttachmentProcessing
                                                ? theme
                                                      .colorScheme
                                                      .onSurfaceVariant
                                                      .withValues(alpha: 0.45)
                                                : theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            labelPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 0,
                                                ),
                                            labelStyle: TextStyle(
                                              fontSize: _settings.useLargeText
                                                  ? 14
                                                  : 12,
                                              fontWeight: FontWeight.bold,
                                              height: 1,
                                            ),
                                            unselectedLabelStyle: TextStyle(
                                              fontSize: _settings.useLargeText
                                                  ? 14
                                                  : 12,
                                              fontWeight: FontWeight.bold,
                                              height: 1,
                                            ),
                                            tabs: const [
                                              Tab(
                                                icon: Icon(
                                                  Icons.apps,
                                                  size: 20,
                                                ),
                                                text: 'All',
                                                iconMargin: EdgeInsets.only(
                                                  bottom: 2,
                                                ),
                                              ),
                                              Tab(
                                                icon: Icon(
                                                  Icons.notes,
                                                  size: 20,
                                                ),
                                                text: 'Text',
                                                iconMargin: EdgeInsets.only(
                                                  bottom: 2,
                                                ),
                                              ),
                                              Tab(
                                                icon: Icon(Icons.mic, size: 20),
                                                text: 'Audio',
                                                iconMargin: EdgeInsets.only(
                                                  bottom: 2,
                                                ),
                                              ),
                                              Tab(
                                                icon: Icon(
                                                  Icons.image,
                                                  size: 20,
                                                ),
                                                text: 'Image',
                                                iconMargin: EdgeInsets.only(
                                                  bottom: 2,
                                                ),
                                              ),
                                              Tab(
                                                icon: Icon(
                                                  Icons.videocam,
                                                  size: 20,
                                                ),
                                                text: 'Video',
                                                iconMargin: EdgeInsets.only(
                                                  bottom: 2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        bottom: 0,
                                        width: hiddenWidth,
                                        child: Container(
                                          color: theme.colorScheme.surface,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    'Attach Media',
                                                    style: theme
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          color: theme
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize:
                                                              _settings
                                                                  .useLargeText
                                                              ? 14
                                                              : 12,
                                                          height: 1,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              VerticalDivider(
                                                width: 1,
                                                thickness: 1,
                                                indent: 12,
                                                endIndent: 12,
                                                color: theme
                                                    .colorScheme
                                                    .outlineVariant,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              )
                            : TabBar(
                                controller: _tabController,
                                indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: _settings.isHighContrast
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.primaryContainer
                                            .withValues(alpha: 0.5),
                                ),
                                splashBorderRadius: BorderRadius.circular(8),
                                indicatorSize: TabBarIndicatorSize.tab,
                                dividerColor: Colors.transparent,
                                labelColor: _settings.isHighContrast
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.primary,
                                unselectedLabelColor:
                                    theme.colorScheme.onSurfaceVariant,
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                ),
                                labelStyle: TextStyle(
                                  fontSize: _settings.useLargeText ? 14 : 12,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                                tabs: const [
                                  Tab(
                                    icon: Icon(Icons.apps, size: 20),
                                    text: 'All',
                                    iconMargin: EdgeInsets.only(bottom: 2),
                                  ),
                                  Tab(
                                    icon: Icon(Icons.notes, size: 20),
                                    text: 'Text',
                                    iconMargin: EdgeInsets.only(bottom: 2),
                                  ),
                                  Tab(
                                    icon: Icon(Icons.mic, size: 20),
                                    text: 'Audio',
                                    iconMargin: EdgeInsets.only(bottom: 2),
                                  ),
                                  Tab(
                                    icon: Icon(Icons.image, size: 20),
                                    text: 'Image',
                                    iconMargin: EdgeInsets.only(bottom: 2),
                                  ),
                                  Tab(
                                    icon: Icon(Icons.videocam, size: 20),
                                    text: 'Video',
                                    iconMargin: EdgeInsets.only(bottom: 2),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              if (_isCreatingEntry)
                Expanded(
                  child: DiaryEntryCreationSection(
                    tabController: _tabController,
                    settings: _settings,
                    onCancel: () => setState(() {
                      _isCreatingEntry = false;
                      _tabController.index = 0;
                      _selectedTabIndex = 0;
                    }),
                    onSave: (title, notes, isPrivate, attachments) async {
                      final newEntry = await _diaryService.createEntry(
                        title: title,
                        content: notes,
                        isPrivate: isPrivate,
                        attachments: attachments,
                      );
                      if (!mounted) return;
                      setState(() {
                        _allEntries.insert(0, newEntry);
                        _isCreatingEntry = false;
                        _tabController.index = 0;
                        _selectedTabIndex = 0;
                        _dateFilter = null;
                        _privacyFilter = null;
                      });
                    },
                  ),
                )
              else if (_isLoadingEntries)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: _filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = _filteredEntries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          color: theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  entry.title,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                    fontSize: 16,
                                                    fontFamily: 'Roboto',
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.2,
                                                    letterSpacing: 0.15,
                                                  ),
                                                ),
                                              ),
                                              if (entry.badgeCount != null &&
                                                  entry.badgeCount! > 0) ...[
                                                const SizedBox(width: 8),
                                                PulsingBadge(
                                                  label: entry.badgeCount! > 9 ? '9+' : entry.badgeCount.toString(),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        MenuAnchor(
                                          alignmentOffset: Offset(
                                            -(cardWidth / 2) + 40,
                                            0,
                                          ),
                                          style: MenuStyle(
                                            padding: WidgetStateProperty.all(
                                              EdgeInsets.zero,
                                            ),
                                            fixedSize: WidgetStateProperty.all(
                                              Size(cardWidth / 2, 48),
                                            ),
                                            shape: WidgetStateProperty.all(
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                side: _settings.isHighContrast
                                                    ? BorderSide(
                                                        color: theme
                                                            .colorScheme
                                                            .onSurface,
                                                        width: 2,
                                                      )
                                                    : BorderSide.none,
                                              ),
                                            ),
                                          ),
                                          builder:
                                              (context, controller, child) {
                                                return IconButton(
                                                  icon: const Icon(
                                                    Icons.more_vert,
                                                  ),
                                                  onPressed: () {
                                                    if (controller.isOpen) {
                                                      controller.close();
                                                    } else {
                                                      controller.open();
                                                    }
                                                  },
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                );
                                              },
                                          menuChildren: [
                                            MenuItemButton(
                                              onPressed: () =>
                                                  _showDeleteConfirmation(
                                                    entry,
                                                  ),
                                              style: ButtonStyle(
                                                fixedSize:
                                                    WidgetStateProperty.all(
                                                      Size(cardWidth / 2, 48),
                                                    ),
                                              ),
                                              leadingIcon: Icon(
                                                Icons.delete_outline,
                                                color: theme.colorScheme.error,
                                              ),
                                              child: Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color:
                                                      theme.colorScheme.error,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        _buildEntryChip(
                                          theme,
                                          entry.date,
                                          onTap: () {
                                            setState(() {
                                              if (_dateFilter == entry.date) {
                                                _dateFilter = null;
                                              } else {
                                                _dateFilter = entry.date;
                                              }
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        _buildEntryChip(
                                          theme,
                                          entry.isPrivate
                                              ? 'Private'
                                              : 'Public',
                                          onTap: () {
                                            setState(() {
                                              final val = entry.isPrivate
                                                  ? 'Private'
                                                  : 'Public';
                                              if (_privacyFilter == val) {
                                                _privacyFilter = null;
                                              } else {
                                                _privacyFilter = val;
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (entry.content.trim().isNotEmpty) ...[
                                      Text(
                                        entry.content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: _buildMediaChipsList(
                                          theme,
                                          text: entry.hasText,
                                          audioCount: entry.audioCount,
                                          imageCount: entry.imageCount,
                                          videoCount: entry.videoCount,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DiaryEntryPage(entry: entry),
                                        ),
                                      );
                                    },
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('View Full Entry'),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterExtendedFab(
    ThemeData theme,
    String label,
    VoidCallback onPressed,
    String heroTag,
  ) {
    return SizedBox(
      height: 56,
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: 1.0,
        child: FloatingActionButton.extended(
          heroTag: heroTag,
          onPressed: onPressed,
          label: Text(label),
          icon: const Icon(Icons.close),
          backgroundColor: _settings.isHighContrast
              ? theme.colorScheme.primary
              : theme.colorScheme.secondaryContainer,
          foregroundColor: _settings.isHighContrast
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSecondaryContainer,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMediaChipsList(
    ThemeData theme, {
    required bool text,
    required int audioCount,
    required int imageCount,
    required int videoCount,
  }) {
    final List<Widget> chips = [];
    if (text) chips.add(_buildMediaChip(theme, Icons.notes, 'Text'));
    if (audioCount > 0) {
      chips.add(
        _buildMediaChip(
          theme,
          Icons.mic,
          '$audioCount Audio${audioCount > 1 ? "s" : ""}',
        ),
      );
    }
    if (imageCount > 0) {
      chips.add(
        _buildMediaChip(
          theme,
          Icons.image,
          '$imageCount Image${imageCount > 1 ? "s" : ""}',
        ),
      );
    }
    if (videoCount > 0) {
      chips.add(
        _buildMediaChip(
          theme,
          Icons.videocam,
          '$videoCount Video${videoCount > 1 ? "s" : ""}',
        ),
      );
    }
    if (chips.isEmpty) return [];
    return List.generate(chips.length * 2 - 1, (index) {
      if (index.isEven) return Expanded(child: chips[index ~/ 2]);
      return const SizedBox(width: 8);
    });
  }

  Widget _buildEntryChip(ThemeData theme, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildMediaChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
