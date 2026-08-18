import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/theme.dart';

/// The chip theme carries its selected and unselected treatments in
/// widget-state properties, which are typed as the plain value they stand in
/// for. These read the branch a given state resolves to.
BorderSide? chipSide(ChipThemeData chip, Set<WidgetState> states) =>
    (chip.side! as WidgetStateProperty<BorderSide?>).resolve(states);

Color chipLabelColor(ChipThemeData chip, Set<WidgetState> states) =>
    (chip.labelStyle!.color! as WidgetStateColor).resolve(states);

void main() {
  group('KithTheme', () {
    test('light theme uses a light Material 3 scheme', () {
      final theme = KithTheme.light;

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.appBarTheme.backgroundColor, theme.colorScheme.surface);
      expect(theme.appBarTheme.foregroundColor, theme.colorScheme.onSurface);
      expect(theme.appBarTheme.centerTitle, isFalse);
    });

    test('dark theme uses a dark Material 3 scheme', () {
      final theme = KithTheme.dark;

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('both themes expose distinct freshness colours', () {
      final light = KithTheme.light.extension<FreshnessColors>();
      final dark = KithTheme.dark.extension<FreshnessColors>();

      expect(light, isNotNull);
      expect(dark, isNotNull);
      expect(light!.fresh, isNot(dark!.fresh));
      expect(
        {light.fresh, light.due, light.overdue, light.unknown},
        hasLength(4),
        reason: 'each freshness state must be visually distinguishable',
      );
    });
  });

  group('palette', () {
    test('surfaces are the documented values, not seed-derived tones', () {
      expect(KithTheme.light.colorScheme.surface, const Color(0xFFF8FAF8));
      expect(KithTheme.dark.colorScheme.surface, const Color(0xFF141817));
      expect(KithTheme.light.colorScheme.primary, const Color(0xFF3E6B52));
      expect(KithTheme.dark.colorScheme.primary, const Color(0xFF93C3A7));
    });

    test('the scaffold matches the surface in both themes', () {
      expect(
        KithTheme.light.scaffoldBackgroundColor,
        KithTheme.light.colorScheme.surface,
      );
      expect(
        KithTheme.dark.scaffoldBackgroundColor,
        KithTheme.dark.colorScheme.surface,
      );
    });

    test('the surface container ramp is overridden end to end', () {
      for (final scheme in [
        KithTheme.light.colorScheme,
        KithTheme.dark.colorScheme,
      ]) {
        expect(
          {
            scheme.surfaceContainerLowest,
            scheme.surfaceContainerLow,
            scheme.surfaceContainer,
            scheme.surfaceContainerHigh,
            scheme.surfaceContainerHighest,
          },
          hasLength(5),
          reason: 'every step of the ramp is a distinct hand-picked value',
        );
      }
    });

    test('no surface tint, so elevation never tones a surface', () {
      expect(KithTheme.light.colorScheme.surfaceTint, Colors.transparent);
      expect(KithTheme.dark.colorScheme.surfaceTint, Colors.transparent);
    });

    test('freshness colours track the accent and the error colour', () {
      for (final theme in [KithTheme.light, KithTheme.dark]) {
        final freshness = theme.extension<FreshnessColors>()!;
        expect(freshness.fresh, theme.colorScheme.primary);
        expect(freshness.overdue, theme.colorScheme.error);
      }
    });
  });

  group('typography', () {
    test('titles are set in the display face', () {
      for (final theme in [KithTheme.light, KithTheme.dark]) {
        expect(theme.textTheme.headlineMedium?.fontFamily, 'Fraunces');
        expect(theme.textTheme.headlineSmall?.fontFamily, 'Fraunces');
        expect(theme.textTheme.titleLarge?.fontFamily, 'Fraunces');
      }
    });

    test('body copy is set in the body face', () {
      for (final theme in [KithTheme.light, KithTheme.dark]) {
        expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
        expect(theme.textTheme.titleMedium?.fontFamily, 'Inter');
        expect(theme.textTheme.labelLarge?.fontFamily, 'Inter');
      }
    });

    test('styles the scale does not name still fall back to the body face', () {
      expect(KithTheme.light.textTheme.displayLarge?.fontFamily, 'Inter');
      expect(KithTheme.light.textTheme.labelSmall?.fontFamily, 'Inter');
    });

    test('text is coloured from the scheme in both brightnesses', () {
      expect(
        KithTheme.light.textTheme.bodyMedium?.color,
        KithTheme.light.colorScheme.onSurface,
      );
      expect(
        KithTheme.dark.textTheme.bodyMedium?.color,
        KithTheme.dark.colorScheme.onSurface,
      );
    });
  });

  group('components', () {
    test('every app bar carries the hairline instead of a shadow', () {
      for (final theme in [KithTheme.light, KithTheme.dark]) {
        final appBar = theme.appBarTheme;

        expect(appBar.elevation, 0);
        expect(appBar.scrolledUnderElevation, 0);
        expect(appBar.titleTextStyle?.fontFamily, 'Fraunces');
        expect(
          appBar.shape,
          Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
        );
      }
    });

    test('cards are a hairline surface, never an elevated one', () {
      for (final theme in [KithTheme.light, KithTheme.dark]) {
        final card = theme.cardTheme;

        expect(card.elevation, 0);
        expect(card.color, theme.colorScheme.surfaceContainerLow);
        expect(card.margin, EdgeInsets.zero);

        final shape = card.shape! as RoundedRectangleBorder;
        expect(shape.side.color, theme.colorScheme.outlineVariant);
        expect(shape.borderRadius, KithRadius.surfaceBorder);
      }
    });

    test('input borders come from the theme, at the control radius', () {
      for (final theme in [KithTheme.light, KithTheme.dark]) {
        final inputs = theme.inputDecorationTheme;
        final scheme = theme.colorScheme;

        final enabled = inputs.enabledBorder! as OutlineInputBorder;
        expect(enabled.borderSide.color, scheme.outline);
        expect(enabled.borderSide.width, 1);
        expect(enabled.borderRadius, KithRadius.controlBorder);

        final focused = inputs.focusedBorder! as OutlineInputBorder;
        expect(focused.borderSide.color, scheme.primary);
        expect(focused.borderSide.width, 1.5);

        expect(
          (inputs.errorBorder! as OutlineInputBorder).borderSide.color,
          scheme.error,
        );
      }
    });

    test('dividers are a one-pixel outlineVariant hairline', () {
      for (final theme in [KithTheme.light, KithTheme.dark]) {
        expect(theme.dividerTheme.color, theme.colorScheme.outlineVariant);
        expect(theme.dividerTheme.thickness, 1);
      }
    });

    test('nothing ripples', () {
      expect(KithTheme.light.splashFactory, NoSplash.splashFactory);
      expect(KithTheme.dark.splashFactory, NoSplash.splashFactory);
    });

    test('buttons are flat, tall enough to hit, and control-radius', () {
      for (final theme in [KithTheme.light, KithTheme.dark]) {
        final style = theme.filledButtonTheme.style!;

        expect(style.elevation?.resolve({}), 0);
        expect(style.minimumSize?.resolve({})?.height, 48);
        expect(
          style.shape?.resolve({}),
          const RoundedRectangleBorder(
            borderRadius: KithRadius.controlBorder,
          ),
        );
      }
    });

    test('a press reads as an overlay now the ripple is gone', () {
      final style = KithTheme.light.filledButtonTheme.style!;
      final overlay = style.overlayColor!;

      expect(overlay.resolve({}), isNull);
      expect(
        overlay.resolve({WidgetState.pressed}),
        isNotNull,
        reason: 'the overlay is the only remaining press feedback',
      );
      expect(
        overlay.resolve({WidgetState.hovered}),
        isNotNull,
        reason: 'a pointer still gets a hint before it commits',
      );
      expect(
        overlay.resolve({WidgetState.focused}),
        overlay.resolve({WidgetState.hovered}),
        reason: 'keyboard focus is as visible as a hover',
      );
      expect(
        overlay.resolve({WidgetState.pressed})!.a,
        greaterThan(overlay.resolve({WidgetState.hovered})!.a),
        reason: 'a press reads stronger than a hover',
      );
    });

    test('chips are quiet outlined pills', () {
      for (final theme in [KithTheme.light, KithTheme.dark]) {
        final chip = theme.chipTheme;

        expect(chip.backgroundColor, Colors.transparent);
        expect(chip.shape, isA<StadiumBorder>());
        expect(chipSide(chip, const {})?.color, theme.colorScheme.outline);
        expect(
          chipLabelColor(chip, const {}),
          theme.colorScheme.onSurfaceVariant,
        );
      }
    });

    test(
      'a selected chip is marked by its border, not by a fill or a tick',
      () {
        const selected = {WidgetState.selected};

        for (final theme in [KithTheme.light, KithTheme.dark]) {
          final chip = theme.chipTheme;

          expect(chip.selectedColor, Colors.transparent);
          expect(chip.showCheckmark, isFalse);
          expect(chipSide(chip, selected)?.color, theme.colorScheme.primary);
          expect(chipSide(chip, selected)?.width, greaterThan(1));
          expect(chipLabelColor(chip, selected), theme.colorScheme.primary);
        }
      },
    );

    test('the floating action button is flat and wears the accent', () {
      for (final theme in [KithTheme.light, KithTheme.dark]) {
        final fab = theme.floatingActionButtonTheme;

        expect(fab.backgroundColor, theme.colorScheme.primary);
        expect(fab.foregroundColor, theme.colorScheme.onPrimary);
        expect(fab.elevation, 0);
        expect(fab.highlightElevation, 0);
        expect(fab.splashColor, Colors.transparent);
        expect(
          fab.shape,
          isA<RoundedRectangleBorder>().having(
            (shape) => shape.borderRadius,
            'borderRadius',
            KithRadius.surfaceBorder,
          ),
        );
      }
    });

    test('snackbars float on the inverse surface', () {
      for (final theme in [KithTheme.light, KithTheme.dark]) {
        final snackBar = theme.snackBarTheme;

        expect(snackBar.behavior, SnackBarBehavior.floating);
        expect(snackBar.backgroundColor, theme.colorScheme.inverseSurface);
        expect(
          snackBar.contentTextStyle?.color,
          theme.colorScheme.onInverseSurface,
        );
      }
    });

    test('spinners are thin, round-capped and in the accent', () {
      for (final theme in [KithTheme.light, KithTheme.dark]) {
        final progress = theme.progressIndicatorTheme;

        expect(progress.color, theme.colorScheme.primary);
        expect(progress.strokeWidth, 2.5);
        expect(progress.strokeCap, StrokeCap.round);
      }
    });

    test('page transitions are calm on both platforms', () {
      final builders = KithTheme.light.pageTransitionsTheme.builders;

      expect(
        builders[TargetPlatform.android],
        isA<FadeForwardsPageTransitionsBuilder>(),
      );
      expect(builders[TargetPlatform.iOS], isNotNull);
    });
  });

  group('FreshnessColors', () {
    const base = FreshnessColors(
      fresh: Color(0xFF000001),
      due: Color(0xFF000002),
      overdue: Color(0xFF000003),
      unknown: Color(0xFF000004),
    );

    test('copyWith with no arguments preserves every field', () {
      expect(base.copyWith().fresh, base.fresh);
      expect(base.copyWith().due, base.due);
      expect(base.copyWith().overdue, base.overdue);
      expect(base.copyWith().unknown, base.unknown);
    });

    test('copyWith replaces each field independently', () {
      const replacement = Color(0xFFFF0000);

      expect(base.copyWith(fresh: replacement).fresh, replacement);
      expect(base.copyWith(fresh: replacement).due, base.due);
      expect(base.copyWith(due: replacement).due, replacement);
      expect(base.copyWith(due: replacement).overdue, base.overdue);
      expect(base.copyWith(overdue: replacement).overdue, replacement);
      expect(base.copyWith(overdue: replacement).unknown, base.unknown);
      expect(base.copyWith(unknown: replacement).unknown, replacement);
      expect(base.copyWith(unknown: replacement).fresh, base.fresh);
    });

    test('lerp at t=1 yields the target', () {
      const other = FreshnessColors(
        fresh: Color(0xFFFFFFFF),
        due: Color(0xFFFFFFFE),
        overdue: Color(0xFFFFFFFD),
        unknown: Color(0xFFFFFFFC),
      );

      final result = base.lerp(other, 1);

      expect(result.fresh, other.fresh);
      expect(result.due, other.due);
      expect(result.overdue, other.overdue);
      expect(result.unknown, other.unknown);
    });

    test('lerp at t=0 yields the source', () {
      const other = FreshnessColors(
        fresh: Color(0xFFFFFFFF),
        due: Color(0xFFFFFFFE),
        overdue: Color(0xFFFFFFFD),
        unknown: Color(0xFFFFFFFC),
      );

      expect(base.lerp(other, 0).fresh, base.fresh);
    });

    test('lerp against a non-FreshnessColors extension returns the source', () {
      expect(base.lerp(null, 0.5), same(base));
    });
  });
}
