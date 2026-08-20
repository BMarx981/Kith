import 'package:kith/core/result/failure.dart';
import 'package:kith/l10n/gen/app_localizations.dart';

/// User-facing copy for [failure] from the create-or-join flow.
///
/// The switch is exhaustive over [Failure], so a new failure type fails to
/// compile until it has copy here. `Failure.message` is for logs and is never
/// shown; what the user typed is judged under the field by
/// `HouseholdFieldValidator` before it ever gets this far.
String householdFailureMessage(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      NetworkFailure() => l10n.errorOffline,
      PermissionFailure() => l10n.errorSignInAgain,
      NotFoundFailure() => l10n.householdFailureNotFound,
      ValidationFailure() => l10n.householdFailureValidation,
      ConflictFailure() => l10n.householdFailureConflict,
      AuthFailure() => l10n.errorSignInAgain,
      UnknownFailure() => l10n.errorGeneric,
    };
