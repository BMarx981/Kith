import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/planned_hangout_status.dart';

void main() {
  group('PlannedHangoutStatus', () {
    test('wire names are stable and distinct', () {
      expect(PlannedHangoutStatus.proposed.wireName, 'proposed');
      expect(PlannedHangoutStatus.confirmed.wireName, 'confirmed');
      expect(PlannedHangoutStatus.snoozed.wireName, 'snoozed');
      expect(
        PlannedHangoutStatus.values.map((s) => s.wireName).toSet(),
        hasLength(PlannedHangoutStatus.values.length),
      );
    });

    test('round-trips through its wire name', () {
      for (final status in PlannedHangoutStatus.values) {
        expect(PlannedHangoutStatus.fromWireName(status.wireName), status);
      }
    });

    test('falls back to proposed for unknown or missing values', () {
      expect(
        PlannedHangoutStatus.fromWireName('kept'),
        PlannedHangoutStatus.proposed,
      );
      expect(
        PlannedHangoutStatus.fromWireName(''),
        PlannedHangoutStatus.proposed,
      );
      expect(
        PlannedHangoutStatus.fromWireName(null),
        PlannedHangoutStatus.proposed,
      );
    });

    test('counts the two arranged states as arranged, and a snooze as not', () {
      expect(PlannedHangoutStatus.proposed.isArranged, isTrue);
      expect(PlannedHangoutStatus.confirmed.isArranged, isTrue);
      expect(PlannedHangoutStatus.snoozed.isArranged, isFalse);
    });
  });
}
