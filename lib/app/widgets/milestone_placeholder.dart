import 'package:flutter/material.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/l10n/l10n.dart';

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
    this.actions,
    super.key,
  });

  /// Screen title, shown in the app bar.
  final String title;

  /// The milestone that will implement this screen, e.g. `M2`.
  final String milestone;

  /// Illustrative icon for the empty body.
  final IconData icon;

  /// App bar actions, for the few controls that exist before the screen does.
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: KithSpacing.sm),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: KithSpacing.xxs),
            Text(
              context.l10n.arrivesInMilestone(milestone),
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
