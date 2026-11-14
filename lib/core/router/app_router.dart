import 'package:go_router/go_router.dart';

import '../../features/jobs/jobs_screen.dart';
import '../../features/onboarding/access_preferences_screen.dart';
import '../../features/onboarding/contact_screen.dart';
import '../../features/onboarding/identity_route_screen.dart';
import '../../features/onboarding/profile_review_screen.dart';
import '../../features/onboarding/sign_in_screen.dart';
import '../../features/onboarding/skills_screen.dart';
import '../../features/onboarding/support_preferences_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../constants/route_names.dart';

/// The app's [GoRouter]. Every onboarding screen has a named route, plus stub
/// routes for the job/application flow (Phase 2).
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.welcome,
  routes: <RouteBase>[
    GoRoute(
      name: RouteNames.welcome,
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      name: RouteNames.accessPreferences,
      path: AppRoutes.accessPreferences,
      builder: (context, state) => const AccessPreferencesScreen(),
    ),
    GoRoute(
      name: RouteNames.contact,
      path: AppRoutes.contact,
      builder: (context, state) => const ContactScreen(),
    ),
    GoRoute(
      name: RouteNames.identity,
      path: AppRoutes.identity,
      builder: (context, state) => const IdentityRouteScreen(),
    ),
    GoRoute(
      name: RouteNames.skills,
      path: AppRoutes.skills,
      builder: (context, state) => const SkillsScreen(),
    ),
    GoRoute(
      name: RouteNames.support,
      path: AppRoutes.support,
      builder: (context, state) => const SupportPreferencesScreen(),
    ),
    GoRoute(
      name: RouteNames.profileReview,
      path: AppRoutes.profileReview,
      builder: (context, state) => const ProfileReviewScreen(),
    ),
    GoRoute(
      name: RouteNames.signIn,
      path: AppRoutes.signIn,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      name: RouteNames.jobs,
      path: AppRoutes.jobs,
      builder: (context, state) => const JobsScreen(),
    ),
    GoRoute(
      name: RouteNames.profile,
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
