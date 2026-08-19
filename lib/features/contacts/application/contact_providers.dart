import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show ProviderFamily, StreamProviderFamily;
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/data/repositories/contact_repository.dart';
import 'package:kith/data/repositories/relationship_type_repository.dart';
import 'package:kith/features/contacts/domain/upcoming_birthday.dart';

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

/// The given household's birthdays landing in the next month, soonest first.
///
/// Derived from [contactsProvider] rather than queried: the whole list is
/// already streamed for the contacts screen, and a birthday is a field on a
/// contact rather than a record of its own.
///
/// Empty while the contacts are still loading, the same way the suggestions
/// are. The screen tells "nobody has a birthday coming up" from "not loaded
/// yet" by watching the contact stream itself.
final ProviderFamily<List<UpcomingBirthday>, String> upcomingBirthdaysProvider =
    Provider.family<List<UpcomingBirthday>, String>((ref, householdId) {
      final contacts = ref.watch(contactsProvider(householdId)).value;
      if (contacts == null) return const [];
      return upcomingBirthdays(
        contacts: contacts,
        now: ref.watch(nowProvider),
      );
    });
