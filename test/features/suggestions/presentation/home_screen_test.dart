import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/theme.dart';
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
      expect(find.byIcon(KithIcons.reconnect), findsOneWidget);
    });

    // Where the buttons go is the router's business, and is asserted there.
    testWidgets('offers the ways through to contacts and the household', (
      tester,
    ) async {
      await tester.pumpApp(const HomeScreen());

      expect(find.byKey(HomeScreen.contactsKey), findsOneWidget);
      expect(find.byTooltip('Contacts'), findsOneWidget);
      expect(find.byKey(HomeScreen.householdKey), findsOneWidget);
      expect(find.byTooltip('Household'), findsOneWidget);
    });

    testWidgets('tells the two destinations apart by their icons', (
      tester,
    ) async {
      await tester.pumpApp(const HomeScreen());

      expect(find.byIcon(KithIcons.people), findsOneWidget);
      expect(find.byIcon(KithIcons.household), findsOneWidget);
    });
  });
}
