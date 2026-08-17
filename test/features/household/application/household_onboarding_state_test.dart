import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/household/application/household_onboarding_state.dart';

void main() {
  const failure = NotFoundFailure('no such code');

  group('HouseholdOnboardingState', () {
    test('defaults to an idle create form with nothing to report', () {
      const state = HouseholdOnboardingState();

      expect(state.mode, HouseholdOnboardingMode.create);
      expect(state.isSubmitting, isFalse);
      expect(state.failure, isNull);
    });

    test('copyWith replaces each field', () {
      const state = HouseholdOnboardingState();

      expect(
        state.copyWith(mode: HouseholdOnboardingMode.join).mode,
        HouseholdOnboardingMode.join,
      );
      expect(state.copyWith(isSubmitting: true).isSubmitting, isTrue);
      expect(state.copyWith(failure: failure).failure, failure);
    });

    test('copyWith keeps fields it is not given', () {
      const state = HouseholdOnboardingState(
        mode: HouseholdOnboardingMode.join,
        isSubmitting: true,
        failure: failure,
      );

      expect(state.copyWith(), state);
    });

    test('clearFailure nulls out what copyWith cannot', () {
      const state = HouseholdOnboardingState(failure: failure);

      expect(state.copyWith(clearFailure: true).failure, isNull);
    });

    test('clearFailure wins over a replacement value', () {
      const state = HouseholdOnboardingState(failure: failure);

      final cleared = state.copyWith(
        failure: const NetworkFailure('offline'),
        clearFailure: true,
      );

      expect(cleared.failure, isNull);
    });

    test('equal states compare equal and hash alike', () {
      const one = HouseholdOnboardingState(
        mode: HouseholdOnboardingMode.join,
        isSubmitting: true,
        failure: failure,
      );
      const other = HouseholdOnboardingState(
        mode: HouseholdOnboardingMode.join,
        isSubmitting: true,
        failure: failure,
      );

      expect(one, other);
      expect(one.hashCode, other.hashCode);
      expect(one, one);
    });

    test('differing states compare unequal', () {
      const state = HouseholdOnboardingState();

      expect(state, isNot(state.copyWith(mode: HouseholdOnboardingMode.join)));
      expect(state, isNot(state.copyWith(isSubmitting: true)));
      expect(state, isNot(state.copyWith(failure: failure)));
      expect(state, isNot(const Object()));
    });

    test('toString names the mode and carries the feedback', () {
      const state = HouseholdOnboardingState(
        mode: HouseholdOnboardingMode.join,
        isSubmitting: true,
        failure: failure,
      );

      expect(
        state.toString(),
        'HouseholdOnboardingState(mode: join, isSubmitting: true, '
        'failure: NotFoundFailure(no such code))',
      );
    });
  });
}
