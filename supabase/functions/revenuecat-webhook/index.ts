// revenuecat-webhook — RevenueCat abonelik olaylarını alır, paylaşılan secret'ı
// doğrular ve profiles.is_pro alanını service_role ile günceller.
// Secret: `supabase secrets set REVENUECAT_WEBHOOK_SECRET=...`
// RevenueCat panelinde webhook Authorization header'ı "Bearer <secret>" olmalı.
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders, json } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  try {
    const secret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
    const auth = req.headers.get("Authorization") ?? "";
    if (!secret || auth !== `Bearer ${secret}`) {
      return json({ error: "unauthorized" }, 401);
    }

    const payload = await req.json();
    const event = payload?.event ?? {};
    // RevenueCat app_user_id = uygulamada Supabase user.id olarak ayarlanmalı.
    const appUserId: string | undefined = event.app_user_id;
    const type: string = event.type ?? "";
    if (!appUserId) return json({ error: "app_user_id yok" }, 400);

    // Aktif abonelik tipleri PRO, iptal/expire PRO değil.
    const active = ["INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION", "PRODUCT_CHANGE"]
      .includes(type);
    const inactive = ["CANCELLATION", "EXPIRATION", "BILLING_ISSUE"].includes(type);
    if (!active && !inactive) return json({ ok: true, ignored: type });

    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { error } = await admin
      .from("profiles")
      .update({ is_pro: active })
      .eq("id", appUserId);

    if (error) return json({ error: error.message }, 400);
    return json({ ok: true, is_pro: active });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
