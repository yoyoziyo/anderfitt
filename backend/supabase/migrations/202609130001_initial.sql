create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null check (username = lower(username) and username ~ '^[a-z0-9._-]{3,32}$'),
  display_name text not null,
  role text not null check (role in ('admin', 'student')),
  must_change_password boolean not null default true,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create unique index profiles_username_unique on public.profiles (lower(username));

create table public.student_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  height_cm numeric(5,2),
  objective text not null default '',
  water_goal_ml integer not null default 2500 check (water_goal_ml between 250 and 10000),
  goal_title text not null default 'Defina sua meta com o personal',
  goal_start numeric(6,2),
  goal_target numeric(6,2),
  updated_at timestamptz not null default now()
);

create table public.workouts (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  title text not null default 'Treino do dia',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.exercises (
  id uuid primary key default gen_random_uuid(),
  workout_id uuid not null references public.workouts(id) on delete cascade,
  name text not null,
  sets_reps text not null,
  rest_seconds integer not null default 60 check (rest_seconds between 0 and 3600),
  video_url text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.workout_completions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  workout_id uuid references public.workouts(id) on delete set null,
  completed_on date not null default current_date,
  created_at timestamptz not null default now(),
  unique (student_id, completed_on)
);

create table public.measurements (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  measured_on date not null default current_date,
  weight numeric(6,2) not null check (weight > 0),
  chest numeric(6,2) not null default 0,
  arm numeric(6,2) not null default 0,
  waist numeric(6,2) not null default 0,
  hip numeric(6,2) not null default 0,
  thigh numeric(6,2) not null default 0,
  created_at timestamptz not null default now(),
  unique (student_id, measured_on)
);

create table public.hydration (
  student_id uuid not null references public.profiles(id) on delete cascade,
  consumed_on date not null default current_date,
  amount_ml integer not null default 0 check (amount_ml between 0 and 100000),
  updated_at timestamptz not null default now(),
  primary key (student_id, consumed_on)
);

create table public.device_tokens (
  token text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null default 'android',
  updated_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  sent_at timestamptz not null default now()
);

create table public.login_attempts (
  username text primary key,
  failed_count integer not null default 0,
  locked_until timestamptz,
  updated_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and active = true
  );
$$;

grant execute on function public.is_admin() to authenticated;
revoke all on public.login_attempts from anon, authenticated;

alter table public.profiles enable row level security;
alter table public.student_profiles enable row level security;
alter table public.workouts enable row level security;
alter table public.exercises enable row level security;
alter table public.workout_completions enable row level security;
alter table public.measurements enable row level security;
alter table public.hydration enable row level security;
alter table public.device_tokens enable row level security;
alter table public.notifications enable row level security;
alter table public.login_attempts enable row level security;

create policy profiles_select on public.profiles for select to authenticated
using (id = auth.uid() or public.is_admin());
create policy profiles_update_self on public.profiles for update to authenticated
using (id = auth.uid()) with check (id = auth.uid());
create policy profiles_admin_all on public.profiles for all to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy student_profiles_select on public.student_profiles for select to authenticated
using (user_id = auth.uid() or public.is_admin());
create policy student_profiles_update on public.student_profiles for update to authenticated
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());
create policy student_profiles_admin_insert on public.student_profiles for insert to authenticated
with check (public.is_admin());

create policy workouts_select on public.workouts for select to authenticated
using (student_id = auth.uid() or public.is_admin());
create policy workouts_admin_all on public.workouts for all to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy exercises_select on public.exercises for select to authenticated
using (exists (
  select 1 from public.workouts w
  where w.id = workout_id and (w.student_id = auth.uid() or public.is_admin())
));
create policy exercises_admin_all on public.exercises for all to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy completions_select on public.workout_completions for select to authenticated
using (student_id = auth.uid() or public.is_admin());
create policy completions_student_insert on public.workout_completions for insert to authenticated
with check (student_id = auth.uid());
create policy completions_admin_all on public.workout_completions for all to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy measurements_select on public.measurements for select to authenticated
using (student_id = auth.uid() or public.is_admin());
create policy measurements_write on public.measurements for all to authenticated
using (student_id = auth.uid() or public.is_admin())
with check (student_id = auth.uid() or public.is_admin());

create policy hydration_select on public.hydration for select to authenticated
using (student_id = auth.uid() or public.is_admin());
create policy hydration_write on public.hydration for all to authenticated
using (student_id = auth.uid() or public.is_admin())
with check (student_id = auth.uid() or public.is_admin());

create policy tokens_own on public.device_tokens for all to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy tokens_admin_select on public.device_tokens for select to authenticated
using (public.is_admin());

create policy notifications_select on public.notifications for select to authenticated
using (recipient_id = auth.uid() or recipient_id is null or public.is_admin());
create policy notifications_admin_all on public.notifications for all to authenticated
using (public.is_admin()) with check (public.is_admin());

create index workouts_student_idx on public.workouts(student_id);
create index exercises_workout_idx on public.exercises(workout_id, sort_order);
create index completions_student_date_idx on public.workout_completions(student_id, completed_on desc);
create index measurements_student_date_idx on public.measurements(student_id, measured_on desc);
create index notifications_recipient_idx on public.notifications(recipient_id, sent_at desc);
