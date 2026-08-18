import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/app/widgets/freshness_gauge.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/hangouts/domain/freshness.dart';

import '../helpers/load_fonts.dart';
import '../helpers/pump_app.dart';

/// Pins the freshness gauge in each of its four states, in both brightnesses.
///
/// The gauge is the app's central signal, and the whole point of the four
/// states is that they are told apart at a glance, so this is the one widget
/// with a golden per state rather than a golden per screen. A diff here means
/// the arc, the track or a `FreshnessColors` value moved.
///
/// Authored on macOS. Text rasterises differently on other platforms, so a
/// Linux CI would need its own set rather than a shared one.
void main() {
  final now = DateTime.utc(2026, 8, 18);

  setUpAll(loadAppFonts);

  /// A reading [daysAgo] days into a monthly cadence: 7 days is a quarter of
  /// the way round and comfortably fresh, 26 is just over the due line, and
  /// 60 is twice the cadence.
  Freshness at(int daysAgo) => Freshness.of(
    cadence: Cadence.monthly,
    lastSeenOn: now.subtract(Duration(days: daysAgo)),
    now: now,
  );

  final states = <(String, Freshness)>[
    ('fresh', at(7)),
    ('due', at(26)),
    ('overdue', at(60)),
    ('never', const Freshness.never()),
  ];

  for (final (state, freshness) in states) {
    for (final (brightness, theme) in [
      ('light', KithTheme.light),
      ('dark', KithTheme.dark),
    ]) {
      testWidgets('the gauge reading $state ($brightness)', (tester) async {
        tester.view.physicalSize = const Size(160, 160);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpApp(
          // Inside a Scaffold, because the gauge carries a contact's initial
          // and text outside a Material ancestor is painted as a warning
          // rather than as type.
          Scaffold(
            body: Center(
              child: FreshnessGauge(
                freshness: freshness,
                diameter: 96,
                strokeWidth: 4,
                child: const Text('M'),
              ),
            ),
          ),
          theme: theme,
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('freshness_gauge_${state}_$brightness.png'),
        );
      });
    }
  }
}
