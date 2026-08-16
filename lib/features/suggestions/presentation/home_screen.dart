import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:kith/app/widgets/milestone_placeholder.dart';

/// Landing screen; will host the ranked "Reconnect" suggestions.
@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MilestonePlaceholder(
      title: 'Reconnect',
      milestone: 'M4',
      icon: Icons.favorite_outline,
    );
  }
}
