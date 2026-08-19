import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/services/google_sign_in_service.dart';

/// An in-memory [GoogleSignInService] for tests that need a scope granted or
/// refused without the plugin's platform channels.
///
/// Starts with nothing authorised, which is what a household that has never
/// linked a calendar looks like.
class FakeGoogleSignInService implements GoogleSignInService {
  /// Access token handed back once [authorizeScopes] has been accepted, and
  /// by [existingAccessToken] from then on. Set it to stand for a grant that
  /// was made on an earlier run.
  String? token;

  /// Failure [authorizeScopes] answers with instead of granting, when set.
  /// A cancelled sheet is the usual one.
  Failure? authorizeFailure;

  /// Scope lists passed to [authorizeScopes], oldest first.
  final authorizeCalls = <List<String>>[];

  /// Scope lists passed to [existingAccessToken], oldest first.
  final existingCalls = <List<String>>[];

  /// Number of [signOut] calls.
  int signOutCalls = 0;

  @override
  Future<Result<GoogleTokens>> authenticate() async =>
      Ok(GoogleTokens(idToken: 'id-token', accessToken: token));

  @override
  Future<Result<String>> authorizeScopes(List<String> scopes) async {
    authorizeCalls.add(scopes);
    final failure = authorizeFailure;
    if (failure != null) return Err(failure);
    return Ok(token ??= 'access-token');
  }

  @override
  Future<String?> existingAccessToken(List<String> scopes) async {
    existingCalls.add(scopes);
    return token;
  }

  @override
  Future<void> signOut() async => signOutCalls++;
}
