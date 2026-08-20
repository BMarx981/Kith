import 'package:kith/core/result/failure.dart';
import 'package:kith/l10n/gen/app_localizations.dart';
import 'package:kith/l10n/validation_messages.dart';

/// User-facing copy for [failure] from a contact or relationship type write.
///
/// The switch is exhaustive over [Failure], so a new failure type fails to
/// compile until it has copy here. `Failure.message` is for logs and is never
/// shown, with one exception: a [ValidationFailure] carrying no issue falls
/// back to it through `validationMessage`.
String contactFailureMessage(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      NetworkFailure() => l10n.errorOffline,
      PermissionFailure() => l10n.contactFailurePermission,
      NotFoundFailure() => l10n.contactFailureNotFound,
      final ValidationFailure validation =>
        validationMessage(l10n, validation)!,
      ConflictFailure() => l10n.contactFailureConflict,
      AuthFailure() => l10n.errorSignInAgain,
      UnknownFailure() => l10n.errorGeneric,
    };
