import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/services/notification_scheduler.dart';

/// An in-memory [NotificationScheduler] for unit and widget tests.
///
/// Records what was asked of it rather than doing anything, which is the whole
/// point of the seam: there is no native notification system under
/// `flutter test`, so what the tests can check is the decision — schedule
/// this, at that time, saying that; or cancel — and not the delivery.
class FakeNotificationScheduler implements NotificationScheduler {
  /// Arguments of every [scheduleWeeklyDigest] call, oldest first.
  final scheduled = <({DateTime at, String title, String body})>[];

  /// How many times [cancelWeeklyDigest] was called.
  int cancelCount = 0;

  /// How many times [requestPermission] was called.
  int permissionAsks = 0;

  /// What [requestPermission] answers. False stands in for a user who
  /// declined the system prompt.
  bool permissionGranted = true;

  /// Failure to return from the next call to any method, instead of
  /// succeeding. Cleared once consumed.
  Failure? nextFailure;

  /// The most recent thing scheduled, or null if nothing is.
  ({DateTime at, String title, String body})? get lastScheduled =>
      scheduled.isEmpty ? null : scheduled.last;

  @override
  Future<Result<bool>> requestPermission() async {
    permissionAsks++;
    final failure = _takeFailure();
    return failure != null ? Err(failure) : Ok(permissionGranted);
  }

  @override
  Future<Result<void>> scheduleWeeklyDigest({
    required DateTime at,
    required String title,
    required String body,
  }) async {
    scheduled.add((at: at, title: title, body: body));
    final failure = _takeFailure();
    return failure != null ? Err(failure) : const Ok(null);
  }

  @override
  Future<Result<void>> cancelWeeklyDigest() async {
    cancelCount++;
    final failure = _takeFailure();
    return failure != null ? Err(failure) : const Ok(null);
  }

  Failure? _takeFailure() {
    final failure = nextFailure;
    nextFailure = null;
    return failure;
  }
}
