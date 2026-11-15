# SYNC — Configuration Items (CI → CSC → CSU) and requirement traceability

This document decomposes the SYNC application into configuration items the
way a software configuration management plan expects:

```
CSCI  — Computer Software Configuration Item   (the deliverable system)
 └─ CSC — Computer Software Component          (major subsystems)
     └─ CSU — Computer Software Unit           (individually testable files/classes)
```

Every requirement from the brief (Track 1 accessible onboarding + Career
gateway) is then traced to the CSUs that implement it, and each CSU is
traced back to the test that verifies it.

Baseline: all CSUs are under version control in this repository;
`flutter analyze` is clean and `flutter test` passes (63 tests) at the
time of writing.

---

## 1. CSCI level

| CSCI | Description | Verification |
| --- | --- | --- |
| **SYNC** | Flutter mobile application for accessible job onboarding and job applications, backed by Supabase (auth, profiles, jobs, applications) | `flutter analyze` → 0 issues; `flutter test` → 63/63 pass |

The CSCI is delivered in two runtime configurations from one codebase:

| Build configuration | Backend | Purpose |
| --- | --- | --- |
| `flutter run --dart-define-from-file=config.json` | Supabase (`Supabase*Service`s) | Production / demo against the live project |
| `flutter run` (no defines) | In-memory (`InMemory*Service`s) | UI development, tests, first run without setup |

Selection happens once in `ServiceLocator` on
`SupabaseBootstrap.useSupabase`; the UI layer never branches on it.

---

## 2. CSC level — components of the CSCI

| # | CSC | Responsibility | Directory |
| --- | --- | --- | --- |
| CSC-1 | **Core** | Configuration, constants (routes, strings), providers/state, router, theming, accessibility callbacks (voice TTS/STT wiring) | `lib/core/` |
| CSC-2 | **Domain models** | Equatable data models shared by every component | `lib/models/` |
| CSC-3 | **Services** | Contracts + Supabase implementations + in-memory fallbacks for auth, profiles, jobs; service locator | `lib/services/` |
| CSC-4 | **Feature: Onboarding** | Access preferences, contact, identity route, skills, support preferences, profile review, sign-in | `lib/features/onboarding/` |
| CSC-5 | **Feature: Jobs & career gateway** | Job listings, support-needs filter, application flow, My Jobs, employer postings | `lib/features/jobs/` |
| CSC-6 | **Feature: Profile & More** | Stored-profile view/edit, account/settings menu | `lib/features/profile/`, `lib/features/more/` |
| CSC-7 | **Shared UI** | Form engine (one question per screen), auth form, status views, option cards, mic button, banners | `lib/shared/` |
| CSC-8 | **Persistence schema** | Supabase DDL, RLS policies, seed data | `supabase/schema.sql` |
| CSC-9 | **Verification** | Unit, mapping and widget tests | `test/` |

---

## 3. CSU level — units per component

### CSC-1 Core

| CSU | File | Notes |
| --- | --- | --- |
| CSU-1.1 | `lib/core/config/supabase_config.dart` | `SupabaseConfig` (URL/key parsing) + `SupabaseBootstrap` (init, `useSupabase`) |
| CSU-1.2 | `lib/core/constants/app_strings.dart` | All user-facing copy, incl. simpler-wording variants |
| CSU-1.3 | `lib/core/constants/route_names.dart` | Route names/paths paired so they cannot mismatch |
| CSU-1.4 | `lib/core/providers/app_providers.dart` | Riverpod providers; `AccessPreferencesNotifier` (Access Passport), `OnboardingDraftNotifier` (persisted draft), jobs/applications/employer-jobs/profile providers |
| CSU-1.5 | `lib/core/router/app_router.dart` | Flat `GoRouter` route table incl. apply and employer routes |
| CSU-1.6 | `lib/core/theme/app_colors.dart`, `app_spacing.dart`, `app_theme.dart` | Palette, spacing, 48dp tap-target constant, themes |
| CSU-1.7 | `lib/core/access/access_callbacks.dart` | Voice-input and read-aloud callback wiring |

### CSC-2 Domain models

| CSU | File | Notes |
| --- | --- | --- |
| CSU-2.1 | `lib/models/applicant_profile_model.dart` | `PersonalContact`, `SkillsInfo`, `AccessPassport`, `PrivateSupport`, `ApplicantProfile` |
| CSU-2.2 | `lib/models/job_model.dart` | `Job` incl. `employerId` + `isActive` |
| CSU-2.3 | `lib/models/job_application_model.dart` | `JobApplication` incl. `coverNote` |
| CSU-2.4 | `lib/models/user_model.dart` | `SyncUser` session identity |

### CSC-3 Services

