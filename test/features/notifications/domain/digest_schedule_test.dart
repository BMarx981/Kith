import 'package:flutter_test/flutter_test.dart';
import 'package:kith/features/notifications/domain/digest_schedule.dart';

void main() {
  group('DigestSchedule.next', () {
    // 2026-08-18 is a Tuesday.
    final tuesdayMorning = DateTime(2026, 8, 18, 7, 30);

    test('is later today when the day matches and the hour is ahead', () {
      expect(
        DigestSchedule.next(
          weekday: DateTime.tuesday,
          hour: 9,
          from: tuesdayMorning,
        ),
        DateTime(2026, 8, 18, 9),
      );
    });

    test('rolls a week on when the hour has gone by', () {
      expect(
        DigestSchedule.next(
          weekday: DateTime.tuesday,
          hour: 9,
          from: DateTime(2026, 8, 18, 9, 1),
        ),
        DateTime(2026, 8, 25, 9),
      );
    });

    test('rolls a week on when the hour is exactly now', () {
      expect(
        DigestSchedule.next(
          weekday: DateTime.tuesday,
          hour: 9,
          from: DateTime(2026, 8, 18, 9),
        ),
        DateTime(2026, 8, 25, 9),
      );
    });

    test('finds the next matching weekday ahead', () {
      expect(
        DigestSchedule.next(
          weekday: DateTime.friday,
          hour: 18,
          from: tuesdayMorning,
        ),
        DateTime(2026, 8, 21, 18),
      );
    });

    test('wraps into next week for a weekday already behind', () {
      expect(
        DigestSchedule.next(
          weekday: DateTime.monday,
          hour: 9,
          from: tuesdayMorning,
        ),
        DateTime(2026, 8, 24, 9),
      );
    });

    test('crosses a month boundary', () {
      expect(
        DigestSchedule.next(
          weekday: DateTime.tuesday,
          hour: 9,
          from: DateTime(2026, 8, 30, 12),
        ),
        DateTime(2026, 9, 1, 9),
      );
    });

    test('lands on the hour, on the minute', () {
      final next = DigestSchedule.next(
        weekday: DateTime.sunday,
        hour: 20,
        from: tuesdayMorning,
      );
      expect(next.hour, 20);
      expect(next.minute, 0);
      expect(next.second, 0);
      expect(next.weekday, DateTime.sunday);
    });

    test('is always strictly ahead of now, for every day and hour', () {
      for (var weekday = 1; weekday <= 7; weekday++) {
        for (var hour = 0; hour < 24; hour++) {
          final next = DigestSchedule.next(
            weekday: weekday,
            hour: hour,
            from: tuesdayMorning,
          );
          expect(next.isAfter(tuesdayMorning), isTrue);
          expect(next.weekday, weekday);
          expect(next.hour, hour);
          expect(
            next.difference(tuesdayMorning).inDays,
            lessThan(8),
            reason: 'never more than a week out',
          );
        }
      }
    });
  });

  group('DigestSchedule.dayLabel', () {
    test('names every weekday', () {
      expect(DigestSchedule.dayLabel(DateTime.monday), 'Monday');
      expect(DigestSchedule.dayLabel(DateTime.sunday), 'Sunday');
    });
  });

  group('DigestSchedule.hourLabel', () {
    test('writes the hour as a 12-hour clock', () {
      expect(DigestSchedule.hourLabel(0), '12am');
      expect(DigestSchedule.hourLabel(9), '9am');
      expect(DigestSchedule.hourLabel(12), '12pm');
      expect(DigestSchedule.hourLabel(13), '1pm');
      expect(DigestSchedule.hourLabel(23), '11pm');
    });
  });
}
