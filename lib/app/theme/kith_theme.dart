import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:kith/app/theme/freshness_colors.dart';
import 'package:kith/app/theme/kith_colors.dart';
import 'package:kith/app/theme/kith_radius.dart';
import 'package:kith/app/theme/kith_spacing.dart';
import 'package:kith/app/theme/kith_typography.dart';

/// Light and dark themes for the app shell.
///
/// Every component treatment lives here, so screens carry no styling of their
/// own beyond reaching for a role or a spacing token. `docs/DESIGN.md` is the
/// spec this implements.
abstract final class KithTheme {
  /// The light theme.
  static ThemeData get light =>
      _build(KithColors.light, KithColors.lightFreshness);

  /// The dark theme.
  static ThemeData get dark =>
      _build(KithColors.dark, KithColors.darkFreshness);

  static ThemeData _build(ColorScheme scheme, FreshnessColors freshness) {
    final text = KithTypography.textTheme(scheme);
    final hairline = BorderSide(color: scheme.outlineVariant);

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: KithTypography.bodyFamily,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,

      // The ink ripple is the loudest stock-Material tell; presses read as a
      // low-alpha overlay from each button's own style instead.
      splashFactory: NoSplash.splashFactory,

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // The signature detail: a hairline under every app bar that does not
      // change on scroll, in place of the elevation shadow.
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
        shape: Border(bottom: hairline),
      ),

      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: KithRadius.surfaceBorder,
          side: hairline,
        ),
      ),

      // Borders live here so no screen passes its own `border:`.
      inputDecorationTheme: InputDecorationThemeData(
        border: _inputBorder(scheme.outline),
        enabledBorder: _inputBorder(scheme.outline),
        focusedBorder: _inputBorder(scheme.primary, width: 1.5),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 1.5),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.outline),
        helperStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KithSpacing.md,
          vertical: KithSpacing.md,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: KithRadius.controlBorder),
          ),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          overlayColor: _overlay(scheme.onPrimary),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(scheme.primary),
          minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: KithRadius.controlBorder),
          ),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          overlayColor: _overlay(scheme.primary),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        side: BorderSide(color: scheme.outline),
        shape: const StadiumBorder(),
        elevation: 0,
        pressElevation: 0,
        labelStyle: text.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: KithSpacing.xs,
          vertical: KithSpacing.xxs,
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KithSpacing.md,
          vertical: KithSpacing.xxs,
        ),
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: KithRadius.controlBorder,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        circularTrackColor: Colors.transparent,
        linearTrackColor: scheme.surfaceContainerHighest,
        strokeWidth: 2.5,
        strokeCap: StrokeCap.round,
      ),

      extensions: [freshness],
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: KithRadius.controlBorder,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// The press feedback that stands in for the removed ripple.
  static WidgetStateProperty<Color?> _overlay(Color color) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return color.withValues(alpha: 0.14);
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return color.withValues(alpha: 0.08);
      }
      return null;
    });
  }
}
