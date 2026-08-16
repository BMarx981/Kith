import 'package:flutter/foundation.dart';
import 'package:kith/core/result/failure.dart';

/// The outcome of an operation that can fail with a domain [Failure].
///
/// Repositories and services return this rather than throwing, so callers are
/// forced by the exhaustiveness checker to handle both branches.
@immutable
sealed class Result<T> {
  const Result();

  /// Whether this is an [Ok].
  bool get isOk => this is Ok<T>;

  /// Whether this is an [Err].
  bool get isErr => this is Err<T>;

  /// The value if this is an [Ok], otherwise null.
  T? get valueOrNull => switch (this) {
    Ok(value: final v) => v,
    Err() => null,
  };

  /// The failure if this is an [Err], otherwise null.
  Failure? get failureOrNull => switch (this) {
    Ok() => null,
    Err(failure: final f) => f,
  };

  /// Collapses both branches to a single value.
  R fold<R>({
    required R Function(T value) onOk,
    required R Function(Failure failure) onErr,
  }) => switch (this) {
    Ok(value: final v) => onOk(v),
    Err(failure: final f) => onErr(f),
  };

  /// Applies [transform] to the value of an [Ok]; an [Err] passes through.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok(value: final v) => Ok(transform(v)),
    Err(failure: final f) => Err(f),
  };
}

/// A successful outcome carrying [value].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  /// The produced value.
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok<T>, value);

  @override
  String toString() => 'Ok($value)';
}

/// A failed outcome carrying [failure].
final class Err<T> extends Result<T> {
  const Err(this.failure);

  /// Why the operation failed.
  final Failure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Err<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err<T>, failure);

  @override
  String toString() => 'Err($failure)';
}
