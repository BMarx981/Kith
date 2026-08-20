import 'package:kith/core/result/failure.dart';
import 'package:kith/l10n/gen/app_localizations.dart';

/// User-facing copy for [failure].
///
/// The switch is exhaustive over [AuthFailureReason], so adding a reason to
/// the enum fails to compile until it has copy here. `Failure.message` is for
/// logs and is never shown.
String authFailureMessage(AppLocalizations l10n, AuthFailure failure) =>
    switch (failure.reason) {
      AuthFailureReason.invalidCredentials => l10n.authInvalidCredentials,
      AuthFailureReason.emailAlreadyInUse => l10n.authEmailAlreadyInUse,
      AuthFailureReason.weakPassword => l10n.authWeakPassword,
      AuthFailureReason.invalidEmail => l10n.authInvalidEmail,
      AuthFailureReason.userDisabled => l10n.authUserDisabled,
      AuthFailureReason.tooManyRequests => l10n.authTooManyRequests,
      AuthFailureReason.network => l10n.errorOffline,
      AuthFailureReason.providerUnavailable => l10n.authProviderUnavailable,
      AuthFailureReason.cancelled => l10n.authCancelled,
      AuthFailureReason.accountExistsWithDifferentCredential =>
        l10n.authAccountExistsWithDifferentCredential,
      AuthFailureReason.unknown => l10n.errorGeneric,
    };
