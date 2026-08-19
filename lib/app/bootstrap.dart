import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:http/http.dart' as http;
import 'package:kith/data/repositories/firestore_contact_repository.dart';
import 'package:kith/data/repositories/firestore_hangout_repository.dart';
import 'package:kith/data/repositories/firestore_household_repository.dart';
import 'package:kith/data/repositories/firestore_planned_hangout_repository.dart';
import 'package:kith/data/repositories/firestore_relationship_type_repository.dart';
import 'package:kith/data/services/device_contact_directory.dart';
import 'package:kith/data/services/firebase_auth_service.dart';
import 'package:kith/data/services/google_calendar_directory.dart';
import 'package:kith/data/services/google_calendar_sink.dart';
import 'package:kith/data/services/google_sign_in_service.dart';
import 'package:kith/data/services/notification_scheduler.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/calendar/application/calendar_providers.dart';
import 'package:kith/features/calendar/domain/calendar_scopes.dart';
import 'package:kith/features/contacts/application/contact_import_controller.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/notifications/application/notification_providers.dart';
import 'package:kith/features/suggestions/application/suggestion_providers.dart';

/// Provider overrides that bind the graph to live Firebase and Google
/// services.
///
/// The entry point and its test share this list, so the wiring under test is
/// the wiring that ships. Firebase itself must already be initialised.
///
/// Every collaborator is passed in rather than built here, the entry point's
/// job being to decide what the real ones are: the test binds the same graph
/// over fakes, without the plugin's platform channels or a socket.
///
/// [googleSignIn] does double duty. It is how a member signs in, and it is
/// where the calendar scopes are granted, so both go through one account
/// rather than two sessions of the same one.
/// [scheduler] and [deviceContacts] are the device's notification system and
/// its address book, and are passed in for the same reason the rest are: under
/// `flutter test` there is no native side to either, so the test binds fakes
/// and the entry point binds the plugins.
List<Override> firebaseOverrides({
  required FirebaseAuth auth,
  required FirebaseFirestore firestore,
  required GoogleSignInService googleSignIn,
  required http.Client httpClient,
  required NotificationScheduler scheduler,
  required DeviceContactDirectory deviceContacts,
}) {
  // Consulted per call rather than held: an access token that expired between
  // two writes is refreshed by asking again, and a member who has not granted
  // the scopes simply has none.
  Future<String?> accessToken() =>
      googleSignIn.existingAccessToken(CalendarScopes.all);

  return [
    authServiceProvider.overrideWithValue(
      FirebaseAuthService(auth, googleSignIn),
    ),
    googleSignInServiceProvider.overrideWithValue(googleSignIn),
    calendarSinkProvider.overrideWithValue(
      GoogleCalendarSink(httpClient: httpClient, accessToken: accessToken),
    ),
    calendarDirectoryProvider.overrideWithValue(
      GoogleCalendarDirectory(
        httpClient: httpClient,
        accessToken: accessToken,
      ),
    ),
    householdRepositoryProvider.overrideWithValue(
      FirestoreHouseholdRepository(firestore, Random.secure()),
    ),
    contactRepositoryProvider.overrideWithValue(
      FirestoreContactRepository(firestore),
    ),
    relationshipTypeRepositoryProvider.overrideWithValue(
      FirestoreRelationshipTypeRepository(firestore),
    ),
    hangoutRepositoryProvider.overrideWithValue(
      FirestoreHangoutRepository(firestore),
    ),
    plannedHangoutRepositoryProvider.overrideWithValue(
      FirestorePlannedHangoutRepository(firestore),
    ),
    notificationSchedulerProvider.overrideWithValue(scheduler),
    deviceContactDirectoryProvider.overrideWithValue(deviceContacts),
  ];
}
