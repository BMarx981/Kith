import 'package:flutter_test/flutter_test.dart';
import 'package:kith/features/household/domain/household_field_validator.dart';

void main() {
  group('name', () {
    test('accepts a household name', () {
      expect(HouseholdFieldValidator.name('The Marx house'), isNull);
    });

    test('rejects nothing at all', () {
      expect(HouseholdFieldValidator.name(null), isNotNull);
      expect(HouseholdFieldValidator.name(''), isNotNull);
      expect(HouseholdFieldValidator.name('   '), isNotNull);
    });

    test('rejects a name longer than the rules allow', () {
      expect(
        HouseholdFieldValidator.name(
          'x' * HouseholdFieldValidator.maxNameLength,
        ),
        isNull,
      );
      expect(
        HouseholdFieldValidator.name(
          'x' * (HouseholdFieldValidator.maxNameLength + 1),
        ),
        isNotNull,
      );
    });
  });

  group('displayName', () {
    test('accepts a name', () {
      expect(HouseholdFieldValidator.displayName('Brian'), isNull);
    });

    test('rejects nothing at all', () {
      expect(HouseholdFieldValidator.displayName(null), isNotNull);
      expect(HouseholdFieldValidator.displayName('  '), isNotNull);
    });

    test('rejects a name longer than the rules allow', () {
      expect(
        HouseholdFieldValidator.displayName(
          'x' * (HouseholdFieldValidator.maxNameLength + 1),
        ),
        isNotNull,
      );
    });
  });

  group('inviteCode', () {
    test('accepts a well-formed code', () {
      expect(HouseholdFieldValidator.inviteCode('KH7RQ2'), isNull);
    });

    test('accepts a code as it is read aloud, spaced or hyphenated', () {
      expect(HouseholdFieldValidator.inviteCode('kh7-rq2'), isNull);
      expect(HouseholdFieldValidator.inviteCode(' KH7 RQ2 '), isNull);
    });

    test('rejects an empty code', () {
      expect(HouseholdFieldValidator.inviteCode(null), isNotNull);
      expect(HouseholdFieldValidator.inviteCode(''), isNotNull);
    });

    test('rejects a code of the wrong length', () {
      expect(HouseholdFieldValidator.inviteCode('KH7RQ'), isNotNull);
      expect(HouseholdFieldValidator.inviteCode('KH7RQ22'), isNotNull);
    });

    test('names the character that does not belong', () {
      expect(HouseholdFieldValidator.inviteCode(r'KH7RQ$'), contains(r'$'));
    });
  });
}
