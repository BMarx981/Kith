import 'package:kith/core/result/failure.dart';
import 'package:kith/l10n/gen/app_localizations.dart';
import 'package:kith/l10n/validation_messages.dart';

/// User-facing copy for [failure] from linking or reading a calendar.
///
/// The switch is exhaustive over [Failure], so a new failure type fails to
/// compile until it has copy here. `Failure.message` is for logs and is never
/// shown, with one exception: a [ValidationFailure] carrying no issue falls
/// back to it through `validationMessage`.
///
/// Separate from the household and suggestion messages rather than shared,
/// because the same failure means something different here: a permission
/// problem is almost always Google's rather than Kith's, and telling somebody
/// they are not allowed to change this household would send them looking in
/// the wrong place.
String calendarFailureMessage(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      NetworkFailure() => l10n.calendarFailureNetwork,
      PermissionFailure() => l10n.calendarFailurePermission,
      NotFoundFailure() => l10n.calendarFailureNotFound,
      final ValidationFailure validation =>
        validationMessage(l10n, validation)!,
      ConflictFailure() => l10n.calendarFailureConflict,
      AuthFailure() => l10n.errorSignInAgain,
      UnknownFailure() => l10n.calendarFailureUnknown,
    };
