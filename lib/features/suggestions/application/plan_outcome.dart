import 'package:flutter/foundation.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/planned_hangout.dart';

/// What came of acting on a suggestion with "Plan it".
///
/// Two answers rather than one, because the plan and its calendar event can
/// part ways: the plan is Kith's own record and either succeeds or does not,
/// while putting it on the household's calendar depends on a linked calendar
/// and on Google being reachable. A plan that was made but not published is a
/// real outcome, and the card says so rather than claiming either more or
/// less than happened.
@immutable
class PlanOutcome {
  const PlanOutcome({
    required this.plan,
    this.isOnCalendar = false,
    this.calendarFailure,
  });

  /// The plan as it was stored.
  final PlannedHangout plan;

  /// Whether an event for it now sits on the household's calendar.
  final bool isOnCalendar;

  /// Why it did not get there, or null when no calendar is linked and none
  /// was attempted.
  final Failure? calendarFailure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanOutcome &&
          other.plan == plan &&
          other.isOnCalendar == isOnCalendar &&
          other.calendarFailure == calendarFailure;

  @override
  int get hashCode => Object.hash(plan, isOnCalendar, calendarFailure);

  @override
  String toString() =>
      'PlanOutcome(plan: ${plan.id}, isOnCalendar: $isOnCalendar, '
      'calendarFailure: $calendarFailure)';
}
