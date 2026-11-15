import 'package:flutter/material.dart';

/// Raw color tokens for SYNC — modern lavender/purple palette.
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

  // ---- Brand (light) — purple ----
  static const Color primary = Color(0xFF7C3AED);       // vivid violet
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFEDE9FE); // soft lavender
  static const Color onPrimaryContainer = Color(0xFF3B0764);

  static const Color secondary = Color(0xFFA78BFA);     // lighter purple
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFF5F3FF);
  static const Color onSecondaryContainer = Color(0xFF4C1D95);

  // ---- Surfaces (light) ----
  static const Color surface = Color(0xFFFDFCFF);
  static const Color onSurface = Color(0xFF1A1A2E);
  static const Color surfaceVariant = Color(0xFFEDE9FE);
  static const Color onSurfaceVariant = Color(0xFF4A4560);
  static const Color outline = Color(0xFF8B84A3);
  static const Color outlineVariant = Color(0xFFD4CCF0);

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
  static const Color primaryDark = Color(0xFFC4B5FD);
  static const Color onPrimaryDark = Color(0xFF3B0764);
  static const Color primaryContainerDark = Color(0xFF5B21B6);
  static const Color onPrimaryContainerDark = Color(0xFFEDE9FE);

  static const Color secondaryDark = Color(0xFFA78BFA);
  static const Color onSecondaryDark = Color(0xFF2E1065);
  static const Color secondaryContainerDark = Color(0xFF4C1D95);
  static const Color onSecondaryContainerDark = Color(0xFFF5F3FF);

  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color onSurfaceDark = Color(0xFFE8E4F5);
  static const Color surfaceVariantDark = Color(0xFF2D2847);
  static const Color onSurfaceVariantDark = Color(0xFFC4B5FD);
  static const Color outlineDark = Color(0xFF8B84A3);
  static const Color outlineVariantDark = Color(0xFF3D3660);

  static const Color errorDark = Color(0xFFF2B8B5);
  static const Color onErrorDark = Color(0xFF601410);
  static const Color errorContainerDark = Color(0xFF8C1D18);
  static const Color onErrorContainerDark = Color(0xFFF9DEDC);
  static const Color successDark = Color(0xFF8CD99A);
  static const Color onSuccessDark = Color(0xFF0A2711);

  // ---- High-contrast overrides ----
  static const Color primaryHighContrast = Color(0xFF4C0FAD);
  static const Color onPrimaryHighContrast = Color(0xFFFFFFFF);
  static const Color surfaceHighContrast = Color(0xFFFFFFFF);
  static const Color onSurfaceHighContrast = Color(0xFF000000);
  static const Color surfaceVariantHighContrast = Color(0xFFEDEDED);
  static const Color onSurfaceVariantHighContrast = Color(0xFF1A1A1A);
  static const Color outlineHighContrast = Color(0xFF333333);
  static const Color errorHighContrast = Color(0xFF7A0E0A);

  static const Color primaryDarkHighContrast = Color(0xFFD8C4FF);
  static const Color onPrimaryDarkHighContrast = Color(0xFF000000);
  static const Color surfaceDarkHighContrast = Color(0xFF000000);
  static const Color onSurfaceDarkHighContrast = Color(0xFFFFFFFF);
  static const Color surfaceVariantDarkHighContrast = Color(0xFF1A1A1A);
  static const Color onSurfaceVariantDarkHighContrast = Color(0xFFFFFFFF);
  static const Color outlineDarkHighContrast = Color(0xFFCCCCCC);
  static const Color errorDarkHighContrast = Color(0xFFFFB4AB);

  // ---- Rounded-card UI — modern lavender style ----
  /// Lavender page background (matches the reference design background).
  static const Color pageGradientStart = Color(0xFFE8E4F8);
  static const Color pageGradientEnd = Color(0xFFF0EDFC);

  /// Hero banner gradient — rich purple.
  static const Color heroStart = Color(0xFF8B5CF6);
  static const Color heroEnd = Color(0xFF6D28D9);
  static const Color onHero = Color(0xFFFFFFFF);

  /// Vibrant accent cards (yellow, light-blue, pink).
  static const Color cardAmber = Color(0xFFFFD54F);     // amber/yellow card
  static const Color onCardAmber = Color(0xFF1A1200);   // near-black on amber
  static const Color cardAmberBadge = Color(0xFFFFF8E1);

  static const Color cardSky = Color(0xFFBBDEFB);       // light blue card
  static const Color onCardSky = Color(0xFF0D1B2A);     // dark ink on sky
  static const Color cardSkyBadge = Color(0xFFE3F2FD);

  static const Color cardPink = Color(0xFFF8BBD0);      // rose/pink accent
  static const Color onCardPink = Color(0xFF1A0010);

  /// Soft lavender chip / badge background.
  static const Color cardMint = Color(0xFFEDE9FE);
  static const Color cardAqua = Color(0xFFE8E4F8);
  static const Color cardSlate = Color(0xFFDCD8F0);
  static const Color cardDeep = Color(0xFF4C1D95);
  static const Color onCardDeep = Color(0xFFFFFFFF);

  /// Text and outline colours used on the white cards.
  static const Color cardInk = Color(0xFF14151A);
  static const Color cardInkMuted = Color(0xFF5F5B75);
  static const Color cardBorder = Color(0xFFE4E0F5);
  static const Color cardTrack = Color(0xFFDDD9EE);

  /// Soft shadows, pre-multiplied so no `withOpacity` calls are needed.
  static const Color shadowSoft = Color(0x1A7C3AED); // 10% purple
  static const Color shadowCard = Color(0x1414151A); // 8% ink
  static const Color shadowHero = Color(0x336D28D9); // 20% deep purple

  /// The dark floating navigation capsule.
  static const Color navBar = Color(0xFF14151A);
  static const Color navBarShadow = Color(0x3814151A); // 22% ink
  static const Color navItemIdle = Color(0xB3FFFFFF);  // white 70%
}
