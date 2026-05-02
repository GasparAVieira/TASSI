import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class AccessibilityProfilePicker extends StatelessWidget {
  final bool wheelchairEnabled;
  final bool lowVisionEnabled;
  final bool blindEnabled;
  final ValueChanged<bool> onWheelchairChanged;
  final ValueChanged<bool> onLowVisionChanged;
  final ValueChanged<bool> onBlindChanged;
  final bool showApplyButton;
  final Future<void> Function()? onApply;
  final bool useCard;

  const AccessibilityProfilePicker({
    super.key,
    required this.wheelchairEnabled,
    required this.lowVisionEnabled,
    required this.blindEnabled,
    required this.onWheelchairChanged,
    required this.onLowVisionChanged,
    required this.onBlindChanged,
    this.showApplyButton = false,
    this.onApply,
    this.useCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final description = _profileDescription(
      l10n,
      wheelchairEnabled,
      lowVisionEnabled,
      blindEnabled,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.accessibilityProfile,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            SizedBox(
              width: 100,
              child: _buildToggleOption(
                context,
                icon: Icons.accessible,
                label: l10n.wheelchairProfile,
                selected: wheelchairEnabled,
                onTap: () => onWheelchairChanged(!wheelchairEnabled),
              ),
            ),
            SizedBox(
              width: 100,
              child: _buildToggleOption(
                context,
                icon: Icons.visibility,
                label: l10n.lowVisionProfile,
                selected: lowVisionEnabled,
                onTap: () => onLowVisionChanged(!lowVisionEnabled),
              ),
            ),
            SizedBox(
              width: 100,
              child: _buildToggleOption(
                context,
                icon: Icons.remove_red_eye,
                label: l10n.blindProfile,
                selected: blindEnabled,
                onTap: () => onBlindChanged(!blindEnabled),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          description,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (showApplyButton && onApply != null) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await onApply!();
            },
            child: Text(l10n.applyProfileSettings),
          ),
        ],
      ],
    );

    if (!useCard) {
      return content;
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: content,
      ),
    );
  }

  String _profileDescription(
    AppLocalizations l10n,
    bool wheelchairEnabled,
    bool lowVisionEnabled,
    bool blindEnabled,
  ) {
    if (wheelchairEnabled && blindEnabled) {
      return l10n.accessibilityProfileDescriptionBoth;
    }
    if (wheelchairEnabled) {
      return l10n.accessibilityProfileDescriptionWheelchair;
    }
    if (blindEnabled) {
      return l10n.accessibilityProfileDescriptionBlind;
    }
    if (lowVisionEnabled) {
      return l10n.accessibilityProfileDescriptionLowVision;
    }
    return l10n.accessibilityProfileDescriptionNone;
  }

  Widget _buildToggleOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final selectedColor = selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final backgroundColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
                width: selected ? 2.5 : 1.0,
              ),
            ),
            child: Icon(icon, size: 26, color: selectedColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
