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
  static const String speakInstead = 'Speak instead';
  static const String listening = 'Listening…';
  static const String voiceUnavailable = 'Voice input is not ready yet. You '
      'can type your answer, or check that your phone lets SYNC use the '
      'microphone.';
  static const String voiceNoSpeech = 'We didn’t catch that. Tap the mic '
      'and start speaking straight away — keep talking until your words '
      'appear.';

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
  static const String readJobAloud = 'Read this job aloud';

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

  // Simpler-wording variants (Access Passport → "Use simpler wording").
  static const String fullNameQuestionSimple = 'What is your name?';
  static const String fullNameHintSimple = 'Your name.';
  static const String phoneQuestionSimple = 'What number can we call?';
  static const String phoneHintSimple = 'Your phone number.';
  static const String emailQuestionSimple = 'Your email (you can skip this).';
  static const String emailHintSimple = 'No email? Skip this.';

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
  static const String identityHeadingSimple = 'How do you want to prove who you are?';
  static const String identityHintSimple = 'Pick one. You can change it later.';

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

  // Simpler-wording variants for the skills steps.
  static const String occupationQuestionSimple = 'What work do you do now?';
  static const String occupationHintSimple = 'For example: farm, shop, teach.';
  static const String educationQuestionSimple = 'What is the last school you finished?';
  static const String educationHintSimple = 'Tap the one that fits.';
  static const String keySkillsQuestionSimple = 'What are you good at?';
  static const String keySkillsHintSimple = 'Say or type them.';
  static const String languagesQuestionSimple = 'What languages do you speak?';
  static const String languagesHintSimple = 'Say or type them.';

  // ---- Support preferences ----
  static const String supportHeading = 'Your support preferences';
  static const String supportPrivacy =
      'This information stays private. It is never shared with employers.';
  static const String supportWrittenInstructions = 'Written instructions preferred';
  static const String supportExtraTime = 'Extra interview time';
  static const String supportRemote = 'Remote interview';
  static const String supportOther = 'Other';
  static const String supportOtherHint = 'Tell us what would help.';
  static const String supportHeadingSimple = 'What would help you?';
  static const String supportSubtitle =
      'Select any options that make applying or interviewing easier.';
  static const String supportSubtitleSimple =
      'Tap what makes it easier for you.';

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
  static const String saving = 'Saving…';
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

  // ---- Account / authentication ----
  static const String signInHeading = 'Sign in';
  static const String signInSubtitle =
      'Sign in to keep your profile and applications in sync.';
  static const String createAccountHeading = 'Create your account';
  static const String createAccountSubtitle =
      'One account keeps your profile and applications safe.';
  static const String emailLabel = 'Email address';
  static const String authEmailHint = 'The email you use to sign in.';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'At least 6 characters.';
  static const String showPassword = 'Show password';
  static const String hidePassword = 'Hide password';
  static const String signInAction = 'Sign in';
  static const String createAccountAction = 'Create account';
  static const String switchToSignUp = 'Create a new account';
  static const String passwordTooShort =
      'Please choose a password of at least 6 characters.';
  static const String authFailed =
      'Something went wrong. Please try again.';
  static const String authPromptTitle = 'Sign in to continue';
  static const String cancel = 'Cancel';
  static String signedInAs(String email) => 'Signed in as $email';
  static const String notSignedIn = 'Not signed in';
  static const String signInToContinue = 'Sign in to sync your profile.';
  static const String continueToJobs = 'Continue to jobs';
  static const String signOut = 'Sign out';
  static const String signedOutMessage = 'You have been signed out.';
  static String confirmationSent(String email) =>
      'We sent a confirmation email to $email. Open it to confirm your '
      'account, then sign in here.';

  /// Shown when account creation discovers the email already belongs to an
  /// account: the form hands over to sign-in with the address kept.
  static const String accountExistsSignIn =
      'You already have an account. Sign in with your password to continue.';

  // ---- Jobs ----
  static const String jobsHeading = 'Job listings';
  static const String jobsSearchHint = 'Search for jobs...';
  static const String jobsEmptyTitle = 'No jobs found';
  static const String jobsEmptyBody =
      'Try a different search or filter.';
  static const String jobsLoadFailed =
      'Could not load jobs. Please try again.';
  static const String apply = 'Apply';
  static const String applied = 'Applied';
  static const String applicationSent = 'Application sent.';
  static const String applicationFailed =
      'Could not send your application. Please try again.';
  static const String withdraw = 'Withdraw';
  static const String applicationWithdrawn = 'Application withdrawn.';
  static String signInToApply(String title) =>
      'Sign in to apply for $title.';
  static const String myJobsEmptyTitle = 'No applications yet';
  static const String myJobsEmptyBody =
      'Jobs you apply for will appear here.';
  static const String signInToSeeApplications =
      'Sign in to see your applications.';
  static const String tryAgain = 'Try again';

  // ---- Support-needs job filter (private, matched locally) ----
  static const String filterMySupport = 'My support';
  static const String supportFilterUnavailableTitle =
      'Sign in to filter by your support needs';
  static const String supportFilterUnavailableBody =
      'This filter matches your private support preferences against job '
      'accommodations. It stays on your side — employers never see it.';
  static const String supportFilterNoPrefsTitle =
      'No support preferences saved yet';
  static const String supportFilterNoPrefsBody =
      'Add what would help you in your profile, then this filter will find '
      'jobs that offer it.';
  static const String supportFilterEditPrefs = 'Edit support preferences';
  static const String supportFilterEmptyTitle = 'No jobs match your needs yet';
  static const String supportFilterEmptyBody =
      'Nothing in the current listings offers everything you asked for. '
      'Try removing a filter to see more jobs.';
  static const String supportFilterMatchedHint =
      'Jobs that offer the support you asked for.';

  // ---- Employer job form ----
  static const String employerJobsTitle = 'My job postings';
  static const String employerJobsEmptyTitle = 'No jobs posted yet';
  static const String employerJobsEmptyBody =
      'Post a job with the accommodations it offers so the right people can '
      'find it.';
  static const String employerSignInTitle = 'Sign in to manage your jobs';
  static const String employerSignInBody =
      'Job postings are tied to your account so only you can edit them.';
  static const String employerPostJob = 'Post a job';
  static const String employerEditJob = 'Edit job';
  static const String employerJobSaved = 'Job saved.';
  static const String employerJobSaveFailed =
      'Could not save the job. Please try again.';
  static const String employerJobDelete = 'Delete';
  static const String employerJobDeleted = 'Job deleted.';
  static const String employerJobTitleLabel = 'Job title';
  static const String employerJobTitleHint = 'For example: Warehouse assistant.';
  static const String employerJobTitleSimple = 'What is the job called?';
  static const String employerJobEmployerLabel = 'Organisation name';
  static const String employerJobEmployerHint = 'The company or group hiring.';
  static const String employerJobEmployerSimple = 'Who is hiring?';
  static const String employerJobLocationLabel = 'Location';
  static const String employerJobLocationHint =
      'City, or "Remote" if there is no office.';
  static const String employerJobLocationSimple = 'Where is the job?';
  static const String employerJobDescriptionLabel = 'What the job involves';
  static const String employerJobDescriptionHint =
      'A short description of the work.';
  static const String employerJobDescriptionSimple = 'What will they do?';
  static const String employerJobAccommodationsLabel =
      'What does this job offer?';
  static const String employerJobAccommodationsHint =
      'Pick everything the job provides. Job seekers filter by these.';
  static const String employerJobAccommodationsSimple =
      'What does the job give?';
  static const String employerJobDeleteConfirm =
      'Delete this job posting? This cannot be undone.';

  // ---- Job application flow (voice answers) ----
  static const String applyFlowTitle = 'Apply';
  static const String applyWhyQuestion = 'Why do you want this job?';
  static const String applyWhyHint =
      'A short note the employer will read with your application.';
  static const String applyWhySimple = 'Why do you want this job?';
  static const String applyWhyHintSimple = 'Say it or type it.';
  static const String applyExperienceQuestion =
      'What experience would you bring?';
  static const String applyExperienceHint =
      'For example: years, skills, or similar work.';
  static const String applyExperienceSimple = 'What can you do?';
  static const String applyExperienceHintSimple = 'Say it or type it.';
  static const String applyAnswersPrivateNote =
      'Your answers go only to this employer with your application.';
  static const String myAnswerLabel = 'Your answers';

  // ---- Profile ----
  static const String profileEmptyTitle = 'No profile yet';
  static const String profileEmptyBody =
      'Complete onboarding once and your profile is saved here.';
  static const String startProfile = 'Start your profile';
  static const String editProfile = 'Edit profile';
  static const String profileLoadFailed =
      'Could not load your profile. Please try again.';
  static const String profileSubmitFailed =
      'Could not submit your application. Please try again.';
  static const String authPromptForSubmit =
      'Create an account to submit your application. We keep your details '
      'private.';
}
