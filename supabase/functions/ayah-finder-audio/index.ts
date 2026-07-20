// ayah-finder-audio — Kur'an VIDEOSUNDAN okunan ayetleri tanir.
//
// Akis: istemci videoyu `ayah-audio` (PRIVATE) bucket'ina yukler → bu fonksiyon
// imzali URL uretir → Groq Whisper videodan ham Arapca dokum + zaman damgasi
// cikarir → `segments.ts` otoriter `_shared/quran` matcher'i ile sure:ayet
// ARALIGINI ve zaman cizelgesini belirler → video SILINIR.
//
// Dini dogruluk (domain kurali): ASR yalniz Arapca metin uretir. Sure adi, ayet
// numarasi ve meal HER ZAMAN sunucudaki otoriter veri setinden gelir — modelden
// ASLA. Belirsizlikte tek yanlis ayet yerine aday listesi (status='ambiguous').
//
// NEDEN FFMPEG YOK: Groq mp4/m4a/webm konteynerini dogrudan kabul eder (ses izini
// kendi ayristirir). Ayrica Edge Function'da native binary calismaz, ffmpeg.wasm
// da 20MB bundle + 2sn CPU limitine sigmaz. Ses ayiklama adimina gerek YOKTUR.
//
// NEDEN LINKTEN INDIRME YOK: App Store 5.2.3 ucuncu-parti kaynaktan medya
// indirmeyi yasaklar; video kullanicinin CIHAZINDAN gelir, uygulama hicbir sey
// indirmez. Bkz. PROJECT_MEMORY Karar Gunlugu.
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders, json } from "../_shared/cors.ts";
import { analyze, type AsrSegment } from "./segments.ts";

const BUCKET = "ayah-audio";
const GROQ_URL = "https://api.groq.com/openai/v1/audio/transcriptions";
// turbo: $0.04/saat, 3 dk video ≈ $0.002. Isabet yetersiz kalirsa `whisper-large-v3`
// (daha dogru, $0.111/saat) tek satirlik yukseltme yolu.
const GROQ_MODEL = "whisper-large-v3-turbo";
const SIGNED_URL_TTL = 300; // sn — Groq'un indirmesi icin yeterli, sonra oluyor
const GROQ_TIMEOUT_MS = 100_000; // EF duvar saati (free 150sn) altinda kal

interface GroqSegment {
  start: number;
  end: number;
  text: string;
}

function baseForm(): FormData {
  const f = new FormData();
  f.append("model", GROQ_MODEL);
  f.append("language", "ar"); // Arapca — isabeti ve gecikmeyi iyilestirir
  f.append("response_format", "verbose_json"); // segment zaman damgalari icin sart
  f.append("temperature", "0");
  return f;
}

function postGroq(apiKey: string, form: FormData): Promise<Response> {
  return fetch(GROQ_URL, {
    method: "POST",
    headers: { Authorization: `Bearer ${apiKey}` },
    body: form,
    signal: AbortSignal.timeout(GROQ_TIMEOUT_MS),
  });
}

/// Groq yanitini ASR segmentlerine cevir. `segments` yoksa tek parca metne duser.
function toSegments(data: unknown): AsrSegment[] {
  const d = data as { text?: string; segments?: GroqSegment[] };
  const segs = d?.segments;
  if (Array.isArray(segs) && segs.length > 0) {
    return segs.map((s) => ({
      start: Number(s.start) || 0,
      end: Number(s.end) || 0,
      text: String(s.text ?? ""),
    }));
  }
  const text = String(d?.text ?? "").trim();
  return text ? [{ start: 0, end: 0, text }] : [];
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const apiKey = Deno.env.get("GROQ_API_KEY");
  if (!apiKey) {
    return json({ status: "error", errorCode: "no_api_key", matches: [] }, 500);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const admin = createClient(
    supabaseUrl,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  let path: string | null = null;

  try {
    const body = await req.json().catch(() => ({}));
    const raw: unknown = body.path;
    if (typeof raw !== "string" || raw.length === 0) {
      return json({ status: "error", errorCode: "no_video", matches: [] }, 400);
    }

    // ── Sahiplik dogrulamasi ──────────────────────────────────────────────────
    // service_role RLS'i BYPASS eder → cagiranin kendi klasorunu okudugunu BURADA
    // dogrulamak zorundayiz. Aksi halde herhangi bir kullanici baskasinin
    // videosunun yolunu gonderip icerigini okutabilirdi.
    const userClient = createClient(
      supabaseUrl,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      {
        global: {
          headers: { Authorization: req.headers.get("Authorization") ?? "" },
        },
      },
    );
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) {
      return json({ status: "error", errorCode: "auth_required", matches: [] }, 401);
    }
    if (!raw.startsWith(`${user.id}/`) || raw.includes("..")) {
      return json({ status: "error", errorCode: "forbidden_path", matches: [] }, 403);
    }
    path = raw;

    // ── Imzali URL → Groq ─────────────────────────────────────────────────────
    const { data: signed, error: signErr } = await admin.storage
      .from(BUCKET)
      .createSignedUrl(path, SIGNED_URL_TTL);
    if (signErr || !signed?.signedUrl) {
      return json({ status: "error", errorCode: "video_missing", matches: [] }, 404);
    }

    // Once `url` parametresi: video baytlari EF belleginden HIC gecmez (256MB /
    // 2sn CPU tavani baypas olur). Groq dokumanlari bu parametrede celisiyor →
    // reddedilirse multipart'a duseriz (ayni sonuc, sadece daha pahali).
    const urlForm = baseForm();
    urlForm.append("url", signed.signedUrl);
    let res = await postGroq(apiKey, urlForm);

    if (!res.ok && [400, 404, 415, 422].includes(res.status)) {
      console.warn(`groq url param reddedildi (${res.status}) → multipart fallback`);
      const dl = await admin.storage.from(BUCKET).download(path);
      if (dl.error || !dl.data) {
        return json({ status: "error", errorCode: "video_missing", matches: [] }, 404);
      }
      const fileForm = baseForm();
      fileForm.append("file", dl.data, path.split("/").pop() ?? "video.mp4");
      res = await postGroq(apiKey, fileForm);
    }

    if (!res.ok) {
      const detail = await res.text();
      console.error(`groq ${res.status}: ${detail}`);
      const code = res.status === 429 ? "rate_limited" : "asr_failed";
      return json({ status: "error", errorCode: code, matches: [] }, 502);
    }

    const result = analyze(toSegments(await res.json()));
    return json(result);
  } catch (e) {
    console.error(`ayah-finder-audio: ${e}`);
    return json({ status: "error", errorCode: "server_error", matches: [] }, 500);
  } finally {
    // Gizlilik: kullanici videosu isi bitince sunucuda KALMAZ. Silme basarisiz
    // olursa sessizce yutma — logla (kalan dosyalar bucket'ta birikir).
    if (path) {
      const { error } = await admin.storage.from(BUCKET).remove([path]);
      if (error) console.error(`temizlik basarisiz (${path}): ${error.message}`);
    }
  }
});
