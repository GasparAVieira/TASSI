import 'package:flutter/material.dart';

import '../models/location.dart';

class LocationCard extends StatelessWidget {
  final Location location;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onFavoriteToggle;

  const LocationCard({
    super.key,
    required this.location,
    required this.isExpanded,
    required this.onToggle,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: onToggle,
            leading: const FlutterLogo(size: 56.0),
            title: Text(
              location.name,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              location.type,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (location.isWheelchairFriendly)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      label: Text(
                        'Wheelchair',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                IconButton(
                  icon: Icon(isExpanded ? Icons.close : Icons.chevron_right),
                  onPressed: onToggle,
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            if (location.imageUrl != null && location.imageUrl!.isNotEmpty)
              Image.network(
                location.imageUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              )
            else
              Container(
                width: double.infinity,
                height: 180,
                color: theme.colorScheme.surfaceVariant,
                child: Icon(
                  Icons.location_on,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              location.type,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          location.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: location.isFavorite ? theme.colorScheme.primary : null,
                        ),
                        onPressed: onFavoriteToggle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    location.description ?? 'No description available.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Open in Map'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        child: const Text('Go To'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
