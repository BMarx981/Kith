import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/services/local_notification_scheduler.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/timezone.dart' as tz;

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockAndroid extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class _MockIos extends Mock implements IOSFlutterLocalNotificationsPlugin {}

void main() {
  late _MockPlugin plugin;

  setUpAll(() {
    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(tz.TZDateTime.utc(2026));
  });

  setUp(() {
    plugin = _MockPlugin();
    when(
      () => plugin.initialize(settings: any(named: 'settings')),
    ).thenAnswer((_) async => true);
    when(
      () => plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >(),
    ).thenReturn(null);
    when(
      () => plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >(),
    ).thenReturn(null);
  });

  LocalNotificationScheduler schedulerOf({
    String zone = 'America/New_York',
    Future<String> Function()? readTimeZoneName,
  }) => LocalNotificationScheduler(
    plugin: plugin,
    readTimeZoneName: readTimeZoneName ?? () async => zone,
  );

  void allowSchedule() => when(
    () => plugin.zonedSchedule(
      id: any(named: 'id'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      scheduledDate: any(named: 'scheduledDate'),
      notificationDetails: any(named: 'notificationDetails'),
      androidScheduleMode: any(named: 'androidScheduleMode'),
    ),
  ).thenAnswer((_) async {});

  group('scheduleWeeklyDigest', () {
    test('sends the digest under one stable id', () async {
      allowSchedule();

      final result = await schedulerOf().scheduleWeeklyDigest(
        at: DateTime(2026, 8, 23, 9),
        title: '3 people are overdue',
        body: 'Marcus, Ana and Ben.',
        channelName: 'Weekly digest',
        channelDescription: 'A weekly summary.',
      );

      expect(result.isOk, isTrue);
      // mocktail captures in the order the parameters are declared on
      // zonedSchedule: id, scheduledDate, androidScheduleMode, title, body.
      final sent = verify(
        () => plugin.zonedSchedule(
          id: captureAny(named: 'id'),
          title: captureAny(named: 'title'),
          body: captureAny(named: 'body'),
          scheduledDate: captureAny(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: captureAny(named: 'androidScheduleMode'),
        ),
      ).captured;
      expect(sent[0], LocalNotificationScheduler.digestId);
      expect(sent[2], AndroidScheduleMode.inexactAllowWhileIdle);
      expect(sent[3], '3 people are overdue');
      expect(sent[4], 'Marcus, Ana and Ben.');
    });

    test('posts on one channel id, under the copy it was given', () async {
      allowSchedule();

      await schedulerOf().scheduleWeeklyDigest(
        at: DateTime(2026, 8, 23, 9),
        title: 'title',
        body: 'body',
        channelName: 'Résumé hebdomadaire',
        channelDescription: 'Un résumé hebdomadaire.',
      );

      final details =
          verify(
                () => plugin.zonedSchedule(
                  id: any(named: 'id'),
                  title: any(named: 'title'),
                  body: any(named: 'body'),
                  scheduledDate: any(named: 'scheduledDate'),
                  notificationDetails: captureAny(named: 'notificationDetails'),
                  androidScheduleMode: any(named: 'androidScheduleMode'),
                ),
              ).captured.single
              as NotificationDetails;
      // The id is fixed so the channel survives a change of language; the name
      // and description are whatever the caller read out of the ARB files.
      expect(details.android?.channelId, LocalNotificationScheduler.channelId);
      expect(details.android?.channelName, 'Résumé hebdomadaire');
      expect(details.android?.channelDescription, 'Un résumé hebdomadaire.');
    });

    test('schedules in the device zone, at the hour asked for', () async {
      allowSchedule();

      await schedulerOf().scheduleWeeklyDigest(
        at: DateTime(2026, 8, 23, 9),
        title: 'title',
        body: 'body',
        channelName: 'Weekly digest',
        channelDescription: 'A weekly summary.',
      );

      final when_ =
          verify(
                () => plugin.zonedSchedule(
                  id: any(named: 'id'),
                  title: any(named: 'title'),
                  body: any(named: 'body'),
                  scheduledDate: captureAny(named: 'scheduledDate'),
                  notificationDetails: any(named: 'notificationDetails'),
                  androidScheduleMode: any(named: 'androidScheduleMode'),
                ),
              ).captured.single
              as tz.TZDateTime;
      expect(when_.location.name, 'America/New_York');
      // Whatever the zones, the instant is the one the caller named.
      expect(
        when_.millisecondsSinceEpoch,
        DateTime(2026, 8, 23, 9).millisecondsSinceEpoch,
      );
    });

    test('falls back to UTC when the zone cannot be read', () async {
      allowSchedule();

      await schedulerOf(
        readTimeZoneName: () async => throw StateError('no channel'),
      ).scheduleWeeklyDigest(
        at: DateTime.utc(2026, 8, 23, 9),
        title: 'title',
        body: 'body',
        channelName: 'Weekly digest',
        channelDescription: 'A weekly summary.',
      );

      expect(tz.local, tz.UTC);
    });

    test('falls back to UTC for a zone name nobody recognises', () async {
      allowSchedule();

      await schedulerOf(zone: 'Middle/Earth').scheduleWeeklyDigest(
        at: DateTime.utc(2026, 8, 23, 9),
        title: 'title',
        body: 'body',
        channelName: 'Weekly digest',
        channelDescription: 'A weekly summary.',
      );

      expect(tz.local, tz.UTC);
    });

    test('maps a platform error onto a domain failure', () async {
      when(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
        ),
      ).thenThrow(StateError('no alarm slots'));

      final result = await schedulerOf().scheduleWeeklyDigest(
        at: DateTime(2026, 8, 23, 9),
        title: 'title',
        body: 'body',
        channelName: 'Weekly digest',
        channelDescription: 'A weekly summary.',
      );

      expect(result.failureOrNull, isA<UnknownFailure>());
      expect(
        (result.failureOrNull! as UnknownFailure).cause,
        isA<StateError>(),
      );
    });

    test('initialises once across repeated calls', () async {
      allowSchedule();
      final scheduler = schedulerOf();

      await scheduler.scheduleWeeklyDigest(
        at: DateTime(2026, 8, 23, 9),
        title: 'a',
        body: 'b',
        channelName: 'Weekly digest',
        channelDescription: 'A weekly summary.',
      );
      await scheduler.scheduleWeeklyDigest(
        at: DateTime(2026, 8, 30, 9),
        title: 'c',
        body: 'd',
        channelName: 'Weekly digest',
        channelDescription: 'A weekly summary.',
      );

      verify(
        () => plugin.initialize(settings: any(named: 'settings')),
      ).called(1);
    });
  });

  group('cancelWeeklyDigest', () {
    test('cancels the digest id', () async {
      when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});

      final result = await schedulerOf().cancelWeeklyDigest();

      expect(result.isOk, isTrue);
      verify(
        () => plugin.cancel(id: LocalNotificationScheduler.digestId),
      ).called(1);
    });

    test('maps a platform error onto a domain failure', () async {
      when(
        () => plugin.cancel(id: any(named: 'id')),
      ).thenThrow(StateError('gone'));

      final result = await schedulerOf().cancelWeeklyDigest();

      expect(result.failureOrNull, isA<UnknownFailure>());
    });
  });

  group('requestPermission', () {
    test('asks Android when Android is what is there', () async {
      final android = _MockAndroid();
      when(
        android.requestNotificationsPermission,
      ).thenAnswer((_) async => true);
      when(
        () => plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >(),
      ).thenReturn(android);

      final result = await schedulerOf().requestPermission();

      expect(result.valueOrNull, isTrue);
      verify(android.requestNotificationsPermission).called(1);
    });

    test('reads a refusal as false rather than as a failure', () async {
      final android = _MockAndroid();
      when(
        android.requestNotificationsPermission,
      ).thenAnswer((_) async => false);
      when(
        () => plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >(),
      ).thenReturn(android);

      final result = await schedulerOf().requestPermission();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isFalse);
    });

    test('reads an unanswered ask as false', () async {
      final android = _MockAndroid();
      when(
        android.requestNotificationsPermission,
      ).thenAnswer((_) async => null);
      when(
        () => plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >(),
      ).thenReturn(android);

      expect((await schedulerOf().requestPermission()).valueOrNull, isFalse);
    });

    test('asks iOS for alert, badge and sound when iOS is there', () async {
      final ios = _MockIos();
      when(
        () => ios.requestPermissions(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >(),
      ).thenReturn(ios);

      final result = await schedulerOf().requestPermission();

      expect(result.valueOrNull, isTrue);
      verify(
        () => ios.requestPermissions(alert: true, badge: true, sound: true),
      ).called(1);
    });

    test('answers false on a platform with nothing to grant', () async {
      final result = await schedulerOf().requestPermission();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isFalse);
    });

    test('maps a platform error onto a domain failure', () async {
      final android = _MockAndroid();
      when(android.requestNotificationsPermission).thenThrow(StateError('no'));
      when(
        () => plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >(),
      ).thenReturn(android);

      final result = await schedulerOf().requestPermission();

      expect(result.failureOrNull, isA<UnknownFailure>());
    });
  });
}
