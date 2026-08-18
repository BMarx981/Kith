import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show ProviderFamily, StreamProviderFamily;
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/data/repositories/planned_hangout_repository.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/suggestions/engine/suggestion.dart';
import 'package:kith/features/suggestions/engine/suggestion_engine.dart';

/// The app's [PlannedHangoutRepository].
///
/// Deliberately has no default: the composition root overrides it with the
/// Firestore implementation and tests override it with a fake, so reading it
/// unoverridden throws rather than quietly talking to nothing.
final plannedHangoutRepositoryProvider = Provider<PlannedHangoutRepository>((
  ref,
) {
  throw UnimplementedError(
    'plannedHangoutRepositoryProvider must be overridden with a '
    'PlannedHangoutRepository implementation before it is read.',
  );
});

/// Every plan in the given household, soonest day first.
///
/// Family-scoped rather than reading an ambient "current household" so that
/// the id always comes from somewhere explicit.
final StreamProviderFamily<List<PlannedHangout>, String>
plannedHangoutsProvider = StreamProvider.family<List<PlannedHangout>, String>(
  (ref, householdId) => ref
      .watch(plannedHangoutRepositoryProvider)
      .watchPlannedHangouts(householdId),
);

/// The given household's plans narrowed to one contact, soonest first.
///
/// Derived from [plannedHangoutsProvider] rather than queried separately: the
/// whole short list is already in memory and already watched.
final ProviderFamily<
  List<PlannedHangout>,
  ({String householdId, String contactId})
>
contactPlansProvider =
    Provider.family<
      List<PlannedHangout>,
      ({String householdId, String contactId})
    >((ref, args) {
      final plans =
          ref.watch(plannedHangoutsProvider(args.householdId)).value ??
          const [];
      return [
        for (final plan in plans)
          if (plan.includes(args.contactId)) plan,
      ];
    });

/// Who the given household should reconnect with, most pressing first.
///
/// Everything the ranking needs is already streamed for other screens — the
/// contacts, the freshness index built from the timeline, the plans — so this
/// is a derivation rather than a fourth subscription, and it re-ranks the
/// moment a hangout is logged or a plan is made on either device.
///
/// Empty while any of the three is still loading: an empty Reconnect section
/// says "nothing to do", and saying that before the data has arrived would be
/// a lie the user acts on. The screen tells the two apart by watching the
/// underlying streams.
final ProviderFamily<List<Suggestion>, String> suggestionsProvider =
    Provider.family<List<Suggestion>, String>((ref, householdId) {
      final contacts = ref.watch(contactsProvider(householdId)).value;
      final plans = ref.watch(plannedHangoutsProvider(householdId)).value;
      if (contacts == null || plans == null) return const [];
      return SuggestionEngine.rank(
        contacts: contacts,
        freshness: ref.watch(freshnessIndexProvider(householdId)),
        plans: plans,
        now: ref.watch(nowProvider),
      );
    });
