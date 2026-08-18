import 'dart:async';

import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/data/repositories/relationship_type_repository.dart';

/// An in-memory [RelationshipTypeRepository] for widget and controller tests.
class FakeRelationshipTypeRepository implements RelationshipTypeRepository {
  /// Labels by id.
  final types = <String, RelationshipType>{};

  /// Names passed to [createRelationshipType], oldest first.
  final createCalls = <({String householdId, String name})>[];

  /// Arguments of every [renameRelationshipType] call, oldest first.
  final renameCalls = <({String householdId, String typeId, String name})>[];

  /// Orders passed to [reorderRelationshipTypes], oldest first.
  final reorderCalls = <({String householdId, List<String> orderedIds})>[];

  /// Arguments of every [deleteRelationshipType] call, oldest first.
  final deleteCalls =
      <({String householdId, String typeId, String reassignToId})>[];

  /// Household ids passed to [seedDefaults], oldest first.
  final seedCalls = <String>[];

  /// Failure to return from the next write. Cleared once consumed.
  Failure? nextFailure;

  /// Completes before the next write returns, when set.
  Completer<void>? gate;

  /// Error the label stream emits instead of data, when set.
  Failure? streamFailure;

  /// When labels created through this fake say they were created.
  DateTime now = DateTime.utc(2026, 8, 18);

  final _changes = StreamController<void>.broadcast();
  var _nextId = 0;

  @override
  Stream<List<RelationshipType>> watchRelationshipTypes(String householdId) =>
      streamFailure != null
      ? Stream.error(streamFailure!)
      : _onChange().map(
          (_) =>
              types.values.toList()
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
        );

  @override
  Future<Result<List<RelationshipType>>> seedDefaults(
    String householdId,
  ) async {
    seedCalls.add(householdId);
    await gate?.future;
    final failure = _takeFailure();
    if (failure != null) return Err(failure);

    if (types.isNotEmpty) return Ok(types.values.toList());
    for (final (index, name) in RelationshipType.defaultNames.indexed) {
      _put(
        RelationshipType(
          id: 'rid-${++_nextId}',
          name: name,
          sortOrder: index,
          createdAt: now,
        ),
      );
    }
    return Ok(types.values.toList());
  }

  @override
  Future<Result<RelationshipType>> createRelationshipType({
    required String householdId,
    required String name,
  }) async {
    createCalls.add((householdId: householdId, name: name));
    await gate?.future;
    final failure = _takeFailure();
    if (failure != null) return Err(failure);

    final type = RelationshipType(
      id: 'rid-${++_nextId}',
      name: name.trim(),
      sortOrder: types.length,
      createdAt: now,
    );
    _put(type);
    return Ok(type);
  }

  @override
  Future<Result<void>> renameRelationshipType({
    required String householdId,
    required String typeId,
    required String name,
  }) async {
    renameCalls.add((householdId: householdId, typeId: typeId, name: name));
    await gate?.future;
    final failure = _takeFailure();
    if (failure != null) return Err(failure);

    final existing = types[typeId];
    if (existing == null) return const Err(NotFoundFailure('No such label.'));
    _put(existing.copyWith(name: name.trim()));
    return const Ok(null);
  }

  @override
  Future<Result<void>> reorderRelationshipTypes({
    required String householdId,
    required List<String> orderedIds,
  }) async {
    reorderCalls.add((householdId: householdId, orderedIds: orderedIds));
    await gate?.future;
    final failure = _takeFailure();
    if (failure != null) return Err(failure);

    for (final (index, id) in orderedIds.indexed) {
      final existing = types[id];
      if (existing != null) _put(existing.copyWith(sortOrder: index));
    }
    return const Ok(null);
  }

  @override
  Future<Result<void>> deleteRelationshipType({
    required String householdId,
    required String typeId,
    required String reassignToId,
  }) async {
    deleteCalls.add((
      householdId: householdId,
      typeId: typeId,
      reassignToId: reassignToId,
    ));
    await gate?.future;
    final failure = _takeFailure();
    if (failure != null) return Err(failure);

    types.remove(typeId);
    if (_changes.hasListener) _changes.add(null);
    return const Ok(null);
  }

  /// Puts [type] in the list without going through a write, for seeding.
  void seed(RelationshipType type) => _put(type);

  /// Releases the change stream. Register with `addTearDown`.
  Future<void> dispose() => _changes.close();

  void _put(RelationshipType type) {
    types[type.id] = type;
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
