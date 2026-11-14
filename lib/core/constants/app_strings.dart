/// All user-facing strings for SYNC.
///
/// No string literal that is shown to the user should appear in a build
/// method; reference it from here instead. Parameterised strings use small
/// helper methods so the format lives in one place.
class AppStrings {
  AppStrings._();

  // ---- App identity ----
  static const String appName = 'SYNC';
  static const String appTagline = 'Apply for work, your way.';
  static const String appNameFull = 'SYNC — Accessible Onboarding';

  // ---- Common navigation ----
  static const String next = 'Next';
  static const String back = 'Back';
  static const String continueLabel = 'Continue';
  static const String skip = 'Skip this step';
  static const String save = 'Save';
  static const String saveAndContinue = 'Save and continue';
  static const String edit = 'Edit';
  static const String goBack = 'Go back';
  static const String getStarted = 'Get started';
  static const String iHaveAnAccount = 'I already have an account';

  // ---- Accessibility helper text ----
  static const String tapToSpeak = 'Tap to record your answer by voice';
  static const String listening = 'Listening…';
  static const String voiceUnavailable = 'Voice input is not ready yet. You can type your answer.';

  /// Announced to screen readers as the user moves between form steps.
  static String stepProgress(int current, int total) =>
      'Step $current of $total';

  /// Visual progress label shown above the form.
  static String stepProgressLabel(int current, int total) =>
      'Step $current of $total';

  // ---- Welcome ----
  static const String welcomeHeading = 'Welcome to SYNC';
  static const String welcomeBody =
      'SYNC helps you apply for work in the way that suits you best. '
      'You can type, use your voice, take extra time, and choose how questions '
      'are shown. Nothing you tell us here is shared without your permission.';
  static const String readAloud = 'Read this screen aloud';
  static const String readAloudHint = 'Hear the welcome text spoken out loud';

  // ---- Access preferences ----
  static const String accessPreferencesHeading = 'Your access preferences';
  static const String accessPreferencesHint =
      'Choose how SYNC should work for you. You can change these any time. '
      'These choices make up your Access Passport.';
  static const String answerModeQuestion = 'How do you prefer to answer questions?';
  static const String answerVoice = 'Prefer voice answers';
  static const String answerTyped = 'Prefer typed answers';
  static const String answerEither = 'Either is fine';
  static const String readAloudPref = 'Read questions and instructions aloud';
  static const String simplerWording = 'Use simpler wording';
  static const String largerText = 'Use larger text';
  static const String strongerContrast = 'Use stronger contrast';
  static const String extraTime = 'Allow extra time, avoid forced limits';
  static const String largerTextHint =
      'Makes text bigger across the whole app. You can still change it later.';
  static const String strongerContrastHint =
      'Switches to a high-contrast colour scheme across the whole app.';
  static const String extraTimeHint =
      'Tells SYNC never to rush you with timers.';
  static const String yes = 'Yes';
  static const String no = 'No';

  // ---- Contact ----
  static const String contactFlowTitle = 'How can we reach you?';
  static const String fullNameQuestion = 'What is your full name?';
  static const String fullNameHint = 'The name you want employers to see.';
  static const String phoneQuestion = 'What is your phone number?';
  static const String phoneHint = 'A number we can contact you on.';
  static const String emailQuestion = 'What is your email? (optional)';
  static const String emailHint = 'Leave this blank if you do not have one.';

  // ---- Identity route ----
  static const String identityHeading = 'How would you like to verify your identity?';
  static const String identityHint =
      'You only need one option. You can change this later.';
  static const String identityNationalId = 'Standard national ID';
  static const String identityNationalIdDesc =
      'Use an official national ID card.';
  static const String identityRefugeeId = 'Refugee ID';
  static const String identityRefugeeIdDesc =
      'Use a refugee ID or registration document.';
  static const String identityOtherDoc = 'Other supporting document';
  static const String identityOtherDocDesc =
      'Use another official document, such as a birth certificate.';
  static const String identityPartner = 'Refer me through a partner';
  static const String identityPartnerDesc =
      'A trusted partner organisation helps verify your identity.';

  // ---- Skills ----
  static const String skillsFlowTitle = 'Tell us about your experience';
  static const String occupationQuestion = 'What is your current occupation or field?';
  static const String occupationHint = 'For example: farming, retail, teaching.';
  static const String educationQuestion = 'What is your highest education level?';
  static const String educationHint = 'Choose the one that fits best.';
  static const String educationPrimary = 'Primary school';
  static const String educationSecondary = 'Secondary school';
  static const String educationVocational = 'Vocational training';
  static const String educationUniversity = 'University';
  static const String educationNoneOrOther = 'None or other';
  static const String keySkillsQuestion = 'What are your key skills?';
  static const String keySkillsHint = 'Separate them with commas, or speak them.';
  static const String languagesQuestion = 'Which languages do you speak?';
  static const String languagesHint = 'Separate them with commas, or speak them.';

  // ---- Support preferences ----
  static const String supportHeading = 'Your support preferences';
  static const String supportPrivacy =
      'This information stays private. It is never shared with employers.';
  static const String supportWrittenInstructions = 'Written instructions preferred';
  static const String supportExtraTime = 'Extra interview time';
  static const String supportRemote = 'Remote interview';
  static const String supportOther = 'Other';
  static const String supportOtherHint = 'Tell us what would help.';

  // ---- Profile review ----
  static const String profileReviewHeading = 'Review your profile';
  static const String profileReviewHint =
      'Check everything is correct. You can edit any section.';
  static const String sectionName = 'Name';
  static const String sectionContact = 'Contact';
  static const String sectionIdentity = 'Identity route';
  static const String sectionSkills = 'Skills';
  static const String sectionLanguages = 'Languages';
  static const String sectionAccessPreferences = 'Access preferences';
  static const String sectionSupport = 'Support preferences';
  static const String notProvided = 'Not provided';
  static const String saveProfile = 'Save profile';
  static const String profileSavedTitle = 'Profile saved';
  static const String profileSavedBody =
      'Your profile is ready. You can now browse jobs.';
  static const String exploreJobs = 'Explore jobs';

  // ---- Validation ----
  static const String requiredError = 'This field is required.';
  static const String invalidPhoneError = 'Please enter a valid phone number.';
  static const String invalidEmailError = 'Please enter a valid email address.';
  static const String chooseOptionError = 'Please choose an option to continue.';

  // ---- Semantic state / hints (announced to assistive tech) ----
  static const String stateSelected = 'Selected';
  static const String stateNotSelected = 'Not selected';
  static String editSectionHint(String section) =>
      'Double tap to change your $section.';

  // ---- Stub screens (Phase 2) ----
  static const String jobsHeading = 'Job listings';
  static const String jobsStubBody = 'Job listings are coming soon.';
  static const String signInHeading = 'Sign in';
  static const String signInStubBody = 'Sign in is coming soon.';
  static const String profileStubBody = 'Profile management is coming in Phase 2.';
}
