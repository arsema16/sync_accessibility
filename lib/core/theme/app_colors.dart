import 'package:flutter/material.dart';

/// Raw color tokens for SYNC.
///
/// These are chosen to meet WCAG AA contrast ratios for text against the
/// surfaces they appear on:
///   - Light: [onSurface] on [surface] is ~16:1; [onPrimary] white on
///     [primary] is ~6.4:1.
///   - Dark: [onSurfaceDark] on [surfaceDark] is ~12:1.
///   - High-contrast variants push toward pure black/white (>= 7:1).
///
/// Color is never the only signal for state. Selected, error and success
/// states are always paired with an icon and/or descriptive text.
class AppColors {
  AppColors._();

  // ---- Brand (light) ----
  static const Color primary = Color(0xFF1B7A6E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFB2DFDB);  // light teal
  static const Color onPrimaryContainer = Color(0xFF004D44);

  static const Color secondary = Color(0xFF26A69A);          // lighter teal
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE0F2F1);
  static const Color onSecondaryContainer = Color(0xFF00332E);

  // ---- Surfaces (light) ----
  static const Color surface = Color(0xFFFDFCFF);
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color surfaceVariant = Color(0xFFE0E2EC);
  static const Color onSurfaceVariant = Color(0xFF43474E);
  static const Color outline = Color(0xFF74777F);
  static const Color outlineVariant = Color(0xFFC4C6D0);

  // ---- Semantic (light) ----
  static const Color error = Color(0xFFB3261E);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onErrorContainer = Color(0xFF410E0B);
  static const Color success = Color(0xFF1E6B2E);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFD7F2DB);
  static const Color onSuccessContainer = Color(0xFF0A2711);

  // ---- Dark ----
  static const Color primaryDark = Color(0xFFA6CAFF);
  static const Color onPrimaryDark = Color(0xFF002F66);
  static const Color primaryContainerDark = Color(0xFF00468F);
  static const Color onPrimaryContainerDark = Color(0xFFD7E3FF);

  static const Color secondaryDark = Color(0xFFAAC7FF);
  static const Color onSecondaryDark = Color(0xFF0A1F44);
  static const Color secondaryContainerDark = Color(0xFF1F4F9C);
  static const Color onSecondaryContainerDark = Color(0xFFD6E4FF);

  static const Color surfaceDark = Color(0xFF1A1C1E);
  static const Color onSurfaceDark = Color(0xFFE3E2E6);
  static const Color surfaceVariantDark = Color(0xFF43474E);
  static const Color onSurfaceVariantDark = Color(0xFFC3C7CF);
  static const Color outlineDark = Color(0xFF8D9199);
  static const Color outlineVariantDark = Color(0xFF43474E);

  static const Color errorDark = Color(0xFFF2B8B5);
  static const Color onErrorDark = Color(0xFF601410);
  static const Color errorContainerDark = Color(0xFF8C1D18);
  static const Color onErrorContainerDark = Color(0xFFF9DEDC);
  static const Color successDark = Color(0xFF8CD99A);
  static const Color onSuccessDark = Color(0xFF0A2711);

  // ---- High-contrast overrides ----
  // Used by the stronger-contrast access preference. Pure black/white pairs
  // for body text exceed 20:1.
  static const Color primaryHighContrast = Color(0xFF0D4F47);
  static const Color onPrimaryHighContrast = Color(0xFFFFFFFF);
  static const Color surfaceHighContrast = Color(0xFFFFFFFF);
  static const Color onSurfaceHighContrast = Color(0xFF000000);
  static const Color surfaceVariantHighContrast = Color(0xFFEDEDED);
  static const Color onSurfaceVariantHighContrast = Color(0xFF1A1A1A);
  static const Color outlineHighContrast = Color(0xFF333333);
  static const Color errorHighContrast = Color(0xFF7A0E0A);

  static const Color primaryDarkHighContrast = Color(0xFFB2DFDB);
  static const Color onPrimaryDarkHighContrast = Color(0xFF000000);
  static const Color surfaceDarkHighContrast = Color(0xFF000000);
  static const Color onSurfaceDarkHighContrast = Color(0xFFFFFFFF);
  static const Color surfaceVariantDarkHighContrast = Color(0xFF1A1A1A);
  static const Color onSurfaceVariantDarkHighContrast = Color(0xFFFFFFFF);
  static const Color outlineDarkHighContrast = Color(0xFFCCCCCC);
  static const Color errorDarkHighContrast = Color(0xFFFFB4AB);
}
