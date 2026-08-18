import 'package:flutter/foundation.dart';
import 'package:kith/core/result/result.dart';

/// The tokens a completed Google sign-in hands back.
///
/// Deliberately not serialisable: these are short-lived secrets whose only
/// purpose is to be exchanged for a Firebase credential and then dropped, so
/// there is no `toMap`/`fromMap` that could write one somewhere it outlives
/// the call. Both fields are nullable because the plugin splits authentication
/// from authorization — signing in yields an id token, and an access token
/// only arrives once a scope has actually been authorised.
@immutable
class GoogleTokens {
  const GoogleTokens({this.idToken, this.accessToken});

  /// Identifies the account to Firebase.
  final String? idToken;

  /// Calls Google APIs on the account's behalf. Null until a scope is granted.
  final String? accessToken;

  /// Whether there is anything here Firebase could build a credential from.
  bool get isEmpty => idToken == null && accessToken == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoogleTokens &&
          other.idToken == idToken &&
          other.accessToken == accessToken;

  @override
  int get hashCode => Object.hash(idToken, accessToken);

  /// Redacts both tokens: a token in a log line is a token that has leaked.
  @override
  String toString() =>
      'GoogleTokens(idToken: ${idToken == null ? 'null' : '<redacted>'}, '
      'accessToken: ${accessToken == null ? 'null' : '<redacted>'})';
}

/// Google's half of federated sign-in.
///
/// Kept behind an interface so the rest of the app can be tested without the
/// plugin's platform channels, and so M5 can ask for the calendar scope
/// through the same account rather than signing in a second time.
///
/// Implementations translate the plugin's errors into domain failures before
/// returning; nothing above this interface sees a `GoogleSignInException`.
abstract interface class GoogleSignInService {
  /// Runs the interactive account picker.
  ///
  /// Dismissing the sheet yields `AuthFailureReason.cancelled`, which is the
  /// user changing their mind rather than something to report as an error.
  Future<Result<GoogleTokens>> authenticate();

  /// Forgets the Google account, so the next [authenticate] asks again.
  ///
  /// Signing out of Firebase alone would leave Google's own session standing,
  /// and the next sign-in would silently reuse the account the user had just
  /// left rather than offering the picker.
  Future<void> signOut();
}
