import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/widgets/milestone_placeholder.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/suggestions/presentation/home_screen.dart';

import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/pump_app.dart';

void main() {
  const user = AuthUser(id: 'uid-1', email: 'brian@example.com');

  late FakeAuthService auth;

  setUp(() {
    auth = FakeAuthService(initialUser: user);
    addTearDown(auth.dispose);
  });

  List<Override> overrides() => [authServiceProvider.overrideWithValue(auth)];

  group('HomeScreen', () {
    testWidgets('renders a placeholder titled "Reconnect"', (tester) async {
      await tester.pumpApp(const HomeScreen(), overrides: overrides());

      expect(find.byType(MilestonePlaceholder), findsOneWidget);
      expect(find.text('Reconnect'), findsNWidgets(2));
    });

    testWidgets('is scheduled for M4', (tester) async {
      await tester.pumpApp(const HomeScreen(), overrides: overrides());

      expect(find.text('Arrives in M4'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
    });

    testWidgets('signs out from the app bar', (tester) async {
      await tester.pumpApp(const HomeScreen(), overrides: overrides());

      await tester.tap(find.byKey(HomeScreen.signOutKey));
      await tester.pumpAndSettle();

      expect(auth.currentUser, isNull);
    });
  });
}
