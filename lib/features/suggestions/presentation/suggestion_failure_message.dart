import 'package:kith/core/result/failure.dart';
import 'package:kith/l10n/gen/app_localizations.dart';
import 'package:kith/l10n/validation_messages.dart';

/// User-facing copy for [failure] from a plan read or write.
///
/// The switch is exhaustive over [Failure], so a new failure type fails to
/// compile until it has copy here. `Failure.message` is for logs and is never
/// shown, with one exception: a [ValidationFailure] carrying no issue falls
/// back to it through `validationMessage`.
///
/// Separate from the contact and hangout messages rather than shared, because
/// the same failure means something different here: a plan that is no longer
/// there has usually just been kept or dropped by the other partner, which is
/// not an error worth alarming anyone about.
String suggestionFailureMessage(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      NetworkFailure() => l10n.errorOffline,
      PermissionFailure() => l10n.contactFailurePermission,
      NotFoundFailure() => l10n.suggestionFailureNotFound,
      final ValidationFailure validation =>
        validationMessage(l10n, validation)!,
      ConflictFailure() => l10n.suggestionFailureConflict,
      AuthFailure() => l10n.errorSignInAgain,
      UnknownFailure() => l10n.errorGeneric,
    };
