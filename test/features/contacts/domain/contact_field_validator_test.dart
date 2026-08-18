import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/features/contacts/domain/contact_field_validator.dart';

void main() {
  group('ContactFieldValidator.name', () {
    test('accepts a name', () {
      expect(ContactFieldValidator.name('Marcus'), isNull);
    });

    test('refuses blank and missing', () {
      expect(ContactFieldValidator.name(''), isNotNull);
      expect(ContactFieldValidator.name('   '), isNotNull);
      expect(ContactFieldValidator.name(null), isNotNull);
    });

    test('refuses a name past what the rules store', () {
      expect(
        ContactFieldValidator.name('a' * Contact.maxNameLength),
        isNull,
      );
      expect(
        ContactFieldValidator.name('a' * (Contact.maxNameLength + 1)),
        isNotNull,
      );
    });
  });

  group('ContactFieldValidator.labelName', () {
    test('accepts a label and refuses a blank one', () {
      expect(ContactFieldValidator.labelName('Friend'), isNull);
      expect(ContactFieldValidator.labelName('  '), isNotNull);
    });

    test('refuses a label past what the rules store', () {
      expect(
        ContactFieldValidator.labelName(
          'a' * (RelationshipType.maxNameLength + 1),
        ),
        isNotNull,
      );
    });
  });

  group('ContactFieldValidator.detail', () {
    test('allows a blank optional field', () {
      expect(ContactFieldValidator.detail(''), isNull);
      expect(ContactFieldValidator.detail(null), isNull);
    });

    test('refuses an oversized detail', () {
      expect(
        ContactFieldValidator.detail('a' * (Contact.maxDetailLength + 1)),
        isNotNull,
      );
    });
  });

  group('ContactFieldValidator.notes', () {
    test('allows blank and refuses an oversized note', () {
      expect(ContactFieldValidator.notes(null), isNull);
      expect(
        ContactFieldValidator.notes('a' * (Contact.maxNotesLength + 1)),
        isNotNull,
      );
    });
  });

  group('ContactFieldValidator.customCadence', () {
    test('accepts a whole number of days', () {
      expect(ContactFieldValidator.customCadence('45'), isNull);
    });

    test('refuses anything that is not one', () {
      expect(ContactFieldValidator.customCadence(''), isNotNull);
      expect(ContactFieldValidator.customCadence('soon'), isNotNull);
      expect(ContactFieldValidator.customCadence('0'), isNotNull);
      expect(ContactFieldValidator.customCadence(null), isNotNull);
    });
  });

  group('ContactFieldValidator tags', () {
    test('splits on commas, dropping the empties', () {
      expect(
        ContactFieldValidator.parseTags(' soccer , , school,'),
        orderedEquals(<String>['soccer', 'school']),
      );
    });

    test('an empty field parses to no tags', () {
      expect(ContactFieldValidator.parseTags('   '), isEmpty);
    });

    test('renders tags back into the field', () {
      expect(
        ContactFieldValidator.formatTags(const ['soccer', 'school']),
        'soccer, school',
      );
      expect(ContactFieldValidator.formatTags(const []), '');
    });

    test('accepts a reasonable tag list', () {
      expect(ContactFieldValidator.tags('soccer, school'), isNull);
      expect(ContactFieldValidator.tags(null), isNull);
    });

    test('refuses too many tags, and one that is too long', () {
      final many = List.generate(Contact.maxTags + 1, (i) => 'tag$i').join(',');

      expect(ContactFieldValidator.tags(many), isNotNull);
      expect(
        ContactFieldValidator.tags('a' * (Contact.maxTagLength + 1)),
        isNotNull,
      );
    });
  });
}
