import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/widgets/app_splash.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('AppSplash', () {
    testWidgets('names the app and shows that it is working', (tester) async {
      await tester.pumpApp(const AppSplash());
      await tester.pump();

      expect(find.text('Kith'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders in the dark theme', (tester) async {
      await tester.pumpApp(const AppSplash(), theme: ThemeData.dark());
      await tester.pump();

      expect(find.byType(AppSplash), findsOneWidget);
    });
  });
}
