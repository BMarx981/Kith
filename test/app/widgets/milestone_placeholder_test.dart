import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/widgets/milestone_placeholder.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('MilestonePlaceholder', () {
    testWidgets('renders the title in the app bar and the body', (
      tester,
    ) async {
      await tester.pumpApp(
        const MilestonePlaceholder(
          title: 'Contacts',
          milestone: 'M2',
          icon: Icons.people_outline,
        ),
      );

      expect(find.text('Contacts'), findsNWidgets(2));
    });

    testWidgets('names the milestone that will implement it', (tester) async {
      await tester.pumpApp(
        const MilestonePlaceholder(
          title: 'Contacts',
          milestone: 'M2',
          icon: Icons.people_outline,
        ),
      );

      expect(find.text('Arrives in M2'), findsOneWidget);
    });

    testWidgets('shows the supplied icon', (tester) async {
      await tester.pumpApp(
        const MilestonePlaceholder(
          title: 'Reconnect',
          milestone: 'M4',
          icon: Icons.favorite_outline,
        ),
      );

      expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
    });

    testWidgets('renders in the dark theme', (tester) async {
      await tester.pumpApp(
        const MilestonePlaceholder(
          title: 'Sign in',
          milestone: 'M1',
          icon: Icons.login_outlined,
        ),
        theme: ThemeData.dark(),
      );

      expect(find.byType(MilestonePlaceholder), findsOneWidget);
    });
  });
}
