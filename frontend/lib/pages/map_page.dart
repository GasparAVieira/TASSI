import 'package:flutter/material.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';
import '../models/navigation_direction.dart';
import '../services/auth_service.dart';
import '../services/beacon_service.dart';
import '../services/feedback_service.dart';
import '../services/location_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  final VoidCallback? onOpenSettings;
  final Map<String, dynamic>? activeRouteData;
  final VoidCallback? onStopNavigation;

  const MapPage({super.key, this.onOpenSettings, this.activeRouteData, this.onStopNavigation});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final LocationService locationService = LocationService();
  final FeedbackService _feedbackService = FeedbackService();
  List<dynamic> allLocations = [];

  final BeaconService beaconService = BeaconService(
    targetLocationId: "f6dbc5e3-f901-4799-ba06-c23deb71a4b5",
  );

  final MapController _mapController = MapController();

  final LatLngBounds isepBounds = LatLngBounds(
    const LatLng(41.1770, -8.6098),
    const LatLng(41.1800, -8.6051),
  );

  Set<String> activeRouteNodeIds = {};

  BeaconDevice? currentBeacon;
  bool scanning = false;

  String currentInstruction = "";
  String currentLocationName = "";

  StreamSubscription? _beaconSub;
  StreamSubscription? _navigationSub;

  String selectedFloor = 'F1';
  final List<String> floors = ['F3', 'F2', 'F1'];
  bool isLegendVisible = false;
  bool isSidebarExpanded = true;

  late FixedExtentScrollController _floorScrollController;
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  double _sheetPosition = 0.15;
  int _currentStepIndex = 0;
  int? _lastAnnouncedStepIndex;
  Timer? _completionTimer;
  int _completionSecondsRemaining = 5;

  bool get _isNavigationComplete {
    final steps = widget.activeRouteData?['steps'] as List<dynamic>? ?? [];
    return steps.isNotEmpty && _currentStepIndex >= steps.length;
  }

  void updateActiveRoute(Map<String, dynamic> routeData) {
    setState(() {
      final sequence = routeData['location_sequence'] as List<dynamic>? ?? [];
      activeRouteNodeIds = sequence.map((id) => id.toString()).toSet();
    });
  }

  void _cancelCompletionCountdown() {
    _completionTimer?.cancel();
    _completionTimer = null;
    _completionSecondsRemaining = 5;
  }

  void _startCompletionCountdown() {
    _cancelCompletionCountdown();

    setState(() {
      _completionSecondsRemaining = 5;
    });

    _completionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (widget.activeRouteData == null) {
        timer.cancel();
        _completionTimer = null;
        return;
      }

      if (_completionSecondsRemaining <= 1) {
        timer.cancel();
        _completionTimer = null;

        widget.onStopNavigation?.call();
        if (!mounted) return;

        setState(() {
          _currentStepIndex = 0;
          _lastAnnouncedStepIndex = null;
          _completionSecondsRemaining = 5;
        });
        return;
      }

      setState(() {
        _completionSecondsRemaining--;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _floorScrollController = FixedExtentScrollController(
      initialItem: floors.indexOf(selectedFloor),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        currentInstruction = "TESTE: instrução a funcionar";
        print("TESTE: instrução a funcionar");
      });
    });

    Future.microtask(() async {
      try {
        await beaconService.startScanning();
        if (!mounted) return;
        setState(() => scanning = true);
      } catch (e) {
        debugPrint('Beacon scan initialization failed: $e');
      }
    });

    _beaconSub = beaconService.stream.listen((beacon) {
      if (!mounted) return;
      setState(() {
        currentBeacon = beacon;
      });
    });

    _navigationSub = beaconService.navigationStream.listen((data) {
      if (!mounted) return;
      print("NAV RECEBIDO: $data");

      setState(() {
        currentInstruction = "TESTE FORÇADO";
      });
    });

    _loadMapPoints();

    if (widget.activeRouteData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _announceStepIfNeeded(0);
      });
    }
  }

  @override
  void didUpdateWidget(covariant MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final hadRoute = oldWidget.activeRouteData != null;
    final hasRoute = widget.activeRouteData != null;

    if (hadRoute && !hasRoute) {
      _cancelCompletionCountdown();
      _lastAnnouncedStepIndex = null;
      _feedbackService.stopSpeech();
      return;
    }

    if (hasRoute && oldWidget.activeRouteData != widget.activeRouteData) {
      _cancelCompletionCountdown();
      _currentStepIndex = 0;
      _lastAnnouncedStepIndex = null;
      _announceStepIfNeeded(0);
    }
  }

  Future<void> startScan() async {
    await beaconService.startScanning();
    setState(() => scanning = true);
  }

  Future<void> stopScan() async {
    await beaconService.stopScanning();
    setState(() => scanning = false);
  }

  Future<void> _loadMapPoints() async {
    try {
      final locations = await locationService.fetchLocations();
      if (mounted) {
        setState(() {
          allLocations = locations;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar localizações: $e');
    }
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _beaconSub?.cancel();
    _navigationSub?.cancel();
    beaconService.dispose();
    _floorScrollController.dispose();
    super.dispose();
  }

  void _onFloorChanged(int index) {
    setState(() {
      selectedFloor = floors[index];
    });
  }

  void _setCurrentStepIndex(int newIndex) {
    final steps = widget.activeRouteData?['steps'] as List<dynamic>? ?? [];
    if (steps.isEmpty) return;

    final boundedIndex = newIndex.clamp(0, steps.length);
    if (boundedIndex == _currentStepIndex) return;

    setState(() {
      _currentStepIndex = boundedIndex;
    });

    if (boundedIndex >= steps.length) {
      _lastAnnouncedStepIndex = null;
      final completionMessage = '${AppLocalizations.of(context)!.destinationReached}. ${AppLocalizations.of(context)!.allStepsCompleted}';
      _feedbackService.speak(completionMessage);
      _startCompletionCountdown();
      return;
    }

    _cancelCompletionCountdown();
    _announceStepIfNeeded(boundedIndex);
  }

  Future<void> _announceStepIfNeeded(int stepIndex) async {
    final steps = widget.activeRouteData?['steps'] as List<dynamic>? ?? [];
    if (steps.isEmpty || stepIndex < 0 || stepIndex >= steps.length) return;
    if (_lastAnnouncedStepIndex == stepIndex) return;

    final step = steps[stepIndex] as Map<String, dynamic>;
    final instruction = (step['instruction'] ?? '').toString().trim();
    if (instruction.isEmpty) return;

    final distanceRaw = step['distance'];
    final distance = double.tryParse(distanceRaw?.toString() ?? '')?.round();
    final distanceText = distance != null ? ', $distance m' : '';

    _lastAnnouncedStepIndex = stepIndex;
    await _feedbackService.speak('$instruction$distanceText');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final sequence = widget.activeRouteData?['location_sequence'] as List<dynamic>? ?? [];
    List<LatLng> routePoints = [];

    for (var nodeId in sequence) {
      final location = allLocations.firstWhere(
            (loc) => loc['id'].toString() == nodeId.toString(),
        orElse: () => null,
      );

      if (location != null) {
        final lat = double.parse(location['local_x'].toString());
        final lng = double.parse(location['local_y'].toString());
        routePoints.add(LatLng(lat, lng));
      }
    }

    int currentIndex = floors.indexOf(selectedFloor);
    bool isAtTop = currentIndex == 0;
    bool isAtBottom = currentIndex == floors.length - 1;

    final hasRoute = widget.activeRouteData != null;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // FAB dimensions and margins
    const double fabMargin = 16.0;
    const double fabHeight = 56.0; // Standard FAB height
    const double fabAreaHeight = fabMargin + fabHeight + fabMargin;

    // FAB bottom position logic:
    // When sheet is at min size (0.15), the FAB should be ABOVE the sheet.
    // The sheet height is screenHeight * _sheetPosition.
    // We want the FAB to sit fabMargin above the sheet.
    double fabBottom = fabMargin;
    if (hasRoute && _sheetPosition < 0.3) {
      fabBottom = (screenHeight * _sheetPosition) + fabMargin;
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(41.1785, -8.6075),
              initialZoom: 18.0,
              minZoom: 17.0,
              maxZoom: 22.0,
              cameraConstraint: CameraConstraint.contain(bounds: isepBounds),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tassi.app',
              ),

              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: theme.colorScheme.primary,
                      strokeWidth: 5.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: allLocations.where((loc) {

                  bool isSameFloor = "F${loc['floor']}" == selectedFloor;
                  if (!isSameFloor) return false;

                  final sequence = widget.activeRouteData?['location_sequence'] as List<dynamic>? ?? [];
                  final routeNodeIdsFromWidget = sequence.map((id) => id.toString()).toSet();

                  final allActiveNodes = {...routeNodeIdsFromWidget, ...activeRouteNodeIds};

                  bool isUserHere = currentBeacon?.id == loc['beacon_uuid'];
                  bool isPartOfRoute = allActiveNodes.contains(loc['id'].toString());

                  return isPartOfRoute || isUserHere;
                }).map((loc) {
                  final lat = double.parse(loc['local_x'].toString());
                  final lng = double.parse(loc['local_y'].toString());
                  bool isUserHere = currentBeacon?.id == loc['beacon_uuid'];

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 60,
                    height: 60,
                    child: isUserHere
                        ? _buildUserLocationMarker(theme)
                        : _buildStationaryMarker(theme),
                  );
                }).toList(),
              ),
            ],
          ),

          // Top Right: Sidebar content and controls
          Positioned(
            top: 50,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sidebar hide/show button
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      final willOpen = !isSidebarExpanded;
                      setState(() => isSidebarExpanded = willOpen);
                      if (willOpen) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _floorScrollController.jumpToItem(
                            floors.indexOf(selectedFloor),
                          );
                        });
                      }
                    },
                    icon: Icon(
                      isSidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: isSidebarExpanded ? 'Hide sidebar' : 'Show sidebar',
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    final offsetAnimation = Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    ));
                    return SlideTransition(
                      position: offsetAnimation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: isSidebarExpanded
                      ? Column(
                          key: const ValueKey('sidebarOpen'),
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Floor Selector
                            Container(
                              width: 50,
                              height: 140, // Tighter height
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Column(
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minHeight: 28),
                                    onPressed: isAtTop ? null : () {
                                      _floorScrollController.animateToItem(
                                        currentIndex - 1,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                                    color: isAtTop
                                        ? theme.colorScheme.primary.withValues(alpha: 0.2)
                                        : theme.colorScheme.primary,
                                  ),
                                  Expanded(
                                    child: ListWheelScrollView.useDelegate(
                                      controller: _floorScrollController,
                                      itemExtent: 28,
                                      perspective: 0.00001, // Flat look
                                      diameterRatio: 10,     // Flat look
                                      physics: const FixedExtentScrollPhysics(),
                                      onSelectedItemChanged: _onFloorChanged,
                                      childDelegate: ListWheelChildBuilderDelegate(
                                        childCount: floors.length,
                                        builder: (context, index) {
                                          bool isSelected = selectedFloor == floors[index];
                                          return Center(
                                            child: Text(
                                              floors[index],
                                              style: TextStyle(
                                                color: theme.colorScheme.primary,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                fontSize: 18,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minHeight: 28),
                                    onPressed: isAtBottom ? null : () {
                                      _floorScrollController.animateToItem(
                                        currentIndex + 1,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                    color: isAtBottom
                                        ? theme.colorScheme.primary.withValues(alpha: 0.2)
                                        : theme.colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Legend button
                            GestureDetector(
                              onTap: () => setState(() => isLegendVisible = !isLegendVisible),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isLegendVisible
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.list,
                                  color: isLegendVisible
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox(
                          key: ValueKey('sidebarClosed'),
                          width: 50,
                          height: 0,
                        ),
                ),
              ],
            ),
          ),

          // Navigation Sheet
          if (hasRoute)
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                setState(() {
                  _sheetPosition = notification.extent;
                });
                return true;
              },
              child: DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: 0.15,
                minChildSize: 0.15,
                maxChildSize: 1.0,
                snap: true,
                snapSizes: const [0.15, 0.5, 1.0],
                builder: (context, scrollController) {
                  return _buildNavigationSheet(theme, l10n, scrollController);
                },
              ),
            ),

          // Bottom Left: Settings Button
          AnimatedPositioned(
            duration: const Duration(milliseconds: 50),
            bottom: fabBottom,
            left: 16,
            child: FloatingActionButton.extended(
              heroTag: 'settings_fab',
              onPressed: widget.onOpenSettings,
              backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              icon: Icon(Icons.accessibility_new, color: theme.colorScheme.primary),
              label: Text(
                l10n.settings,
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ),

          // Bottom Right: Recenter Button
          AnimatedPositioned(
            duration: const Duration(milliseconds: 50),
            bottom: fabBottom,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'recenter_fab',
              onPressed: () {
                _mapController.move(const LatLng(41.1785, -8.6075), 18.0);
              },
              backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
              child: Icon(Icons.location_on, color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSheet(ThemeData theme, AppLocalizations l10n, ScrollController scrollController) {
    final steps = widget.activeRouteData?['steps'] as List<dynamic>? ?? [];
    if (steps.isEmpty) return const SizedBox.shrink();

    // FAB dimensions and margins for expanded padding
    const double fabMargin = 16.0;
    const double fabHeight = 56.0; 
    const double fabAreaHeight = fabMargin + fabHeight + fabMargin;

    final isSmallestState = _sheetPosition < 0.2;
    final isComplete = _isNavigationComplete;
    final displayStepIndex = isComplete ? steps.length - 1 : _currentStepIndex.clamp(0, steps.length - 1);
    final currentStep = steps[displayStepIndex] as Map<String, dynamic>;
    final direction = NavigationDirection.fromServerValue(currentStep['direction']);
    final currentStepTitle = isComplete ? l10n.destinationReached : (currentStep['instruction'] ?? 'Unknown step');
    final currentStepSubtitle = isComplete
        ? l10n.allStepsCompleted
        : 'Step ${displayStepIndex + 1} of ${steps.length} • ${double.parse(currentStep['distance'].toString()).round()}m';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header section - Wrapped in ScrollView to share sheet controller
          SingleChildScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handlebar section
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 4,
                  width: double.infinity,
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),

                // Header (Current Step)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          direction.icon,
                          color: theme.colorScheme.onPrimary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentStepTitle,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              currentStepSubtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isComplete)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.keyboard_arrow_left,
                                size: 32,
                                color: _currentStepIndex == 0 ? theme.disabledColor : theme.colorScheme.primary,
                              ),
                              onPressed: _currentStepIndex == 0 ? null : () => _setCurrentStepIndex(_currentStepIndex - 1),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.keyboard_arrow_right,
                                size: 32,
                                color: theme.colorScheme.primary,
                              ),
                              onPressed: () => _setCurrentStepIndex(_currentStepIndex + 1),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.close,
                                size: 24,
                                color: theme.colorScheme.error,
                              ),
                              onPressed: () {
                                _cancelCompletionCountdown();
                                if (widget.onStopNavigation != null) {
                                  widget.onStopNavigation!();
                                  setState(() {
                                    _currentStepIndex = 0;
                                  });
                                }
                              },
                            ),
                          ],
                        )
                      else
                        SizedBox(
                          width: 96,
                          height: 64,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: _completionSecondsRemaining / 5,
                                      strokeWidth: 3,
                                      backgroundColor: theme.colorScheme.primaryContainer,
                                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                                    ),
                                    Text(
                                      '$_completionSecondsRemaining',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '5s',
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Only show List if NOT in smallest state and not complete
          if (!isSmallestState && !isComplete) ...[
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(16, 16, 16, fabAreaHeight),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  final stepDirection = NavigationDirection.fromServerValue(step['direction']);
                  final isActive = index == _currentStepIndex;
                  final isPassed = index < _currentStepIndex;

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 40,
                          child: Column(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isPassed 
                                      ? Colors.grey.withValues(alpha: 0.2) 
                                      : (isActive ? theme.colorScheme.primary : theme.colorScheme.primaryContainer),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPassed ? Icons.check : stepDirection.icon,
                                  color: isPassed ? Colors.grey : (isActive ? theme.colorScheme.onPrimary : theme.colorScheme.primary),
                                  size: 16,
                                ),
                              ),
                              if (index < steps.length - 1)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step['instruction'] ?? '',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                    color: isPassed ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  isActive ? 'Active Step • ${double.parse(step['distance'].toString()).round()}m' : 'Step ${index + 1} of ${steps.length} • ${double.parse(step['distance'].toString()).round()}m',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserLocationMarker(ThemeData theme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Anel externo com opacidade (Efeito de pulsação visual)
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        ),
        // Ponto Central
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.navigation,
            color: Colors.white,
            size: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStationaryMarker(ThemeData theme) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
