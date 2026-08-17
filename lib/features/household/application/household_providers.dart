import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:kith/data/models/household.dart';
import 'package:kith/data/models/member.dart';
import 'package:kith/data/repositories/household_repository.dart';
import 'package:kith/features/auth/application/auth_providers.dart';

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

/// The households the signed-in user belongs to, longest-standing first.
///
/// Stays `AsyncLoading` until auth has reported, so a cold start with a stored
/// session is never mistaken for a user who belongs to nowhere; that
/// distinction is what the household guard turns on. Emits an empty list once
/// it is known that there is no membership, including when nobody is signed
/// in, and re-runs against the new identity whenever that changes.
final householdIdsProvider = StreamProvider<List<String>>((ref) async* {
  final user = await ref.watch(authStateChangesProvider.future);
  if (user == null) {
    yield const [];
    return;
  }
  yield* ref.watch(householdRepositoryProvider).watchHouseholdIdsFor(user.id);
});

/// The household this session works in, or null.
///
/// Null covers both "belongs to none" and "not known yet", the same way
/// `currentUserProvider` does; anything that has to tell those apart watches
/// [householdIdsProvider] instead. v1 puts a user in one household, and this
/// is the single place that policy is applied: the oldest membership wins.
final currentHouseholdIdProvider = Provider<String?>((ref) {
  final ids = ref.watch(householdIdsProvider).value;
  return ids == null || ids.isEmpty ? null : ids.first;
});
