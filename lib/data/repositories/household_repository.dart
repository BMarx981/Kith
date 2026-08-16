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
}
