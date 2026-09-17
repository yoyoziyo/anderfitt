import { adminClient, corsHeaders, json, requireAdmin } from "./client.ts";

function base64url(value: Uint8Array | string) {
  const bytes = typeof value === "string" ? new TextEncoder().encode(value) : value;
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "");
}

async function accessToken(service: Record<string, string>) {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = base64url(JSON.stringify({
    iss: service.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: service.token_uri,
    iat: now,
    exp: now + 3600,
  }));
  const pem = service.private_key.replace(/-----[^-]+-----/g, "").replace(/\s/g, "");
  const raw = Uint8Array.from(atob(pem), (char) => char.charCodeAt(0));
  const key = await crypto.subtle.importKey("pkcs8", raw, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
  const unsigned = `${header}.${payload}`;
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned));
  const response = await fetch(service.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion: `${unsigned}.${base64url(new Uint8Array(signature))}` }),
  });
  const result = await response.json();
  if (!response.ok) throw new Error("Falha na autorização do FCM.");
  return result.access_token as string;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const sender = await requireAdmin(req);
  if (!sender) return json({ error: "Acesso administrativo necessário." }, 403);
  try {
    const body = await req.json();
    const title = String(body.title ?? "").trim();
    const message = String(body.body ?? "").trim();
    const recipients = Array.isArray(body.recipientIds) ? body.recipientIds.map(String) : [];
    if (!title || !message) return json({ error: "Preencha título e mensagem." }, 400);
    const client = adminClient();
    let query = client.from("device_tokens").select("token,user_id");
    if (recipients.length) query = query.in("user_id", recipients);
    const { data: devices, error } = await query;
    if (error) return json({ error: error.message }, 400);
    const service = JSON.parse(new TextDecoder().decode(Uint8Array.from(atob(Deno.env.get("FIREBASE_SERVICE_ACCOUNT_B64")!), (c) => c.charCodeAt(0))));
    const token = await accessToken(service);
    const results = await Promise.allSettled((devices ?? []).map((device) => fetch(
      `https://fcm.googleapis.com/v1/projects/${service.project_id}/messages:send`,
      {
        method: "POST",
        headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
        body: JSON.stringify({ message: { token: device.token, notification: { title, body: message }, data: { route: "home" } } }),
      },
    )));
    if (recipients.length) {
      await client.from("notifications").insert(recipients.map((recipientId) => ({ sender_id: sender.id, recipient_id: recipientId, title, body: message })));
    } else {
      await client.from("notifications").insert({ sender_id: sender.id, recipient_id: null, title, body: message });
    }
    return json({ success: true, devices: devices?.length ?? 0, attempted: results.length });
  } catch (_) {
    return json({ error: "Não foi possível enviar a notificação." }, 500);
  }
});
