// ayah-finder — gorselden/baglantidan Kur'an ayeti tanima.
//
// Akis: istemci gorsel (base64) VEYA gonderi baglantisi gonderir → (baglanti ise
// link_resolver gorseli cozer) → Gemini Flash gorseldeki Arapca metni AYNEN
// cikarir (sure:ayet TAHMIN ETMEZ) → normalize + otoriter eslestirme (matcher.ts)
// → sure:ayet + Diyanet meali DOGRULANMIS olarak doner.
//
// Dini dogruluk (domain kurali): sure:ayet ve meal yalnizca sunucudaki QURAN
// veri setinden gelir, LLM'den ASLA. Belirsizlikte tek yanlis ayet yerine aday
// listesi (status='ambiguous') doner.
//
// Faz 1: imageBase64 (galeri). Faz 2: postUrl (link cozumleme). Faz 3: paylas
// menusu de imageBase64 yoluyla gelir (istemci dosyayi okuyup gonderir).
import { encodeBase64 } from "jsr:@std/encoding/base64";
import { corsHeaders, json } from "../_shared/cors.ts";
// Otoriter eslestirici `_shared/quran/`te — `ayah-finder-audio` da ayni matcher
// ve ayni Kur'an veri setini kullanir (tek dogru kaynak).
import { match } from "../_shared/quran/matcher.ts";
import { fetchImage, resolvePostImage } from "./link_resolver.ts";

// NOT: gemini-2.0-flash ücretsiz tier'dan kaldırıldı (free_tier limit:0 → 429).
// gemini-2.5-flash ücretsiz tier'da aktif (2026-06 doğrulandı).
const GEMINI_MODEL = "gemini-2.5-flash";
const GEMINI_URL =
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

const PROMPT =
  "Sen bir OCR aracisin. Bu gorseldeki Arapca Kur'an metnini AYNEN cikar. " +
  "Sure adi veya ayet numarasi TAHMIN ETME, yorum yapma. " +
  'Yalniz su JSON formatinda yanit ver: {"arabic":"<gorseldeki Arapca metin>",' +
  '"turkish":"<varsa Turkce meal metni, yoksa bos>"}. ' +
  "Gorselde Arapca yoksa arabic alanini bos birak.";

interface Extracted {
  arabic: string;
  turkish: string;
}

interface ImageSource {
  base64: string;
  mime: string;
}

// Gemini'den {arabic, turkish} cikar. JSON disi cikti gelirse en iyi caba parse.
async function extractFromImage(
  apiKey: string,
  src: ImageSource,
): Promise<Extracted> {
  // Anahtar QUERY STRING'de DEGIL baslikta: Deno'nun fetch hatalari mesajin
  // icinde TAM URL'yi tasir ("error sending request for url (...?key=AIza...)").
  // Query string'de kalsaydi her ag hatasi GEMINI_API_KEY'i disari sizdirirdi.
  const res = await fetch(GEMINI_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
    body: JSON.stringify({
      contents: [{
        parts: [
          { text: PROMPT },
          { inline_data: { mime_type: src.mime, data: src.base64 } },
        ],
      }],
      generationConfig: { temperature: 0, responseMimeType: "application/json" },
    }),
  });
  if (!res.ok) {
    throw new Error(`Gemini ${res.status}: ${await res.text()}`);
  }
  const data = await res.json();
  const text: string = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}";
  try {
    const parsed = JSON.parse(text);
    return {
      arabic: String(parsed.arabic ?? "").trim(),
      turkish: String(parsed.turkish ?? "").trim(),
    };
  } catch {
    return { arabic: "", turkish: "" };
  }
}

// "data:image/png;base64,...." veya saf base64 → {base64, mime}.
function splitDataUrl(input: string): ImageSource {
  const m = input.match(/^data:([^;]+);base64,(.*)$/s);
  if (m) return { mime: m[1], base64: m[2] };
  return { mime: "image/jpeg", base64: input };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  try {
    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) return json({ status: "error", errorCode: "no_api_key", matches: [] }, 500);

    const body = await req.json().catch(() => ({}));
    const imageBase64: string | undefined = body.imageBase64;
    const postUrl: string | undefined = body.postUrl;

    // Gorsel kaynagini belirle: dogrudan gorsel > baglanti cozumleme.
    let src: ImageSource | null = null;
    if (imageBase64) {
      src = splitDataUrl(imageBase64);
    } else if (postUrl) {
      // Cozumleme de indirme de link_resolver'daki tek SSRF kapisindan gecer.
      const resolved = await resolvePostImage(postUrl);
      const dl = resolved.url
        ? await fetchImage(resolved.url)
        : { errorCode: resolved.errorCode ?? "link_unresolved" };
      if ("errorCode" in dl) {
        // Baglanti cozulemedi (or. Instagram giris duvari) → durust hata.
        // Engellenen host disindaki tum nedenler ayni fallback'i onerir
        // (ekran goruntusu / video sec) → link_unresolved.
        return json({
          status: "error",
          errorCode: dl.errorCode === "blocked_host" ? "blocked_host" : "link_unresolved",
          extractedArabic: "",
          matches: [],
        });
      }
      src = { base64: encodeBase64(dl.bytes), mime: dl.mime };
    } else {
      return json({ status: "error", errorCode: "no_image", matches: [] }, 400);
    }

    const extracted = await extractFromImage(apiKey, src);
    if (!extracted.arabic) {
      return json({ status: "notFound", extractedArabic: "", matches: [] });
    }

    const matches = match(extracted.arabic, 5);
    if (matches.length === 0) {
      return json({ status: "notFound", extractedArabic: extracted.arabic, matches: [] });
    }

    const best = matches[0].confidence;
    const second = matches[1]?.confidence ?? 0;
    // Net kazanan: yuksek guven + ikinciye belirgin ustunluk → tek sonuc.
    if (best >= 0.5 && best - second >= 0.12) {
      return json({ status: "matched", extractedArabic: extracted.arabic, matches: [matches[0]] });
    }
    // Cok dusuk guven → bulunamadi say (yanlis ayet gostermektense).
    if (best < 0.2) {
      return json({ status: "notFound", extractedArabic: extracted.arabic, matches: [] });
    }
    // Belirsiz: kullanici dogru adayi secsin.
    return json({ status: "ambiguous", extractedArabic: extracted.arabic, matches });
  } catch (e) {
    // Ham istisna metnini ISTEMCIYE DONDURME: icinde ic uc nokta URL'leri,
    // yigin izleri ve (anahtar baslikta olsa bile) ortam ayrintilari tasiyabilir.
    // Sunucu gunlugune tam metin, istemciye yalniz kod.
    console.error("ayah-finder beklenmeyen hata:", e);
    return json({ status: "error", errorCode: "server_error", matches: [] }, 500);
  }
});
