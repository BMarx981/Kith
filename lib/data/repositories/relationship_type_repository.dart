import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/relationship_type.dart';

/// Reads and writes a household's relationship labels.
///
/// Implementations translate backend errors into domain failures before
/// returning; nothing above this interface sees a `FirebaseException`.
abstract interface class RelationshipTypeRepository {
  /// The labels of [householdId], in the order the household arranged them.
  Stream<List<RelationshipType>> watchRelationshipTypes(String householdId);

  /// Writes the starter set into a household that has no labels yet.
  ///
  /// Idempotent: a household that already has labels keeps them and gets its
  /// existing list back, so running this twice cannot double the list.
  Future<Result<List<RelationshipType>>> seedDefaults(String householdId);

  /// Adds a label called [name] to the end of [householdId]'s list.
  ///
  /// Fails with a `ConflictFailure` when the household already has a label by
  /// that name, ignoring case: two labels a person cannot tell apart are a
  /// mistake rather than a preference.
  Future<Result<RelationshipType>> createRelationshipType({
    required String householdId,
    required String name,
  });

  /// Renames the label [typeId] to [name].
  ///
  /// Contacts reference the label by id, so a rename reaches every contact
  /// filed under it without touching a single contact document.
  Future<Result<void>> renameRelationshipType({
    required String householdId,
    required String typeId,
    required String name,
  });

  /// Rearranges [householdId]'s labels to match [orderedIds], first to last.
  Future<Result<void>> reorderRelationshipTypes({
    required String householdId,
    required List<String> orderedIds,
  });

  /// Deletes the label [typeId], moving every contact filed under it to
  /// [reassignToId] in the same write.
  ///
  /// Reassignment is mandatory rather than optional: a contact whose label no
  /// longer exists has nothing to render and nothing to filter by, so the
  /// caller has to say where those contacts go before the label can go.
  Future<Result<void>> deleteRelationshipType({
    required String householdId,
    required String typeId,
    required String reassignToId,
  });
}
