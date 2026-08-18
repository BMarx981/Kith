import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show ProviderFamily, StreamProviderFamily;
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/data/repositories/hangout_repository.dart';
import 'package:kith/features/hangouts/domain/freshness_index.dart';

/// The app's [HangoutRepository].
///
/// Deliberately has no default: the composition root overrides it with the
/// Firestore implementation and tests override it with a fake, so reading it
/// unoverridden throws rather than quietly talking to nothing.
final hangoutRepositoryProvider = Provider<HangoutRepository>((ref) {
  throw UnimplementedError(
    'hangoutRepositoryProvider must be overridden with a '
    'HangoutRepository implementation before it is read.',
  );
});

/// Every hangout in the given household, most recent day first.
///
/// Family-scoped rather than reading an ambient "current household" so that
/// the id always comes from somewhere explicit.
final StreamProviderFamily<List<Hangout>, String> hangoutsProvider =
    StreamProvider.family<List<Hangout>, String>(
      (ref, householdId) =>
          ref.watch(hangoutRepositoryProvider).watchHangouts(householdId),
    );

/// The given household's hangouts narrowed to one contact, most recent first.
///
/// Derived from [hangoutsProvider] rather than queried separately: the whole
/// timeline is already in memory and already watched, so a contact's history
/// costs a filter rather than a second subscription and an array-contains
/// index.
final ProviderFamily<List<Hangout>, ({String householdId, String contactId})>
contactHangoutsProvider =
    Provider.family<List<Hangout>, ({String householdId, String contactId})>((
      ref,
      args,
    ) {
      final hangouts =
          ref.watch(hangoutsProvider(args.householdId)).value ?? const [];
      return [
        for (final hangout in hangouts)
          if (hangout.includes(args.contactId)) hangout,
      ];
    });

/// Every contact's freshness in the given household, as of now.
///
/// Rebuilt whenever the timeline changes, which is what makes a hangout
/// logged on one device move the gauges on the other: one stream feeds one
/// index, and every gauge in the app reads that index. Falls back to the
/// empty index while the timeline is still loading, so a gauge shows "never
/// logged" rather than nothing at all.
final ProviderFamily<FreshnessIndex, String> freshnessIndexProvider =
    Provider.family<FreshnessIndex, String>((ref, householdId) {
      final hangouts = ref.watch(hangoutsProvider(householdId)).value;
      if (hangouts == null) return FreshnessIndex.empty;
      return FreshnessIndex.from(
        hangouts: hangouts,
        now: ref.watch(clockProvider).now(),
      );
    });
