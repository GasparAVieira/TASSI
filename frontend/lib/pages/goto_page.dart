import 'package:flutter/material.dart';

import '../models/location.dart';
import '../services/location_service.dart';
import '../services/navigation_service.dart';
import '../widgets/error_popup.dart';
import '../widgets/location_card.dart';

class GoToPage extends StatefulWidget {
  const GoToPage({super.key});

  @override
  State<GoToPage> createState() => _GoToPageState();
}

class _GoToPageState extends State<GoToPage> {
  int? _expandedIndex;
  bool _isLoading = false;
  bool _isRequestingRoute = false;

  final LocationService _locationService = LocationService();
  final NavigationService _navigationService = NavigationService();
  final TextEditingController _searchController = TextEditingController();

  List<Location> _allLocations = [];
  List<Location> _displayedLocations = [];

  Location? _selectedOrigin;
  Map<String, dynamic>? _routeResult;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _filterLocations(_searchController.text);
    });
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locations = await _locationService.fetchLocations();
      if (!mounted) return;

      setState(() {
        _allLocations = locations;
        _displayedLocations = List.from(locations);
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

  void _filterLocations(String query) {
    final normalized = query.toLowerCase().trim();

    setState(() {
      _expandedIndex = null;
      _routeResult = null;

      if (normalized.isEmpty) {
        _displayedLocations = List.from(_allLocations);
      } else {
        _displayedLocations = _allLocations.where((location) {
          return location.name.toLowerCase().contains(normalized) ||
              (location.description?.toLowerCase().contains(normalized) ?? false) ||
              location.type.toLowerCase().contains(normalized);
        }).toList();
      }
    });
  }

  Future<void> _requestRoute(Location destination) async {
    if (_selectedOrigin == null) {
      _showMessage('Select your current location first.');
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
    Location destination,
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
                      hintText: 'Search destination...',
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
                                _filterLocations('');
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
            const SizedBox(height: 10),

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
                  child: DropdownButtonFormField<Location>(
                    value: _selectedOrigin,
                    decoration: const InputDecoration(
                      labelText: 'Current location',
                      border: OutlineInputBorder(),
                    ),
                    items: _allLocations
                        .map(
                          (location) => DropdownMenuItem<Location>(
                            value: location,
                            child: Text(location.name),
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

            const SizedBox(height: 10),

            Expanded(
              child: _displayedLocations.isEmpty && !_isLoading
                  ? Center(
                      child: Text(
                        'No Locations Found.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: _displayedLocations.length,
                      itemBuilder: (context, index) {
                        final location = _displayedLocations[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Column(
                            children: [
                              LocationCard(
                                location: location,
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
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _isRequestingRoute
                                      ? null
                                      : () => _requestRoute(location),
                                  icon: const Icon(Icons.alt_route),
                                  label: const Text('Go To'),
                                ),
                              ),
                            ],
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