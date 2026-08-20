import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/l10n/gen/app_localizations_en.dart';
import 'package:kith/l10n/gen/app_localizations_es.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('Cadence', () {
    test('presets carry the day counts the plan names', () {
      expect(Cadence.weekly.days, 7);
      expect(Cadence.biweekly.days, 14);
      expect(Cadence.monthly.days, 30);
      expect(Cadence.quarterly.days, 91);
      expect(Cadence.twiceAYear.days, 182);
    });

    test('presets are listed in ascending order and are distinct', () {
      final days = Cadence.presets.map((c) => c.days).toList();

      expect(days, hasLength(Cadence.presets.toSet().length));
      expect(days, orderedEquals(List.of(days)..sort()));
    });

    test('fromDays round-trips any in-range day count', () {
      for (final days in [Cadence.minDays, 7, 45, Cadence.maxDays]) {
        expect(Cadence.fromDays(days).days, days);
      }
    });

    test('fromDays clamps a stored value that is out of range', () {
      expect(Cadence.fromDays(0).days, Cadence.minDays);
      expect(Cadence.fromDays(-30).days, Cadence.minDays);
      expect(Cadence.fromDays(Cadence.maxDays + 1).days, Cadence.maxDays);
    });

    test('parse accepts a whole number of days, padded or not', () {
      expect(Cadence.parse('21'), const Ok(Cadence.custom(21)));
      expect(Cadence.parse('  21  '), const Ok(Cadence.custom(21)));
    });

    test('parse rejects an empty field', () {
      expect(Cadence.parse('  ').failureOrNull, isA<ValidationFailure>());
    });

    test('parse rejects anything that is not a whole number', () {
      for (final input in ['abc', '3.5', '2 weeks', '']) {
        expect(
          Cadence.parse(input).failureOrNull,
          isA<ValidationFailure>(),
          reason: '"$input" is not a day count',
        );
      }
    });

    test('parse rejects a day count outside the supported range', () {
      expect(Cadence.parse('0').failureOrNull, isA<ValidationFailure>());
      expect(
        Cadence.parse('${Cadence.maxDays + 1}').failureOrNull,
        isA<ValidationFailure>(),
      );
    });

    test('labels each preset by the interval people say out loud', () {
      expect(Cadence.weekly.label(l10n), 'Weekly');
      expect(Cadence.biweekly.label(l10n), 'Every 2 weeks');
      expect(Cadence.monthly.label(l10n), 'Monthly');
      expect(Cadence.quarterly.label(l10n), 'Every 3 months');
      expect(Cadence.twiceAYear.label(l10n), 'Twice a year');
    });

    test('phrases each interval to sit mid-sentence', () {
      expect(Cadence.weekly.phrase(l10n), 'weekly');
      expect(Cadence.biweekly.phrase(l10n), 'every 2 weeks');
      expect(Cadence.monthly.phrase(l10n), 'monthly');
      expect(Cadence.quarterly.phrase(l10n), 'every 3 months');
      expect(Cadence.twiceAYear.phrase(l10n), 'twice a year');
      expect(const Cadence.custom(45).phrase(l10n), 'every 45 days');
      expect(const Cadence.custom(1).phrase(l10n), 'daily');
    });

    test('speaks the locale it is handed', () {
      expect(Cadence.monthly.label(AppLocalizationsEs()), 'Mensual');
      expect(Cadence.monthly.phrase(AppLocalizationsEs()), 'cada mes');
    });

    test('labels a custom interval by its day count', () {
      expect(const Cadence.custom(45).label(l10n), 'Every 45 days');
      expect(const Cadence.custom(1).label(l10n), 'Daily');
    });

    test('knows whether it is one of the presets', () {
      expect(Cadence.monthly.isPreset, isTrue);
      expect(Cadence.fromDays(30).isPreset, isTrue);
      expect(const Cadence.custom(45).isPreset, isFalse);
    });

    test('has value semantics', () {
      expect(Cadence.fromDays(30), Cadence.monthly);
      expect(Cadence.fromDays(30).hashCode, Cadence.monthly.hashCode);
      expect(const Cadence.custom(31), isNot(Cadence.monthly));
    });

    test('toString names the day count', () {
      expect(Cadence.monthly.toString(), contains('30'));
    });
  });
}
