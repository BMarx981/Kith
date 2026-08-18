import 'package:flutter/material.dart';
import 'package:kith/app/theme.dart';

/// The page both pre-household screens are laid out on.
///
/// Sign-in and household onboarding are the only screens with no app bar and
/// nothing but a form: each centres its content, caps it at a comfortable
/// reading width and lets it scroll once a keyboard or a short window squeezes
/// it. That layout is identical on both, so it lives here.
class CenteredFormShell extends StatelessWidget {
  const CenteredFormShell({required this.child, super.key});

  /// The form, or whatever stands in its place.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: KithSpacing.lg,
              vertical: KithSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: KithSpacing.formMaxWidth,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
