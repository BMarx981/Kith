import 'package:flutter_test/flutter_test.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/suggestions/domain/snooze_horizon.dart';

void main() {
  group('SnoozeHorizon', () {
    // A Tuesday, mid-afternoon, so the day maths has a time to discard.
    final now = DateTime.utc(2026, 8, 18, 15, 42);

    test('a week is a week out, whatever the cadence', () {
      for (final cadence in Cadence.presets) {
        expect(
          SnoozeHorizon.week.from(now, cadence: cadence),
          DateTime.utc(2026, 8, 25),
        );
      }
    });

    test('a dismissal is one whole cadence out', () {
      expect(
        SnoozeHorizon.fullCadence.from(now, cadence: Cadence.weekly),
        DateTime.utc(2026, 8, 25),
      );
      expect(
        SnoozeHorizon.fullCadence.from(now, cadence: Cadence.monthly),
        DateTime.utc(2026, 9, 17),
      );
      expect(
        SnoozeHorizon.fullCadence.from(now, cadence: Cadence.twiceAYear),
        DateTime.utc(2027, 2, 16),
      );
    });

    test('lands on midnight UTC whatever zone the caller is in', () {
      final local = DateTime(2026, 8, 18, 23, 30);

      expect(
        SnoozeHorizon.week.from(local, cadence: Cadence.monthly),
        DateTime.utc(2026, 8, 25),
      );
    });

    test('labels each choice for the card', () {
      expect(SnoozeHorizon.week.label, 'Snooze');
      expect(SnoozeHorizon.fullCadence.label, 'Dismiss');
    });
  });
}
