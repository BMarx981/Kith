import 'package:flutter/foundation.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';

/// How often you mean to see a contact, in days.
///
/// Days rather than a named interval because that is what the freshness maths
/// divides by: `daysSinceLastHangout / cadenceDays`. The named intervals are
/// presets over the same number, so "Monthly" and a custom 30 days are the
/// same cadence and are stored, compared and computed with identically. Only
/// [label] tells them apart, and only for display.
@immutable
class Cadence {
  /// A cadence of exactly [days], for the custom option in the editor.
  ///
  /// Const so the presets can be built from it. Out-of-range values are the
  /// caller's problem here; [parse] and [Cadence.fromDays] are the guarded
  /// ways in.
  const Cadence.custom(this.days);

  /// Rebuilds a cadence from a stored day count.
  ///
  /// Clamps rather than throwing: a document holding a nonsensical interval
  /// should still render as a contact, and the clamped value is closer to the
  /// truth than refusing to load the row.
  factory Cadence.fromDays(int days) =>
      Cadence.custom(days.clamp(minDays, maxDays));

  /// The interval in days. Always between [minDays] and [maxDays] for any
  /// cadence built by [parse] or [Cadence.fromDays].
  final int days;

  /// Shortest interval the editor accepts.
  static const minDays = 1;

  /// Longest interval the editor accepts: ten years, which is past the point
  /// where "how often do you want to see them" means anything.
  static const maxDays = 3650;

  /// Once a week.
  static const weekly = Cadence.custom(7);

  /// Once a fortnight.
  static const biweekly = Cadence.custom(14);

  /// Once a month, rounded to a flat 30 days so the maths needs no calendar.
  static const monthly = Cadence.custom(30);

  /// Once a quarter: 13 weeks.
  static const quarterly = Cadence.custom(91);

  /// Twice a year: 26 weeks.
  static const twiceAYear = Cadence.custom(182);

  /// The offered intervals, shortest first. The editor renders these as
  /// choices and everything else as "custom".
  static const presets = <Cadence>[
    weekly,
    biweekly,
    monthly,
    quarterly,
    twiceAYear,
  ];

  /// Reads a day count the user typed into the custom field.
  ///
  /// Returns the error to show under the field on anything that is not a
  /// whole number of days in range.
  static Result<Cadence> parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const Err(ValidationFailure('Enter how many days.'));
    }
    final days = int.tryParse(trimmed);
    if (days == null) {
      return const Err(ValidationFailure('Use a whole number of days.'));
    }
    if (days < minDays) {
      return const Err(ValidationFailure('Use at least $minDays day.'));
    }
    if (days > maxDays) {
      return const Err(ValidationFailure('Use at most $maxDays days.'));
    }
    return Ok(Cadence.custom(days));
  }

  /// Whether this matches one of the [presets].
  bool get isPreset => presets.contains(this);

  /// How the interval is written in the UI.
  String get label => switch (days) {
    1 => 'Daily',
    7 => 'Weekly',
    14 => 'Every 2 weeks',
    30 => 'Monthly',
    91 => 'Every 3 months',
    182 => 'Twice a year',
    _ => 'Every $days days',
  };

  /// The interval as it reads mid-sentence: "you usually see Marcus
  /// monthly", "you usually see Ana every 2 weeks".
  ///
  /// [label] with its first letter dropped to lower case, rather than a
  /// second table of wordings that could drift from the first. Every label is
  /// ASCII and starts with a word, so the first code unit is the first letter.
  String get phrase {
    final label = this.label;
    return label[0].toLowerCase() + label.substring(1);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Cadence && other.days == days;

  @override
  int get hashCode => days.hashCode;

  @override
  String toString() => 'Cadence($days days)';
}
