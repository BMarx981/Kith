import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/services/device_contact_directory.dart';
import 'package:kith/features/contacts/application/contact_import_state.dart';
import 'package:kith/features/contacts/domain/contact_import.dart';

ImportCandidate _candidate(String id, {bool isAlreadyHere = false}) =>
    ImportCandidate(
      person: DeviceContact(id: id, name: 'Person $id'),
      isAlreadyHere: isAlreadyHere,
    );

void main() {
  group('ContactImportState', () {
    test('starts idle, with nothing read and nothing chosen', () {
      const state = ContactImportState();

      expect(state.step, ContactImportStep.idle);
      expect(state.candidates, isEmpty);
      expect(state.selected, isEmpty);
      expect(state.importedCount, 0);
      expect(state.failure, isNull);
      expect(state.isBusy, isFalse);
    });

    test('is busy only while reading or importing', () {
      for (final step in ContactImportStep.values) {
        expect(
          ContactImportState(step: step).isBusy,
          step == ContactImportStep.reading ||
              step == ContactImportStep.importing,
          reason: step.name,
        );
      }
    });

    test('importable leaves out the ones already here', () {
      final state = ContactImportState(
        candidates: [
          _candidate('a'),
          _candidate('b', isAlreadyHere: true),
          _candidate('c'),
        ],
      );

      expect(state.importable.map((c) => c.person.id), ['a', 'c']);
    });

    test('isEverySelected counts against the importable ones only', () {
      final candidates = [
        _candidate('a'),
        _candidate('b', isAlreadyHere: true),
      ];

      expect(
        ContactImportState(
          candidates: candidates,
          selected: const {'a'},
        ).isEverySelected,
        isTrue,
      );
      expect(
        ContactImportState(candidates: candidates).isEverySelected,
        isFalse,
      );
    });

    test('isEverySelected is false when there is nothing importable', () {
      expect(
        ContactImportState(
          candidates: [_candidate('a', isAlreadyHere: true)],
        ).isEverySelected,
        isFalse,
      );
    });

    test('copyWith replaces each field, and with nothing is an identity', () {
      final state = ContactImportState(
        step: ContactImportStep.ready,
        candidates: [_candidate('a')],
        selected: const {'a'},
        importedCount: 2,
        failure: const NetworkFailure('offline'),
      );

      expect(state.copyWith(), state);
      expect(state.copyWith(step: ContactImportStep.done).step,
          ContactImportStep.done);
      expect(state.copyWith(selected: const {}).selected, isEmpty);
      expect(state.copyWith(importedCount: 5).importedCount, 5);
      expect(state.copyWith(clearFailure: true).failure, isNull);
    });

    test('has value semantics, sets compared by content', () {
      final a = ContactImportState(
        candidates: [_candidate('a')],
        selected: const {'x', 'y'},
      );
      final b = ContactImportState(
        candidates: [_candidate('a')],
        selected: const {'y', 'x'},
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const ContactImportState()));
      expect(
        const ContactImportState().toString(),
        'ContactImportState(step: idle, candidates: 0, selected: 0, '
        'imported: 0, failure: null)',
      );
    });
  });
}
