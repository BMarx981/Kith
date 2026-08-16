import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/app/widgets/milestone_placeholder.dart';
import 'package:kith/features/auth/application/auth_providers.dart';

/// Landing screen; will host the ranked "Reconnect" suggestions.
///
/// Carries sign-out until the member screens exist to hold it: without it
/// there is no way back out of a session, on a device or in a test.
@RoutePage()
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Identifies the sign-out action to tests.
  static const signOutKey = Key('home.signOut');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MilestonePlaceholder(
      title: 'Reconnect',
      milestone: 'M4',
      icon: Icons.favorite_outline,
      actions: [
        IconButton(
          key: signOutKey,
          onPressed: () => ref.read(authServiceProvider).signOut(),
          icon: const Icon(Icons.logout_outlined),
          tooltip: 'Sign out',
        ),
      ],
    );
  }
}
