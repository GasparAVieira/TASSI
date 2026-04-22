import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'diary_entry_widgets.dart';

class NotificationData {
  final String id;
  final String title;
  final String message;
  final String timestamp;
  final IconData icon;
  final bool isUnread;

  NotificationData({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    required this.isUnread,
  });
}

class NotificationPopup extends StatelessWidget {
  final double width;
  final double height;
  
  const NotificationPopup({super.key, required this.width, required this.height});

  static final List<NotificationData> _mockNotifications = [
    NotificationData(
      id: '1',
      title: 'New Diary Entry Shared',
      message: 'Someone shared a new diary entry with you from their trip to the mountains. Check out the beautiful photos and the audio logs they recorded during the hike!',
      timestamp: '24 Oct 2023 • 14:30',
      icon: Icons.share_outlined,
      isUnread: true,
    ),
    NotificationData(
      id: '2',
      title: 'System Update',
      message: 'A new version of Navigation Diary is available. Version 2.1.0 includes performance improvements for map rendering and a new dark mode theme. Update now to enjoy the latest features and bug fixes. We have also improved the diary entry synchronization to be faster and more reliable.',
      timestamp: '23 Oct 2023 • 09:15',
      icon: Icons.system_update_outlined,
      isUnread: true,
    ),
    NotificationData(
      id: '3',
      title: 'Location Reminder',
      message: 'You are near "University Library". Would you like to check your previous diary entries from this location? It seems you spent a lot of time here last month.',
      timestamp: '22 Oct 2023 • 18:45',
      icon: Icons.location_on_outlined,
      isUnread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = SettingsService();

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: settings.isHighContrast 
                ? BorderSide(color: theme.colorScheme.onSurface, width: 2.0) 
                : BorderSide.none,
          ),
          shadows: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Your Feed',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 22,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            PulsingBadge(
                              label: '${_mockNotifications.length}',
                            ),
                          ],
                        ),
                        Text(
                          'System Notifications & Alerts',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 14,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(10),
                children: [
                  ..._mockNotifications.map((n) => NotificationCard(notification: n)),
                  const SizedBox(height: 10),
                  _buildStaticNotificationCard(theme),
                ],
              ),
            ),
            // Bottom Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
            ),
            // Bottom margin same as the top margin (10px) to prevent cards from touching the edge
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticNotificationCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 95,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 48,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You’re all caught up for now.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationCard extends StatefulWidget {
  final NotificationData notification;

  const NotificationCard({super.key, required this.notification});

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _shadowAnimation;
  final SettingsService _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double badgeSize = 18.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(widget.notification.icon, color: theme.colorScheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.notification.title,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 16,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),
                      if (widget.notification.isUnread) const SizedBox(width: badgeSize),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: Scrollbar(
                      controller: _scrollController,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Text(
                              widget.notification.message,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w400,
                                height: 1.43,
                                letterSpacing: 0.25,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.notification.timestamp,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.notification.isUnread)
              Positioned(
                top: badgeSize / 2,
                right: badgeSize / 2,
                child: AnimatedBuilder(
                  animation: _shadowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                        boxShadow: _settings.isPulsingEnabled ? [
                          BoxShadow(
                            color: theme.colorScheme.error.withValues(alpha: 0.4),
                            blurRadius: _shadowAnimation.value,
                            spreadRadius: _shadowAnimation.value / 2,
                          ),
                        ] : null,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void showNotificationPopup(BuildContext context, {GlobalKey? tabBarKey, GlobalKey? fabKey, GlobalKey? newEntryKey}) {
  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    useSafeArea: false,
    builder: (context) => _NotificationPopupDialog(tabBarKey: tabBarKey, fabKey: fabKey, newEntryKey: newEntryKey),
  );
}

class _NotificationPopupDialog extends StatelessWidget {
  final GlobalKey? tabBarKey;
  final GlobalKey? fabKey;
  final GlobalKey? newEntryKey;

  const _NotificationPopupDialog({this.tabBarKey, this.fabKey, this.newEntryKey});

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final bool isLandscape = mediaQuery.orientation == Orientation.landscape;
        
        double popupTop = 100.0;
        double popupBottom = mediaQuery.size.height - 100;
        double popupWidth = mediaQuery.size.width - 20;
        double popupLeft = 10.0;

        if (isLandscape && newEntryKey?.currentContext != null) {
          final RenderBox box = newEntryKey!.currentContext!.findRenderObject() as RenderBox;
          final Offset pos = box.localToGlobal(Offset.zero);
          popupTop = pos.dy;
        } else if (tabBarKey?.currentContext != null) {
          final RenderBox box = tabBarKey!.currentContext!.findRenderObject() as RenderBox;
          final Offset pos = box.localToGlobal(Offset.zero);
          popupTop = pos.dy;
          popupWidth = box.size.width;
          popupLeft = pos.dx;
        }

        if (fabKey?.currentContext != null) {
          final RenderBox box = fabKey!.currentContext!.findRenderObject() as RenderBox;
          final Offset pos = box.localToGlobal(Offset.zero);
          popupBottom = pos.dy + (box.size.height / 2);
        }

        double popupHeight = popupBottom - popupTop;
        if (popupHeight < 200) popupHeight = 200;

        return Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(128),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: popupTop,
              left: popupLeft,
              child: NotificationPopup(width: popupWidth, height: popupHeight),
            ),
          ],
        );
      },
    );
  }
}
