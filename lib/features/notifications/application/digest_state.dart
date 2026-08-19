import 'package:flutter/foundation.dart';
import 'package:kith/core/result/failure.dart';

/// What the weekly-digest setting knows.
@immutable
class DigestState {
  const DigestState({
    this.isBusy = false,
    this.isPermissionDenied = false,
    this.failure,
  });

  /// Whether a request is in flight; the control is inert while it is.
  final bool isBusy;

  /// Whether the last attempt to turn the digest on was refused at the system
  /// prompt.
  ///
  /// Distinct from [failure] because it is not an error: declining a
  /// permission is a choice, and the answer is a line telling the user where
  /// to change their mind rather than "something went wrong".
  final bool isPermissionDenied;

  /// Why the last attempt could not be stored, or null if none failed.
  final Failure? failure;

  /// Returns a copy with the given fields replaced.
  ///
  /// The `clear` flag exists because passing null to a named parameter cannot
  /// be told apart from omitting it.
  DigestState copyWith({
    bool? isBusy,
    bool? isPermissionDenied,
    Failure? failure,
    bool clearFailure = false,
  }) => DigestState(
    isBusy: isBusy ?? this.isBusy,
    isPermissionDenied: isPermissionDenied ?? this.isPermissionDenied,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DigestState &&
          other.isBusy == isBusy &&
          other.isPermissionDenied == isPermissionDenied &&
          other.failure == failure;

  @override
  int get hashCode => Object.hash(isBusy, isPermissionDenied, failure);

  @override
  String toString() =>
      'DigestState(isBusy: $isBusy, '
      'isPermissionDenied: $isPermissionDenied, failure: $failure)';
}
