import 'package:flutter/foundation.dart';
import 'package:kith/core/time/calendar_day.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/l10n/gen/app_localizations.dart';

/// Where a contact sits against the cadence you set for them.
///
/// Four states, not three: a contact nobody has logged yet is not overdue,
/// it is unmeasured, and colouring it red would be a claim the data does not
/// support. `docs/DESIGN.md` gives each its colour.
enum FreshnessState {
  /// Seen recently relative to the cadence: ratio below [Freshness.dueFrom].
  fresh,

  /// At or near the cadence: ratio between [Freshness.dueFrom] and
  /// [Freshness.overdueAbove], both ends included.
  due,

  /// Well past the cadence: ratio above [Freshness.overdueAbove].
  overdue,

  /// No hangout has ever been logged for this contact.
  never,
}

/// How overdue a contact is, as of a fixed instant.
///
/// Pure: built from a cadence, a last-seen day and a "now", with no clock read
/// and no I/O of its own, which is what makes the whole gauge table-testable.
/// Callers get "now" from `clockProvider`.
@immutable
class Freshness {
  const Freshness._({
    required this.state,
    required this.ratio,
    required this.daysSince,
    required this.lastSeenOn,
  });

  /// The reading for a contact with no hangout behind them.
  const Freshness.never()
    : state = FreshnessState.never,
      ratio = null,
      daysSince = null,
      lastSeenOn = null;

  /// Where [cadence] and [lastSeenOn] put a contact as of [now].
  ///
  /// A null [lastSeenOn] is [FreshnessState.never]. A day in the future — a
  /// hangout logged ahead, or a phone whose clock is behind — reads as zero
  /// days since rather than as a negative ratio, so the gauge never runs
  /// backwards.
  factory Freshness.of({
    required Cadence cadence,
    required DateTime? lastSeenOn,
    required DateTime now,
  }) {
    if (lastSeenOn == null) return const Freshness.never();
    final days = CalendarDay.between(lastSeenOn, now).clamp(0, 1 << 30);
    final ratio = days / cadence.days;
    return Freshness._(
      state: _stateFor(ratio),
      ratio: ratio,
      daysSince: days,
      lastSeenOn: CalendarDay.of(lastSeenOn),
    );
  }

  /// Which of the four readings this is.
  final FreshnessState state;

  /// `daysSinceLastHangout / cadenceDays`, or null when [state] is
  /// [FreshnessState.never]. Unclamped: 3.0 means three times the cadence has
  /// gone by, which the suggestion engine ranks on.
  final double? ratio;

  /// Whole days since the last hangout, or null when there has been none.
  final int? daysSince;

  /// The day they were last seen, as midnight UTC, or null.
  final DateTime? lastSeenOn;

  /// Ratio at which a contact stops being fresh and comes due.
  static const dueFrom = 0.75;

  /// Ratio above which a contact is overdue rather than due.
  static const overdueAbove = 1.25;

  /// Whether a hangout has ever been logged for this contact.
  bool get isMeasured => state != FreshnessState.never;

  /// How far round the gauge ring to sweep, from 0 to 1.
  ///
  /// Capped at a full ring: past the cadence the colour carries the message,
  /// and a ring that wrapped twice would read as fresh again.
  double get sweep => (ratio ?? 0).clamp(0.0, 1.0);

  /// How long it has been, written the way a person would say it.
  ///
  /// A method taking [l10n] rather than a getter: which stretch of time this
  /// is stays domain logic, but the wording of each stretch belongs to the
  /// locale.
  String lastSeenLabel(AppLocalizations l10n) => switch (daysSince) {
    null => l10n.seenNever,
    0 => l10n.seenToday,
    1 => l10n.seenYesterday,
    final days when days < 7 => l10n.seenDaysAgo(days),
    // "Seen a week ago" would be the elapsed phrase, but a week and a half is
    // still last week to a person, so this stretch keeps its own wording.
    final days when days < 14 => l10n.seenLastWeek,
    _ => l10n.seenAgo(elapsedLabel(l10n)!),
  };

  /// The bare span since the last hangout — "6 weeks", "3 days" — or null
  /// when there has been none.
  ///
  /// A phrase rather than a sentence, so it can be dropped into copy that
  /// puts it somewhere other than the end: "It's been 6 weeks" as much as
  /// "Seen 6 weeks ago". Coarsens as it lengthens, because nobody wants the
  /// number of days since they last saw someone two years ago.
  String? elapsedLabel(AppLocalizations l10n) => switch (daysSince) {
    null => null,
    0 => l10n.elapsedLessThanADay,
    1 => l10n.elapsedADay,
    final days when days < 7 => l10n.elapsedDays(days),
    final days when days < 14 => l10n.elapsedAWeek,
    final days when days < 60 => l10n.elapsedWeeks((days / 7).round()),
    final days when days < 365 => l10n.elapsedMonths((days / 30).round()),
    final days => l10n.elapsedYears((days / 365).floor()),
  };

  /// Which reading a [ratio] falls in. The boundaries belong to `due` at both
  /// ends, as `docs/PLAN.md` writes them: fresh < 0.75 <= due <= 1.25 <
  /// overdue.
  static FreshnessState _stateFor(double ratio) {
    if (ratio < dueFrom) return FreshnessState.fresh;
    if (ratio <= overdueAbove) return FreshnessState.due;
    return FreshnessState.overdue;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Freshness &&
          other.state == state &&
          other.ratio == ratio &&
          other.daysSince == daysSince &&
          other.lastSeenOn == lastSeenOn;

  @override
  int get hashCode => Object.hash(state, ratio, daysSince, lastSeenOn);

  @override
  String toString() =>
      'Freshness(state: ${state.name}, ratio: $ratio, '
      'daysSince: $daysSince, lastSeenOn: $lastSeenOn)';
}
