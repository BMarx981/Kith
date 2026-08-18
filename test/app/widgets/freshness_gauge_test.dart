import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/app/widgets/freshness_gauge.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/hangouts/domain/freshness.dart';

import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime.utc(2026, 8, 18);

  Freshness at(int daysAgo, {Cadence cadence = Cadence.monthly}) =>
      Freshness.of(
        cadence: cadence,
        lastSeenOn: now.subtract(Duration(days: daysAgo)),
        now: now,
      );

  testWidgets('draws at the size it is asked for', (tester) async {
    await tester.pumpApp(
      Center(child: FreshnessGauge(freshness: at(1), diameter: 72)),
    );

    expect(
      tester.getSize(find.byType(FreshnessGauge)),
      const Size(72, 72),
    );
  });

  testWidgets('holds its child inside the ring', (tester) async {
    await tester.pumpApp(
      Center(
        child: FreshnessGauge(freshness: at(1), child: const Text('M')),
      ),
    );

    expect(find.text('M'), findsOneWidget);
  });

  testWidgets('announces how long it has been', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(Center(child: FreshnessGauge(freshness: at(1))));

    expect(find.bySemanticsLabel('Seen yesterday'), findsOneWidget);

    await tester.pumpApp(
      const Center(child: FreshnessGauge(freshness: Freshness.never())),
    );

    expect(find.bySemanticsLabel('Never logged'), findsOneWidget);
    handle.dispose();
  });

  group('colorOf', () {
    testWidgets('reads each state off the theme extension', (tester) async {
      late BuildContext context;
      await tester.pumpApp(
        Builder(
          builder: (inner) {
            context = inner;
            return const SizedBox.shrink();
          },
        ),
      );
      final colors = KithTheme.light.extension<FreshnessColors>()!;

      expect(
        FreshnessGauge.colorOf(context, FreshnessState.fresh),
        colors.fresh,
      );
      expect(FreshnessGauge.colorOf(context, FreshnessState.due), colors.due);
      expect(
        FreshnessGauge.colorOf(context, FreshnessState.overdue),
        colors.overdue,
      );
      expect(
        FreshnessGauge.colorOf(context, FreshnessState.never),
        colors.unknown,
      );
    });

    testWidgets('follows the dark scheme when the app is dark', (tester) async {
      late BuildContext context;
      await tester.pumpApp(
        Builder(
          builder: (inner) {
            context = inner;
            return const SizedBox.shrink();
          },
        ),
        theme: KithTheme.dark,
      );

      expect(
        FreshnessGauge.colorOf(context, FreshnessState.fresh),
        KithTheme.dark.extension<FreshnessColors>()!.fresh,
      );
    });

    testWidgets('falls back to the app palette outside the app theme', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpApp(
        Builder(
          builder: (inner) {
            context = inner;
            return const SizedBox.shrink();
          },
        ),
        theme: ThemeData.light(),
      );

      expect(
        FreshnessGauge.colorOf(context, FreshnessState.overdue),
        KithColors.lightFreshness.overdue,
      );
    });

    testWidgets('falls back to the dark palette in a dark bare theme', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpApp(
        Builder(
          builder: (inner) {
            context = inner;
            return const SizedBox.shrink();
          },
        ),
        theme: ThemeData.dark(),
      );

      expect(
        FreshnessGauge.colorOf(context, FreshnessState.fresh),
        KithColors.darkFreshness.fresh,
      );
    });
  });

  group('painting', () {
    /// The gauge repaints only when what it draws has changed, which is what
    /// keeps a long contact list cheap to scroll.
    testWidgets('repaints when the reading moves', (tester) async {
      await tester.pumpApp(Center(child: FreshnessGauge(freshness: at(1))));
      final first = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(FreshnessGauge),
          matching: find.byType(CustomPaint),
        ),
      );

      await tester.pumpApp(Center(child: FreshnessGauge(freshness: at(20))));
      final second = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(FreshnessGauge),
          matching: find.byType(CustomPaint),
        ),
      );

      expect(second.painter!.shouldRepaint(first.painter!), isTrue);
    });

    testWidgets('does not repaint for an unchanged reading', (tester) async {
      await tester.pumpApp(Center(child: FreshnessGauge(freshness: at(1))));
      final painter = tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(FreshnessGauge),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter!;

      expect(painter.shouldRepaint(painter), isFalse);
    });

    testWidgets('renders every state without throwing', (tester) async {
      for (final freshness in [
        at(1),
        at(25),
        at(90),
        const Freshness.never(),
      ]) {
        await tester.pumpApp(
          Center(child: FreshnessGauge(freshness: freshness)),
        );

        expect(tester.takeException(), isNull);
      }
    });
  });
}
