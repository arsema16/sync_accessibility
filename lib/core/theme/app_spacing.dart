/// Spacing and sizing tokens for SYNC.
///
/// [minTapTarget] matches the accessibility requirement that every interactive
/// control is at least 48x48 logical pixels.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal padding used by full-width screen bodies.
  static const double pagePadding = 20;

  /// Minimum size for any tappable control (WCAG 2.2 Target Size, Level AA).
  static const double minTapTarget = 48;

  /// Larger text scale applied app-wide when "use larger text" is selected.
  static const double largeTextScale = 1.3;
}
