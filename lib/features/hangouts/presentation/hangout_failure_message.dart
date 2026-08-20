import 'package:kith/core/result/failure.dart';
import 'package:kith/l10n/gen/app_localizations.dart';
import 'package:kith/l10n/validation_messages.dart';

/// User-facing copy for [failure] from a hangout read or write.
///
/// The switch is exhaustive over [Failure], so a new failure type fails to
/// compile until it has copy here. `Failure.message` is for logs and is never
/// shown, with one exception: a [ValidationFailure] carrying no issue falls
/// back to it through `validationMessage`.
///
/// Separate from `contactFailureMessage` rather than shared, because the same
/// failure means something different here: a conflict on a contact write is a
/// duplicate label, and there is no such thing on a hangout.
String hangoutFailureMessage(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      NetworkFailure() => l10n.errorOffline,
      PermissionFailure() => l10n.contactFailurePermission,
      NotFoundFailure() => l10n.hangoutFailureNotFound,
      final ValidationFailure validation =>
        validationMessage(l10n, validation)!,
      ConflictFailure() => l10n.hangoutFailureConflict,
      AuthFailure() => l10n.errorSignInAgain,
      UnknownFailure() => l10n.errorGeneric,
    };
