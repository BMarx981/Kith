import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/l10n/gen/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('ContactPriority', () {
    test('wire names are stable and distinct', () {
      expect(ContactPriority.low.wireName, 'low');
      expect(ContactPriority.normal.wireName, 'normal');
      expect(ContactPriority.high.wireName, 'high');
      expect(
        ContactPriority.values.map((p) => p.wireName).toSet(),
        hasLength(ContactPriority.values.length),
      );
    });

    test('round-trips through its wire name', () {
      for (final priority in ContactPriority.values) {
        expect(ContactPriority.fromWireName(priority.wireName), priority);
      }
    });

    test('falls back to normal for unknown or missing values', () {
      expect(ContactPriority.fromWireName('urgent'), ContactPriority.normal);
      expect(ContactPriority.fromWireName(''), ContactPriority.normal);
      expect(ContactPriority.fromWireName(null), ContactPriority.normal);
    });

    test('carries the suggestion weights the plan names', () {
      expect(ContactPriority.low.weight, 0.5);
      expect(ContactPriority.normal.weight, 1.0);
      expect(ContactPriority.high.weight, 1.5);
    });

    test('is ordered least to most important', () {
      expect(
        ContactPriority.values.map((p) => p.weight).toList(),
        orderedEquals(<double>[0.5, 1, 1.5]),
      );
    });

    test('labels each level for the editor', () {
      expect(ContactPriority.low.label(l10n), 'Low');
      expect(ContactPriority.normal.label(l10n), 'Normal');
      expect(ContactPriority.high.label(l10n), 'High');
    });
  });
}
