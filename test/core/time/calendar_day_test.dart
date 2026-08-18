import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/time/calendar_day.dart';

void main() {
  group('of', () {
    test('reduces a UTC instant to midnight on its own date', () {
      expect(
        CalendarDay.of(DateTime.utc(2026, 8, 18, 23, 59, 59, 999)),
        DateTime.utc(2026, 8, 18),
      );
    });

    test('reads the local date off a local instant', () {
      final local = DateTime(2026, 8, 18, 21, 30);

      expect(CalendarDay.of(local), DateTime.utc(2026, 8, 18));
    });

    test('is idempotent, so a stored day survives being read back', () {
      final day = CalendarDay.of(DateTime.utc(2026, 8, 18, 6));

      expect(CalendarDay.of(day), day);
    });

    test('always returns a UTC value', () {
      expect(CalendarDay.of(DateTime(2026, 8, 18, 9)).isUtc, isTrue);
    });
  });

  group('between', () {
    test('counts whole days forward', () {
      expect(
        CalendarDay.between(
          DateTime.utc(2026, 8),
          DateTime.utc(2026, 8, 18),
        ),
        17,
      );
    });

    test('is negative when the second day is the earlier one', () {
      expect(
        CalendarDay.between(
          DateTime.utc(2026, 8, 18),
          DateTime.utc(2026, 8),
        ),
        -17,
      );
    });

    test('is zero within one day, whatever the times of day', () {
      expect(
        CalendarDay.between(
          DateTime.utc(2026, 8, 18, 0, 1),
          DateTime.utc(2026, 8, 18, 23, 59),
        ),
        0,
      );
    });

    test('counts date squares rather than 24-hour blocks', () {
      // 23:59 to 00:01 is two minutes, and one day.
      expect(
        CalendarDay.between(
          DateTime.utc(2026, 8, 18, 23, 59),
          DateTime.utc(2026, 8, 19, 0, 1),
        ),
        1,
      );
    });

    test('crosses a month and a leap day', () {
      expect(
        CalendarDay.between(DateTime.utc(2028, 2, 28), DateTime.utc(2028, 3)),
        2,
      );
    });
  });

  group('isSameDay', () {
    test('is true for two instants on one date', () {
      expect(
        CalendarDay.isSameDay(
          DateTime.utc(2026, 8, 18, 1),
          DateTime.utc(2026, 8, 18, 22),
        ),
        isTrue,
      );
    });

    test('is false across midnight', () {
      expect(
        CalendarDay.isSameDay(
          DateTime.utc(2026, 8, 18, 23),
          DateTime.utc(2026, 8, 19),
        ),
        isFalse,
      );
    });
  });
}
