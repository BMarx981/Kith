import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:kith/app/widgets/milestone_placeholder.dart';
import 'package:kith/routing/app_router.dart';

/// Landing screen; will host the ranked "Reconnect" suggestions.
///
/// Its one control is the way through to the household screen, which is where
/// the members, the invite code and sign-out live.
@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Identifies the household action to tests.
  static const householdKey = Key('home.household');

  @override
  Widget build(BuildContext context) {
    return MilestonePlaceholder(
      title: 'Reconnect',
      milestone: 'M4',
      icon: Icons.favorite_outline,
      actions: [
        IconButton(
          key: householdKey,
          onPressed: () => context.router.push(const HouseholdRoute()),
          icon: const Icon(Icons.people_outline),
          tooltip: 'Household',
        ),
      ],
    );
  }
}
