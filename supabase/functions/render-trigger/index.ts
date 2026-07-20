// render-trigger — ayet→video render işini kuyruğa ekler (worker sunucu
// tarafında işler). Kullanıcı JWT'si ile RLS uygulanır; user_id = auth.uid().
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

    const { template, reciter, reference, arabic, meal } = await req.json();
    if (!template || !reciter) {
      return json({ error: "template ve reciter zorunlu" }, 400);
    }

    const { data, error } = await supabase
      .from("render_jobs")
      .insert({
        user_id: user.id,
        template,
        reciter,
        reference: reference ?? null,
        arabic: arabic ?? null,
        meal: meal ?? null,
        status: "queued",
      })
      .select("id, status")
      .single();

    if (error) return json({ error: error.message }, 400);

    // TODO(worker): gerçek render kuyruğuna (ör. başka bir servis/queue) iş bırak.
    return json({ jobId: data.id, status: data.status });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
