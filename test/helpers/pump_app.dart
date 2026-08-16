import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/theme.dart';

/// Pumps a widget inside the app's theme and a [ProviderScope].
///
/// Widget tests supply fakes through provider overrides; they never build real
/// repositories.
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
    ThemeData? theme,
  }) {
    return pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(theme: theme ?? KithTheme.light, home: widget),
      ),
    );
  }
}
