import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/services/google_sign_in_service.dart';
import 'package:kith/data/services/plugin_google_sign_in_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AuthFailureReason reasonFor(GoogleSignInExceptionCode code) {
    final failure = googleSignInFailure(
      GoogleSignInException(code: code, description: 'because'),
    );
    return (failure as AuthFailure).reason;
  }

  group('googleSignInFailure', () {
    test('reads a dismissed sheet as a cancellation, not an error', () {
      expect(
        reasonFor(GoogleSignInExceptionCode.canceled),
        AuthFailureReason.cancelled,
      );
    });

    test('reads an interrupted flow the same way a user would', () {
      expect(
        reasonFor(GoogleSignInExceptionCode.interrupted),
        AuthFailureReason.cancelled,
      );
    });

    test('reports every configuration problem as provider unavailable', () {
      for (final code in [
        GoogleSignInExceptionCode.clientConfigurationError,
        GoogleSignInExceptionCode.providerConfigurationError,
        GoogleSignInExceptionCode.uiUnavailable,
      ]) {
        expect(
          reasonFor(code),
          AuthFailureReason.providerUnavailable,
          reason: '$code should be a setup problem',
        );
      }
    });

    test('falls back to unknown for a code it does not name', () {
      expect(
        reasonFor(GoogleSignInExceptionCode.unknownError),
        AuthFailureReason.unknown,
      );
      expect(
        reasonFor(GoogleSignInExceptionCode.userMismatch),
        AuthFailureReason.unknown,
      );
    });

    test('carries the description through for the log', () {
      final failure = googleSignInFailure(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
          description: 'the wheels came off',
        ),
      );

      expect(failure.message, 'the wheels came off');
    });

    test('falls back to the code when there is no description', () {
      final failure = googleSignInFailure(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      );

      expect(failure.message, 'canceled');
    });
  });

  group('GoogleTokens', () {
    test('is empty only when neither token arrived', () {
      expect(const GoogleTokens().isEmpty, isTrue);
      expect(const GoogleTokens(idToken: 'id').isEmpty, isFalse);
      expect(const GoogleTokens(accessToken: 'access').isEmpty, isFalse);
    });

    test('compares by value', () {
      const a = GoogleTokens(idToken: 'id', accessToken: 'access');
      const b = GoogleTokens(idToken: 'id', accessToken: 'access');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const GoogleTokens(idToken: 'other')));
    });

    test('keeps the tokens out of its string form', () {
      const tokens = GoogleTokens(idToken: 'secret-id', accessToken: 'secret');

      expect(tokens.toString(), isNot(contains('secret')));
      expect(const GoogleTokens().toString(), contains('null'));
    });
  });

  group('PluginGoogleSignInService', () {
    late _FakeGoogleSignInPlatform platform;

    setUp(() {
      platform = _FakeGoogleSignInPlatform();
      GoogleSignInPlatform.instance = platform;
    });

    test('returns the id token from a plain sign-in', () async {
      final service = PluginGoogleSignInService();

      final result = await service.authenticate();

      expect(result.valueOrNull, const GoogleTokens(idToken: 'id-token'));
      expect(platform.initCalls, 1);
      expect(platform.requestedScopes, isNull);
    });

    test('asks for the hinted scopes and returns the access token', () async {
      final service = PluginGoogleSignInService(
        scopeHint: const ['https://www.googleapis.com/auth/calendar.events'],
      );

      final result = await service.authenticate();

      expect(
        result.valueOrNull,
        const GoogleTokens(idToken: 'id-token', accessToken: 'access-token'),
      );
      expect(platform.requestedScopes, [
        'https://www.googleapis.com/auth/calendar.events',
      ]);
    });

    test('reports no access token when the scope was not granted', () async {
      platform.authorization = null;
      final service = PluginGoogleSignInService(scopeHint: const ['scope']);

      final result = await service.authenticate();

      expect(result.valueOrNull, const GoogleTokens(idToken: 'id-token'));
    });

    test('initialises once across repeated sign-ins', () async {
      final service = PluginGoogleSignInService();

      await service.authenticate();
      await service.authenticate();

      expect(platform.initCalls, 1);
    });

    test('translates a dismissed sheet into a domain failure', () async {
      platform.authenticateThrows = const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: 'user closed it',
      );
      final service = PluginGoogleSignInService();

      final result = await service.authenticate();

      expect(
        result.failureOrNull,
        isA<AuthFailure>().having(
          (failure) => failure.reason,
          'reason',
          AuthFailureReason.cancelled,
        ),
      );
    });

    test('hands back the access token once a scope is granted', () async {
      final service = PluginGoogleSignInService();

      final result = await service.authorizeScopes(const ['calendar.events']);

      expect(result.valueOrNull, 'access-token');
      expect(platform.requestedScopes, ['calendar.events']);
      expect(platform.promptedForAuthorization, isTrue);
    });

    test('translates a declined scope sheet into a domain failure', () async {
      platform.authorizationThrows = const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
        description: 'user closed it',
      );
      final service = PluginGoogleSignInService();

      final result = await service.authorizeScopes(const ['calendar.events']);

      expect(
        result.failureOrNull,
        isA<AuthFailure>().having(
          (failure) => failure.reason,
          'reason',
          AuthFailureReason.cancelled,
        ),
      );
    });

    test('reads an already-granted scope without prompting', () async {
      final service = PluginGoogleSignInService();

      final token = await service.existingAccessToken(const [
        'calendar.events',
      ]);

      expect(token, 'access-token');
      expect(platform.promptedForAuthorization, isFalse);
    });

    test('answers null for a scope that was never granted', () async {
      platform.authorization = null;
      final service = PluginGoogleSignInService();

      expect(await service.existingAccessToken(const ['scope']), isNull);
    });

    test('answers null rather than throwing on a silent read', () async {
      platform.authorizationThrows = const GoogleSignInException(
        code: GoogleSignInExceptionCode.uiUnavailable,
      );
      final service = PluginGoogleSignInService();

      expect(await service.existingAccessToken(const ['scope']), isNull);
    });

    test('signing out before signing in touches nothing', () async {
      await PluginGoogleSignInService().signOut();

      expect(platform.initCalls, 0);
      expect(platform.signOutCalls, 0);
    });

    test('signs out once a session exists', () async {
      final service = PluginGoogleSignInService();
      await service.authenticate();

      await service.signOut();

      expect(platform.signOutCalls, 1);
    });
  });
}

