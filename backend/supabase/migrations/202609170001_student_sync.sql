-- Upsert verifica a política INSERT mesmo quando a linha já existe.
create policy student_profiles_insert_self on public.student_profiles
for insert to authenticated with check (user_id = auth.uid());

-- A sincronização reenvia conclusões existentes; precisa poder atualizar a própria linha.
create policy completions_student_update on public.workout_completions
for update to authenticated
using (student_id = auth.uid())
with check (
  student_id = auth.uid() and (
    workout_id is null or exists (
      select 1 from public.workouts w
      where w.id = workout_id and w.student_id = auth.uid()
    )
  )
);

drop policy completions_student_insert on public.workout_completions;
create policy completions_student_insert on public.workout_completions
for insert to authenticated with check (
  student_id = auth.uid() and (
    workout_id is null or exists (
      select 1 from public.workouts w
      where w.id = workout_id and w.student_id = auth.uid()
    )
  )
);

drop policy exercise_checks_write on public.exercise_checks;
create policy exercise_checks_write on public.exercise_checks
for all to authenticated
using (student_id = auth.uid())
with check (
  student_id = auth.uid() and exists (
    select 1 from public.exercises e join public.workouts w on w.id = e.workout_id
    where e.id = exercise_id and w.student_id = auth.uid()
  )
);
