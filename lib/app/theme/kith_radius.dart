import 'package:flutter/widgets.dart';

/// The corner radii described in `docs/DESIGN.md`.
///
/// Nothing in the app is rounder than [surface] except chips, which are
/// stadium-shaped.
abstract final class KithRadius {
  /// 10 — inputs, buttons and snackbars.
  static const control = 10.0;

  /// 12 — bordered surfaces such as cards.
  static const surface = 12.0;

  /// [control] as a [BorderRadius].
  static const controlBorder = BorderRadius.all(Radius.circular(control));

  /// [surface] as a [BorderRadius].
  static const surfaceBorder = BorderRadius.all(Radius.circular(surface));
}
