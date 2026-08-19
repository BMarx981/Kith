import 'package:flutter/foundation.dart';
import 'package:kith/features/contacts/domain/upcoming_birthday.dart';
import 'package:kith/features/suggestions/engine/suggestion.dart';

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
  String get title {
    if (overdue.isNotEmpty) {
      return overdue.length == 1
          ? '1 person is overdue'
          : '${overdue.length} people are overdue';
    }
    if (birthdays.isNotEmpty) {
      return birthdays.length == 1
          ? '1 birthday this week'
          : '${birthdays.length} birthdays this week';
    }
    return '';
  }

  /// The notification's second line: who, and whose birthday.
  String get body {
    final parts = <String>[
      if (overdue.isNotEmpty)
        '${_joined([for (final s in overdue) s.contact.name])}.',
      if (birthdays.length == 1)
        birthdays.single.headline
      else if (birthdays.length > 1)
        _birthdayList,
    ];
    return parts.join(' ');
  }

  /// The several-birthdays line, kept out of [body]'s literal list so the two
  /// halves of the sentence are not read as an accidental adjacent-string
  /// concatenation.
  String get _birthdayList =>
      'Birthdays this week: '
      '${_joined([for (final b in birthdays) b.contact.name])}.';

  /// [names] written as a list somebody would say out loud: "Marcus",
  /// "Marcus and Ana", "Marcus, Ana and Ben".
  static String _joined(List<String> names) => switch (names.length) {
    0 => '',
    1 => names.single,
    2 => '${names[0]} and ${names[1]}',
    _ =>
      '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}',
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
