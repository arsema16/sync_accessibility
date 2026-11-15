# SYNC — Supabase setup

Everything needed to run SYNC against a real backend.

## 1. Create a project

1. Go to <https://supabase.com/dashboard> → **New project**.
2. Note the **Project URL** and **anon (public) key** from
   *Project Settings → API*.

## 2. Create the schema

Open **SQL Editor → New query**, paste the contents of
[`schema.sql`](schema.sql) and press **Run**.

It creates (idempotently — safe to re-run):

| Table | Purpose | Access |
| --- | --- | --- |
| `profiles` | One row per user with the onboarding answers | Owner read/write (RLS) |
| `jobs` | Public job listings + seeded sample jobs | Anyone can read; employers insert/update/delete **only their own** rows (`employer_id`) |
| `job_applications` | One row per user per applied job, incl. `cover_note` answers | Owner read/write (RLS) |

plus row-level security policies (including the employer write policies),
indexes and an `updated_at` trigger.

> **Upgrading an existing project?** Re-run `schema.sql` — it adds
> `jobs.employer_id`, `job_applications.cover_note` and the employer
> policies via `if not exists` / `drop policy if exists` statements, so
> nothing already there is lost.

## 3. Configure authentication

*Authentication → Providers → Email*:

* **Turn "Confirm email" OFF** if you want sign-up to open a session
  immediately (simplest for development).
* Leave it **ON** if you prefer verified addresses — the app detects the
  pending confirmation and shows *"We sent a confirmation email to …"*
  instead of failing.

Email/password sign-in is enabled by default; no other provider is required.

## 4. Wire the credentials into the app

```sh
cp config.json.example config.json
# edit config.json: fill in SUPABASE_URL and SUPABASE_ANON_KEY
```

`config.json` is gitignored so keys never end up in the repository.

```sh
flutter run --dart-define-from-file=config.json
```

Without the define the app still runs, using local in-memory storage (see
`lib/core/config/supabase_config.dart`) — handy for UI work and the test
suite.

> Never ship the **service_role** key in the app. The anon/publishable key is
> the only key that belongs in a client, and row-level security is what keeps
> user data private.

## 5. Verify

1. Run the app, complete onboarding and **Submit Application** — you will be
   asked to create an account; afterwards a row appears in `profiles`.
2. Open **Jobs** → **Apply** — answer the two voice questions; a row appears
   in `job_applications` with a `cover_note`.
3. **My Jobs** lists it with your answers; **Withdraw** deletes it.
4. **More → My job postings** → **Post a job** (pick accommodations, publish)
   — a row appears in `jobs` with your `employer_id`. Editing or deleting
   it only affects *your* rows; the job then shows in the public **Jobs**
   list and matches the **My support** filter.
5. **More → Sign out** clears the session.

You can also watch rows arrive live from the dashboard's *Table Editor*.

## Useful SQL

```sql
-- Everything a signed-in user can see (run as that user, or with service role):
select * from public.profiles;
select * from public.job_applications;
select * from public.jobs where is_active order by posted_at desc;

-- An employer's own postings (as that user, or with service role):
select * from public.jobs where employer_id = auth.uid() order by posted_at desc;

-- Seed a job with no employer (service role / SQL editor; RLS is bypassed):
insert into public.jobs (title, employer, location, description, tags)
values ('Baker', 'Sunrise Bakery', 'Addis Ababa', 'Early shifts.', array['Flexible Hours']);

-- See the accommodations a listing offers (job seekers filter on these):
select title, tags from public.jobs where is_active;
```
