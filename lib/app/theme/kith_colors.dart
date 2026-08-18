import 'package:flutter/material.dart';
import 'package:kith/app/theme/freshness_colors.dart';

/// The palette described in `docs/DESIGN.md`.
///
/// Each scheme starts from [seed], so the roles the app never renders stay
/// internally coherent, and then overrides every role it does. Left to itself
/// `fromSeed` derives tonal purple-grey surfaces, which are the loudest
/// stock-Material tell and the main thing the redesign replaces.
///
/// The whole `surfaceContainer` ramp is overridden, not just the two steps the
/// app renders today: a dialog or menu picking a seed-derived value out of the
/// middle of a hand-built ramp would read as a different app.
abstract final class KithColors {
  /// Seed for the roles neither scheme overrides.
  static const seed = Color(0xFF4C7A5A);

  static ColorScheme _base(Brightness brightness) =>
      ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

  /// Roles for the light theme.
  static ColorScheme get light => _base(Brightness.light).copyWith(
    primary: const Color(0xFF3E6B52),
    onPrimary: const Color(0xFFF7F9F7),
    surface: const Color(0xFFF8FAF8),
    onSurface: const Color(0xFF1E2622),
    surfaceContainerLowest: const Color(0xFFFFFFFF),
    surfaceContainerLow: const Color(0xFFF1F4F1),
    surfaceContainer: const Color(0xFFEEF2EF),
    surfaceContainerHigh: const Color(0xFFECEFEC),
    surfaceContainerHighest: const Color(0xFFE9EDEA),
    onSurfaceVariant: const Color(0xFF5B655F),
    outline: const Color(0xFFAEB8B1),
    outlineVariant: const Color(0xFFE2E7E3),
    error: const Color(0xFFA6403A),
    inverseSurface: const Color(0xFF2A322D),
    onInverseSurface: const Color(0xFFF1F4F1),
    // Elevation overlays are what tint Material's surfaces; with every
    // elevation at zero the tint should never arrive at all.
    surfaceTint: Colors.transparent,
  );

  /// Roles for the dark theme.
  static ColorScheme get dark => _base(Brightness.dark).copyWith(
    primary: const Color(0xFF93C3A7),
    onPrimary: const Color(0xFF11291C),
    surface: const Color(0xFF141817),
    onSurface: const Color(0xFFE3E8E4),
    surfaceContainerLowest: const Color(0xFF0F1211),
    surfaceContainerLow: const Color(0xFF1B201D),
    surfaceContainer: const Color(0xFF1F2421),
    surfaceContainerHigh: const Color(0xFF222825),
    surfaceContainerHighest: const Color(0xFF262C29),
    onSurfaceVariant: const Color(0xFF98A29B),
    outline: const Color(0xFF4C544F),
    outlineVariant: const Color(0xFF272D2A),
    error: const Color(0xFFDD8F89),
    inverseSurface: const Color(0xFFE3E8E4),
    onInverseSurface: const Color(0xFF1E2622),
    surfaceTint: Colors.transparent,
  );

  /// Freshness states for the light theme.
  ///
  /// `fresh` is the accent and `overdue` is the error colour, so the gauge
  /// harmonises with the rest of the app instead of importing a third palette.
  static const lightFreshness = FreshnessColors(
    fresh: Color(0xFF3E6B52),
    due: Color(0xFF9A7126),
    overdue: Color(0xFFA6403A),
    unknown: Color(0xFF79837D),
  );

  /// Freshness states for the dark theme.
  static const darkFreshness = FreshnessColors(
    fresh: Color(0xFF93C3A7),
    due: Color(0xFFD3AC66),
    overdue: Color(0xFFDD8F89),
    unknown: Color(0xFF828C86),
  );
}
