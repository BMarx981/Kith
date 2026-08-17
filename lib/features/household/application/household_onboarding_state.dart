import 'package:flutter/foundation.dart';
import 'package:kith/core/result/failure.dart';

/// Which form the onboarding screen is showing.
enum HouseholdOnboardingMode {
  /// Starting a household nobody else is in yet.
  create,

  /// Joining one with an invite code from whoever created it.
  join,
}

/// Everything the onboarding screen renders that is not held by its fields.
@immutable
class HouseholdOnboardingState {
  const HouseholdOnboardingState({
    this.mode = HouseholdOnboardingMode.create,
    this.isSubmitting = false,
    this.failure,
  });

  /// Whether the form creates a household or joins one.
  final HouseholdOnboardingMode mode;

  /// Whether a request is in flight; the form is inert while it is.
  final bool isSubmitting;

  /// Why the last attempt was refused, or null if none was.
  final Failure? failure;

  /// Returns a copy with the given fields replaced.
  ///
  /// The `clear` flag exists because passing null to a named parameter cannot
  /// be told apart from omitting it.
  HouseholdOnboardingState copyWith({
    HouseholdOnboardingMode? mode,
    bool? isSubmitting,
    Failure? failure,
    bool clearFailure = false,
  }) => HouseholdOnboardingState(
    mode: mode ?? this.mode,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HouseholdOnboardingState &&
          other.mode == mode &&
          other.isSubmitting == isSubmitting &&
          other.failure == failure;

  @override
  int get hashCode => Object.hash(mode, isSubmitting, failure);

  @override
  String toString() =>
      'HouseholdOnboardingState(mode: ${mode.name}, '
      'isSubmitting: $isSubmitting, failure: $failure)';
}
