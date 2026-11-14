import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_spacing.dart';

/// The SYNC entry point. Two primary actions plus a read-aloud helper.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  static const Color _teal = Color(0xFF1B7A6E);
  static const Color _tealDark = Color(0xFF0D4F47);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_teal, _tealDark],
              ),
            ),
          ),
          // City skyline silhouette at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _SkylineSilhouette(screenWidth: size.width),
          ),
          // Scrollable content overlay
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  // Logo
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco,
                        size: 48,
                        color: _teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Wordmark
                  const Text(
                    'Sync',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Tagline
                  const Text(
                    'Your Ability. Our Opportunity.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Subtitle
                  const Text(
                    'An inclusive way to find and apply for jobs',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  // Get Started button — white fill, teal text
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _teal,
                      minimumSize: const Size.fromHeight(AppSpacing.minTapTarget),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                      ),
                    ),
                    onPressed: () {
                      ref.read(onboardingDraftProvider.notifier).reset();
                      context.pushNamed(RouteNames.accessPreferences);
                    },
                    child: const Text(
                      'Get Started →',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Accessibility Options / sign-in link
                  TextButton(
                    onPressed: () => context.pushNamed(RouteNames.signIn),
                    child: const Text(
                      'Accessibility Options',
                      style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Read aloud
                  Semantics(
                    label: AppStrings.readAloud,
                    hint: AppStrings.readAloudHint,
                    button: true,
                    child: TextButton.icon(
                      onPressed: () {
                        final readAloud = ref.read(readAloudProvider);
                        readAloud(
                          'Sync. Your Ability. Our Opportunity. '
                          'An inclusive way to find and apply for jobs.',
                        );
                      },
                      icon: const Icon(Icons.volume_up, color: Colors.white),
                      label: const Text(
                        AppStrings.readAloud,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  // Extra space so content clears the skyline
                  SizedBox(height: size.height * 0.18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple row of dark-teal rectangles suggesting a city skyline.
class _SkylineSilhouette extends StatelessWidget {
  const _SkylineSilhouette({required this.screenWidth});

  final double screenWidth;

  static const Color _skylineFill = Color(0xFF0D4F47);

  @override
  Widget build(BuildContext context) {
    // Heights chosen to look like a varied skyline
    const heights = [40.0, 70.0, 55.0, 90.0, 60.0, 80.0, 45.0, 65.0, 50.0, 75.0, 40.0, 60.0];
    final count = heights.length;
    final tileWidth = screenWidth / count;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(count, (i) {
        return Container(
          width: tileWidth,
          height: heights[i],
          decoration: BoxDecoration(
            color: _skylineFill,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(i.isEven ? 6 : 2),
              topRight: Radius.circular(i.isOdd ? 6 : 2),
            ),
          ),
        );
      }),
    );
  }
}
