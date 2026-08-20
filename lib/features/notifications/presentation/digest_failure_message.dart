import 'package:kith/core/result/failure.dart';
import 'package:kith/l10n/gen/app_localizations.dart';
import 'package:kith/l10n/validation_messages.dart';

/// User-facing copy for [failure] from setting up the weekly digest.
///
/// The switch is exhaustive over [Failure], so a new failure type fails to
/// compile until it has copy here. `Failure.message` is for logs and is never
/// shown, with one exception: a [ValidationFailure] carrying no issue falls
/// back to it through `validationMessage`.
///
/// Separate from the household copy rather than shared, because the digest
/// fails in two different places: storing the preference is a Firestore write
/// like any other, while scheduling it is the device's own notification
/// system, and "something went wrong saving that" would send somebody looking
/// in the wrong place for a phone that would not set a reminder.
String digestFailureMessage(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      NetworkFailure() => l10n.digestFailureNetwork,
      PermissionFailure() => l10n.digestFailurePermission,
      NotFoundFailure() => l10n.digestFailureNotFound,
      final ValidationFailure validation =>
        validationMessage(l10n, validation)!,
      ConflictFailure() => l10n.digestFailureConflict,
      AuthFailure() => l10n.errorSignInAgain,
      UnknownFailure() => l10n.digestFailureUnknown,
    };
