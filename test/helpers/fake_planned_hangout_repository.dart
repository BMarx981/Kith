import 'dart:async';

import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/data/models/planned_hangout_status.dart';
import 'package:kith/data/repositories/planned_hangout_repository.dart';

/// An in-memory [PlannedHangoutRepository] for widget and controller tests.
///
/// Holds plans in a map and re-emits the whole list on every change, the way a
/// Firestore query does. Widget tests never build the real repository.
class FakePlannedHangoutRepository implements PlannedHangoutRepository {
  /// Plans by id, in insertion order.
  final plans = <String, PlannedHangout>{};

  /// Arguments of every [planHangout] call, oldest first.
  final planCalls =
      <
        ({
          String householdId,
          List<String> contactIds,
          DateTime plannedFor,
          String createdBy,
          String? note,
        })
      >[];

  /// Arguments of every [snoozeContacts] call, oldest first.
  final snoozeCalls =
      <
        ({
          String householdId,
          List<String> contactIds,
          DateTime until,
          String createdBy,
        })
      >[];

  /// Arguments of every [cancelPlan] call, oldest first.
  final cancelCalls = <({String householdId, String plannedHangoutId})>[];

  /// Failure to return from the next write, instead of succeeding. Cleared
  /// once consumed.
  Failure? nextFailure;

  /// Completes before the next write returns, when set. Lets a test observe
  /// the card mid-request.
  Completer<void>? gate;

  /// Error the plan stream emits instead of data, when set.
  Failure? streamFailure;

  /// When the fake stamps a write, in UTC.
  DateTime now = DateTime.utc(2026, 8, 18);

  final _changes = StreamController<void>.broadcast();
  var _nextId = 0;

  @override
  Stream<List<PlannedHangout>> watchPlannedHangouts(String householdId) =>
      streamFailure != null
      ? Stream.error(streamFailure!)
      : _onChange().map(
          (_) =>
              plans.values.toList()
                ..sort((a, b) => a.plannedFor.compareTo(b.plannedFor)),
        );

  @override
  Future<Result<PlannedHangout>> planHangout({
    required String householdId,
    required List<String> contactIds,
    required DateTime plannedFor,
    required String createdBy,
    String? note,
  }) async {
    planCalls.add((
      householdId: householdId,
      contactIds: contactIds,
      plannedFor: plannedFor,
      createdBy: createdBy,
      note: note,
    ));
    return _write(
      contactIds: contactIds,
      day: plannedFor,
      status: PlannedHangoutStatus.proposed,
      createdBy: createdBy,
      note: note,
    );
  }

  @override
  Future<Result<PlannedHangout>> snoozeContacts({
    required String householdId,
    required List<String> contactIds,
    required DateTime until,
    required String createdBy,
  }) async {
    snoozeCalls.add((
      householdId: householdId,
      contactIds: contactIds,
      until: until,
      createdBy: createdBy,
    ));
    return _write(
      contactIds: contactIds,
      day: until,
      status: PlannedHangoutStatus.snoozed,
      createdBy: createdBy,
      note: null,
    );
  }

  @override
  Future<Result<void>> cancelPlan({
    required String householdId,
    required String plannedHangoutId,
  }) async {
    cancelCalls.add((
      householdId: householdId,
      plannedHangoutId: plannedHangoutId,
    ));
    await gate?.future;
    final failure = _takeFailure();
    if (failure != null) return Err(failure);

    if (plans.remove(plannedHangoutId) == null) {
      return const Err(NotFoundFailure('No such plan.'));
    }
    if (_changes.hasListener) _changes.add(null);
    return const Ok(null);
  }

  /// Puts [plan] in the list without going through a write, for seeding.
  void seed(PlannedHangout plan) => _put(plan);

  /// Releases the change stream. Register with `addTearDown`.
  Future<void> dispose() => _changes.close();

  Future<Result<PlannedHangout>> _write({
    required List<String> contactIds,
    required DateTime day,
    required PlannedHangoutStatus status,
    required String createdBy,
    required String? note,
  }) async {
    await gate?.future;
    final failure = _takeFailure();
    if (failure != null) return Err(failure);
    if (contactIds.isEmpty) {
      return const Err(ValidationFailure('Choose who the plan is with.'));
    }

    final plan = PlannedHangout(
      id: 'pid-${++_nextId}',
      plannedFor: day,
      contactIds: contactIds,
      status: status,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
      note: note,
    );
    _put(plan);
    return Ok(plan);
  }

  void _put(PlannedHangout plan) {
    plans[plan.id] = plan;
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
