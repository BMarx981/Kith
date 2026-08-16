import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/app.dart';
import 'package:kith/app/bootstrap.dart';
import 'package:kith/data/services/firebase_auth_service.dart';
import 'package:kith/features/auth/application/auth_providers.dart';

void main() {
  group('firebaseOverrides', () {
    test('binds authServiceProvider to the Firebase implementation', () {
      final container = ProviderContainer(
        overrides: firebaseOverrides(auth: MockFirebaseAuth()),
      );
      addTearDown(container.dispose);

      expect(container.read(authServiceProvider), isA<FirebaseAuthService>());
    });

    testWidgets('is enough to mount the app', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: firebaseOverrides(auth: MockFirebaseAuth()),
          child: const KithApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(KithApp), findsOneWidget);
    });
  });
}
