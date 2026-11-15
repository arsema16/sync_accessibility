import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// The SYNC entry point. Two primary actions plus a read-aloud helper.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // Read the welcome copy aloud on arrival when read-aloud is on — the
    // same text the on-screen "Read aloud" button speaks.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final access = ref.read(accessPreferencesNotifierProvider);
      if (access.readAloud) {
        ref.read(readAloudProvider)(
          'SYNC. Your Ability. Our Opportunity. '
          'An inclusive way to find and apply for jobs.',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: AppColors.pageGradientEnd,
      body: Stack(
        children: [
          // Full-screen gradient background
          const SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.pageGradientStart,
                    AppColors.pageGradientEnd,
                  ],
                ),
              ),
            ),
          ),
          // Decorative teal shapes behind the card
          Positioned(top: -40, right: -30, child: ExcludeSemantics(child: _WelcomeShapes())),
          // City skyline silhouette at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ExcludeSemantics(child: _SkylineSilhouette(screenWidth: size.width)),
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
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(36)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowSoft,
                              blurRadius: 30,
                              offset: Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo: teal gradient circle with a mic, matching
                            // the launcher icon. Decorative — the SYNC wordmark
                            // below is the accessible label.
                            Center(
                              child: ExcludeSemantics(
                                child: Container(
                                width: 88,
                                height: 88,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.heroStart,
                                      AppColors.heroEnd,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.mic,
                                  size: 44,
                                  color: Colors.white,
                                ),
                              ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            // Wordmark
                            const Text(
                              'SYNC',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                                color: AppColors.cardInk,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            // Tagline
                            const Text(
                              'Your Ability. Our Opportunity.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            // Subtitle
                            const Text(
                              'An inclusive way to find and apply for jobs',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.5,
                                height: 1.45,
                                color: AppColors.cardInkMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            // Get Started button — teal fill, white text
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(
                                  AppSpacing.minTapTarget,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50)),
                                ),
                              ),
                              onPressed: () {
                                ref
                                    .read(onboardingDraftProvider.notifier)
                                    .reset();
                                context.pushNamed(RouteNames.accessPreferences);
                              },
                              child: const Text(
                                'Get Started →',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Sign in — a full-width outlined button so a
                            // returning user spots it straight away (the old
                            // "Accessibility Options" link already navigated
                            // here, just under a name nobody looked for).
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                ),
                                minimumSize: const Size.fromHeight(
                                  AppSpacing.minTapTarget,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50)),
                                ),
                              ),
                              onPressed: () =>
                                  context.pushNamed(RouteNames.signIn),
                              child: const Text(
                                AppStrings.signInAction,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            // Read aloud
                            Semantics(
                              label: AppStrings.readAloud,
                              hint: AppStrings.readAloudHint,
                              button: true,
                              child: TextButton.icon(
                                onPressed: () {
                                  final readAloud =
                                      ref.read(readAloudProvider);
                                  readAloud(
                                    'SYNC. Your Ability. Our Opportunity. '
                                    'An inclusive way to find and apply for jobs.',
                                  );
                                },
                                icon: const Icon(
                                  Icons.volume_up,
                                  color: AppColors.primary,
                                ),
                                label: const Text(
                                  AppStrings.readAloud,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Extra space so content clears the skyline
                  SizedBox(height: size.height * 0.16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Decorative teal shapes echoing the reference card artwork. Purely
/// ornamental, so they carry no semantics.
class _WelcomeShapes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 190,
      child: Stack(
        children: [
          Positioned(
            top: 20,
            right: 40,
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: AppColors.cardMint,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 90,
            right: 100,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.cardAqua,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple row of soft-teal rectangles suggesting a city skyline.
class _SkylineSilhouette extends StatelessWidget {
  const _SkylineSilhouette({required this.screenWidth});

  final double screenWidth;

  static const Color _skylineFill = AppColors.cardMint;

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
