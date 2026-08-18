import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';

/// Translates what Firestore throws and emits into domain [Failure]s.
///
/// Every Firestore-backed repository runs its calls through [guard] and its
/// queries through [domainErrors], so the rule that no `FirebaseException`
/// leaves the data layer is enforced in one place rather than restated in
/// each repository.
abstract final class FirestoreErrors {
  /// Runs [body], turning anything Firestore throws into a [Failure].
  static Future<Result<T>> guard<T>(Future<Result<T>> Function() body) async {
    try {
      return await body();
    } on Object catch (error) {
      return Err(from(error));
    }
  }

  /// Re-emits the stream [source] builds, mapping Firestore errors onto domain
  /// failures so a listener never has to catch a `FirebaseException`.
  ///
  /// [source] is a callback rather than a stream because opening a query can
  /// throw before there is a stream to attach a handler to.
  static Stream<T> domainErrors<T>(Stream<T> Function() source) {
    final Stream<T> stream;
    try {
      stream = source();
    } on Object catch (error, stackTrace) {
      return Stream.error(from(error), stackTrace);
    }
    return stream.transform(
      StreamTransformer<T, T>.fromHandlers(
        handleError: (error, stackTrace, sink) =>
            sink.addError(from(error), stackTrace),
      ),
    );
  }

  /// Maps anything thrown by a call or emitted as a stream error onto the
  /// domain failure that describes it.
  ///
  /// A document that will not parse arrives here too, as whatever `fromMap`
  /// threw, and is reported as unknown rather than pretending to be a
  /// backend error.
  static Failure from(Object error) {
    if (error is! FirebaseException) {
      return UnknownFailure('Firestore call failed.', cause: error);
    }
    final message = error.message ?? error.code;
    return switch (error.code) {
      'permission-denied' => PermissionFailure(message),
      'not-found' => NotFoundFailure(message),
      'already-exists' => ConflictFailure(message),
      'unavailable' ||
      'deadline-exceeded' ||
      'aborted' ||
      'cancelled' => NetworkFailure(message),
      _ => UnknownFailure(message, cause: error),
    };
  }
}
