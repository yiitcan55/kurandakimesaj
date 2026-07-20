// daily-content — pg_cron tarafından her gün çağrılır (service_role).
// Günün öne çıkan ayetini seçip daily_content tablosuna yazar. İstemci de
// kendi seed'inden hesaplayabilir; bu, kampanya/sunucu kaynaklı içerik içindir.
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders, json } from "../_shared/cors.ts";

const AYAHS = [
  { reference: "Bakara, 153", arabic: "وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ",
    meal: "Sabır ve namazla Allah'tan yardım dileyin." },
  { reference: "Ra'd, 28", arabic: "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ",
    meal: "Kalpler ancak Allah'ı anmakla huzur bulur." },
  { reference: "İnşirah, 5", arabic: "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا",
    meal: "Şüphesiz güçlükle beraber bir kolaylık vardır." },
  { reference: "Zümer, 53", arabic: "لَا تَقْنَطُوا مِنْ رَحْمَةِ اللَّهِ",
    meal: "Allah'ın rahmetinden ümit kesmeyin." },
];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  try {
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const today = new Date().toISOString().slice(0, 10);
    const dayNum = Math.floor(Date.parse(today) / 86400000);
    const pick = AYAHS[dayNum % AYAHS.length];

    const { error } = await admin
      .from("daily_content")
      .upsert({ day: today, ...pick }, { onConflict: "day" });

    if (error) return json({ error: error.message }, 400);
    return json({ ok: true, day: today, reference: pick.reference });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
