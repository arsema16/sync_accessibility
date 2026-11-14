import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/applicant_profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/job_service.dart';
import '../../services/profile_service.dart';
import '../../services/service_locator.dart';
import '../access/access_callbacks.dart';

/// Must be overridden in `main()` with an initialised [SharedPreferences].
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);

/// The single [ServiceLocator] instance. Swap its field initializers when the
/// real backend is wired up; nothing else should need to change.
final serviceLocatorProvider = Provider<ServiceLocator>(
  (ref) => ServiceLocator.instance,
);

final authServiceProvider = Provider<AuthService>(
  (ref) => ref.read(serviceLocatorProvider).auth,
);

final profileServiceProvider = Provider<ProfileService>(
  (ref) => ref.read(serviceLocatorProvider).profile,
);

final jobServiceProvider = Provider<JobService>(
  (ref) => ref.read(serviceLocatorProvider).jobs,
);

/// Voice input capability. Stubbed — returns empty string. Bethel overrides.
final voiceInputProvider = Provider<VoiceInputCallback>(
  (ref) => voiceInputStub,
);

/// Read-aloud capability. Stubbed — no-op. Bethel overrides.
final readAloudProvider = Provider<ReadAloudCallback>(
  (ref) => readAloudStub,
);

const String _accessPrefsKey = 'sync.access_passport';

/// Holds the Access Passport and persists it to [SharedPreferences] on change.
/// These values also drive the app-wide text scale and theme variant.
class AccessPreferencesNotifier extends Notifier<AccessPassport> {
  @override
  AccessPassport build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return _load(prefs);
  }

  void setAnswerMode(AnswerMode mode) =>
      _persist(state.copyWith(answerMode: mode));
  void setReadAloud(bool value) =>
      _persist(state.copyWith(readAloud: value));
  void setSimplerWording(bool value) =>
      _persist(state.copyWith(simplerWording: value));
  void setLargerText(bool value) => _persist(state.copyWith(largerText: value));
  void setStrongerContrast(bool value) =>
      _persist(state.copyWith(strongerContrast: value));
  void setExtraTime(bool value) =>
      _persist(state.copyWith(extraTime: value));

  void _persist(AccessPassport next) {
    state = next;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(_accessPrefsKey, jsonEncode(next.toMap()));
  }

  static AccessPassport _load(SharedPreferences prefs) {
    final raw = prefs.getString(_accessPrefsKey);
    if (raw == null) {
      return AccessPassport.empty();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AccessPassport.fromMap(decoded);
      }
    } catch (_) {
      // Ignore malformed entries and fall back to defaults.
    }
    return AccessPassport.empty();
  }
}

final accessPreferencesNotifierProvider =
    NotifierProvider<AccessPreferencesNotifier, AccessPassport>(
  AccessPreferencesNotifier.new,
);

const String _onboardingDraftKey = 'sync.onboarding_draft';

/// The applicant profile being built during onboarding. The Access Passport
/// is kept separately (in [accessPreferencesNotifierProvider]) and merged in
/// at save time on the Profile Review screen.
///
/// The draft is persisted to [SharedPreferences] on every change so a user is
/// not dropped mid-flow if the process is killed; it is restored on the next
/// build.
class OnboardingDraftNotifier extends Notifier<ApplicantProfile> {
  @override
  ApplicantProfile build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return _load(prefs);
  }

  void setContact(PersonalContact contact) =>
      _persist(state.copyWith(contact: contact));
  void setIdentityRoute(IdentityRoute route) =>
      _persist(state.copyWith(identityRoute: route));
  void setSkills(SkillsInfo skills) => _persist(state.copyWith(skills: skills));
  void setPrivateSupport(PrivateSupport? support) =>
      _persist(state.copyWith(privateSupport: support));
  void reset() => _persist(ApplicantProfile.empty());

  void _persist(ApplicantProfile next) {
    state = next;
    ref
        .read(sharedPreferencesProvider)
        .setString(_onboardingDraftKey, jsonEncode(next.toMap()));
  }

  static ApplicantProfile _load(SharedPreferences prefs) {
    final raw = prefs.getString(_onboardingDraftKey);
    if (raw == null) {
      return ApplicantProfile.empty();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return ApplicantProfile.fromMap(decoded);
      }
    } catch (_) {
      // Ignore malformed entries and fall back to an empty draft.
    }
    return ApplicantProfile.empty();
  }
}

final onboardingDraftProvider =
    NotifierProvider<OnboardingDraftNotifier, ApplicantProfile>(
  OnboardingDraftNotifier.new,
);