| CSU | File | Notes |
| --- | --- | --- |
| CSU-3.1 | `lib/services/auth_service.dart` | `AuthService` contract + `InMemoryAuthService`; typed `AuthFailure` |
| CSU-3.2 | `lib/services/supabase_auth_service.dart` | Supabase Auth impl |
| CSU-3.3 | `lib/services/profile_service.dart` | `ProfileService` contract + `InMemoryProfileService`; `ProfileException` |
| CSU-3.4 | `lib/services/supabase_profile_service.dart` | `profiles` row mapping (`profileToRow`/`profileFromRow`) + impl |
| CSU-3.5 | `lib/services/job_service.dart` | `JobService` contract + `InMemoryJobService` (listings, employer CRUD, apply with `coverNote`) |
| CSU-3.6 | `lib/services/supabase_job_service.dart` | `jobs`/`job_applications` row mappings + impl incl. employer methods |
| CSU-3.7 | `lib/services/service_locator.dart` | Resolves Supabase vs in-memory once |

### CSC-4 Feature: Onboarding

| CSU | File | Notes |
| --- | --- | --- |
| CSU-4.1 | `welcome_screen.dart` | Entry, read-aloud toggle |
| CSU-4.2 | `access_preferences_screen.dart` | Access Passport editor (voice/typed, read-aloud, simpler wording, larger text, contrast, extra time) |
| CSU-4.3 | `contact_screen.dart` | Name / phone / email steps — text + voice |
| CSU-4.4 | `identity_route_screen.dart` | National ID / refugee ID / other document / partner referral |
| CSU-4.5 | `skills_screen.dart` | Occupation, education, skills, languages |
| CSU-4.6 | `support_preferences_screen.dart` | Private support ask, no medical proof, skippable |
| CSU-4.7 | `profile_review_screen.dart` | Review + edit sections + auth-gated save |
| CSU-4.8 | `sign_in_screen.dart` | Sign in / create account with plain typed errors |

### CSC-5 Feature: Jobs & career gateway

| CSU | File | Notes |
| --- | --- | --- |
| CSU-5.1 | `jobs_screen.dart` | Listings, search, tag filters, **private "My support" filter** (`requiredTagsFor`/`jobMatchesSupport` — matched on-device) |
| CSU-5.2 | `apply_job_screen.dart` | **Application flow with voice answers** (why + experience → `cover_note`) |
| CSU-5.3 | `my_jobs_screen.dart` | Applications incl. submitted answers, withdraw |
| CSU-5.4 | `employer_jobs_screen.dart` | Employer's own postings: list, publish state, delete |
| CSU-5.5 | `employer_job_form_screen.dart` | **Employer form** incl. accommodations offered (filterable tags), draft/live |

### CSC-6 Feature: Profile & More

| CSU | File | Notes |
| --- | --- | --- |
| CSU-6.1 | `profile_screen.dart` | Stored profile view + edit/restore into draft |
| CSU-6.2 | `more_screen.dart` | Account, accessibility settings, profile, employer postings, sign-out |

### CSC-7 Shared UI

| CSU | File | Notes |
| --- | --- | --- |
| CSU-7.1 | `question_screen.dart` | Form engine: one question per screen, no timeouts, progress announced, icon+text errors, read-aloud per step, simpler-wording resolution, **mic on every field type** |
| CSU-7.2 | `form_step.dart` | Step model incl. `simpleTitle`/`simpleHint` |
| CSU-7.3 | `auth_form.dart` | Reusable auth fields + `showAuthPrompt` |
| CSU-7.4 | `status_view.dart` | Icon+text empty/error states |
| CSU-7.5 | `sync_option_card.dart`, `sync_voice_mic_button.dart`, `sync_info_banner.dart`, `sync_progress_bar.dart` | Option cards, 120dp mic, banners |

### CSC-8 Persistence schema

| CSU | File | Notes |
| --- | --- | --- |
| CSU-8.1 | `supabase/schema.sql` | Tables `profiles`, `jobs` (with `employer_id`), `job_applications` (with `cover_note`); RLS incl. **employer insert/update/delete-own** on `jobs`; indexes; `updated_at` trigger; 6 seed jobs — idempotent |

### CSC-9 Verification

| CSU | File | Covers |
| --- | --- | --- |
| CSU-9.1 | `test/core/supabase_config_test.dart` | CSU-1.1 |
| CSU-9.2 | `test/models/applicant_profile_copy_with_test.dart` | CSU-2.1 |
| CSU-9.3 | `test/services/auth_service_test.dart` | CSU-3.1 |
| CSU-9.4 | `test/services/profile_service_test.dart`, `profile_row_mapping_test.dart` | CSU-3.3/3.4 |
| CSU-9.5 | `test/services/job_service_test.dart`, `job_row_mapping_test.dart` | CSU-3.5/3.6 |
| CSU-9.6 | `test/services/employer_job_service_test.dart` | Employer CRUD + cover notes (CSU-3.5) |
| CSU-9.7 | `test/features/support_filter_test.dart` | Support-needs matching (CSU-5.1) |
| CSU-9.8 | `test/features/apply_flow_test.dart` | Cover-note assembly (CSU-5.2) |
| CSU-9.9 | `test/widgets/question_screen_test.dart` | Form engine basics (CSU-7.1) |
| CSU-9.10 | `test/widgets/simpler_wording_test.dart` | Simpler wording + read-aloud + mic on text fields (CSU-7.1) |
| CSU-9.11 | `test/widgets/voice_stub_test.dart` | Voice fallback (CSU-7.1) |
| CSU-9.12 | `test/widgets/access_preferences_screen_test.dart`, `access_preferences_theme_test.dart` | CSU-4.2, 1.6 |
| CSU-9.13 | `test/widgets/onboarding_edit_return_test.dart` | Edit-and-return navigation (CSU-4.7) |
| CSU-9.14 | `test/widgets/profile_review_submit_test.dart` | Auth-gated save (CSU-4.7) |
| CSU-9.15 | `test/widgets/sign_in_screen_test.dart` | CSU-4.8 |

