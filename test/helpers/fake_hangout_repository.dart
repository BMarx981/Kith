import 'dart:async';

import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/data/repositories/hangout_repository.dart';
import 'package:kith/features/hangouts/domain/hangout_draft.dart';

/// An in-memory [HangoutRepository] for widget and controller tests.
///
/// Holds hangouts in a map and re-emits the whole list on every change, the
/// way a Firestore query does. Widget tests never build the real repository.
class FakeHangoutRepository implements HangoutRepository {
  /// Hangouts by id, in insertion order.
  final hangouts = <String, Hangout>{};

  /// Arguments of every [logHangout] call, oldest first.
  final logCalls =
      <({String householdId, HangoutDraft draft, String createdBy})>[];

  /// Arguments of every [updateHangout] call, oldest first.
  final updateCalls =
      <({String householdId, String hangoutId, HangoutDraft draft})>[];

  /// Arguments of every [deleteHangout] call, oldest first.
  final deleteCalls = <({String householdId, String hangoutId})>[];

  /// Failure to return from the next write, instead of succeeding. Cleared
  /// once consumed.
  Failure? nextFailure;

  /// Completes before the next write returns, when set. Lets a test observe
  /// the form mid-request.
  Completer<void>? gate;

  /// Error the hangout stream emits instead of data, when set.
  Failure? streamFailure;

  /// When the hangout stream stamps a write, in UTC.
  DateTime now = DateTime.utc(2026, 8, 18);

  final _changes = StreamController<void>.broadcast();
  var _nextId = 0;

  @override
  Stream<List<Hangout>> watchHangouts(String householdId) =>
      streamFailure != null
      ? Stream.error(streamFailure!)
      : _onChange().map(
          (_) =>
              hangouts.values.toList()
                ..sort((a, b) => b.occurredOn.compareTo(a.occurredOn)),
        );

  @override
  Future<Result<Hangout>> logHangout({
    required String householdId,
    required HangoutDraft draft,
    required String createdBy,
  }) async {
    logCalls.add((
      householdId: householdId,
      draft: draft,
      createdBy: createdBy,
    ));
    await gate?.future;
    final failure = _takeFailure();
    if (failure != null) return Err(failure);

    final hangout = draft.normalised().toHangout(
      id: 'hgid-${++_nextId}',
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
    _put(hangout);
    return Ok(hangout);
  }

  @override
  Future<Result<void>> updateHangout({
    required String householdId,
    required String hangoutId,
    required HangoutDraft draft,
  }) async {
    updateCalls.add((
      householdId: householdId,
      hangoutId: hangoutId,
      draft: draft,
    ));
    await gate?.future;
    final failure = _takeFailure();
    if (failure != null) return Err(failure);

    final existing = hangouts[hangoutId];
    if (existing == null) {
      return const Err(NotFoundFailure('No such hangout.'));
    }
    _put(
      draft.normalised().toHangout(
        id: hangoutId,
        createdBy: existing.createdBy,
        createdAt: existing.createdAt,
        updatedAt: now,
      ),
    );
    return const Ok(null);
  }

  @override
  Future<Result<void>> deleteHangout({
    required String householdId,
    required String hangoutId,
  }) async {
    deleteCalls.add((householdId: householdId, hangoutId: hangoutId));
    await gate?.future;
    final failure = _takeFailure();
    if (failure != null) return Err(failure);

    if (hangouts.remove(hangoutId) == null) {
      return const Err(NotFoundFailure('No such hangout.'));
    }
    if (_changes.hasListener) _changes.add(null);
    return const Ok(null);
  }

  /// Puts [hangout] in the timeline without going through a write, for
  /// seeding.
  void seed(Hangout hangout) => _put(hangout);

  /// Releases the change stream. Register with `addTearDown`.
  Future<void> dispose() => _changes.close();

  void _put(Hangout hangout) {
    hangouts[hangout.id] = hangout;
    if (_changes.hasListener) _changes.add(null);
  }

  Stream<void> _onChange() async* {
    yield null;
    yield* _changes.stream;
  }

  Failure? _takeFailure() {
    final failure = nextFailure;
    nextFailure = null;
    return failure;
  }
}
