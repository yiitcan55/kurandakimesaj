// delete-account — çağıran kullanıcının hesabını kalıcı siler.
// 1) Kullanıcı JWT'siyle kimliği doğrular (anon istemci).
// 2) service_role ile `auth.admin.deleteUser` çağırır; auth user silinince
//    şemadaki `on delete cascade` FK'leri (profiles, feed_posts, messages,
//    conversation_members, follows, khatm…) tüm kullanıcı verisini temizler.
// service_role ANAHTARI YALNIZ BURADA (Deno.env) — istemciye asla gömülmez.
// App Store Guideline 5.1.1(v) + Google Play hesap silme zorunluluğunu karşılar.
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders, json } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  try {
    const authHeader = req.headers.get("Authorization") ?? "";

    // 1) Çağıranı doğrula.
    const userClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) return json({ error: "unauthorized" }, 401);

    // 2) service_role ile sil → cascade FK'ler kullanıcı verisini düşürür.
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { error } = await admin.auth.admin.deleteUser(user.id);
    if (error) return json({ error: error.message }, 400);

    return json({ status: "deleted" });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
