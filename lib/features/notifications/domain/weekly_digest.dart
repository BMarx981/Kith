import 'package:flutter/foundation.dart';
import 'package:kith/features/contacts/domain/upcoming_birthday.dart';
import 'package:kith/features/suggestions/engine/suggestion.dart';
import 'package:kith/l10n/gen/app_localizations.dart';

/// What one weekly digest notification says.
///
/// Built from readings the app already has — the ranked suggestions and the
/// birthdays coming up — rather than from a second pass over the data, so the
/// notification cannot disagree with the Reconnect screen it is a summary of.
///
/// Pure: no clock, no I/O, no plurals decided by the platform. What ships to
/// the scheduler is [title] and [body], and both are checkable in a table.
@immutable
class WeeklyDigest {
  const WeeklyDigest({required this.overdue, required this.birthdays});

  /// Who the engine put forward, in its order. Already the top-N.
  final List<Suggestion> overdue;

  /// Whose birthday lands inside the digest's week, soonest first.
  final List<UpcomingBirthday> birthdays;

  /// How far ahead a digest looks for birthdays: the week it covers.
  static const windowDays = 7;

  /// Whether there is nothing worth interrupting anybody for.
  ///
  /// A digest that says "nobody is overdue" is a notification asking for
  /// attention to report that no attention is needed, so the scheduler posts
  /// nothing at all in this case.
  bool get isEmpty => overdue.isEmpty && birthdays.isEmpty;

  /// The notification's first line.
  String title(AppLocalizations l10n) {
    if (overdue.isNotEmpty) return l10n.digestTitleOverdue(overdue.length);
    if (birthdays.isNotEmpty) {
      return l10n.digestTitleBirthdays(birthdays.length);
    }
    return '';
  }

  /// The notification's second line: who, and whose birthday.
  String body(AppLocalizations l10n) {
    final parts = <String>[
      if (overdue.isNotEmpty)
        l10n.digestSentence(
          _joined(l10n, [for (final s in overdue) s.contact.name]),
        ),
      if (birthdays.length == 1)
        birthdays.single.headline(l10n)
      else if (birthdays.length > 1)
        l10n.digestBirthdayList(
          _joined(l10n, [for (final b in birthdays) b.contact.name]),
        ),
    ];
    return parts.join(' ');
  }

  /// [names] written as a list somebody would say out loud: "Marcus",
  /// "Marcus and Ana", "Marcus, Ana and Ben". The joiners come from the ARB
  /// files, because "and" and the list comma are the locale's to choose.
  static String _joined(AppLocalizations l10n, List<String> names) =>
      switch (names.length) {
        0 => '',
        1 => names.single,
        2 => l10n.nameListPair(names[0], names[1]),
        _ => l10n.nameListPair(
          names.sublist(0, names.length - 1).join(l10n.nameListSeparator),
          names.last,
        ),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyDigest &&
          listEquals(other.overdue, overdue) &&
          listEquals(other.birthdays, birthdays);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(overdue), Object.hashAll(birthdays));

  @override
  String toString() =>
      'WeeklyDigest(overdue: ${overdue.length}, '
      'birthdays: ${birthdays.length})';
}
