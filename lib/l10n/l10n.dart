import 'package:flutter/widgets.dart';
import 'package:kith/l10n/gen/app_localizations.dart';

export 'package:kith/l10n/gen/app_localizations.dart';

/// Shorthand for the generated localizations lookup.
///
/// Presentation code reads strings as `context.l10n.someKey`; the ARB files in
/// `lib/l10n/` are the source of truth for every user-facing string.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