---

## 4. Requirement traceability

### Track 1 — Accessible onboarding

| # | Requirement | Status | Implemented in (CSU) | Verified by |
| --- | --- | --- | --- | --- |
| R1 | Clear labels, plain errors | ✅ | 7.1, 1.2, 7.4 | 9.9, 9.13, 9.14 |
| R2 | No time-outs | ✅ | 7.1 (no forced timeouts anywhere) | 9.9, 9.11 |
| R3 | One question per screen | ✅ | 7.1, 7.2 | 9.9, 9.13 |
| R4 | **Voice input on every field**, with review and edit | ✅ (was partial) | 7.1 — mic on *text* steps (contact name/phone/email, employer form) as well as voice steps; review/edit via profile review | 9.10, 9.11, 9.13 |
| R5 | Private way to ask for support, no medical proof | ✅ | 4.6 (never shared with employers) | 9.13 |
| R6 | Other ID routes: refugee ID, other documents, "refer me" | ✅ | 4.4 | 9.13 |
| R7 | Low-literacy path: simple words, icons, read-aloud | ✅ (was partial — simpler wording now *applies*) | 7.1/7.2 (`simpleTitle`/`simpleHint` resolution incl. read-aloud), 4.5, 4.3, 4.4, 4.6 | 9.10 |
| R8 | Save and resume (local draft) | ✅ | 1.4 (`OnboardingDraftNotifier` persists) | 9.13 |

### Career gateway

| # | Requirement | Status | Implemented in (CSU) | Verified by |
| --- | --- | --- | --- | --- |
| R9 | Job application flow **with voice answers** | ✅ (was missing) | 5.2 (voice answers → `job_applications.cover_note`), 2.3, 3.5/3.6, CSU-8.1 column | 9.8, 9.6, 9.5 |
| R10 | **Private "support I need" job filter** | ✅ (was missing) | 5.1 — `requiredTagsFor`/`jobMatchesSupport` match the saved `PrivateSupport` flags against job tags **on-device**; guidance states for signed-out/no-prefs | 9.7 |
| R11 | **Employer form for accommodations offered** | ✅ (was missing) | 5.5 + 5.4; `jobs.employer_id` + employer RLS write policies (8.1); `listJobsForEmployer`/`saveEmployerJob`/`deleteJob` (3.5/3.6) | 9.6, 9.5 |
| R12 | Live jobs, search, filters, apply, withdraw | ✅ | 5.1, 5.3, 3.5/3.6 | 9.5, 9.6 |
| R13 | Accounts + per-user profile storage | ✅ | 3.1–3.4, 4.7, 4.8, 6.1 | 9.3, 9.4, 9.14, 9.15 |

### Out of scope (agreed)

| Requirement | Note |
| --- | --- |
| Partner registers a learner with consent | Not built; only the "refer me through a partner" *identity choice* exists (R6) |
| Save and resume by SMS link | Not built; needs an SMS provider. Local persisted draft (R8) is the equivalent |

---

## 5. Change / status accounting

| Change | Configuration items affected |
| --- | --- |
| Supabase integration (auth/profiles/jobs) | CSC-1, CSC-3, CSC-8 |
| Gap fill: voice on every field | CSU-7.1, CSU-7.2 |
| Gap fill: working simpler-words mode | CSU-7.1, CSU-7.2, CSU-1.2, CSU-4.3/4.4/4.5/4.6 |
| Gap fill: private support-needs filter | CSU-5.1, CSU-1.4 |
| Gap fill: employer accommodations form | CSU-5.4, CSU-5.5, CSU-2.2, CSU-3.5, CSU-3.6, CSU-8.1, CSU-1.3, CSU-1.5, CSU-6.2 |
| Gap fill: voice answers in applications | CSU-5.2, CSU-5.3, CSU-2.3, CSU-3.5, CSU-3.6, CSU-8.1, CSU-1.3, CSU-1.5 |
| This document | `docs/CONFIGURATION_ITEMS.md` |

### Deployment note

`supabase/schema.sql` is idempotent: **re-run it in the Supabase SQL
editor** after pulling these changes to add `jobs.employer_id`,
`job_applications.cover_note` and the employer write policies.
