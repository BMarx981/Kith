import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/app/widgets/app_splash.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/auth/presentation/sign_in_screen.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/household/domain/invite_code.dart';
import 'package:kith/features/household/presentation/household_screen.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_household_repository.dart';
import '../helpers/load_fonts.dart';
import '../helpers/pump_app.dart';

/// Pins the design language on the surfaces that exist today.
///
/// These are about the theme, not about behaviour: each screen is pumped in a
/// single settled state, in both brightnesses, at one phone-sized window. A
/// diff here means a palette, type or component change reached the pixels, so
/// regenerate them only when that was the point of the change.
///
/// Authored on macOS. Text rasterises differently on other platforms, so a
/// Linux CI would need its own set rather than a shared one.
void main() {
  const owner = AuthUser(id: 'uid-owner', email: 'brian@example.com');
  const partner = AuthUser(id: 'uid-partner', email: 'partner@example.com');

  const window = Size(400, 800);

  setUpAll(loadAppFonts);

  late FakeAuthService auth;
  late FakeHouseholdRepository repository;

  setUp(() {
    auth = FakeAuthService(initialUser: owner);
    addTearDown(auth.dispose);
    repository = FakeHouseholdRepository();
    addTearDown(repository.dispose);
  });

  List<Override> overrides() => [
    authServiceProvider.overrideWithValue(auth),
    householdRepositoryProvider.overrideWithValue(repository),
  ];

  /// Pumps [surface] at a fixed window size.
  ///
  /// A surface whose only motion is an indeterminate spinner never settles, so
  /// [settles] trades `pumpAndSettle` for a fixed advance: fake time makes the
  /// spinner land at the same angle every run.
  Future<void> pumpSurface(
    WidgetTester tester,
    Widget surface, {
    required ThemeData theme,
    bool settles = true,
  }) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpApp(surface, overrides: overrides(), theme: theme);
    if (settles) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  /// Runs [body] against both themes, naming each golden after the brightness.
  void goldenTest(
    String description,
    String file,
    Future<void> Function(WidgetTester tester, ThemeData theme) body,
  ) {
    for (final (name, theme) in [
      ('light', KithTheme.light),
      ('dark', KithTheme.dark),
    ]) {
      testWidgets('$description ($name)', (tester) async {
        await body(tester, theme);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('${file}_$name.png'),
        );
      });
    }
  }

  goldenTest('sign-in, waiting for credentials', 'sign_in', (
    tester,
    theme,
  ) async {
    await pumpSurface(tester, const SignInScreen(), theme: theme);
  });

  goldenTest('the household, its code and its members', 'household', (
    tester,
    theme,
  ) async {
    await repository.createHousehold(
      name: 'The Marx house',
      owner: owner,
      displayName: 'Brian',
    );
    await repository.joinWithInviteCode(
      code: 'KH7RQ2',
      user: partner,
      displayName: 'Partner',
    );
    // The fake creates households without a code; the invite card is one of
    // the surfaces worth pinning, so give it one.
    repository.households.updateAll(
      (_, household) => household.copyWith(
        inviteCode: InviteCode.parse('KH7RQ2').valueOrNull,
      ),
    );

    await pumpSurface(tester, const HouseholdScreen(), theme: theme);
  });

  goldenTest('the splash held before the first route', 'splash', (
    tester,
    theme,
  ) async {
    await pumpSurface(tester, const AppSplash(), theme: theme, settles: false);
  });
}
