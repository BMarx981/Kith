import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/notifications/application/digest_state.dart';
import 'package:kith/features/notifications/application/notification_providers.dart';
import 'package:kith/features/notifications/domain/digest_schedule.dart';
import 'package:kith/l10n/l10n_providers.dart';

/// Turns the weekly digest on and off, and keeps what is scheduled current.
///
/// The digest is a *one-shot* notification carrying a snapshot of who is
/// overdue, rescheduled every time the app opens. That is why [reschedule]
/// exists at all: a repeating notification would keep announcing whatever was
/// true the week it was set up, and a household that has since seen everybody
/// would be told for months that three people are overdue.
///
/// The cost of that choice is honest and worth naming: a member who never
/// opens the app gets one digest and then silence, because there is nobody to
/// recompute the next one. The alternative — a stale nudge repeating forever —
/// is worse, and a correct fix is a server, which the app deliberately does
/// not have.
class DigestController extends Notifier<DigestState> {
  @override
  DigestState build() => const DigestState();

  /// Records that this member wants the digest on [day] at [hour], or no
  /// digest at all when [day] is null, and schedules accordingly.
  ///
  /// Asks for notification permission first when turning the digest on. A
  /// refusal leaves the preference off rather than storing a preference the
  /// device will never honour, which is what stops the setting from reading
  /// "on" beside a system switch that says otherwise.
  Future<void> setPreference({required int? day, required int hour}) async {
    if (state.isBusy) return;

    final householdId = ref.read(currentHouseholdIdProvider);
    final uid = ref.read(currentUserProvider)?.id;
    if (householdId == null || uid == null) return;

    state = const DigestState(isBusy: true);

    if (day != null) {
      final permitted = await ref
          .read(notificationSchedulerProvider)
          .requestPermission();
      switch (permitted) {
        case Err(:final failure):
          state = DigestState(failure: failure);
          return;
        case Ok(value: false):
          state = const DigestState(isPermissionDenied: true);
          return;
        case Ok():
          break;
      }
    }

    final stored = await ref
        .read(householdRepositoryProvider)
        .setDigestPreference(
          householdId: householdId,
          uid: uid,
          digestDay: day,
          digestHour: hour,
        );
    if (stored case Err(:final failure)) {
      state = DigestState(failure: failure);
      return;
    }

    state = const DigestState();
    await _apply(day: day, hour: hour);
  }

  /// Brings what is scheduled into line with the stored preference and the
  /// current data. Called when the app opens.
  ///
  /// Silent: a scheduling error on app open is not something the user asked
  /// for and not something they can act on, so it is left in [state] for a
  /// screen to show if it wants rather than interrupting.
  Future<void> reschedule() async {
    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;
    final member = ref.read(currentMemberProvider(householdId));
    if (member == null) return;
    await _apply(day: member.digestDay, hour: member.digestHour);
  }

  /// Schedules the next digest, or cancels what is scheduled.
  ///
  /// Cancels rather than schedules when the digest is off, and also when it is
  /// on but has nothing to say: a notification whose whole content is "nobody
  /// is overdue" asks for attention in order to report that none is needed.
  Future<void> _apply({required int? day, required int hour}) async {
    final scheduler = ref.read(notificationSchedulerProvider);
    final householdId = ref.read(currentHouseholdIdProvider);

    final digest = householdId == null
        ? null
        : ref.read(weeklyDigestProvider(householdId));
    if (day == null || digest == null || digest.isEmpty) {
      final cancelled = await scheduler.cancelWeeklyDigest();
      if (cancelled case Err(:final failure)) {
        state = state.copyWith(failure: failure);
      }
      return;
    }

    // The device's language rather than a stored preference: a notification
    // reads in whatever the phone reads in, like the rest of the app.
    final l10n = ref.read(appLocalizationsProvider);
    final scheduled = await scheduler.scheduleWeeklyDigest(
      at: DigestSchedule.next(
        weekday: day,
        hour: hour,
        from: ref.read(clockProvider).now(),
      ),
      title: digest.title(l10n),
      body: digest.body(l10n),
    );
    if (scheduled case Err(:final failure)) {
      state = state.copyWith(failure: failure);
    }
  }
}

/// State of the weekly-digest setting.
final digestControllerProvider =
    NotifierProvider<DigestController, DigestState>(DigestController.new);
