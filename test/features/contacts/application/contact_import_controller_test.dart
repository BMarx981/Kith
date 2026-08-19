import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/services/device_contact_directory.dart';
import 'package:kith/features/contacts/application/contact_import_controller.dart';
import 'package:kith/features/contacts/application/contact_import_state.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/birthday.dart';
import 'package:kith/features/contacts/domain/cadence.dart';

import '../../../helpers/fake_contact_repository.dart';
import '../../../helpers/fake_device_contact_directory.dart';

void main() {
  const householdId = 'hid-1';

  late FakeContactRepository contacts;
  late FakeDeviceContactDirectory directory;

  setUp(() {
    contacts = FakeContactRepository();
    addTearDown(contacts.dispose);
    directory = FakeDeviceContactDirectory();
  });

  List<Override> overrides() => [
    contactRepositoryProvider.overrideWithValue(contacts),
    deviceContactDirectoryProvider.overrideWithValue(directory),
  ];

  /// A container whose contacts have arrived, the way the screen's own build
  /// waits for before the import can know who is already here.
  Future<ProviderContainer> settled() async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    container.listen(contactsProvider(householdId), (_, _) {});
    await container.read(contactsProvider(householdId).future);
    return container;
  }

  void seedDevice(
    String id,
    String name, {
    String? phone,
    Birthday? birthday,
  }) => directory.seed(
    DeviceContact(id: id, name: name, phone: phone, birthday: birthday),
  );

  void seedExisting(String name, {String? phone}) => contacts.seed(
    Contact(
      id: 'cid-$name',
      name: name,
      relationshipTypeId: 'rid-1',
      cadence: Cadence.monthly,
      priority: ContactPriority.normal,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      phone: phone,
    ),
  );

  ContactImportController notifierOf(ProviderContainer container) =>
      container.read(contactImportControllerProvider.notifier);

  group('load', () {
    test('asks for permission, reads, and marks who is already here', () async {
      seedDevice('row-1', 'Marcus Bell');
      seedDevice('row-2', 'Ana Reyes');
      seedExisting('Marcus Bell');
      final container = await settled();

      await notifierOf(container).load(householdId);

      final state = container.read(contactImportControllerProvider);
      expect(directory.permissionAsks, 1);
      expect(directory.reads, 1);
      expect(state.step, ContactImportStep.ready);
      expect(state.candidates.map((c) => c.person.name), [
        'Ana Reyes',
        'Marcus Bell',
      ]);
      expect(state.candidates.map((c) => c.isAlreadyHere), [false, true]);
      expect(state.importable.map((c) => c.person.name), ['Ana Reyes']);
    });

    test('starts with nobody ticked', () async {
      seedDevice('row-1', 'Marcus Bell');
      final container = await settled();

      await notifierOf(container).load(householdId);

      expect(container.read(contactImportControllerProvider).selected, isEmpty);
    });

    test('reads nothing when the prompt is declined', () async {
      seedDevice('row-1', 'Marcus Bell');
      directory.permissionGranted = false;
      final container = await settled();

      await notifierOf(container).load(householdId);

      expect(directory.reads, 0);
      expect(
        container.read(contactImportControllerProvider).step,
        ContactImportStep.permissionDenied,
      );
    });

    test('reports a read that failed', () async {
      final container = await settled();
      directory.nextFailure = const PermissionFailure('revoked');

      await notifierOf(container).load(householdId);

      final state = container.read(contactImportControllerProvider);
      expect(state.failure, const PermissionFailure('revoked'));
      expect(state.step, ContactImportStep.idle);
    });
  });

  group('toggle', () {
    test('ticks and unticks somebody importable', () async {
      seedDevice('row-1', 'Marcus Bell');
      final container = await settled();
      await notifierOf(container).load(householdId);

      notifierOf(container).toggle('row-1');
      expect(
        container.read(contactImportControllerProvider).selected,
        {'row-1'},
      );

      notifierOf(container).toggle('row-1');
      expect(container.read(contactImportControllerProvider).selected, isEmpty);
    });

    test('cannot tick somebody already here', () async {
      seedDevice('row-1', 'Marcus Bell');
      seedExisting('Marcus Bell');
      final container = await settled();
      await notifierOf(container).load(householdId);

      notifierOf(container).toggle('row-1');

      expect(container.read(contactImportControllerProvider).selected, isEmpty);
    });

    test('ignores an id the address book never offered', () async {
      seedDevice('row-1', 'Marcus Bell');
      final container = await settled();
      await notifierOf(container).load(householdId);

      notifierOf(container).toggle('row-nowhere');

      expect(container.read(contactImportControllerProvider).selected, isEmpty);
    });

    test('does nothing before the list has been read', () async {
      final container = await settled();

      notifierOf(container).toggle('row-1');

      expect(container.read(contactImportControllerProvider).selected, isEmpty);
    });
  });

  group('toggleAll', () {
    test('ticks everybody importable, then clears them', () async {
      seedDevice('row-1', 'Marcus Bell');
      seedDevice('row-2', 'Ana Reyes');
      seedDevice('row-3', 'Priya Raman');
      seedExisting('Priya Raman');
      final container = await settled();
      await notifierOf(container).load(householdId);

      notifierOf(container).toggleAll();
      final state = container.read(contactImportControllerProvider);
      expect(state.selected, {'row-1', 'row-2'});
      expect(state.isEverySelected, isTrue);

      notifierOf(container).toggleAll();
      expect(container.read(contactImportControllerProvider).selected, isEmpty);
    });

    test('is not "everything" when there is nothing importable', () async {
      seedDevice('row-1', 'Marcus Bell');
      seedExisting('Marcus Bell');
      final container = await settled();
      await notifierOf(container).load(householdId);

      expect(
        container.read(contactImportControllerProvider).isEverySelected,
        isFalse,
      );
    });
  });

  group('import', () {
    test('writes each ticked person as a contact', () async {
      seedDevice(
        'row-1',
        'Marcus Bell',
        phone: '555-0100',
        birthday: const Birthday(month: 3, day: 14, year: 1988),
      );
      seedDevice('row-2', 'Ana Reyes');
      final container = await settled();
      await notifierOf(container).load(householdId);
      notifierOf(container).toggleAll();

      await notifierOf(container).import(
        householdId: householdId,
        relationshipTypeId: 'rid-friend',
        cadence: Cadence.weekly,
      );

      expect(contacts.createCalls, hasLength(2));
      final marcus = contacts.createCalls.firstWhere(
        (call) => call.draft.name == 'Marcus Bell',
      );
      expect(marcus.householdId, householdId);
      expect(marcus.draft.phone, '555-0100');
      expect(
        marcus.draft.birthday,
        const Birthday(month: 3, day: 14, year: 1988),
      );
      expect(marcus.draft.relationshipTypeId, 'rid-friend');
      expect(marcus.draft.cadence, Cadence.weekly);

      final state = container.read(contactImportControllerProvider);
      expect(state.step, ContactImportStep.done);
      expect(state.importedCount, 2);
    });

    test('writes only the ticked ones', () async {
      seedDevice('row-1', 'Marcus Bell');
      seedDevice('row-2', 'Ana Reyes');
      final container = await settled();
      await notifierOf(container).load(householdId);
      notifierOf(container).toggle('row-2');

      await notifierOf(container).import(
        householdId: householdId,
        relationshipTypeId: 'rid-friend',
        cadence: Cadence.monthly,
      );

      expect(contacts.createCalls.single.draft.name, 'Ana Reyes');
    });

    test('does nothing with nobody ticked', () async {
      seedDevice('row-1', 'Marcus Bell');
      final container = await settled();
      await notifierOf(container).load(householdId);

      await notifierOf(container).import(
        householdId: householdId,
        relationshipTypeId: 'rid-friend',
        cadence: Cadence.monthly,
      );

      expect(contacts.createCalls, isEmpty);
      expect(
        container.read(contactImportControllerProvider).step,
        ContactImportStep.ready,
      );
    });

    test('reports how many landed when one write is refused', () async {
      seedDevice('row-1', 'Ana Reyes');
      seedDevice('row-2', 'Marcus Bell');
      final container = await settled();
      await notifierOf(container).load(householdId);
      notifierOf(container).toggleAll();
      // Ana sorts first, so the second write is the one that is refused.
      contacts.createFailureAfter = 1;

      await notifierOf(container).import(
        householdId: householdId,
        relationshipTypeId: 'rid-friend',
        cadence: Cadence.monthly,
      );

      final state = container.read(contactImportControllerProvider);
      expect(state.importedCount, 1);
      expect(state.failure, isA<Failure>());
      // Back on the list rather than done, so the household can retry the
      // rest without re-importing the one that landed.
      expect(state.step, ContactImportStep.ready);
    });
  });
}
