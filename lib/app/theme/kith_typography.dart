import 'package:flutter/material.dart';

/// The type scale described in `docs/DESIGN.md`.
///
/// Two families: [displayFamily] carries the wordmark and every title, and
/// [bodyFamily] carries the rest. The contrast between a warm serif and a
/// quiet sans is the app's signature, so neither drifts into the other's job.
///
/// Both are bundled TTF assets rather than a font package, so the app renders
/// identically offline and in golden tests.
abstract final class KithTypography {
  /// Display face, for the wordmark and titles.
  static const displayFamily = 'Fraunces';

  /// Body face, and the theme's default family.
  static const bodyFamily = 'Inter';

  /// Builds the scale, colouring every style from [scheme].
  ///
  /// Colours are explicit rather than inherited so the scale reads the same
  /// whichever brightness it is built for; screens still tint individual
  /// pieces of copy with `copyWith`.
  static TextTheme textTheme(ColorScheme scheme) {
    final onSurface = scheme.onSurface;

    return TextTheme(
      headlineMedium: TextStyle(
        fontFamily: displayFamily,
        fontSize: 30,
        fontWeight: FontWeight.w600,
        height: 1.15,
        letterSpacing: -0.2,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: displayFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: displayFamily,
        fontSize: 21,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.6,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 16,
        height: 1.5,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 14,
        height: 1.45,
        color: onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 12,
        height: 1.4,
        color: onSurface,
      ),
      labelLarge: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: onSurface,
      ),
    );
  }
}
