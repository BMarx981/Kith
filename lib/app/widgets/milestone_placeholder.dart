import 'package:flutter/material.dart';

/// Stands in for a screen whose feature has not been built yet.
///
/// The M0 skeleton ships the routing graph before the features that fill it,
/// so each route needs something real to render. Screens replace this body
/// wholesale as their milestone lands.
class MilestonePlaceholder extends StatelessWidget {
  const MilestonePlaceholder({
    required this.title,
    required this.milestone,
    required this.icon,
    super.key,
  });

  /// Screen title, shown in the app bar.
  final String title;

  /// The milestone that will implement this screen, e.g. `M2`.
  final String milestone;

  /// Illustrative icon for the empty body.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Arrives in $milestone',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
