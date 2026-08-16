import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/theme.dart';

void main() {
  group('KithTheme', () {
    test('light theme uses a light Material 3 scheme from the seed', () {
      final theme = KithTheme.light;

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.appBarTheme.backgroundColor, theme.colorScheme.surface);
      expect(theme.appBarTheme.foregroundColor, theme.colorScheme.onSurface);
      expect(theme.appBarTheme.centerTitle, isFalse);
    });

    test('dark theme uses a dark Material 3 scheme from the seed', () {
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
