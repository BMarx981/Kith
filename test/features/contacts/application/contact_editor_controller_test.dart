import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/contacts/application/contact_editor_controller.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/application/save_state.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/contacts/domain/contact_draft.dart';

import '../../../helpers/fake_contact_repository.dart';

void main() {
  const householdId = 'hid-1';
  const draft = ContactDraft(
    name: 'Marcus',
    relationshipTypeId: 'rid-1',
    cadence: Cadence.monthly,
  );

  late FakeContactRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeContactRepository();
    addTearDown(repository.dispose);
    container = ProviderContainer(
      overrides: [contactRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  SaveState read() => container.read(contactEditorControllerProvider);
  ContactEditorController controller() =>
      container.read(contactEditorControllerProvider.notifier);

  group('ContactEditorController', () {
    test('starts idle', () {
      expect(read(), const SaveState());
    });

    test('creates a contact when there is no id to edit', () async {
      final saved = await controller().save(
        householdId: householdId,
        draft: draft,
      );

      expect(saved, isTrue);
      expect(repository.createCalls.single.draft, draft);
      expect(repository.updateCalls, isEmpty);
      expect(read(), const SaveState());
    });

    test('updates the contact it was given an id for', () async {
      final saved = await controller().save(
        householdId: householdId,
        contactId: 'cid-1',
        draft: draft,
      );

      expect(saved, isFalse, reason: 'no such contact to update');
      expect(repository.updateCalls.single.contactId, 'cid-1');
      expect(repository.createCalls, isEmpty);
    });

    test('reports the failure a refused save came back with', () async {
      repository.nextFailure = const NetworkFailure('offline');

      final saved = await controller().save(
        householdId: householdId,
        draft: draft,
      );

      expect(saved, isFalse);
      expect(read().isSubmitting, isFalse);
      expect(read().failure, isA<NetworkFailure>());
    });

    test('drops the previous failure when trying again', () async {
      repository.nextFailure = const NetworkFailure('offline');
      await controller().save(householdId: householdId, draft: draft);

      await controller().save(householdId: householdId, draft: draft);

      expect(read().failure, isNull);
    });

    test('holds the form inert while a save is in flight', () async {
      repository.gate = Completer<void>();

      final first = controller().save(householdId: householdId, draft: draft);
      await Future<void>.delayed(Duration.zero);
      expect(read().isSubmitting, isTrue);

      final second = await controller().save(
        householdId: householdId,
        draft: draft,
      );
      expect(second, isFalse, reason: 'a second tap is ignored');

      repository.gate!.complete();
      await first;
      expect(repository.createCalls, hasLength(1));
      expect(read().isSubmitting, isFalse);
    });

    test('archives a contact', () async {
      await controller().save(householdId: householdId, draft: draft);

      final done = await controller().setArchived(
        householdId: householdId,
        contactId: 'cid-1',
        isArchived: true,
      );

      expect(done, isTrue);
      expect(repository.contacts['cid-1']!.isArchived, isTrue);
    });

    test('reports a refused archive', () async {
      repository.nextFailure = const PermissionFailure('nope');

      final done = await controller().setArchived(
        householdId: householdId,
        contactId: 'cid-1',
        isArchived: true,
      );

      expect(done, isFalse);
      expect(read().failure, isA<PermissionFailure>());
    });
  });
}
