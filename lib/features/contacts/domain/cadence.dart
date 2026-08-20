import 'package:flutter/foundation.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/l10n/gen/app_localizations.dart';

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
      return const Err(
        ValidationFailure(
          'Enter how many days.',
          issue: ValidationIssue.cadenceEmpty,
        ),
      );
    }
    final days = int.tryParse(trimmed);
    if (days == null) {
      return const Err(
        ValidationFailure(
          'Use a whole number of days.',
          issue: ValidationIssue.cadenceNotANumber,
        ),
      );
    }
    if (days < minDays) {
      return const Err(
        ValidationFailure(
          'Use at least $minDays day.',
          issue: ValidationIssue.cadenceTooShort,
          args: {'min': minDays},
        ),
      );
    }
    if (days > maxDays) {
      return const Err(
        ValidationFailure(
          'Use at most $maxDays days.',
          issue: ValidationIssue.cadenceTooLong,
          args: {'max': maxDays},
        ),
      );
    }
    return Ok(Cadence.custom(days));
  }

  /// Whether this matches one of the [presets].
  bool get isPreset => presets.contains(this);

  /// How the interval is written in the UI.
  ///
  /// A method taking [l10n] rather than a getter, like every label in the
  /// domain layer: the wording belongs to the locale, and passing the lookup
  /// in keeps this pure and table-testable with a concrete
  /// `AppLocalizationsEn`.
  String label(AppLocalizations l10n) => switch (days) {
    1 => l10n.cadenceDaily,
    7 => l10n.cadenceWeekly,
    14 => l10n.cadenceBiweekly,
    30 => l10n.cadenceMonthly,
    91 => l10n.cadenceQuarterly,
    182 => l10n.cadenceTwiceAYear,
    _ => l10n.cadenceEveryDays(days),
  };

  /// The interval as it reads mid-sentence: "you usually see Marcus
  /// monthly", "you usually see Ana every 2 weeks".
  ///
  /// Its own set of messages rather than [label] with the first letter
  /// lowered: casing mid-sentence is a property of the language, not of the
  /// string, and German would keep the capital this trick strips.
  String phrase(AppLocalizations l10n) => switch (days) {
    1 => l10n.cadencePhraseDaily,
    7 => l10n.cadencePhraseWeekly,
    14 => l10n.cadencePhraseBiweekly,
    30 => l10n.cadencePhraseMonthly,
    91 => l10n.cadencePhraseQuarterly,
    182 => l10n.cadencePhraseTwiceAYear,
    _ => l10n.cadencePhraseEveryDays(days),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Cadence && other.days == days;

  @override
  int get hashCode => days.hashCode;

  @override
  String toString() => 'Cadence($days days)';
}
