import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/app.dart';
import 'package:kith/app/bootstrap.dart';
import 'package:kith/data/repositories/firestore_hangout_repository.dart';
import 'package:kith/data/repositories/firestore_household_repository.dart';
import 'package:kith/data/repositories/firestore_planned_hangout_repository.dart';
import 'package:kith/data/services/firebase_auth_service.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/suggestions/application/suggestion_providers.dart';

void main() {
  group('firebaseOverrides', () {
    List<Override> overrides() => firebaseOverrides(
      auth: MockFirebaseAuth(),
      firestore: FakeFirebaseFirestore(),
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

    testWidgets('is enough to mount the app', (tester) async {
      await tester.pumpWidget(
        ProviderScope(overrides: overrides(), child: const KithApp()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(KithApp), findsOneWidget);
    });
  });
}
