// donation-verify — bir bağış kaydını doğrular. Gerçek üretimde ödeme
// sağlayıcısının (iyzico/Stripe vb.) sunucu API'siyle provider_ref doğrulanır;
// burada kayıt oluşturup 'verified' işaretleyen iskelet yer alır.
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders, json } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return json({ error: "unauthorized" }, 401);

    const { campaign, amount, providerRef } = await req.json();
    if (!campaign) return json({ error: "campaign zorunlu" }, 400);

    // TODO: providerRef'i ödeme sağlayıcısının API'siyle doğrula.
    const verified = typeof providerRef === "string" && providerRef.length > 0;

    const { data, error } = await supabase
      .from("donations")
      .insert({
        user_id: user.id,
        campaign,
        amount: amount ?? null,
        provider_ref: providerRef ?? null,
        status: verified ? "verified" : "pending",
      })
      .select("id, status")
      .single();

    if (error) return json({ error: error.message }, 400);
    return json(data);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
