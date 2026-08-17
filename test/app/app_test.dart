import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/app.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/app/widgets/app_splash.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/auth/presentation/sign_in_screen.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/suggestions/presentation/home_screen.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_household_repository.dart';

void main() {
  const user = AuthUser(id: 'uid-1', email: 'brian@example.com');

  late FakeHouseholdRepository households;

  // The signed-in user here already belongs to a household, so the household
  // guard waves them through and these tests stay about booting the app.
  setUp(() async {
    households = FakeHouseholdRepository();
    addTearDown(households.dispose);
    await households.createHousehold(
      name: 'The Marx house',
      owner: user,
      displayName: 'Brian',
    );
  });

  Future<void> pumpKithApp(WidgetTester tester, FakeAuthService auth) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          householdRepositoryProvider.overrideWithValue(households),
        ],
        child: const KithApp(),
      ),
    );
  }

  group('KithApp', () {
    testWidgets('boots a signed-in user into the home screen', (tester) async {
      final auth = FakeAuthService(initialUser: user);
      addTearDown(auth.dispose);

      await pumpKithApp(tester, auth);
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('boots a signed-out user into the sign-in screen', (
      tester,
    ) async {
      final auth = FakeAuthService();
      addTearDown(auth.dispose);

      await pumpKithApp(tester, auth);
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('fills the wait for the auth state with the splash', (
      tester,
    ) async {
      final auth = FakeAuthService();
      addTearDown(auth.dispose);

      await pumpKithApp(tester, auth);

      expect(find.byType(AppSplash), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('supplies both light and dark themes', (tester) async {
      final auth = FakeAuthService(initialUser: user);
      addTearDown(auth.dispose);

      await pumpKithApp(tester, auth);
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(app.title, 'Kith');
      expect(app.theme?.colorScheme.brightness, Brightness.light);
      expect(app.darkTheme?.colorScheme.brightness, Brightness.dark);
      expect(app.theme?.extension<FreshnessColors>(), isNotNull);
      expect(app.darkTheme?.extension<FreshnessColors>(), isNotNull);
    });
  });
}
