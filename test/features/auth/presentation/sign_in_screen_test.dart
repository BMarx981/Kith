import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/widgets/milestone_placeholder.dart';
import 'package:kith/features/auth/presentation/sign_in_screen.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('SignInScreen', () {
    testWidgets('renders a placeholder titled "Sign in"', (tester) async {
      await tester.pumpApp(const SignInScreen());

      expect(find.byType(MilestonePlaceholder), findsOneWidget);
      expect(find.text('Sign in'), findsNWidgets(2));
    });

    testWidgets('is scheduled for M1', (tester) async {
      await tester.pumpApp(const SignInScreen());

      expect(find.text('Arrives in M1'), findsOneWidget);
      expect(find.byIcon(Icons.login_outlined), findsOneWidget);
    });
  });
}
