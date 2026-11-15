# SYNC — accessible job onboarding

A Flutter app for inclusive job applications: onboarding with an
"Access Passport" (voice or typed answers, larger text, stronger contrast,
read aloud), then browsing and applying for jobs — all backed by Supabase.

## Features

- **Onboarding flow** — access preferences, contact, identity route,
  skills, support preferences, review & submit. One question per screen,
  no time-outs, draft saved locally so you can stop and resume.
- **Accounts** — email/password sign-up and sign-in (Supabase Auth),
  with optional email confirmation.
- **Profiles** — the submitted profile is stored per user and shown on the
  Profile screen, where it can be edited and re-submitted.
- **Jobs** — live listings from the `jobs` table with search and
  accessibility filters (Remote / Step-free / With Support).
- **"My support" filter** — matches your *private* support preferences
  against job accommodations entirely on-device; employers never see your
  preferences.
- **Apply with voice answers** — the application flow asks two short
  questions you can answer by voice; the answers travel with the
  application and are shown back to you in My Jobs.
- **Employer postings** — employers can post, edit, publish/draft and
  delete their own jobs, including the accommodations the job offers
  (which job seekers filter against).
- **My Jobs** — your applications with your submitted answers, and withdraw.
- **Accessibility** — app-wide larger text, high-contrast theme, read-aloud,
  voice input on *every* field, simpler-wording mode, 48dp tap targets,
  screen-reader semantics throughout.

## Quick start

```sh
flutter pub get

# Optional but recommended: connect to Supabase
cp config.json.example config.json   # then fill in your URL + anon key
# run supabase/schema.sql in the Supabase SQL editor (see supabase/README.md)

flutter run --dart-define-from-file=config.json
```

Without `config.json` the app still runs, backed by local in-memory storage —
useful for UI work and tests.

Full backend setup: **[supabase/README.md](supabase/README.md)**.

## Project layout

```
lib/
  core/          # config, constants, providers, router, theme, accessibility
  features/      # screens: onboarding, jobs, profile, more
  models/        # equatable data models
  services/      # auth / profile / job contracts + Supabase + fallback impls
  shared/        # reusable widgets (forms, banners, status views)
docs/
  CONFIGURATION_ITEMS.md  # CI → CSC → CSU decomposition + requirement traceability
supabase/
  schema.sql     # tables, row-level security, seed jobs (idempotent)
test/            # unit + widget tests
```

## Testing and checks

```sh
flutter analyze   # no issues
flutter test      # all tests pass
```

## Notes for production

- Only the **anon/publishable** key ships in the app; row-level security in
  `supabase/schema.sql` is what protects user data.
- Anyone signed in can **read** job listings. Only *employers* can write,
  and only their own rows: the `jobs_insert_own` / `jobs_update_own` /
  `jobs_delete_own` policies tie every write to `jobs.employer_id = auth.uid()`.
- Applicants write only their own `job_applications` rows (and the
  `cover_note` answers), enforced by RLS as well.
- Need to seed jobs without an employer account? Use the SQL editor or the
  service role, which bypasses RLS.

## Configuration items

See [docs/CONFIGURATION_ITEMS.md](docs/CONFIGURATION_ITEMS.md) for the
CSCI → CSC → CSU decomposition and the requirement-to-test traceability
matrix.
