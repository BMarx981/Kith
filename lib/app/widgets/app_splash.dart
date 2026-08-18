import 'package:flutter/material.dart';
import 'package:kith/app/theme.dart';

/// Fills the beat before the first route can be rendered.
///
/// The auth guard waits for the backend to say whether a stored session
/// survived before it resolves the app's first navigation, so on cold start
/// there is a moment with no page to show. This is the router's placeholder
/// for it.
class AppSplash extends StatelessWidget {
  const AppSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kith',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: KithSpacing.lg),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
