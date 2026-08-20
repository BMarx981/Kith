import 'package:flutter_test/flutter_test.dart';
import 'package:kith/features/hangouts/domain/day_label.dart';
import 'package:kith/l10n/gen/app_localizations_en.dart';
import 'package:kith/l10n/gen/app_localizations_fr.dart';

void main() {
  final today = DateTime.utc(2026, 8, 18);
  final l10n = AppLocalizationsEn();

  group('of', () {
    test('names the near days rather than dating them', () {
      expect(
        DayLabel.of(DateTime.utc(2026, 8, 18), today: today, l10n: l10n),
        'Today',
      );
      expect(
        DayLabel.of(DateTime.utc(2026, 8, 17), today: today, l10n: l10n),
        'Yesterday',
      );
      expect(
        DayLabel.of(DateTime.utc(2026, 8, 19), today: today, l10n: l10n),
        'Tomorrow',
      );
    });

    test('drops the year while the day is in it', () {
      expect(
        DayLabel.of(DateTime.utc(2026, 8, 11), today: today, l10n: l10n),
        'Tue 11 Aug',
      );
    });

    test('shows the year once the day is outside it', () {
      expect(
        DayLabel.of(DateTime.utc(2025, 12, 25), today: today, l10n: l10n),
        'Thu 25 Dec 2025',
      );
    });

    test('ignores the time of day on either side', () {
      expect(
        DayLabel.of(
          DateTime.utc(2026, 8, 18, 23),
          today: DateTime.utc(2026, 8, 18, 1),
          l10n: l10n,
        ),
        'Today',
      );
    });

    test('speaks the locale it is handed', () {
      expect(
        DayLabel.of(
          DateTime.utc(2026, 8, 11),
          today: today,
          l10n: AppLocalizationsFr(),
        ),
        'mar 11 août',
      );
    });
  });

  group('full', () {
    test('writes the weekday, day, month and year', () {
      expect(
        DayLabel.full(DateTime.utc(2026, 1, 5), l10n: l10n),
        'Mon 5 Jan 2026',
      );
    });

    test('leaves the year off when asked', () {
      expect(
        DayLabel.full(DateTime.utc(2026, 1, 5), l10n: l10n, withYear: false),
        'Mon 5 Jan',
      );
    });
  });

  group('names', () {
    test('numbers the weekdays from Monday', () {
      expect(
        [for (var i = 1; i <= 7; i++) DayLabel.weekday(i, l10n)],
        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      );
    });

    test('numbers the months from January', () {
      expect(
        [for (var i = 1; i <= 12; i++) DayLabel.month(i, l10n)],
        [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ],
      );
    });

    test('matches what DateTime reports for a known date', () {
      // 18 August 2026 is a Tuesday; the table is only useful if it agrees.
      final date = DateTime.utc(2026, 8, 18);

      expect(DayLabel.weekday(date.weekday, l10n), 'Tue');
      expect(DayLabel.month(date.month, l10n), 'Aug');
    });
  });
}
