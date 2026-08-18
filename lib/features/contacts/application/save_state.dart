import 'package:flutter/foundation.dart';
import 'package:kith/core/result/failure.dart';

/// Whether a write is in flight, and why the last one was refused.
///
/// Shared by the contact editor and the relationship type manager, which do
/// nothing else between tapping save and the backend answering. Neither
/// navigates: a screen closes itself when the state comes back clean.
@immutable
class SaveState {
  const SaveState({this.isSubmitting = false, this.failure});

  /// Whether a request is in flight; the form is inert while it is.
  final bool isSubmitting;

  /// Why the last attempt was refused, or null if none was.
  final Failure? failure;

  /// Returns a copy with the given fields replaced.
  ///
  /// The `clear` flag exists because passing null to a named parameter cannot
  /// be told apart from omitting it.
  SaveState copyWith({
    bool? isSubmitting,
    Failure? failure,
    bool clearFailure = false,
  }) => SaveState(
    isSubmitting: isSubmitting ?? this.isSubmitting,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveState &&
          other.isSubmitting == isSubmitting &&
          other.failure == failure;

  @override
  int get hashCode => Object.hash(isSubmitting, failure);

  @override
  String toString() =>
      'SaveState(isSubmitting: $isSubmitting, failure: $failure)';
}
