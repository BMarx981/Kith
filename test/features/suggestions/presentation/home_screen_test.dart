import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/widgets/milestone_placeholder.dart';
import 'package:kith/features/suggestions/presentation/home_screen.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders a placeholder titled "Reconnect"', (tester) async {
      await tester.pumpApp(const HomeScreen());

      expect(find.byType(MilestonePlaceholder), findsOneWidget);
      expect(find.text('Reconnect'), findsNWidgets(2));
    });

    testWidgets('is scheduled for M4', (tester) async {
      await tester.pumpApp(const HomeScreen());

      expect(find.text('Arrives in M4'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
    });

    // Where the button goes is the router's business, and is asserted there.
    testWidgets('offers the way through to the household', (tester) async {
      await tester.pumpApp(const HomeScreen());

      expect(find.byKey(HomeScreen.householdKey), findsOneWidget);
      expect(find.byTooltip('Household'), findsOneWidget);
    });
  });
}
