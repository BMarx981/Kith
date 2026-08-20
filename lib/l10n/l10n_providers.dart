import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/l10n/gen/app_localizations.dart';

/// The locale the app is running in, resolved against the supported set the
/// same way `MaterialApp` resolves it.
///
/// A provider rather than a read of the platform inline, for the same reason
/// "now" goes through `clockProvider`: code that needs a locale outside a
/// `BuildContext` — the digest controller wording a notification — reads this,
/// and a test overrides it instead of depending on the machine it runs on.
final localeProvider = Provider<Locale>(
  (ref) => basicLocaleListResolution(
    WidgetsBinding.instance.platformDispatcher.locales,
    AppLocalizations.supportedLocales,
  ),
);

/// The app's strings in [localeProvider]'s locale, for callers with no
/// `BuildContext` to look them up through.
///
/// Widgets keep using `context.l10n`, which follows the `MaterialApp`'s own
/// resolution; this exists for the application layer, where notification text
/// is composed.
final appLocalizationsProvider = Provider<AppLocalizations>(
  (ref) => lookupAppLocalizations(ref.watch(localeProvider)),
);
