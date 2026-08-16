import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/widgets/milestone_placeholder.dart';
import 'package:kith/features/contacts/presentation/contacts_screen.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('ContactsScreen', () {
    testWidgets('renders a placeholder titled "Contacts"', (tester) async {
      await tester.pumpApp(const ContactsScreen());

      expect(find.byType(MilestonePlaceholder), findsOneWidget);
      expect(find.text('Contacts'), findsNWidgets(2));
    });

    testWidgets('is scheduled for M2', (tester) async {
      await tester.pumpApp(const ContactsScreen());

      expect(find.text('Arrives in M2'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });
  });
}
