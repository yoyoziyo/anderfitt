import { adminClient, corsHeaders, json, normalizeUsername, requireAdmin, temporaryPassword } from "./client.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const admin = await requireAdmin(req);
  if (!admin) return json({ error: "Acesso administrativo necessário." }, 403);
  try {
    const body = await req.json();
    const action = String(body.action ?? "");
    const client = adminClient();

    if (action === "create_student") {
      const username = normalizeUsername(body.username);
      const displayName = String(body.displayName ?? "").trim();
      if (!/^[a-z0-9._-]{3,32}$/.test(username) || displayName.length < 2) {
        return json({ error: "Confira o usuário e o nome do aluno." }, 400);
      }
      const password = String(body.password ?? temporaryPassword());
      if (password.length < 8) return json({ error: "A senha precisa ter ao menos 8 caracteres." }, 400);
      const { data, error } = await client.auth.admin.createUser({
        email: `${username}@users.anderfit.app`,
        password,
        email_confirm: true,
        user_metadata: { username, display_name: displayName, role: "student" },
      });
      if (error || !data.user) return json({ error: error?.message ?? "Não foi possível criar o aluno." }, 400);
      const { error: profileError } = await client.from("profiles").insert({
        id: data.user.id,
        username,
        display_name: displayName,
        role: "student",
        must_change_password: true,
      });
      if (profileError) {
        await client.auth.admin.deleteUser(data.user.id);
        return json({ error: profileError.message }, 400);
      }
      await client.from("student_profiles").insert({ user_id: data.user.id });
      await client.from("workouts").insert({ student_id: data.user.id, title: "Treino do dia" });
      return json({ id: data.user.id, username, password, displayName }, 201);
    }

    if (action === "delete_student") {
      const studentId = String(body.studentId ?? "");
      const { data: target } = await client.from("profiles").select("role").eq("id", studentId).maybeSingle();
      if (target?.role !== "student") return json({ error: "Aluno não encontrado." }, 404);
      const { error } = await client.auth.admin.deleteUser(studentId);
      return error ? json({ error: error.message }, 400) : json({ success: true });
    }

    if (action === "reset_password") {
      const studentId = String(body.studentId ?? "");
      const password = temporaryPassword();
      const { data: target } = await client.from("profiles").select("role,username").eq("id", studentId).maybeSingle();
      if (target?.role !== "student") return json({ error: "Aluno não encontrado." }, 404);
      const { error } = await client.auth.admin.updateUserById(studentId, { password });
      if (error) return json({ error: error.message }, 400);
      await client.from("profiles").update({ must_change_password: true }).eq("id", studentId);
      return json({ username: target.username, password });
    }

    return json({ error: "Ação desconhecida." }, 400);
  } catch (_) {
    return json({ error: "Não foi possível concluir a operação." }, 500);
  }
});
