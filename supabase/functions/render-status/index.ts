// render-status — bir render işinin durumunu döner (sahibi görebilir, RLS).
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

    const url = new URL(req.url);
    const jobId = url.searchParams.get("jobId");
    if (!jobId) return json({ error: "jobId zorunlu" }, 400);

    const { data, error } = await supabase
      .from("render_jobs")
      .select("id, status, output_url")
      .eq("id", jobId)
      .single();

    if (error) return json({ error: error.message }, 404);
    return json(data);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
