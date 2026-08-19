import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/notifications/application/digest_state.dart';

void main() {
  group('DigestState', () {
    test('starts idle, allowed and unfailed', () {
      const state = DigestState();

      expect(state.isBusy, isFalse);
      expect(state.isPermissionDenied, isFalse);
      expect(state.failure, isNull);
    });

    test('copyWith replaces each field and leaves the rest alone', () {
      const state = DigestState();

      expect(state.copyWith(isBusy: true).isBusy, isTrue);
      expect(
        state.copyWith(isPermissionDenied: true).isPermissionDenied,
        isTrue,
      );
      expect(
        state.copyWith(failure: const NetworkFailure('offline')).failure,
        const NetworkFailure('offline'),
      );
      expect(state.copyWith(isBusy: true).failure, isNull);
    });

    test('copyWith with nothing is an identity', () {
      const state = DigestState(
        isBusy: true,
        isPermissionDenied: true,
        failure: NetworkFailure('offline'),
      );

      expect(state.copyWith(), state);
    });

    test('clearFailure drops the failure', () {
      const state = DigestState(failure: NetworkFailure('offline'));

      expect(state.copyWith(clearFailure: true).failure, isNull);
    });

    test('has value semantics', () {
      const state = DigestState(isBusy: true);

      expect(state, const DigestState(isBusy: true));
      expect(state.hashCode, const DigestState(isBusy: true).hashCode);
      expect(state, isNot(const DigestState()));
      expect(
        state.toString(),
        'DigestState(isBusy: true, isPermissionDenied: false, failure: null)',
      );
    });
  });
}
