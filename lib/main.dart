import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/supabase_config.dart';
import 'core/constants/app_strings.dart';
import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_spacing.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await SupabaseBootstrap.initialize();

  // Build the provider container first so the router redirect can read
  // auth state synchronously on startup.
  final container = ProviderContainer(
    overrides: <Override>[
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // Build the router with access to the container.
  appRouter = buildAppRouter(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SyncApp(),
    ),
  );
}

/// Root widget. Reads the Access Passport so the larger-text and
/// stronger-contrast preferences apply app-wide.
class SyncApp extends ConsumerWidget {
  const SyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessPreferencesNotifierProvider);
    final theme = access.strongerContrast ? AppTheme.highContrastLight() : AppTheme.light();
    final darkTheme = access.strongerContrast ? AppTheme.highContrastDark() : AppTheme.dark();

    return MaterialApp.router(
      title: AppStrings.appNameFull,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final scaled = access.largerText
            ? mediaQuery.textScaler.clamp(
                minScaleFactor: AppSpacing.largeTextScale,
              )
            : mediaQuery.textScaler;
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: scaled),
          child: child!,
        );
      },
    );
  }
}
