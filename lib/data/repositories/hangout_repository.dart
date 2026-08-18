import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/features/hangouts/domain/hangout_draft.dart';

/// Reads and writes a household's logged meetups.
///
/// Implementations translate backend errors into domain failures before
/// returning; nothing above this interface sees a `FirebaseException`.
abstract interface class HangoutRepository {
  /// Every hangout in [householdId], most recent day first.
  ///
  /// One stream for the whole household rather than a query per contact: the
  /// timeline, each contact's history and every freshness gauge in the app
  /// are all views of the same small list, and watching it once is what makes
  /// a hangout logged on one device move the gauges on the other immediately.
  Stream<List<Hangout>> watchHangouts(String householdId);

  /// Logs [draft] in [householdId], crediting [createdBy] with the entry.
  ///
  /// The draft is normalised first, then checked: a hangout naming nobody
  /// comes back as a `ValidationFailure` without any I/O.
  Future<Result<Hangout>> logHangout({
    required String householdId,
    required HangoutDraft draft,
    required String createdBy,
  });

  /// Applies [draft] to the hangout [hangoutId] in [householdId].
  ///
  /// Touches only the fields a draft carries, so who logged it and when they
  /// logged it survive an edit to the date or the note.
  Future<Result<void>> updateHangout({
    required String householdId,
    required String hangoutId,
    required HangoutDraft draft,
  });

  /// Removes the hangout [hangoutId] from [householdId].
  ///
  /// Hangouts do delete, unlike contacts: a meetup logged against the wrong
  /// person is a mistake in the record rather than history worth keeping, and
  /// there is nothing hanging off a hangout to orphan.
  Future<Result<void>> deleteHangout({
    required String householdId,
    required String hangoutId,
  });
}