/// Stands in for the native plugin, which has no implementation under
/// `flutter test`. Only the calls [PluginGoogleSignInService] makes are
/// answered; the rest of the interface throws if it is ever reached.
class _FakeGoogleSignInPlatform extends GoogleSignInPlatform {
  int initCalls = 0;
  int signOutCalls = 0;

  /// Scopes passed to the authorization call, or null if it was never made.
  List<String>? requestedScopes;

  /// Thrown by [authenticate] instead of returning, when set.
  GoogleSignInException? authenticateThrows;

  /// Authorization the platform hands back; null stands for a scope the user
  /// did not grant.
  ClientAuthorizationTokenData? authorization = const
      ClientAuthorizationTokenData(accessToken: 'access-token');

  /// Thrown by the authorization call instead of returning, when set.
  GoogleSignInException? authorizationThrows;

  /// Whether the last authorization call asked to prompt, or null if none was
  /// made.
  bool? promptedForAuthorization;

  @override
  Future<void> init(InitParameters params) async => initCalls++;

  @override
  Future<AuthenticationResults> authenticate(
    AuthenticateParameters params,
  ) async {
    final failure = authenticateThrows;
    if (failure != null) throw failure;
    return const AuthenticationResults(
      user: GoogleSignInUserData(email: 'brian@example.com', id: 'g-1'),
      authenticationTokens: AuthenticationTokenData(idToken: 'id-token'),
    );
  }

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) async {
    requestedScopes = params.request.scopes;
    promptedForAuthorization = params.request.promptIfUnauthorized;
    final failure = authorizationThrows;
    if (failure != null) throw failure;
    return authorization;
  }

  @override
  Future<void> signOut(SignOutParams params) async => signOutCalls++;

  @override
  bool supportsAuthenticate() => true;

  @override
  bool authorizationRequiresUserInteraction() => false;

  @override
  Future<AuthenticationResults?>? attemptLightweightAuthentication(
    AttemptLightweightAuthenticationParameters params,
  ) => throw UnimplementedError();

  @override
  Future<void> disconnect(DisconnectParams params) async =>
      throw UnimplementedError();

  @override
  Future<ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
    ServerAuthorizationTokensForScopesParameters params,
  ) async => throw UnimplementedError();
}
