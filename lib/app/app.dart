import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/routing/app_router.dart';

/// Root widget: wires the router and themes into a [MaterialApp].
class KithApp extends ConsumerWidget {
  const KithApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Kith',
      theme: KithTheme.light,
      darkTheme: KithTheme.dark,
      routerConfig: router.config(),
    );
  }
}
