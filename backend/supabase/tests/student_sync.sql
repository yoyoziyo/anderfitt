-- Execute com uma conexão administrativa. Todos os registros são revertidos no final.
begin;
create temp table anderfit_test_ids as select gen_random_uuid() a, gen_random_uuid() b, gen_random_uuid() admin_id, gen_random_uuid() workout_id, gen_random_uuid() exercise_id;
grant select on anderfit_test_ids to authenticated;
insert into auth.users(id, email, aud, role, raw_app_meta_data, raw_user_meta_data)
select a, 'rls-a-' || a || '@test.invalid', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb from anderfit_test_ids
union all select b, 'rls-b-' || b || '@test.invalid', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb from anderfit_test_ids
union all select admin_id, 'rls-admin-' || admin_id || '@test.invalid', 'authenticated', 'authenticated', '{}'::jsonb, '{}'::jsonb from anderfit_test_ids;
insert into public.profiles(id, username, display_name, role)
select a, 'rlsa' || left(replace(a::text,'-',''),20), 'Aluno teste A', 'student' from anderfit_test_ids
union all select b, 'rlsb' || left(replace(b::text,'-',''),20), 'Aluno teste B', 'student' from anderfit_test_ids
union all select admin_id, 'rlsadm' || left(replace(admin_id::text,'-',''),20), 'Personal teste', 'admin' from anderfit_test_ids;
insert into public.student_profiles(user_id) select a from anderfit_test_ids;
insert into public.measurements(student_id,measured_on,weight) select b,current_date,80 from anderfit_test_ids;
insert into public.workouts(id,student_id) select workout_id,a from anderfit_test_ids;
insert into public.exercises(id,workout_id,name,sets_reps) select exercise_id,workout_id,'Exercício teste','3 x 12' from anderfit_test_ids;
select set_config('request.jwt.claims',(select json_build_object('sub',a::text,'role','authenticated')::text from anderfit_test_ids),true);
set local role authenticated;
insert into public.student_profiles(user_id,height_cm) values(auth.uid(),175.5) on conflict(user_id) do update set height_cm=excluded.height_cm;
insert into public.measurements(student_id,measured_on,weight) values(auth.uid(),current_date,75) on conflict(student_id,measured_on) do update set weight=excluded.weight;
insert into public.hydration(student_id,consumed_on,amount_ml) values(auth.uid(),current_date,250) on conflict(student_id,consumed_on) do update set amount_ml=excluded.amount_ml;
insert into public.workout_completions(student_id,workout_id,completed_on) select a,workout_id,current_date from anderfit_test_ids on conflict(student_id,completed_on) do update set workout_id=excluded.workout_id;
insert into public.workout_completions(student_id,workout_id,completed_on) select a,workout_id,current_date from anderfit_test_ids on conflict(student_id,completed_on) do update set workout_id=excluded.workout_id;
insert into public.exercise_checks(student_id,exercise_id) select a,exercise_id from anderfit_test_ids;
do $$ begin
  if (select count(*) from public.measurements where student_id in (select a from anderfit_test_ids union all select b from anderfit_test_ids)) <> 1 then raise exception 'Aluno leu dados de outro aluno'; end if;
  if (select count(*) from public.workout_completions where student_id=auth.uid()) <> 1 then raise exception 'Conclusão repetida falhou'; end if;
  begin
    insert into public.measurements(student_id,measured_on,weight) select b,current_date+1,90 from anderfit_test_ids;
    raise exception 'Aluno conseguiu gravar dados de outro aluno';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
select set_config('request.jwt.claims',(select json_build_object('sub',admin_id::text,'role','authenticated')::text from anderfit_test_ids),true);
set local role authenticated;
do $$ begin
  if (select count(*) from public.measurements where student_id in (select a from anderfit_test_ids union all select b from anderfit_test_ids)) <> 2 then raise exception 'Admin não conseguiu acompanhar os dois alunos'; end if;
  if (select count(*) from public.hydration where student_id in (select a from anderfit_test_ids)) <> 1 then raise exception 'Admin não leu hidratação'; end if;
  if (select count(*) from public.workout_completions where student_id in (select a from anderfit_test_ids)) <> 1 then raise exception 'Admin não leu conclusões'; end if;
end $$;
reset role;
rollback;
