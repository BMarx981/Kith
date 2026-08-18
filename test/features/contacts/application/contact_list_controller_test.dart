import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/features/contacts/application/contact_list_controller.dart';
import 'package:kith/features/contacts/domain/contact_view.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  ContactView read() => container.read(contactListControllerProvider);
  ContactListController controller() =>
      container.read(contactListControllerProvider.notifier);

  group('ContactListController', () {
    test('starts showing everything, ordered by name', () {
      expect(read(), const ContactView());
      expect(read().sort, ContactSort.name);
      expect(read().isFiltered, isFalse);
    });

    test('records what was searched for', () {
      controller().search('marc');

      expect(read().query, 'marc');
    });

    test('filters to a label and back to all of them', () {
      controller()
        ..filterByType('rid-1')
        ..filterByType(null);

      expect(read().relationshipTypeId, isNull);
    });

    test('reorders the list', () {
      controller().sortBy(ContactSort.cadence);

      expect(read().sort, ContactSort.cadence);
    });

    test('shows and hides archived contacts', () {
      controller().showArchived(show: true);
      expect(read().showArchived, isTrue);

      controller().showArchived(show: false);
      expect(read().showArchived, isFalse);
    });

    test('clearing drops the filters but keeps the ordering', () {
      controller()
        ..search('marc')
        ..filterByType('rid-1')
        ..showArchived(show: true)
        ..sortBy(ContactSort.cadence)
        ..clearFilters();

      expect(read().query, isEmpty);
      expect(read().relationshipTypeId, isNull);
      expect(read().showArchived, isFalse);
      expect(read().sort, ContactSort.cadence);
    });
  });
}
