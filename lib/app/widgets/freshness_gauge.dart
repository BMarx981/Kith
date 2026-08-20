import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/features/hangouts/domain/freshness.dart';
import 'package:kith/l10n/l10n.dart';

/// The ring that says how overdue someone is.
///
/// One arc swept clockwise from twelve o'clock, filling as the cadence runs
/// down and colouring by [FreshnessState]. It is the app's central signal, so
/// it reads the same everywhere: on a list row it rings the avatar, on its own
/// it is the same ring at whatever [diameter] the surface asks for.
///
/// The four states are told apart by more than colour, because colour alone
/// fails for a red-green reader and in a monochrome screenshot:
///
/// * **fresh, due, overdue** draw a hairline track with an arc over it. The
///   arc's length is how far through the cadence they are, capped at a full
///   ring so that being three times overdue cannot wrap round and read as
///   fresh again.
/// * **never** draws no arc at all — the whole ring is the neutral track, in
///   the `unknown` colour. Nothing has been logged, so there is nothing to
///   sweep, and that emptiness is the honest picture.
///
/// Colours come from the `FreshnessColors` extension and from nowhere else.
class FreshnessGauge extends StatelessWidget {
  const FreshnessGauge({
    required this.freshness,
    this.diameter = 44,
    this.strokeWidth = 2.5,
    this.child,
    super.key,
  });

  /// The reading to draw.
  final Freshness freshness;

  /// Outer size of the ring, in logical pixels.
  final double diameter;

  /// Thickness of both the track and the arc. Matches the app's progress
  /// indicators, so the two never read as different weights of the same idea.
  final double strokeWidth;

  /// Drawn inside the ring — a contact's initial, usually. Sized to fit
  /// within the stroke rather than under it.
  final Widget? child;

  /// The colour [state] is drawn in, from the theme's `FreshnessColors`.
  ///
  /// A theme that carries no `FreshnessColors` — a bare `ThemeData` in a test,
  /// or a host app embedding a screen — falls back to the app's own set for
  /// that brightness rather than throwing. The gauge is the one thing on a
  /// contact row that must always draw.
  static Color colorOf(BuildContext context, FreshnessState state) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<FreshnessColors>() ??
        (theme.brightness == Brightness.dark
            ? KithColors.darkFreshness
            : KithColors.lightFreshness);
    return switch (state) {
      FreshnessState.fresh => colors.fresh,
      FreshnessState.due => colors.due,
      FreshnessState.overdue => colors.overdue,
      FreshnessState.never => colors.unknown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = colorOf(context, freshness.state);

    return Semantics(
      label: freshness.lastSeenLabel(context.l10n),
      child: SizedBox.square(
        dimension: diameter,
        child: CustomPaint(
          painter: _GaugePainter(
            sweep: freshness.isMeasured ? freshness.sweep : null,
            color: color,
            // A measured contact gets a hairline track so the unfilled part of
            // the cadence stays visible; an unmeasured one has no track to
            // distinguish, so the whole ring carries the neutral colour.
            trackColor: freshness.isMeasured
                ? theme.colorScheme.outlineVariant
                : color,
            strokeWidth: strokeWidth,
          ),
          child: child == null
              ? null
              : Center(
                  child: Padding(
                    padding: EdgeInsets.all(strokeWidth * 2),
                    child: child,
                  ),
                ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.sweep,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  /// How far round to draw the arc, from 0 to 1, or null for a reading with
  /// nothing to sweep.
  final double? sweep;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  /// Shortest arc that still reads as a mark rather than as a smudge.
  ///
  /// Someone seen this morning is at a sweep of zero, and a zero-length arc
  /// would draw nothing, which is exactly what "never logged" looks like.
  /// A round cap's worth of green at twelve o'clock keeps the two apart.
  static const _minimumSweep = 0.02;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    final sweep = this.sweep;
    if (sweep == null) return;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * math.max(sweep, _minimumSweep),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.sweep != sweep ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
