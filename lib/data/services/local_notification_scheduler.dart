import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/services/notification_scheduler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Reads the device's IANA timezone name, e.g. `Europe/London`.
///
/// A function rather than a call inline so a test can pin the zone: the
/// platform channel behind it has no implementation under `flutter test`.
typedef TimeZoneNameReader = Future<String> Function();

/// The [NotificationScheduler] the app ships, over
/// `flutter_local_notifications`.
///
/// Deliberately thin. Everything worth testing — what the digest says, when it
/// next fires — is pure and lives in `features/notifications/domain`; what is
/// left here is initialisation, one schedule call and one cancel, plus the
/// mapping of anything the platform throws onto a domain failure.
///
/// Times are zoned rather than instants. `timezone` ships the database but
/// cannot ask the phone which zone it is in, so [TimeZoneNameReader] supplies
/// the name and `tz.local` is set from it before anything is scheduled. On a
/// device whose zone cannot be read the scheduler falls back to UTC, which
/// fires at the wrong hour rather than not at all.
class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    TimeZoneNameReader? readTimeZoneName,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _readTimeZoneName = readTimeZoneName ?? _deviceTimeZoneName;

  final FlutterLocalNotificationsPlugin _plugin;
  final TimeZoneNameReader _readTimeZoneName;

  var _ready = false;

  /// Notification id for the weekly digest.
  ///
  /// A constant, because only ever one digest is outstanding: scheduling again
  /// replaces the last one rather than stacking a second notification behind
  /// it, which is what lets the app refresh stale content by rescheduling.
  static const digestId = 1;

  /// Android channel the digest is posted on. Named for what it is, because
  /// the user sees this string in the system notification settings.
  static const channelId = 'kith_weekly_digest';

  /// Human name of [channelId], as Android shows it.
  static const channelName = 'Weekly digest';

  /// What [channelId] is for, as Android shows it.
  static const channelDescription =
      'A weekly summary of who you are overdue to see.';

  /// The icon Android draws in the status bar. `@mipmap/ic_launcher` is the
  /// launcher icon every Flutter project ships with, so no new asset is
  /// needed.
  static const androidIcon = '@mipmap/ic_launcher';

  @override
  Future<Result<bool>> requestPermission() async {
    try {
      await _ensureReady();
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return Ok(await android.requestNotificationsPermission() ?? false);
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return Ok(granted ?? false);
      }
      // A platform with no notification support of its own. Not a failure to
      // report; there is simply nothing to grant.
      return const Ok(false);
    } on Object catch (error) {
      return Err(_failure('Could not ask for notification permission.', error));
    }
  }

  @override
  Future<Result<void>> scheduleWeeklyDigest({
    required DateTime at,
    required String title,
    required String body,
  }) async {
    try {
      await _ensureReady();
      await _plugin.zonedSchedule(
        id: digestId,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            icon: androidIcon,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // Inexact on purpose: an exact alarm needs SCHEDULE_EXACT_ALARM, which
        // Android grants grudgingly and reserves for alarms and timers. A
        // weekly summary that arrives within the hour is the same summary.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return const Ok(null);
    } on Object catch (error) {
      return Err(_failure('Could not schedule the weekly digest.', error));
    }
  }

  @override
  Future<Result<void>> cancelWeeklyDigest() async {
    try {
      await _ensureReady();
      await _plugin.cancel(id: digestId);
      return const Ok(null);
    } on Object catch (error) {
      return Err(_failure('Could not cancel the weekly digest.', error));
    }
  }

  /// Loads the timezone database, points `tz.local` at the device's zone and
  /// initialises the plugin. Runs once; every entry point awaits it.
  Future<void> _ensureReady() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await _readTimeZoneName()));
    } on Object {
      // An unreadable or unrecognised zone name leaves tz.local at UTC. Worth
      // swallowing rather than refusing to schedule: a digest an hour out of
      // place still says what it came to say.
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(androidIcon),
        // Asked for explicitly by requestPermission, at the moment the user
        // turns the digest on, rather than on the app's first launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  static Future<String> _deviceTimeZoneName() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;

  /// Anything the platform throws, as a domain failure.
  ///
  /// One kind, because the plugin does not distinguish: a refused permission
  /// comes back as `false` from [requestPermission] rather than as a throw,
  /// so what is left here is genuinely unexpected.
  static Failure _failure(String message, Object cause) =>
      UnknownFailure(message, cause: cause);
}
