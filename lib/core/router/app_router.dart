import 'package:go_router/go_router.dart';

import '../../features/jobs/apply_job_screen.dart';
import '../../features/jobs/employer_job_form_screen.dart';
import '../../features/jobs/employer_jobs_screen.dart';
import '../../features/jobs/jobs_screen.dart';
import '../../features/jobs/my_jobs_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/onboarding/access_preferences_screen.dart';
import '../../features/onboarding/contact_screen.dart';
import '../../features/onboarding/identity_route_screen.dart';
import '../../features/onboarding/profile_review_screen.dart';
import '../../features/onboarding/sign_in_screen.dart';
import '../../features/onboarding/skills_screen.dart';
import '../../features/onboarding/support_preferences_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../models/job_model.dart';
import '../constants/route_names.dart';

/// The flat route table. Extracted so tests can build a [GoRouter] with a
/// different [GoRouter.initialLocation] against the same screens and builders.
///
/// Onboarding screens that can be edited from Profile Review read
/// [GoRouterState.extra]: when it is `true` the screen is in "edit mode" and
/// completing it pops back to review instead of advancing the flow.
final List<RouteBase> appRouteList = <RouteBase>[
  GoRoute(
    name: RouteNames.welcome,
    path: AppRoutes.welcome,
    builder: (context, state) => const WelcomeScreen(),
  ),
  GoRoute(
    name: RouteNames.accessPreferences,
    path: AppRoutes.accessPreferences,
    builder: (context, state) =>
        AccessPreferencesScreen(editMode: state.extra == true),
  ),
  GoRoute(
    name: RouteNames.contact,
    path: AppRoutes.contact,
    builder: (context, state) => ContactScreen(editMode: state.extra == true),
  ),
  GoRoute(
    name: RouteNames.identity,
    path: AppRoutes.identity,
    builder: (context, state) =>
        IdentityRouteScreen(editMode: state.extra == true),
  ),
  GoRoute(
    name: RouteNames.skills,
    path: AppRoutes.skills,
    builder: (context, state) => SkillsScreen(editMode: state.extra == true),
  ),
  GoRoute(
    name: RouteNames.support,
    path: AppRoutes.support,
    builder: (context, state) =>
        SupportPreferencesScreen(editMode: state.extra == true),
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
    name: RouteNames.myJobs,
    path: AppRoutes.myJobs,
    builder: (context, state) => const MyJobsScreen(),
  ),
  GoRoute(
    name: RouteNames.profile,
    path: AppRoutes.profile,
    builder: (context, state) => const ProfileScreen(),
  ),
  GoRoute(
    name: RouteNames.more,
    path: AppRoutes.more,
    builder: (context, state) => const MoreScreen(),
  ),
  GoRoute(
    name: RouteNames.employerJobs,
    path: AppRoutes.employerJobs,
    builder: (context, state) => const EmployerJobsScreen(),
  ),
  GoRoute(
    name: RouteNames.employerJobForm,
    path: AppRoutes.employerJobForm,
    builder: (context, state) => EmployerJobFormScreen(
      existing: state.extra is Job ? state.extra as Job : null,
    ),
  ),
  GoRoute(
    name: RouteNames.applyJob,
    path: AppRoutes.applyJob,
    builder: (context, state) => ApplyJobScreen(
      // The jobs screen always passes the job; fall back safely if deep
      // links omit it.
      job: state.extra is Job
          ? state.extra as Job
          : const Job(id: '', title: '', employer: ''),
    ),
  ),
];

/// The app's [GoRouter]. Every onboarding screen has a named route, plus the
/// job/application flow (listings, applications, employer postings).
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.welcome,
  routes: appRouteList,
);
