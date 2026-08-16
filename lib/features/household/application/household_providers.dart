import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:kith/data/models/household.dart';
import 'package:kith/data/models/member.dart';
import 'package:kith/data/repositories/household_repository.dart';

/// The app's [HouseholdRepository].
///
/// Deliberately has no default: the composition root overrides it with the
/// Firestore implementation and tests override it with a fake, so reading it
/// unoverridden throws rather than quietly talking to nothing.
final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  throw UnimplementedError(
    'householdRepositoryProvider must be overridden with a '
    'HouseholdRepository implementation before it is read.',
  );
});

/// The household with the given id, as it changes.
///
/// Family-scoped rather than reading an ambient "current household" so that
/// the id always comes from somewhere explicit.
final StreamProviderFamily<Household?, String> householdProvider =
    StreamProvider.family<Household?, String>(
      (ref, householdId) =>
          ref.watch(householdRepositoryProvider).watchHousehold(householdId),
    );

/// The members of the given household, longest-standing first.
final StreamProviderFamily<List<Member>, String> householdMembersProvider =
    StreamProvider.family<List<Member>, String>(
      (ref, householdId) =>
          ref.watch(householdRepositoryProvider).watchMembers(householdId),
    );
