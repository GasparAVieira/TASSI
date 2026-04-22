import 'package:flutter/material.dart';
import '../models/location.dart';
import '../services/location_service.dart';
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
  String? _searchingWithQuery;
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  List<Location> _allLocations = [];
  late List<Location> _displayedLocations;

  @override
  void initState() {
    super.initState();
    _displayedLocations = [];
    _searchController.addListener(() {
      setState(() {}); // Rebuild to update suffix icon
    });
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _allLocations = await _locationService.fetchLocations();
      if (mounted) {
        setState(() {
          _displayedLocations = List.from(_allLocations);
        });
      }
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Mimics a remote API search call
  Future<void> _handleSearch(String query) async {
    setState(() {
      _isLoading = true;
      _searchingWithQuery = query;
      _expandedIndex = null; // Close any expanded cards on new search
    });

    try {
      final results = await _locationService.fetchLocations(query);
      if (!mounted || _searchingWithQuery != query) return;
      setState(() {
        _displayedLocations = results;
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

  Future<void> _toggleFavorite(Location location) async {
    await _locationService.toggleFavorite(location);
    if (!mounted) return;
    setState(() {});
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
            // Search Bar with Close/Clear button and Async logic
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
                    onChanged: _handleSearch,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 16, 
                                height: 16, 
                                child: CircularProgressIndicator(strokeWidth: 2)
                              ),
                            ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _handleSearch('');
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
            // Locations List
            Expanded(
              child: _displayedLocations.isEmpty && !_isLoading
                ? Center(
                    child: Text(
                      'No Locations Found.',
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: _displayedLocations.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: LocationCard(
                          location: _displayedLocations[index],
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
                          onFavoriteToggle: () => _toggleFavorite(_displayedLocations[index]),
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

