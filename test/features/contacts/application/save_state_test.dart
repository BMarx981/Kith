import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/contacts/application/save_state.dart';

void main() {
  const failure = NetworkFailure('offline');

  group('SaveState', () {
    test('starts idle with nothing to report', () {
      const state = SaveState();

      expect(state.isSubmitting, isFalse);
      expect(state.failure, isNull);
    });

    test('copyWith covers every field', () {
      const state = SaveState();

      expect(state.copyWith(), state);
      expect(state.copyWith(isSubmitting: true).isSubmitting, isTrue);
      expect(state.copyWith(failure: failure).failure, failure);
    });

    test('clearing the failure is distinct from omitting it', () {
      const state = SaveState(failure: failure);

      expect(state.copyWith().failure, failure);
      expect(state.copyWith(clearFailure: true).failure, isNull);
    });

    test('has value semantics', () {
      const state = SaveState(isSubmitting: true, failure: failure);

      expect(state.copyWith(), state);
      expect(state.copyWith().hashCode, state.hashCode);
      expect(state.copyWith(isSubmitting: false), isNot(state));
      expect(state.copyWith(clearFailure: true), isNot(state));
    });

    test('toString names both fields', () {
      const state = SaveState(isSubmitting: true, failure: failure);

      expect(state.toString(), contains('isSubmitting: true'));
      expect(state.toString(), contains('offline'));
    });
  });
}
