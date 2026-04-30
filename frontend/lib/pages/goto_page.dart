import 'package:flutter/material.dart';

import '../models/room.dart';
import '../services/room_service.dart';
import '../services/navigation_service.dart';
import '../widgets/error_popup.dart';
import '../widgets/room_card.dart';

class GoToPage extends StatefulWidget {
  const GoToPage({super.key});

  @override
  State<GoToPage> createState() => _GoToPageState();
}

class _GoToPageState extends State<GoToPage> {
  int? _expandedIndex;
  bool _isLoading = false;
  bool _isRequestingRoute = false;

  final RoomService _roomService = RoomService();
  final NavigationService _navigationService = NavigationService();
  final TextEditingController _searchController = TextEditingController();

  List<Room> _allRooms = [];
  List<Room> _displayedRooms = [];

  Room? _selectedOrigin;
  Map<String, dynamic>? _routeResult;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _filterRooms(_searchController.text);
    });
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rooms = await _roomService.fetchRooms();
      if (!mounted) return;

      setState(() {
        _allRooms = rooms;
        _displayedRooms = List.from(rooms);
      });
    } catch (_) {
      if (mounted) {
        showErrorPopup(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterRooms(String query) {
    final normalized = query.toLowerCase().trim();

    setState(() {
      _expandedIndex = null;
      _routeResult = null;

      if (normalized.isEmpty) {
        _displayedRooms = List.from(_allRooms);
      } else {
        _displayedRooms = _allRooms.where((room) {
          return room.name.toLowerCase().contains(normalized) ||
              room.code.toLowerCase().contains(normalized) ||
              room.floor.toString().contains(normalized);
        }).toList();
      }
    });
  }

  Future<void> _requestRoute(Room destination) async {
    if (_selectedOrigin == null) {
      _showMessage('Select your current room first.');
      return;
    }

    setState(() {
      _isRequestingRoute = true;
      _routeResult = null;
    });

    try {
      final result = await _navigationService.getRoute(
        fromLocationId: _selectedOrigin!.id,
        toLocationId: destination.id,
      );

      if (!mounted) return;

      setState(() {
        _routeResult = result;
      });

      _showRouteBottomSheet(result, destination);
    } catch (_) {
      if (mounted) {
        showErrorPopup(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingRoute = false;
        });
      }
    }
  }

  void _showRouteBottomSheet(
    Map<String, dynamic> route,
    Room destination,
  ) {
    final steps = route['steps'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Route to ${destination.name}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Profile used: ${route['profile_used']}'),
                Text('Total distance: ${route['total_distance']}'),
                Text('Total cost: ${route['total_cost']}'),
                const SizedBox(height: 16),
                if (steps.isEmpty)
                  const Text('No route steps available.')
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: steps.length,
                      itemBuilder: (context, index) {
                        final step = steps[index] as Map<String, dynamic>;
                        return Card(
                          child: ListTile(
                            title: Text(
                              step['instruction']?.toString() ?? 'No instruction',
                            ),
                            subtitle: Text(
                              'Direction: ${step['direction']} • Distance: ${step['distance']}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search destinations...',
                      prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLoading || _isRequestingRoute)
                            const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterRooms('');
                              },
                            ),
                        ],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ),
            ),

            /*
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DropdownButtonFormField<Room>(
                    value: _selectedOrigin,
                    decoration: const InputDecoration(
                      labelText: 'Current room',
                      border: OutlineInputBorder(),
                    ),
                    items: _allRooms
                        .map(
                          (room) => DropdownMenuItem<Room>(
                            value: room,
                            child: Text(room.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedOrigin = value;
                        _routeResult = null;
                      });
                    },
                  ),
                ),
              ),
            ),
            */

            const SizedBox(height: 10),

            Expanded(
              child: _displayedRooms.isEmpty && !_isLoading
                  ? Center(
                      child: Text(
                        'No rooms found.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRooms,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: _displayedRooms.length,
                        itemBuilder: (context, index) {
                          final room = _displayedRooms[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: RoomCard(
                              room: room,
                              isExpanded: _expandedIndex == index,
                              onToggle: () {
                                setState(() {
                                  if (_expandedIndex == index) {
                                    _expandedIndex = null;
                                  } else {
                                    _expandedIndex = index;
                                  }
                                });
                              },
                              onFavoriteToggle: () {},
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}