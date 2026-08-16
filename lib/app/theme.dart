import 'package:flutter/material.dart';

/// Freshness is the app's central visual signal, so its three states are
/// defined once here and reused by the gauge, list rows and suggestion cards.
@immutable
class FreshnessColors extends ThemeExtension<FreshnessColors> {
  const FreshnessColors({
    required this.fresh,
    required this.due,
    required this.overdue,
    required this.unknown,
  });

  /// Seen recently relative to the contact's cadence.
  final Color fresh;

  /// Approaching or just past the cadence.
  final Color due;

  /// Well past the cadence.
  final Color overdue;

  /// Never seen, or no hangouts logged yet. Distinct from all of the above.
  final Color unknown;

  @override
  FreshnessColors copyWith({
    Color? fresh,
    Color? due,
    Color? overdue,
    Color? unknown,
  }) {
    return FreshnessColors(
      fresh: fresh ?? this.fresh,
      due: due ?? this.due,
      overdue: overdue ?? this.overdue,
      unknown: unknown ?? this.unknown,
    );
  }

  @override
  FreshnessColors lerp(ThemeExtension<FreshnessColors>? other, double t) {
    if (other is! FreshnessColors) return this;
    return FreshnessColors(
      fresh: Color.lerp(fresh, other.fresh, t)!,
      due: Color.lerp(due, other.due, t)!,
      overdue: Color.lerp(overdue, other.overdue, t)!,
      unknown: Color.lerp(unknown, other.unknown, t)!,
    );
  }
}

/// Light and dark themes for the app shell.
abstract final class KithTheme {
  /// Seed for the Material 3 colour scheme.
  static const seed = Color(0xFF4C7A5A);

  static const _lightFreshness = FreshnessColors(
    fresh: Color(0xFF2E7D5B),
    due: Color(0xFFB77A1B),
    overdue: Color(0xFFB3261E),
    unknown: Color(0xFF6B6B6B),
  );

  static const _darkFreshness = FreshnessColors(
    fresh: Color(0xFF6FD3A2),
    due: Color(0xFFE3B565),
    overdue: Color(0xFFF2B8B5),
    unknown: Color(0xFF9E9E9E),
  );

  /// The light theme.
  static ThemeData get light => _build(Brightness.light, _lightFreshness);

  /// The dark theme.
  static ThemeData get dark => _build(Brightness.dark, _darkFreshness);

  static ThemeData _build(Brightness brightness, FreshnessColors freshness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
      ),
      extensions: [freshness],
    );
  }
}
