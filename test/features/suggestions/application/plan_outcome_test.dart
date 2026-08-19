import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/data/models/planned_hangout_status.dart';
import 'package:kith/features/suggestions/application/plan_outcome.dart';

void main() {
  final plan = PlannedHangout(
    id: 'pid-1',
    plannedFor: DateTime.utc(2026, 8, 25),
    contactIds: const ['cid-1'],
    status: PlannedHangoutStatus.proposed,
    createdBy: 'uid-1',
    createdAt: DateTime.utc(2026, 8, 18),
    updatedAt: DateTime.utc(2026, 8, 18),
  );

  group('PlanOutcome', () {
    test(
      'a plan with no calendar behind it reached none, and failed at none',
      () {
        final outcome = PlanOutcome(plan: plan);

        expect(outcome.isOnCalendar, isFalse);
        expect(outcome.calendarFailure, isNull);
      },
    );

    test('has value semantics', () {
      final outcome = PlanOutcome(plan: plan, isOnCalendar: true);

      expect(outcome, PlanOutcome(plan: plan, isOnCalendar: true));
      expect(
        outcome.hashCode,
        PlanOutcome(plan: plan, isOnCalendar: true).hashCode,
      );
      expect(outcome, isNot(PlanOutcome(plan: plan)));
      expect(
        outcome,
        isNot(
          PlanOutcome(
            plan: plan,
            isOnCalendar: true,
            calendarFailure: const NetworkFailure('offline'),
          ),
        ),
      );
    });

    test('toString names the plan and what became of it', () {
      final outcome = PlanOutcome(
        plan: plan,
        calendarFailure: const NetworkFailure('offline'),
      );

      expect(outcome.toString(), contains('pid-1'));
      expect(outcome.toString(), contains('isOnCalendar: false'));
      expect(outcome.toString(), contains('offline'));
    });
  });
}
