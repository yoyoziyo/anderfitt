import { adminClient, corsHeaders, json, normalizeUsername, publicClient } from "./client.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Método inválido." }, 405);
  const body = await req.json().catch(() => ({}));
  const username = normalizeUsername(body.username);
  const password = String(body.password ?? "");
  if (!/^[a-z0-9._-]{3,32}$/.test(username) || password.length < 1) {
    return json({ error: "Usuário ou senha inválidos." }, 400);
  }

  const admin = adminClient();
  const { data: attempt } = await admin.from("login_attempts").select("*").eq("username", username).maybeSingle();
  const now = Date.now();
  const lockedUntil = attempt?.locked_until ? Date.parse(attempt.locked_until) : 0;
  if (lockedUntil > now) {
    return json({ error: "Acesso temporariamente bloqueado.", retryAfter: Math.ceil((lockedUntil - now) / 1000) }, 429);
  }

  const client = publicClient();
  const { data, error } = await client.auth.signInWithPassword({
    email: `${username}@users.anderfit.app`,
    password,
  });
  if (error || !data.session) {
    const failures = (attempt?.failed_count ?? 0) + 1;
    const lock = failures >= 3 ? new Date(now + 5 * 60 * 1000).toISOString() : null;
    await admin.from("login_attempts").upsert({
      username,
      failed_count: failures >= 3 ? 0 : failures,
      locked_until: lock,
      updated_at: new Date().toISOString(),
    });
    return json({
      error: lock ? "Três tentativas incorretas. Aguarde cinco minutos." : "Usuário ou senha inválidos.",
      attemptsRemaining: lock ? 0 : 3 - failures,
      retryAfter: lock ? 300 : null,
    }, lock ? 429 : 401);
  }

  await admin.from("login_attempts").delete().eq("username", username);
  const { data: profile } = await admin.from("profiles").select("id,username,display_name,role,must_change_password,active").eq("id", data.user.id).single();
  if (!profile?.active) {
    await client.auth.signOut();
    return json({ error: "Conta desativada." }, 403);
  }
  return json({ session: data.session, user: profile });
});
