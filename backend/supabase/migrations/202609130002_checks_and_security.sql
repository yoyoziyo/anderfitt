drop policy if exists profiles_update_self on public.profiles;
revoke update on public.profiles from authenticated;

create table public.exercise_checks (
  student_id uuid not null references public.profiles(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id) on delete cascade,
  checked_on date not null default current_date,
  primary key (student_id, exercise_id, checked_on)
);
alter table public.exercise_checks enable row level security;
create policy exercise_checks_select on public.exercise_checks for select to authenticated
using (student_id = auth.uid() or public.is_admin());
create policy exercise_checks_write on public.exercise_checks for all to authenticated
using (student_id = auth.uid()) with check (student_id = auth.uid());

create or replace function public.complete_password_change()
returns void
language sql
security definer
set search_path = public
as $$
  update public.profiles set must_change_password = false where id = auth.uid();
$$;
grant execute on function public.complete_password_change() to authenticated;

create index exercise_checks_student_date_idx on public.exercise_checks(student_id, checked_on desc);
