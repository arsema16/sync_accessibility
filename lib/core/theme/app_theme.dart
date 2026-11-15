import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Builds the four ThemeData variants used by SYNC.
///
/// [light] and [dark] are the defaults. [highContrastLight] and
/// [highContrastDark] are selected when the user enables "use stronger
/// contrast"; they push text/background pairs toward pure black/white for
/// maximum legibility. Color is never the sole state indicator anywhere in the
/// component themes (selected and error states also use icons/weight).
class AppTheme {
  AppTheme._();

  static ThemeData light() => _base(
        const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          secondaryContainer: AppColors.secondaryContainer,
          onSecondaryContainer: AppColors.onSecondaryContainer,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          surfaceContainerHighest: AppColors.surfaceVariant,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          outline: AppColors.outline,
          outlineVariant: AppColors.outlineVariant,
          error: AppColors.error,
          onError: AppColors.onError,
          errorContainer: AppColors.errorContainer,
          onErrorContainer: AppColors.onErrorContainer,
        ),
        Brightness.light,
      );

  static ThemeData dark() => _base(
        const ColorScheme.dark(
          primary: AppColors.primaryDark,
          onPrimary: AppColors.onPrimaryDark,
          primaryContainer: AppColors.primaryContainerDark,
          onPrimaryContainer: AppColors.onPrimaryContainerDark,
          secondary: AppColors.secondaryDark,
          onSecondary: AppColors.onSecondaryDark,
          secondaryContainer: AppColors.secondaryContainerDark,
          onSecondaryContainer: AppColors.onSecondaryContainerDark,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.onSurfaceDark,
          surfaceContainerHighest: AppColors.surfaceVariantDark,
          onSurfaceVariant: AppColors.onSurfaceVariantDark,
          outline: AppColors.outlineDark,
          outlineVariant: AppColors.outlineVariantDark,
          error: AppColors.errorDark,
          onError: AppColors.onErrorDark,
          errorContainer: AppColors.errorContainerDark,
          onErrorContainer: AppColors.onErrorContainerDark,
        ),
        Brightness.dark,
      );

  static ThemeData highContrastLight() => _base(
        const ColorScheme.light(
          primary: AppColors.primaryHighContrast,
          onPrimary: AppColors.onPrimaryHighContrast,
          primaryContainer: AppColors.surfaceVariantHighContrast,
          onPrimaryContainer: AppColors.onSurfaceHighContrast,
          secondary: AppColors.primaryHighContrast,
          onSecondary: AppColors.onPrimaryHighContrast,
          surface: AppColors.surfaceHighContrast,
          onSurface: AppColors.onSurfaceHighContrast,
          surfaceContainerHighest: AppColors.surfaceVariantHighContrast,
          onSurfaceVariant: AppColors.onSurfaceVariantHighContrast,
          outline: AppColors.outlineHighContrast,
          outlineVariant: AppColors.outlineHighContrast,
          error: AppColors.errorHighContrast,
          onError: AppColors.onPrimaryHighContrast,
          errorContainer: AppColors.errorContainer,
          onErrorContainer: AppColors.onErrorContainer,
        ),
        Brightness.light,
      );

  static ThemeData highContrastDark() => _base(
        const ColorScheme.dark(
          primary: AppColors.primaryDarkHighContrast,
          onPrimary: AppColors.onPrimaryDarkHighContrast,
          primaryContainer: AppColors.primaryContainerDark,
          onPrimaryContainer: AppColors.onPrimaryDarkHighContrast,
          secondary: AppColors.primaryDarkHighContrast,
          onSecondary: AppColors.onPrimaryDarkHighContrast,
          surface: AppColors.surfaceDarkHighContrast,
          onSurface: AppColors.onSurfaceDarkHighContrast,
          surfaceContainerHighest: AppColors.surfaceVariantDarkHighContrast,
          onSurfaceVariant: AppColors.onSurfaceVariantDarkHighContrast,
          outline: AppColors.outlineDarkHighContrast,
          outlineVariant: AppColors.outlineDarkHighContrast,
          error: AppColors.errorDarkHighContrast,
          onError: AppColors.onPrimaryDarkHighContrast,
          errorContainer: AppColors.errorContainerDark,
          onErrorContainer: AppColors.onPrimaryDarkHighContrast,
        ),
        Brightness.dark,
      );

  static ThemeData _base(ColorScheme scheme, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isLight ? Colors.white : scheme.surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: _textTheme(scheme),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: scheme.onSurface),
      ),
      inputDecorationTheme: _inputDecoration(scheme),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          textStyle: AppTextStyles.labelLarge,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(50)),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          textStyle: AppTextStyles.labelLarge,
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(50)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          textStyle: AppTextStyles.labelLarge,
          foregroundColor: scheme.primary,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(50)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSpacing.minTapTarget, AppSpacing.minTapTarget),
          textStyle: AppTextStyles.labelLarge,
          foregroundColor: scheme.primary,
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: AppTextStyles.labelMedium.copyWith(color: scheme.onSurface),
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.onPrimaryContainer,
        side: BorderSide(color: scheme.outline, width: isLight ? 1.4 : 1.0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: scheme.outlineVariant, width: 1),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.onSurface,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: scheme.surface),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? Colors.white : scheme.surface,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: isLight ? const Color(0xFF1A1A1A) : scheme.onSurface,
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: isLight ? const Color(0xFF1A1A1A) : scheme.onSurface,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final base = <TextStyle, TextStyle Function(TextStyle)>{
      AppTextStyles.displayLarge: (s) => s.copyWith(color: scheme.onSurface),
      AppTextStyles.headlineLarge: (s) => s.copyWith(color: scheme.onSurface),
      AppTextStyles.headlineMedium: (s) => s.copyWith(color: scheme.onSurface),
      AppTextStyles.titleLarge: (s) => s.copyWith(color: scheme.onSurface),
      AppTextStyles.bodyLarge: (s) => s.copyWith(color: scheme.onSurface),
      AppTextStyles.bodyMedium: (s) => s.copyWith(color: scheme.onSurface),
      AppTextStyles.bodySmall: (s) => s.copyWith(color: scheme.onSurfaceVariant),
      AppTextStyles.labelLarge: (s) => s.copyWith(color: scheme.onSurface),
      AppTextStyles.labelMedium: (s) => s.copyWith(color: scheme.onSurfaceVariant),
    };
    return TextTheme(
      displayLarge: base[AppTextStyles.displayLarge]!(AppTextStyles.displayLarge),
      displayMedium: AppTextStyles.headlineLarge.copyWith(color: scheme.onSurface),
      displaySmall: AppTextStyles.headlineLarge.copyWith(color: scheme.onSurface),
      headlineLarge: base[AppTextStyles.headlineLarge]!(AppTextStyles.headlineLarge),
      headlineMedium: base[AppTextStyles.headlineMedium]!(AppTextStyles.headlineMedium),
      headlineSmall: AppTextStyles.headlineLarge.copyWith(color: scheme.onSurface),
      titleLarge: base[AppTextStyles.titleLarge]!(AppTextStyles.titleLarge),
      titleMedium: AppTextStyles.labelLarge.copyWith(color: scheme.onSurface),
      titleSmall: AppTextStyles.labelMedium.copyWith(color: scheme.onSurface),
      bodyLarge: base[AppTextStyles.bodyLarge]!(AppTextStyles.bodyLarge),
      bodyMedium: base[AppTextStyles.bodyMedium]!(AppTextStyles.bodyMedium),
      bodySmall: base[AppTextStyles.bodySmall]!(AppTextStyles.bodySmall),
      labelLarge: base[AppTextStyles.labelLarge]!(AppTextStyles.labelLarge),
      labelMedium: base[AppTextStyles.labelMedium]!(AppTextStyles.labelMedium),
      labelSmall: AppTextStyles.bodySmall.copyWith(color: scheme.onSurfaceVariant),
    );
  }

  static InputDecorationTheme _inputDecoration(ColorScheme scheme) {
    final outline = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: scheme.outline, width: 1.5),
    );
    final focused = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: scheme.primary, width: 2),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      labelStyle: AppTextStyles.labelLarge.copyWith(color: scheme.onSurfaceVariant),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: scheme.onSurfaceVariant),
      helperStyle: AppTextStyles.helper.copyWith(color: scheme.onSurfaceVariant),
      errorStyle: AppTextStyles.error.copyWith(color: scheme.error),
      border: outline,
      enabledBorder: outline,
      focusedBorder: focused,
      disabledBorder: outline,
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
    );
  }
}
