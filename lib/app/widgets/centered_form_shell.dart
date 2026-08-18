import 'package:flutter/material.dart';
import 'package:kith/app/theme.dart';

/// The layout every form in the app is laid out on.
///
/// Centres its content, caps it at a comfortable reading width and lets it
/// scroll once a keyboard or a short window squeezes it. Separate from
/// [CenteredFormShell] because the contact editor needs this layout inside a
/// scaffold that already has an app bar.
class CenteredFormBody extends StatelessWidget {
  const CenteredFormBody({required this.child, super.key});

  /// The form, or whatever stands in its place.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
    );
  }
}

/// The page both pre-household screens are laid out on.
///
/// Sign-in and household onboarding are the only screens with no app bar and
/// nothing but a form: each gives the form a page of its own, laid out by
/// [CenteredFormBody].
class CenteredFormShell extends StatelessWidget {
  const CenteredFormShell({required this.child, super.key});

  /// The form, or whatever stands in its place.
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: CenteredFormBody(child: child));
}
