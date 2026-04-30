import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import '../models/notification.dart';
import 'diary_entry_widgets.dart';

class NotificationPopup extends StatefulWidget {
  final double width;
  final double height;
  
  const NotificationPopup({super.key, required this.width, required this.height});

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.addListener(_onNotificationServiceChanged);
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationServiceChanged);
    super.dispose();
  }

  void _onNotificationServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = SettingsService();
    final notifications = _notificationService.notifications;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: widget.width,
        height: widget.height,
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
                              label: _notificationService.unreadCountDisplay,
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
              child: _notificationService.isLoading && notifications.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(10),
                    children: [
                      ...notifications.map((n) => NotificationCard(notification: n)),
                      if (notifications.isEmpty)
                        _buildStaticNotificationCard(theme),
                      const SizedBox(height: 10),
                    ],
                  ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
            ),
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
  final NotificationService _notificationService = NotificationService();

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

    // Mark as read when it appears
    if (widget.notification.isUnread) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notificationService.markAsRead(widget.notification.id);
      });
    }
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
                      _formatDateTime(widget.notification.shownAt),
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

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} • ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
