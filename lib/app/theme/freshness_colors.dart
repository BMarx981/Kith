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
