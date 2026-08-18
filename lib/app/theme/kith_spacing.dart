/// The spacing scale described in `docs/DESIGN.md`.
///
/// A plain class of static consts rather than a `ThemeExtension`: spacing does
/// not lerp between themes, and const values keep `const EdgeInsets` possible
/// at call sites.
///
/// A one-off number in a screen is a sign the scale is missing a step, not a
/// licence to hardcode one.
abstract final class KithSpacing {
  /// 4 — the gap between a line and its own caption.
  static const xxs = 4.0;

  /// 8 — the gap between tightly related widgets.
  static const xs = 8.0;

  /// 12 — the gap inside a grouped block.
  static const sm = 12.0;

  /// 16 — the default gutter, and the gap between form fields.
  static const md = 16.0;

  /// 24 — the gap between a block and the next one.
  static const lg = 24.0;

  /// 32 — the gap under a page's heading block.
  static const xl = 32.0;

  /// 48 — the gap between major sections.
  static const xxl = 48.0;

  /// The widest a centred form grows before it stops stretching.
  static const formMaxWidth = 420.0;
}
