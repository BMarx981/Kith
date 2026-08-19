import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/models/household.dart';
import 'package:kith/data/models/member.dart';

/// Reads and writes the household a signed-in user shares with their partner.
///
/// Implementations translate backend errors into domain failures before
/// returning; nothing above this interface sees a `FirebaseException`. The
/// streams emit domain models and, on failure, a `Failure` rather than a
/// Firebase error.
abstract interface class HouseholdRepository {
  /// Creates a household named [name] with [owner] as its first member.
  ///
  /// [displayName] is what the other members see, and is asked for during
  /// onboarding because an email sign-up carries no name of its own.
  ///
  /// Reserves an unused invite code as part of the same flow; a code that
  /// collides with an existing one is retried before giving up with a
  /// `ConflictFailure`.
  Future<Result<Household>> createHousehold({
    required String name,
    required AuthUser owner,
    required String displayName,
  });

  /// Joins the household that [code] points at, as [user].
  ///
  /// Fails with a `ValidationFailure` if the code is not well formed and a
  /// `NotFoundFailure` if it matches no household, including the case where
  /// the code was valid once but has since been rotated.
  Future<Result<Household>> joinWithInviteCode({
    required String code,
    required AuthUser user,
    required String displayName,
  });

  /// The household [householdId], emitting again on every change.
  ///
  /// Emits null when the household does not exist, which is what a member who
  /// has been removed sees.
  Stream<Household?> watchHousehold(String householdId);

  /// The members of [householdId], longest-standing first.
  Stream<List<Member>> watchMembers(String householdId);

  /// The ids of the households [uid] belongs to, longest-standing first.
  ///
  /// This is how a returning user finds their household on cold start: the
  /// membership document is the only record of it, so the question is asked of
  /// the membership documents directly rather than of a copy kept elsewhere.
  ///
  /// Emits an empty list for a user who belongs to none, which is what sends a
  /// freshly signed-up user into onboarding, and emits again when they are
  /// added to or removed from one. v1 puts a user in a single household; the
  /// list is what the data can actually hold, and callers pick from it.
  Stream<List<String>> watchHouseholdIdsFor(String uid);

  /// Points [householdId] at the Google Calendar [calendarId], named
  /// [calendarName].
  ///
  /// Any member may link, not just the owner: the calendar the frame reads is
  /// household property, and either partner setting it up is the point. The
  /// OAuth grant that made the pick is the linking member's own and is never
  /// stored, so this writes the choice and nothing else.
  ///
  /// Comes back as a `ValidationFailure` without any I/O for an empty or
  /// over-long id or name.
  Future<Result<void>> linkCalendar({
    required String householdId,
    required String calendarId,
    required String calendarName,
  });

  /// Records that [uid] wants the weekly digest on [digestDay] at
  /// [digestHour], or no digest at all when [digestDay] is null.
  ///
  /// A self-write: a member sets their own preference and nobody else's, which
  /// is what the security rule enforces. [digestHour] is kept even while the
  /// digest is off, so turning it back on does not lose the time they picked.
  ///
  /// Comes back as a `ValidationFailure` without any I/O for a day that is not
  /// a weekday or an hour outside 0-23.
  Future<Result<void>> setDigestPreference({
    required String householdId,
    required String uid,
    required int? digestDay,
    required int digestHour,
  });

  /// Stops writing [householdId]'s plans to a calendar.
  ///
  /// Events already on the calendar are left where they are: they are the
  /// household's now, and silently clearing a shared calendar because somebody
  /// unlinked would be the app deleting what it does not own. The plans keep
  /// their `calendarEventId`, so relinking the same calendar finds them again.
  Future<Result<void>> unlinkCalendar({required String householdId});
}
