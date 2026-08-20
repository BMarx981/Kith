import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/l10n/l10n.dart';

/// Pumps a widget inside the app's theme and a [ProviderScope].
///
/// Widget tests supply fakes through provider overrides; they never build real
/// repositories. Localizations resolve to English unless a locale says
/// otherwise, so `find.text` assertions match the template ARB.
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
    ThemeData? theme,
    Locale locale = const Locale('en'),
  }) {
    return pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme ?? KithTheme.light,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: widget,
        ),
      ),
    );
  }
}
