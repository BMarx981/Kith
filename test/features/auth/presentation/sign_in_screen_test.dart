import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/auth/domain/credential_validator.dart';
import 'package:kith/features/auth/presentation/sign_in_screen.dart';

import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/pump_app.dart';

/// A fake whose sign-in only finishes when the test says so, which is the
/// only way to observe the form mid-request.
class _GatedAuthService extends FakeAuthService {
  final gate = Completer<void>();

  @override
  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await gate.future;
    return super.signInWithEmail(email: email, password: password);
  }
}

void main() {
  late FakeAuthService auth;

  setUp(() {
    auth = FakeAuthService();
    addTearDown(auth.dispose);
  });

  List<Override> overrides() => [
    authServiceProvider.overrideWithValue(auth),
  ];

  Future<void> pumpScreen(WidgetTester tester) =>
      tester.pumpApp(const SignInScreen(), overrides: overrides());

  Future<void> enterCredentials(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await tester.enterText(find.byKey(SignInScreen.emailFieldKey), email);
    await tester.enterText(find.byKey(SignInScreen.passwordFieldKey), password);
  }

  group('SignInScreen diagnostics', () {
    testWidgets('shows the underlying error when the copy cannot say what '
        'went wrong', (tester) async {
      // Debug builds only. Without this the raw Firebase text is captured and
      // then thrown away, so an unrecognised code is indistinguishable from
      // every other unrecognised code.
      auth.nextFailure = const AuthFailure(
        AuthFailureReason.unknown,
        'An internal error has occurred. [ CONFIGURATION_NOT_FOUND ]',
      );
      await pumpScreen(tester);
      await enterCredentials(
        tester,
        email: 'brian@example.com',
        password: 'hunter22',
      );

      await tester.tap(find.byKey(SignInScreen.submitButtonKey));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong. Try again.'), findsOneWidget);
      expect(
        find.textContaining('CONFIGURATION_NOT_FOUND'),
        findsOneWidget,
      );
    });

    testWidgets('keeps the log message out of a failure it has copy for', (
      tester,
    ) async {
      auth.nextFailure = const AuthFailure(
        AuthFailureReason.invalidCredentials,
        'FIREBASE_INTERNAL_DETAIL',
      );
      await pumpScreen(tester);
      await enterCredentials(
        tester,
        email: 'brian@example.com',
        password: 'hunter22',
      );

      await tester.tap(find.byKey(SignInScreen.submitButtonKey));
      await tester.pumpAndSettle();

      expect(find.textContaining('FIREBASE_INTERNAL_DETAIL'), findsNothing);
    });
  });

  group('SignInScreen', () {
    testWidgets('opens on the sign-in form', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Sign in to your household.'), findsOneWidget);
      expect(find.byKey(SignInScreen.emailFieldKey), findsOneWidget);
      expect(find.byKey(SignInScreen.passwordFieldKey), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    });

    testWidgets('offers no Apple button until it works', (tester) async {
      await pumpScreen(tester);

      expect(find.textContaining('Apple'), findsNothing);
    });

    testWidgets('validates the fields before calling the backend', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(SignInScreen.submitButtonKey));
      await tester.pump();

      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      expect(auth.currentUser, isNull);
    });

    testWidgets('rejects a malformed address without a round trip', (
      tester,
    ) async {
      await pumpScreen(tester);

      await enterCredentials(tester, email: 'brian', password: 'hunter22');
      await tester.tap(find.byKey(SignInScreen.submitButtonKey));
      await tester.pump();

      expect(
        find.text('That does not look like an email address.'),
        findsOneWidget,
      );
      expect(auth.currentUser, isNull);
    });

    testWidgets('signs into an existing account', (tester) async {
      auth.seedAccount(email: 'brian@example.com', password: 'hunter22');
      await pumpScreen(tester);

      await enterCredentials(
        tester,
        email: 'brian@example.com',
        password: 'hunter22',
      );
      await tester.tap(find.byKey(SignInScreen.submitButtonKey));
      await tester.pumpAndSettle();

      expect(auth.currentUser?.email, 'brian@example.com');
    });

    testWidgets('submitting from the password field works too', (tester) async {
      auth.seedAccount(email: 'brian@example.com', password: 'hunter22');
      await pumpScreen(tester);

      await enterCredentials(
        tester,
        email: 'brian@example.com',
        password: 'hunter22',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(auth.currentUser?.email, 'brian@example.com');
    });

    testWidgets('shows why the backend refused', (tester) async {
      auth.seedAccount(email: 'brian@example.com', password: 'hunter22');
      await pumpScreen(tester);

      await enterCredentials(
        tester,
        email: 'brian@example.com',
        password: 'wrong-password',
      );
      await tester.tap(find.byKey(SignInScreen.submitButtonKey));
      await tester.pumpAndSettle();

      expect(
        find.text('That email and password do not match an account.'),
        findsOneWidget,
      );
    });

    testWidgets('disables the form while the request is in flight', (
      tester,
    ) async {
      final gated = _GatedAuthService()
        ..seedAccount(email: 'brian@example.com', password: 'hunter22');
      addTearDown(gated.dispose);
      await tester.pumpApp(
        const SignInScreen(),
        overrides: [authServiceProvider.overrideWithValue(gated)],
      );

      await enterCredentials(
        tester,
        email: 'brian@example.com',
        password: 'hunter22',
      );
      await tester.tap(find.byKey(SignInScreen.submitButtonKey));
      await tester.pump();

      final submit = tester.widget<FilledButton>(
        find.byKey(SignInScreen.submitButtonKey),
      );
      expect(submit.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).enabled,
        isFalse,
      );

      gated.gate.complete();
      await tester.pumpAndSettle();
      expect(gated.currentUser?.email, 'brian@example.com');
    });

    testWidgets('switches to creating an account', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(SignInScreen.modeToggleKey));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, 'Create account'),
        findsOneWidget,
      );
      expect(find.byKey(SignInScreen.forgotPasswordKey), findsNothing);
    });

    testWidgets('holds new passwords to the minimum length', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(SignInScreen.modeToggleKey));
      await tester.pumpAndSettle();

      await enterCredentials(
        tester,
        email: 'new@example.com',
        password: 'short',
      );
      await tester.tap(find.byKey(SignInScreen.submitButtonKey));
      await tester.pump();

      expect(
        find.text(
          'Use at least ${CredentialValidator.minPasswordLength} characters.',
        ),
        findsOneWidget,
      );
      expect(auth.currentUser, isNull);
    });

    testWidgets('creates an account in sign-up mode', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(SignInScreen.modeToggleKey));
      await tester.pumpAndSettle();

      await enterCredentials(
        tester,
        email: 'new@example.com',
        password: 'hunter22',
      );
      await tester.tap(find.byKey(SignInScreen.submitButtonKey));
      await tester.pumpAndSettle();

      expect(auth.currentUser?.email, 'new@example.com');
    });

    testWidgets('confirms a password reset by naming the address', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.byKey(SignInScreen.emailFieldKey),
        'brian@example.com',
      );
      await tester.tap(find.byKey(SignInScreen.forgotPasswordKey));
      await tester.pumpAndSettle();

      expect(auth.resetEmailsSent, ['brian@example.com']);
      expect(
        find.text('Password reset link sent to brian@example.com.'),
        findsOneWidget,
      );
    });

    testWidgets('reset with an unusable address reports it inline', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(SignInScreen.forgotPasswordKey));
      await tester.pumpAndSettle();

      expect(auth.resetEmailsSent, isEmpty);
      expect(
        find.text('That does not look like an email address.'),
        findsOneWidget,
      );
    });

    testWidgets('toggles password visibility', (tester) async {
      await pumpScreen(tester);

      expect(find.byIcon(KithIcons.showPassword), findsOneWidget);
      await tester.tap(find.byIcon(KithIcons.showPassword));
      await tester.pumpAndSettle();

      expect(find.byIcon(KithIcons.hidePassword), findsOneWidget);
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(SignInScreen.passwordFieldKey),
          matching: find.byType(TextField),
        ),
      );
      expect(field.obscureText, isFalse);
    });
  });

  group('Google sign-in', () {
    testWidgets('offers a Google button', (tester) async {
      await pumpScreen(tester);

      expect(find.byKey(SignInScreen.googleButtonKey), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('signs in through Google when tapped', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(SignInScreen.googleButtonKey));
      await tester.pumpAndSettle();

      expect(auth.currentUser?.email, 'google@example.com');
    });

    testWidgets('shows nothing when the picker is dismissed', (tester) async {
      await pumpScreen(tester);
      auth.nextFailure = const AuthFailure(
        AuthFailureReason.cancelled,
        'Sign-in was cancelled.',
      );

      await tester.tap(find.byKey(SignInScreen.googleButtonKey));
      await tester.pumpAndSettle();

      expect(find.text('Sign-in was cancelled.'), findsNothing);
      expect(auth.currentUser, isNull);
    });

    testWidgets('reports a refusal that is not a cancellation', (tester) async {
      await pumpScreen(tester);
      auth.nextFailure = const AuthFailure(
        AuthFailureReason.accountExistsWithDifferentCredential,
        'Registered another way.',
      );

      await tester.tap(find.byKey(SignInScreen.googleButtonKey));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'That address already has an account. '
          'Sign in the way you did before.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('is disabled while an email sign-in is in flight', (
      tester,
    ) async {
      final gated = _GatedAuthService();
      addTearDown(gated.dispose);
      gated.seedAccount(email: 'brian@example.com', password: 'hunter22');
      await tester.pumpApp(
        const SignInScreen(),
        overrides: [authServiceProvider.overrideWithValue(gated)],
      );

      await tester.enterText(
        find.byKey(SignInScreen.emailFieldKey),
        'brian@example.com',
      );
      await tester.enterText(
        find.byKey(SignInScreen.passwordFieldKey),
        'hunter22',
      );
      await tester.tap(find.byKey(SignInScreen.submitButtonKey));
      await tester.pump();

      final button = tester.widget<OutlinedButton>(
        find.byKey(SignInScreen.googleButtonKey),
      );
      expect(button.onPressed, isNull);

      gated.gate.complete();
      await tester.pumpAndSettle();
    });
  });
}
