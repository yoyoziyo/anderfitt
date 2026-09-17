import { createClient } from "npm:@supabase/supabase-js@2";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

export function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function adminClient() {
  const keys = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") ?? "{}");
  const key = keys.default ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  return createClient(Deno.env.get("SUPABASE_URL")!, key!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export function publicClient() {
  const keys = JSON.parse(Deno.env.get("SUPABASE_PUBLISHABLE_KEYS") ?? "{}");
  const key = keys.default ?? Deno.env.get("SUPABASE_ANON_KEY");
  return createClient(Deno.env.get("SUPABASE_URL")!, key!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export async function requireAdmin(req: Request) {
  const bearer = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!bearer) return null;
  const client = adminClient();
  const { data } = await client.auth.getUser(bearer);
  if (!data.user) return null;
  const { data: profile } = await client
    .from("profiles")
    .select("id,role,active")
    .eq("id", data.user.id)
    .maybeSingle();
  return profile?.role === "admin" && profile.active ? data.user : null;
}

export function normalizeUsername(value: unknown) {
  return String(value ?? "").trim().toLowerCase();
}

export function temporaryPassword() {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#";
  const bytes = crypto.getRandomValues(new Uint8Array(12));
  return Array.from(bytes, (byte) => alphabet[byte % alphabet.length]).join("");
}
