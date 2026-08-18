import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads every font the app bundles into the test binding.
///
/// Widget tests otherwise render in a placeholder face, which would make a
/// golden say nothing about the type scale that most of the redesign lives in.
/// Reading `FontManifest.json` picks up whatever `pubspec.yaml` declares — the
/// two families and the Material icon font — so a new family is covered
/// without touching this helper.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final manifest =
      json.decode(await rootBundle.loadString('FontManifest.json'))
          as List<dynamic>;

  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family']! as String);
    for (final font
        in (entry['fonts']! as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset']! as String));
    }
    await loader.load();
  }
}
