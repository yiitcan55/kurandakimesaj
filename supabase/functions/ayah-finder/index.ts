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
import { resolvePostImage } from "./link_resolver.ts";

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
  const res = await fetch(`${GEMINI_URL}?key=${apiKey}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
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

// Gonderi baglantisindan gorsel indir → {base64, mime}. Cozulmezse null.
async function fetchImageFromUrl(postUrl: string): Promise<ImageSource | null> {
  const imgUrl = await resolvePostImage(postUrl);
  if (!imgUrl) return null;
  try {
    const res = await fetch(imgUrl, { signal: AbortSignal.timeout(15000) });
    if (!res.ok) return null;
    const mime = res.headers.get("content-type") ?? "image/jpeg";
    if (!mime.startsWith("image/")) return null;
    const bytes = new Uint8Array(await res.arrayBuffer());
    return { base64: encodeBase64(bytes), mime };
  } catch {
    return null;
  }
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
      src = await fetchImageFromUrl(postUrl);
      if (src == null) {
        // Baglanti cozulemedi ( or. Instagram giris duvari) → durust hata.
        return json({
          status: "error",
          errorCode: "link_unresolved",
          extractedArabic: "",
          matches: [],
        });
      }
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
    return json({ status: "error", errorCode: "server_error", message: String(e), matches: [] }, 500);
  }
});
