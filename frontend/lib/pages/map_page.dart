import 'package:flutter/material.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';
import '../services/beacon_service.dart';

class MapPage extends StatefulWidget {
  final VoidCallback? onOpenSettings;

  const MapPage({super.key, this.onOpenSettings});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final BeaconService beaconService = BeaconService(
    targetLocationId: "f6dbc5e3-f901-4799-ba06-c23deb71a4b5",
  );

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

  @override
  void initState() {
    super.initState();
    _floorScrollController = FixedExtentScrollController(
      initialItem: floors.indexOf(selectedFloor),
    );

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        currentInstruction = "TESTE: instrução a funcionar";
        print("TESTE: instrução a funcionar");
      });
    });

    Future.microtask(() async {
      await beaconService.startScanning();
      setState(() => scanning = true);
    });

    _beaconSub = beaconService.stream.listen((beacon) async {
      setState(() {
        currentBeacon = beacon;
      });
    });

    _navigationSub = beaconService.navigationStream.listen((data) {
      print("NAV RECEBIDO: $data");

      setState(() {
        currentInstruction = "TESTE FORÇADO";
      });
    });
  }

  Future<void> startScan() async {
    await beaconService.startScanning();
    setState(() => scanning = true);
  }

  Future<void> stopScan() async {
    await beaconService.stopScanning();
    setState(() => scanning = false);
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    int currentIndex = floors.indexOf(selectedFloor);
    bool isAtTop = currentIndex == 0;
    bool isAtBottom = currentIndex == floors.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // Placeholder for the Map
          Container(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: const Center(
              child: Icon(Icons.map, size: 100, color: Colors.grey),
            ),
          ),

          if (currentInstruction.isNotEmpty)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.navigation,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        currentInstruction,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

          // Bottom Left: Settings Button
          Positioned(
            bottom: 16,
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
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'recenter_fab',
              onPressed: () {
                // Recenter map logic
              },
              backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.location_on, color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
