import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/services/google_sign_in_service.dart';

/// [GoogleSignInService] backed by the `google_sign_in` plugin.
///
/// This is the only place in the app that names a `google_sign_in` type. The
/// plugin exposes a singleton rather than something constructible, so the
/// class holds no collaborator to inject; the part that carries risk is the
/// error translation, which lives in [googleSignInFailure] and is tested on
/// its own.
class PluginGoogleSignInService implements GoogleSignInService {
  PluginGoogleSignInService({this.scopeHint = const []});

  /// Scopes to ask for alongside authentication where the platform supports a
  /// combined flow. A hint only: an authorization can still come back
  /// unauthorised, so nothing may assume a scope was granted because it was
  /// named here.
  final List<String> scopeHint;

  Future<void>? _initialization;

  /// Runs the plugin's one-time setup, once.
  ///
  /// Client ids are read from the platform config files that `flutterfire
  /// configure` writes, so there is nothing to pass here.
  Future<void> _ensureInitialized() =>
      _initialization ??= GoogleSignIn.instance.initialize();

  @override
  Future<Result<GoogleTokens>> authenticate() async {
    try {
      await _ensureInitialized();
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: scopeHint,
      );
      final authorization = scopeHint.isEmpty
          ? null
          : await account.authorizationClient.authorizationForScopes(
              scopeHint,
            );
      return Ok(
        GoogleTokens(
          idToken: account.authentication.idToken,
          accessToken: authorization?.accessToken,
        ),
      );
    } on GoogleSignInException catch (error) {
      return Err(googleSignInFailure(error));
    }
  }

  @override
  Future<void> signOut() async {
    // A sign-out before the first sign-in has nothing to undo, and
    // initialising just to tear down would be a platform round trip for
    // nothing.
    if (_initialization == null) return;
    await GoogleSignIn.instance.signOut();
  }
}

/// Translates a plugin exception into a domain [Failure].
///
/// The plugin documents its code list as open — new values are explicitly not
/// a breaking change — so this deliberately switches with a fallback rather
/// than exhaustively.
@visibleForTesting
Failure googleSignInFailure(GoogleSignInException error) {
  final message = error.description ?? error.code.name;
  return switch (error.code) {
    GoogleSignInExceptionCode.canceled => AuthFailure(
      AuthFailureReason.cancelled,
      message,
    ),
    // Both configuration codes mean somebody has to change a setting, not that
    // the attempt was wrong, which is the same thing `providerUnavailable`
    // already says for a Firebase project with the provider switched off.
    GoogleSignInExceptionCode.clientConfigurationError ||
    GoogleSignInExceptionCode.providerConfigurationError ||
    GoogleSignInExceptionCode.uiUnavailable => AuthFailure(
      AuthFailureReason.providerUnavailable,
      message,
    ),
    // An interruption is the flow being cut short rather than refused, and it
    // reads to the user exactly like cancelling.
    GoogleSignInExceptionCode.interrupted => AuthFailure(
      AuthFailureReason.cancelled,
      message,
    ),
    _ => AuthFailure(AuthFailureReason.unknown, message),
  };
}
