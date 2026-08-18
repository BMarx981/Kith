import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/hangouts/application/hangout_editor_controller.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/hangouts/domain/hangout_draft.dart';

import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/fake_hangout_repository.dart';

void main() {
  const householdId = 'hid-1';
  const user = AuthUser(id: 'uid-1', email: 'brian@example.com');
  final logged = DateTime.utc(2026, 8, 18);

  final draft = HangoutDraft(
    occurredOn: DateTime.utc(2026, 8, 14),
    contactIds: const ['cid-1'],
    attendeeIds: const ['uid-1'],
  );

  late FakeHangoutRepository repository;
  late FakeAuthService auth;
  late ProviderContainer container;

  setUp(() {
    repository = FakeHangoutRepository();
    addTearDown(repository.dispose);
    auth = FakeAuthService(initialUser: user);
    addTearDown(auth.dispose);
    container = ProviderContainer(
      overrides: [
        hangoutRepositoryProvider.overrideWithValue(repository),
        authServiceProvider.overrideWithValue(auth),
      ],
    );
    addTearDown(container.dispose);
  });

  HangoutEditorController controller() {
    final subscription = container.listen(
      hangoutEditorControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    return container.read(hangoutEditorControllerProvider.notifier);
  }

  /// Lets the auth stream report before a save reads the signed-in user.
  Future<void> signIn() async {
    final subscription = container.listen(
      authStateChangesProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(authStateChangesProvider.future);
  }

  group('save', () {
    test('logs a new hangout, crediting the signed-in user', () async {
      await signIn();

      final saved = await controller().save(
        householdId: householdId,
        draft: draft,
      );

      expect(saved, isTrue);
      expect(repository.logCalls.single.createdBy, 'uid-1');
      expect(repository.logCalls.single.householdId, householdId);
      expect(repository.hangouts, hasLength(1));
    });

    test('edits the named hangout instead of logging another', () async {
      await signIn();
      repository.seed(
        Hangout(
          id: 'hgid-1',
          occurredOn: DateTime.utc(2026, 8, 14),
          contactIds: const ['cid-1'],
          attendeeIds: const ['uid-1'],
          createdBy: 'uid-1',
          createdAt: logged,
          updatedAt: logged,
        ),
      );

      final saved = await controller().save(
        householdId: householdId,
        hangoutId: 'hgid-1',
        draft: draft.copyWith(note: 'Coffee'),
      );

      expect(saved, isTrue);
      expect(repository.logCalls, isEmpty);
      expect(repository.updateCalls.single.hangoutId, 'hgid-1');
      expect(repository.hangouts['hgid-1']!.note, 'Coffee');
    });

    test('refuses to log with nobody signed in', () async {
      await auth.signOut();

      final saved = await controller().save(
        householdId: householdId,
        draft: draft,
      );

      expect(saved, isFalse);
      expect(repository.logCalls, isEmpty);
      expect(
        container.read(hangoutEditorControllerProvider).failure,
        isA<AuthFailure>(),
      );
    });

    test(
      'holds the failure and stays not-submitting after a refusal',
      () async {
        await signIn();
        repository.nextFailure = const NetworkFailure('offline');

        final saved = await controller().save(
          householdId: householdId,
          draft: draft,
        );

        expect(saved, isFalse);
        final state = container.read(hangoutEditorControllerProvider);
        expect(state.isSubmitting, isFalse);
        expect(state.failure, isA<NetworkFailure>());
      },
    );

    test('clears the previous failure on the next attempt', () async {
      await signIn();
      repository.nextFailure = const NetworkFailure('offline');
      await controller().save(householdId: householdId, draft: draft);

      final saved = await controller().save(
        householdId: householdId,
        draft: draft,
      );

      expect(saved, isTrue);
      expect(container.read(hangoutEditorControllerProvider).failure, isNull);
    });

    test('marks itself submitting while the write is in flight', () async {
      await signIn();
      final gate = Completer<void>();
      repository.gate = gate;

      final pending = controller().save(
        householdId: householdId,
        draft: draft,
      );
      await pumpEventQueue();

      expect(
        container.read(hangoutEditorControllerProvider).isSubmitting,
        isTrue,
      );

      gate.complete();
      await pending;

      expect(
        container.read(hangoutEditorControllerProvider).isSubmitting,
        isFalse,
      );
    });

    test(
      'a second tap while submitting cannot log the evening twice',
      () async {
        await signIn();
        final gate = Completer<void>();
        repository.gate = gate;
        final editor = controller();

        final first = editor.save(householdId: householdId, draft: draft);
        await pumpEventQueue();
        final second = await editor.save(
          householdId: householdId,
          draft: draft,
        );

        expect(second, isFalse);
        gate.complete();
        await first;
        expect(repository.logCalls, hasLength(1));
      },
    );
  });

  group('delete', () {
    test('removes the hangout', () async {
      repository.seed(
        Hangout(
          id: 'hgid-1',
          occurredOn: DateTime.utc(2026, 8, 14),
          contactIds: const ['cid-1'],
          attendeeIds: const [],
          createdBy: 'uid-1',
          createdAt: logged,
          updatedAt: logged,
        ),
      );

      final done = await controller().delete(
        householdId: householdId,
        hangoutId: 'hgid-1',
      );

      expect(done, isTrue);
      expect(repository.deleteCalls.single.hangoutId, 'hgid-1');
      expect(repository.hangouts, isEmpty);
    });

    test('holds the failure when the delete is refused', () async {
      repository.nextFailure = const PermissionFailure('nope');

      final done = await controller().delete(
        householdId: householdId,
        hangoutId: 'hgid-1',
      );

      expect(done, isFalse);
      expect(
        container.read(hangoutEditorControllerProvider).failure,
        isA<PermissionFailure>(),
      );
    });
  });

  test('starts clean', () {
    final state = container.read(hangoutEditorControllerProvider);

    expect(state.isSubmitting, isFalse);
    expect(state.failure, isNull);
  });
}
