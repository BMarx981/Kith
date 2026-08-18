import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Resolves every [Image] in the pumped tree, so a golden captures it.
///
/// An [AssetImage] loads asynchronously, and a widget test's pumped frames
/// never give that a chance to finish: the frame is captured with the slot
/// still empty. A golden taken that way would say the app ships a button with
/// no logo on it, which is the opposite of what the golden is there to catch.
/// Resolving needs real async work rather than pumped time, hence
/// `WidgetTester.runAsync`.
Future<void> precacheImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  // A single frame, not `pumpAndSettle`: a resolved image paints immediately,
  // and settling would hang on any surface holding a running animation.
  await tester.pump();
}
