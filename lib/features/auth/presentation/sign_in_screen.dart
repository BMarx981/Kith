import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:kith/app/widgets/milestone_placeholder.dart';

/// Entry point for unauthenticated users.
@RoutePage()
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MilestonePlaceholder(
      title: 'Sign in',
      milestone: 'M1',
      icon: Icons.login_outlined,
    );
  }
}
