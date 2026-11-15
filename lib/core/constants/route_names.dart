/// Named route identifiers and path templates for go_router.
///
/// Keeping paths and names together makes it impossible to mismatch the string
/// a screen navigates with the route that handles it.
class RouteNames {
  RouteNames._();

  static const String welcome = 'welcome';
  static const String accessPreferences = 'access-preferences';
  static const String contact = 'contact';
  static const String identity = 'identity';
  static const String skills = 'skills';
  static const String support = 'support';
  static const String profileReview = 'profile-review';
  static const String signIn = 'sign-in';

  // Job/application flow.
  static const String jobs = 'jobs';
  static const String myJobs = 'my-jobs';
  static const String profile = 'profile';
  static const String more = 'more';

  // Career gateway: employer postings + application answers.
  static const String employerJobs = 'employer-jobs';
  static const String employerJobForm = 'employer-job-form';
  static const String applyJob = 'apply-job';
}

class AppRoutes {
  AppRoutes._();

  static const String welcome = '/';
  static const String accessPreferences = '/onboarding/access-preferences';
  static const String contact = '/onboarding/contact';
  static const String identity = '/onboarding/identity';
  static const String skills = '/onboarding/skills';
  static const String support = '/onboarding/support';
  static const String profileReview = '/onboarding/profile-review';
  static const String signIn = '/sign-in';

  // Job/application flow.
  static const String jobs = '/jobs';
  static const String myJobs = '/my-jobs';
  static const String profile = '/profile';
  static const String more = '/more';

  // Career gateway: employer postings + application answers.
  static const String employerJobs = '/employer-jobs';
  static const String employerJobForm = '/employer-jobs/form';
  static const String applyJob = '/jobs/apply';
}
