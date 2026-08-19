import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kith/app/app.dart';
import 'package:kith/app/bootstrap.dart';
import 'package:kith/data/repositories/firestore_hangout_repository.dart';
import 'package:kith/data/repositories/firestore_household_repository.dart';
import 'package:kith/data/repositories/firestore_planned_hangout_repository.dart';
import 'package:kith/data/services/firebase_auth_service.dart';
import 'package:kith/data/services/google_calendar_directory.dart';
import 'package:kith/data/services/google_calendar_sink.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/calendar/application/calendar_providers.dart';
import 'package:kith/features/calendar/application/calendar_sync_service.dart';
import 'package:kith/features/contacts/application/contact_import_controller.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/notifications/application/notification_providers.dart';
import 'package:kith/features/suggestions/application/suggestion_providers.dart';

import '../helpers/fake_device_contact_directory.dart';
import '../helpers/fake_google_sign_in_service.dart';
import '../helpers/fake_notification_scheduler.dart';

void main() {
  group('firebaseOverrides', () {
    // The Google half is faked: the plugin has no implementation under
    // `flutter test`, and a real http.Client would open a socket.
    List<Override> overrides() => firebaseOverrides(
      auth: MockFirebaseAuth(),
      firestore: FakeFirebaseFirestore(),
      googleSignIn: FakeGoogleSignInService(),
      httpClient: MockClient((_) async => http.Response('{}', 200)),
      scheduler: FakeNotificationScheduler(),
      deviceContacts: FakeDeviceContactDirectory(),
    );

    test('binds authServiceProvider to the Firebase implementation', () {
      final container = ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);

      expect(container.read(authServiceProvider), isA<FirebaseAuthService>());
    });

    test('binds householdRepositoryProvider to the Firestore repository', () {
      final container = ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);

      expect(
        container.read(householdRepositoryProvider),
        isA<FirestoreHouseholdRepository>(),
      );
    });

    test('binds deviceContactDirectoryProvider to the one it was given', () {
      final directory = FakeDeviceContactDirectory();
      final container = ProviderContainer(
        overrides: firebaseOverrides(
          auth: MockFirebaseAuth(),
          firestore: FakeFirebaseFirestore(),
          googleSignIn: FakeGoogleSignInService(),
          httpClient: MockClient((_) async => http.Response('{}', 200)),
          scheduler: FakeNotificationScheduler(),
          deviceContacts: directory,
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(deviceContactDirectoryProvider), same(directory));
    });

    test('binds notificationSchedulerProvider to the one it was given', () {
      final scheduler = FakeNotificationScheduler();
      final container = ProviderContainer(
        overrides: firebaseOverrides(
          auth: MockFirebaseAuth(),
          firestore: FakeFirebaseFirestore(),
          googleSignIn: FakeGoogleSignInService(),
          httpClient: MockClient((_) async => http.Response('{}', 200)),
          scheduler: scheduler,
          deviceContacts: FakeDeviceContactDirectory(),
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(notificationSchedulerProvider), same(scheduler));
    });

    test('binds hangoutRepositoryProvider to the Firestore repository', () {
      final container = ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);

      expect(
        container.read(hangoutRepositoryProvider),
        isA<FirestoreHangoutRepository>(),
      );
    });

    test(
      'binds plannedHangoutRepositoryProvider to the Firestore repository',
      () {
        final container = ProviderContainer(overrides: overrides());
        addTearDown(container.dispose);

        expect(
          container.read(plannedHangoutRepositoryProvider),
          isA<FirestorePlannedHangoutRepository>(),
        );
      },
    );

    test('binds the calendar seams to the Google implementations', () {
      final container = ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);

      expect(container.read(calendarSinkProvider), isA<GoogleCalendarSink>());
      expect(
        container.read(calendarDirectoryProvider),
        isA<GoogleCalendarDirectory>(),
      );
      expect(
        container.read(calendarSyncServiceProvider),
        isA<CalendarSyncService>(),
      );
    });

    test('signs in and authorises the calendar through one account', () {
      final google = FakeGoogleSignInService();
      final container = ProviderContainer(
        overrides: firebaseOverrides(
          auth: MockFirebaseAuth(),
          firestore: FakeFirebaseFirestore(),
          googleSignIn: google,
          httpClient: MockClient((_) async => http.Response('{}', 200)),
          scheduler: FakeNotificationScheduler(),
          deviceContacts: FakeDeviceContactDirectory(),
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(googleSignInServiceProvider), same(google));
    });

    test('hands the sink the account token, asked for per call', () async {
      final google = FakeGoogleSignInService()..token = 'tok_123';
      final sent = <String?>[];
      final container = ProviderContainer(
        overrides: firebaseOverrides(
          auth: MockFirebaseAuth(),
          firestore: FakeFirebaseFirestore(),
          googleSignIn: google,
          httpClient: MockClient((request) async {
            sent.add(request.headers['Authorization']);
            return http.Response('{}', 404);
          }),
          scheduler: FakeNotificationScheduler(),
          deviceContacts: FakeDeviceContactDirectory(),
        ),
      );
      addTearDown(container.dispose);

      await container
          .read(calendarSinkProvider)
          .fetchEvent(
            calendarId: 'cal-1',
            eventId: 'evt_1',
          );
      await container.read(calendarDirectoryProvider).listCalendars();

      expect(sent, ['Bearer tok_123', 'Bearer tok_123']);
      expect(google.existingCalls, hasLength(2));
    });

    testWidgets('is enough to mount the app', (tester) async {
      await tester.pumpWidget(
        ProviderScope(overrides: overrides(), child: const KithApp()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(KithApp), findsOneWidget);
    });
  });
}
