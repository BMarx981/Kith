import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/app.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/features/suggestions/presentation/home_screen.dart';

void main() {
  group('KithApp', () {
    testWidgets('boots into the home screen', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: KithApp()));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('supplies both light and dark themes', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: KithApp()));
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(app.title, 'Kith');
      expect(app.theme?.colorScheme.brightness, Brightness.light);
      expect(app.darkTheme?.colorScheme.brightness, Brightness.dark);
      expect(app.theme?.extension<FreshnessColors>(), isNotNull);
      expect(app.darkTheme?.extension<FreshnessColors>(), isNotNull);
    });
  });
}
