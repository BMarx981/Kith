import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/data/repositories/contact_repository.dart';
import 'package:kith/data/repositories/relationship_type_repository.dart';

/// The app's [ContactRepository].
///
/// Deliberately has no default: the composition root overrides it with the
/// Firestore implementation and tests override it with a fake, so reading it
/// unoverridden throws rather than quietly talking to nothing.
final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  throw UnimplementedError(
    'contactRepositoryProvider must be overridden with a '
    'ContactRepository implementation before it is read.',
  );
});

/// The app's [RelationshipTypeRepository]. Overridden the same way as
/// [contactRepositoryProvider].
final relationshipTypeRepositoryProvider = Provider<RelationshipTypeRepository>(
  (ref) {
    throw UnimplementedError(
      'relationshipTypeRepositoryProvider must be overridden with a '
      'RelationshipTypeRepository implementation before it is read.',
    );
  },
);

/// Every contact in the given household, archived ones included.
///
/// Family-scoped rather than reading an ambient "current household" so that
/// the id always comes from somewhere explicit. What the list actually shows
/// is decided by `ContactView`, which is pure and tested on its own.
final StreamProviderFamily<List<Contact>, String> contactsProvider =
    StreamProvider.family<List<Contact>, String>(
      (ref, householdId) =>
          ref.watch(contactRepositoryProvider).watchContacts(householdId),
    );

/// The given household's relationship labels, in the order it arranged them.
final StreamProviderFamily<List<RelationshipType>, String>
relationshipTypesProvider =
    StreamProvider.family<List<RelationshipType>, String>(
      (ref, householdId) => ref
          .watch(relationshipTypeRepositoryProvider)
          .watchRelationshipTypes(householdId),
    );
