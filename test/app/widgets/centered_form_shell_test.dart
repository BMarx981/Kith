import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/app/widgets/centered_form_shell.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('CenteredFormShell', () {
    testWidgets('caps its child at the form width on a wide window', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpApp(
        const CenteredFormShell(
          child: SizedBox(width: double.infinity, key: Key('content')),
        ),
      );

      expect(
        tester.getSize(find.byKey(const Key('content'))).width,
        KithSpacing.formMaxWidth,
      );
    });

    testWidgets('lets a tall child scroll rather than overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpApp(
        const CenteredFormShell(
          child: SizedBox(height: 2000, key: Key('content')),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('gives the form a page of its own', (tester) async {
      await tester.pumpApp(const CenteredFormShell(child: SizedBox()));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
    });
  });
}
