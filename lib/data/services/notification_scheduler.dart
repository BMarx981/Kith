import 'package:kith/core/result/result.dart';

/// Posts the household's weekly digest to the device's notification tray.
///
/// A seam over the platform, for the same reason `CalendarSink` is one: the
/// scheduling itself is untestable under `flutter test` — there is no native
/// side — so everything above this interface is written against it and the one
/// implementation that talks to the plugin is kept as thin as it can be.
///
/// Only one digest is ever outstanding, so the methods name it rather than
/// taking an id: scheduling replaces whatever was scheduled before, which is
/// what lets the app refresh stale content by simply scheduling again.
abstract interface class NotificationScheduler {
  /// Asks the user to allow notifications, returning whether they are now
  /// allowed.
  ///
  /// Answering false is not a failure: declining a permission prompt is a
  /// choice, and the caller turns the digest back off rather than reporting an
  /// error. An `Err` means the ask itself could not be made.
  Future<Result<bool>> requestPermission();

  /// Schedules the digest to appear at [at], replacing any already scheduled.
  ///
  /// [at] is a local wall-clock instant. It is a one-shot rather than a
  /// repeating notification: the digest's text is a snapshot of who is overdue
  /// *now*, and a notification that repeats forever would keep announcing a
  /// week that has long since passed. The app schedules the next one every
  /// time it opens, so the content is never older than the last visit.
  Future<Result<void>> scheduleWeeklyDigest({
    required DateTime at,
    required String title,
    required String body,
  });

  /// Cancels the scheduled digest, if there is one. Cancelling when nothing is
  /// scheduled is not an error.
  Future<Result<void>> cancelWeeklyDigest();
}
