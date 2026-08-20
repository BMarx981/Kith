import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/app/widgets/app_splash.dart';
import 'package:kith/l10n/l10n.dart';
import 'package:kith/routing/app_router.dart';

/// Root widget: wires the router and themes into a [MaterialApp].
class KithApp extends ConsumerWidget {
  const KithApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: KithTheme.light,
      darkTheme: KithTheme.dark,
      routerConfig: router.config(
        // Shown while the auth guard waits to hear whether a stored session
        // survived, which is the only time the stack is empty.
        placeholder: (_) => const AppSplash(),
      ),
    );
  }
}
