-- ============================================================
-- SYNC — Supabase schema
-- ============================================================
-- Paste this whole file into the Supabase SQL editor
-- (Dashboard → SQL Editor → New query → Run), or apply it with
-- `supabase db push` if you use the Supabase CLI.
--
-- Everything here is idempotent: running it twice is safe.
--
-- After running it, also check:
--   Authentication → Providers → Email
--     • Turn OFF "Confirm email" for instant sign-up, OR leave it ON and
--       the app will show a "check your email" notice instead.
-- ============================================================

create extension if not exists "pgcrypto";

-- ------------------------------------------------------------
-- PROFILES — one row per user, mirroring the onboarding flow
-- ------------------------------------------------------------
create table if not exists public.profiles (
  user_id                 uuid primary key references auth.users (id) on delete cascade,
  full_name               text not null default '',
  phone                   text not null default '',
  email                   text,
  identity_route          text,
  occupation              text,
  education_level         text not null default 'noneOrOther',
  key_skills              text[] not null default '{}',
  languages               text[] not null default '{}',
  answer_mode             text not null default 'either',
  read_aloud              boolean not null default false,
  simpler_wording         boolean not null default false,
  larger_text             boolean not null default false,
  stronger_contrast       boolean not null default false,
  extra_time              boolean not null default false,
  written_instructions    boolean not null default false,
  extra_interview_time    boolean not null default false,
  remote_interview        boolean not null default false,
  step_free_location      boolean not null default false,
  accessible_transportation boolean not null default false,
  other_support           text,
  updated_at              timestamptz not null default now()
);

comment on table public.profiles is
  'Applicant profiles created during onboarding. Private support fields are never shared with employers.';

-- ------------------------------------------------------------
-- JOBS — public listings; employers write only their own rows
-- ------------------------------------------------------------
create table if not exists public.jobs (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  employer    text not null,
  employer_id uuid references auth.users (id) on delete cascade,
  location    text,
  description text,
  tags        text[] not null default '{}',
  posted_at   timestamptz not null default now(),
  is_active   boolean not null default true
);

-- Idempotent upgrades for databases created before these columns existed.
alter table public.jobs
  add column if not exists employer_id uuid references auth.users (id) on delete cascade;
alter table public.jobs
  add column if not exists is_active boolean not null default true;

create index if not exists jobs_posted_at_idx
  on public.jobs (posted_at desc);

create index if not exists jobs_active_idx
  on public.jobs (is_active) where is_active = true;

create index if not exists jobs_employer_idx
  on public.jobs (employer_id, posted_at desc);

-- ------------------------------------------------------------
-- JOB APPLICATIONS — one row per user per job
-- ------------------------------------------------------------
create table if not exists public.job_applications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  job_id     uuid not null references public.jobs (id) on delete cascade,
  status     text not null default 'applied'
             check (status in ('applied', 'saved', 'withdrawn')),
  cover_note text,
  created_at timestamptz not null default now(),
  unique (user_id, job_id)
);

-- Idempotent upgrade: the applicant's voice/typed answers.
alter table public.job_applications
  add column if not exists cover_note text;

create index if not exists job_applications_user_idx
  on public.job_applications (user_id, created_at desc);

-- ------------------------------------------------------------
-- updated_at maintenance
-- ------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------------
-- ROW LEVEL SECURITY
-- ------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.jobs enable row level security;
alter table public.job_applications enable row level security;

-- Profiles: owners only (read/write their own row).
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
  on public.profiles for select
  using (auth.uid() = user_id);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own
  on public.profiles for insert
  with check (auth.uid() = user_id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
  on public.profiles for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists profiles_delete_own on public.profiles;
create policy profiles_delete_own
  on public.profiles for delete
  using (auth.uid() = user_id);

-- Jobs: everyone (including anonymous visitors) may read listings.
-- Employers may insert/update/delete ONLY rows they own (employer_id).
-- Service-role writes bypass RLS as usual.
drop policy if exists jobs_public_read on public.jobs;
create policy jobs_public_read
  on public.jobs for select
  using (true);

drop policy if exists jobs_insert_own on public.jobs;
create policy jobs_insert_own
  on public.jobs for insert
  with check (auth.uid() = employer_id);

drop policy if exists jobs_update_own on public.jobs;
create policy jobs_update_own
  on public.jobs for update
  using (auth.uid() = employer_id)
  with check (auth.uid() = employer_id);

drop policy if exists jobs_delete_own on public.jobs;
create policy jobs_delete_own
  on public.jobs for delete
  using (auth.uid() = employer_id);

-- Applications: owners only.
drop policy if exists applications_select_own on public.job_applications;
create policy applications_select_own
  on public.job_applications for select
  using (auth.uid() = user_id);

drop policy if exists applications_insert_own on public.job_applications;
create policy applications_insert_own
  on public.job_applications for insert
  with check (auth.uid() = user_id);

drop policy if exists applications_update_own on public.job_applications;
create policy applications_update_own
  on public.job_applications for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists applications_delete_own on public.job_applications;
create policy applications_delete_own
  on public.job_applications for delete
  using (auth.uid() = user_id);

-- ------------------------------------------------------------
-- SEED DATA — sample jobs covering every list filter
-- (Remote / Step-free / With Support). Fixed ids keep it idempotent.
-- ------------------------------------------------------------
insert into public.jobs (id, title, employer, location, description, tags, posted_at)
values
  ('a1000000-0000-4000-8000-000000000001',
   'Customer Support Advisor',
   'TechCorp Ltd',
   'London, UK',
   'Answer customer questions by chat and email. Full training provided.',
   array['Remote OK', 'Written Instructions'],
   now() - interval '1 day'),

  ('a1000000-0000-4000-8000-000000000002',
   'Warehouse Operative',
   'LogiNext',
   'Manchester, UK',
   'Picking, packing and loading. Step-free site with accessible facilities.',
   array['Step-free Access', 'Flexible Hours'],
   now() - interval '2 days'),

  ('a1000000-0000-4000-8000-000000000003',
   'Data Entry Clerk',
   'FinServe Group',
   'Remote',
   'Record information into internal systems from home.',
   array['Remote OK', 'Flexible Hours', 'Written Instructions'],
   now() - interval '3 days'),

  ('a1000000-0000-4000-8000-000000000004',
   'Retail Assistant',
   'GreenMart',
   'Birmingham, UK',
   'Help customers and stock shelves in a step-free store.',
   array['Step-free Access', 'With Support'],
   now() - interval '4 days'),

  ('a1000000-0000-4000-8000-000000000005',
   'Warehouse assistant',
   'Sunrise Logistics',
   'Addis Ababa',
   'Packing, sorting and loading. Full training provided.',
   array['Step-free Access', 'Flexible Hours'],
   now() - interval '5 days'),

  ('a1000000-0000-4000-8000-000000000006',
   'Office Assistant',
   'Horn of Africa Consulting',
   'Addis Ababa',
   'Scheduling, filing and reception support with a supportive team.',
   array['With Support', 'Written Instructions'],
   now() - interval '6 days')
on conflict (id) do update set
  title       = excluded.title,
  employer    = excluded.employer,
  location    = excluded.location,
  description = excluded.description,
  tags        = excluded.tags,
  is_active   = true;
