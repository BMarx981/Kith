import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/data/repositories/firestore_contact_repository.dart';
import 'package:kith/data/repositories/firestore_errors.dart';
import 'package:kith/data/repositories/relationship_type_repository.dart';

/// [RelationshipTypeRepository] backed by Cloud Firestore.
///
/// Labels live under `households/{hid}/relationshipTypes/{rid}`. Deleting one
/// also rewrites every contact filed under it, which is why this class knows
/// the contacts path: the reassignment and the deletion go in one batch, so a
/// contact can never point at a label that is gone.
class FirestoreRelationshipTypeRepository
    implements RelationshipTypeRepository {
  /// The [Clock] is what makes creation timestamps testable. It is positional
  /// because a named parameter cannot bind straight to a private field.
  const FirestoreRelationshipTypeRepository(
    this._firestore, [
    this._clock = const Clock(),
  ]);

  final FirebaseFirestore _firestore;
  final Clock _clock;

  /// Top-level households collection.
  static const householdsPath = 'households';

  /// Relationship types subcollection of a household.
  static const relationshipTypesPath = 'relationshipTypes';

  @override
  Stream<List<RelationshipType>> watchRelationshipTypes(String householdId) =>
      FirestoreErrors.domainErrors(
        () => _types(householdId)
            .orderBy('sortOrder')
            .snapshots()
            .map(
              (snapshot) => snapshot.docs
                  .map((doc) => RelationshipType.fromMap(doc.data()))
                  .toList(),
            ),
      );

  @override
  Future<Result<List<RelationshipType>>> seedDefaults(String householdId) =>
      FirestoreErrors.guard(() async {
        final existing = await _types(householdId).orderBy('sortOrder').get();
        if (existing.docs.isNotEmpty) {
          return Ok(
            existing.docs
                .map((doc) => RelationshipType.fromMap(doc.data()))
                .toList(),
          );
        }

        final now = _clock.now().toUtc();
        final batch = _firestore.batch();
        final seeded = <RelationshipType>[];
        for (final (index, name) in RelationshipType.defaultNames.indexed) {
          final document = _types(householdId).doc();
          final type = RelationshipType(
            id: document.id,
            name: name,
            sortOrder: index,
            createdAt: now,
          );
          seeded.add(type);
          batch.set(document, type.toMap());
        }
        await batch.commit();
        return Ok(seeded);
      });

  @override
  Future<Result<RelationshipType>> createRelationshipType({
    required String householdId,
    required String name,
  }) async {
    final trimmed = name.trim();
    final invalid = _validateName(trimmed);
    if (invalid != null) return Err(invalid);

    return FirestoreErrors.guard(() async {
      final existing = await _types(householdId).get();
      final types = existing.docs
          .map((doc) => RelationshipType.fromMap(doc.data()))
          .toList();
      if (types.any((type) => _sameName(type.name, trimmed))) {
        return const Err(ConflictFailure('That label already exists.'));
      }

      // Appended past the current end rather than at `length`, so a list with
      // gaps in its sort orders still gets a new label at the bottom.
      final sortOrder =
          types.fold(-1, (a, b) => a > b.sortOrder ? a : b.sortOrder) + 1;
      final document = _types(householdId).doc();
      final type = RelationshipType(
        id: document.id,
        name: trimmed,
        sortOrder: sortOrder,
        createdAt: _clock.now().toUtc(),
      );
      await document.set(type.toMap());
      return Ok(type);
    });
  }

  @override
  Future<Result<void>> renameRelationshipType({
    required String householdId,
    required String typeId,
    required String name,
  }) async {
    final trimmed = name.trim();
    final invalid = _validateName(trimmed);
    if (invalid != null) return Err(invalid);

    return FirestoreErrors.guard(() async {
      final existing = await _types(householdId).get();
      final clashes = existing.docs
          .map((doc) => RelationshipType.fromMap(doc.data()))
          .any((type) => type.id != typeId && _sameName(type.name, trimmed));
      if (clashes) {
        return const Err(ConflictFailure('That label already exists.'));
      }

      await _types(householdId).doc(typeId).update({'name': trimmed});
      return const Ok(null);
    });
  }

  @override
  Future<Result<void>> reorderRelationshipTypes({
    required String householdId,
    required List<String> orderedIds,
  }) => FirestoreErrors.guard(() async {
    final batch = _firestore.batch();
    for (final (index, id) in orderedIds.indexed) {
      batch.update(_types(householdId).doc(id), {'sortOrder': index});
    }
    await batch.commit();
    return const Ok(null);
  });

  @override
  Future<Result<void>> deleteRelationshipType({
    required String householdId,
    required String typeId,
    required String reassignToId,
  }) async {
    if (typeId == reassignToId) {
      return const Err(
        ValidationFailure('Choose a different label to move contacts to.'),
      );
    }

    return FirestoreErrors.guard(() async {
      final target = await _types(householdId).doc(reassignToId).get();
      if (!target.exists) {
        return const Err(
          NotFoundFailure('That label is no longer there to move contacts to.'),
        );
      }

      // One batch, so the reassignment and the deletion land together: a
      // contact is never left pointing at a label that has gone. Batches cap
      // at 500 writes, which a household's contact list does not approach.
      final affected = await _contacts(
        householdId,
      ).where('relationshipTypeId', isEqualTo: typeId).get();
      final batch = _firestore.batch();
      final now = _clock.now().toUtc().millisecondsSinceEpoch;
      for (final contact in affected.docs) {
        batch.update(contact.reference, {
          'relationshipTypeId': reassignToId,
          'updatedAt': now,
        });
      }
      batch.delete(_types(householdId).doc(typeId));
      await batch.commit();
      return const Ok(null);
    });
  }

  /// Why [name] cannot be stored, or null when it can. Mirrors the bounds in
  /// `firestore.rules`.
  static Failure? _validateName(String name) {
    if (name.isEmpty) return const ValidationFailure('Give the label a name.');
    if (name.length > RelationshipType.maxNameLength) {
      return const ValidationFailure(
        'Keep it under ${RelationshipType.maxNameLength} characters.',
      );
    }
    return null;
  }

  /// Whether two labels are the same to a person reading the list.
  static bool _sameName(String a, String b) =>
      a.toLowerCase() == b.toLowerCase();

  CollectionReference<Map<String, dynamic>> _types(String householdId) =>
      _firestore
          .collection(householdsPath)
          .doc(householdId)
          .collection(relationshipTypesPath);

  CollectionReference<Map<String, dynamic>> _contacts(String householdId) =>
      _firestore
          .collection(householdsPath)
          .doc(householdId)
          .collection(FirestoreContactRepository.contactsPath);
}
