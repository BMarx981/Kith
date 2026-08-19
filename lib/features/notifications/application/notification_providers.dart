import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/data/models/member.dart';
import 'package:kith/data/services/notification_scheduler.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/upcoming_birthday.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/notifications/domain/weekly_digest.dart';
import 'package:kith/features/suggestions/application/suggestion_providers.dart';

/// The app's [NotificationScheduler].
///
/// Deliberately has no default: the composition root overrides it with the
/// plugin-backed implementation and tests override it with a fake, so reading
/// it unoverridden throws rather than quietly talking to nothing.
final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  throw UnimplementedError(
    'notificationSchedulerProvider must be overridden with a '
    'NotificationScheduler implementation before it is read.',
  );
});

/// The signed-in user's own membership record in the given household, or null
/// while either the identity or the roster is still loading.
///
/// The digest preference lives on this document, so this is what the settings
/// screen reads and what the scheduler branches on.
final ProviderFamily<Member?, String> currentMemberProvider =
    Provider.family<Member?, String>((ref, householdId) {
      final uid = ref.watch(currentUserProvider)?.id;
      final members = ref.watch(householdMembersProvider(householdId)).value;
      if (uid == null || members == null) return null;
      return members.where((member) => member.id == uid).firstOrNull;
    });

/// What the given household's next digest would say if it fired now.
///
/// Derived from the same readings the Reconnect screen draws — the ranked
/// suggestions and the birthdays coming up — so the notification cannot
/// disagree with the screen it summarises.
///
/// Empty while the contacts are still loading, which is what stops a digest
/// scheduled during a cold start from claiming nobody is overdue.
final ProviderFamily<WeeklyDigest, String> weeklyDigestProvider =
    Provider.family<WeeklyDigest, String>((ref, householdId) {
      final contacts = ref.watch(contactsProvider(householdId)).value;
      return WeeklyDigest(
        overdue: ref.watch(suggestionsProvider(householdId)),
        birthdays: contacts == null
            ? const []
            : upcomingBirthdays(
                contacts: contacts,
                now: ref.watch(nowProvider),
                withinDays: WeeklyDigest.windowDays,
              ),
      );
    });
