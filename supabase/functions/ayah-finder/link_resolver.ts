// Gonderi baglantisindan gorsel cozumleme.
//
// KIRILGAN: Instagram cogu gonderide giris duvari koyar → og:image gelmez,
// null doner ve cagiran "ekran goruntusu al" fallback'ine yonlendirir. X/Twitter,
// Facebook, cogu blog/haber sitesi og:image yayinlar → calisir. Bu yuzden link,
// galeriden SONRA gelen ikincil bir giris yoludur.

const _UA =
  "Mozilla/5.0 (compatible; KuranAyetBulucu/1.0; +https://kurandakimesaj.app)";

function decodeEntities(s: string): string {
  return s
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");
}

const _META_PATTERNS: RegExp[] = [
  /<meta[^>]+property=["']og:image(?::secure_url)?["'][^>]+content=["']([^"']+)["']/i,
  /<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image(?::secure_url)?["']/i,
  /<meta[^>]+name=["']twitter:image(?::src)?["'][^>]+content=["']([^"']+)["']/i,
  /<meta[^>]+content=["']([^"']+)["'][^>]+name=["']twitter:image(?::src)?["']/i,
];

/// Gonderi URL'sinden gorsel URL'si cikar (og:image / twitter:image). Yoksa null.
export async function resolvePostImage(url: string): Promise<string | null> {
  let target: URL;
  try {
    target = new URL(url);
  } catch {
    return null; // gecersiz URL
  }
  if (target.protocol !== "http:" && target.protocol !== "https:") return null;

  try {
    const res = await fetch(target.href, {
      headers: { "User-Agent": _UA, "Accept": "text/html,*/*" },
      redirect: "follow",
      signal: AbortSignal.timeout(12000),
    });
    if (!res.ok) return null;
    const ct = res.headers.get("content-type") ?? "";
    // Dogrudan gorsel linki ise URL'nin kendisi gorseldir.
    if (ct.startsWith("image/")) return target.href;
    if (!ct.includes("text/html")) return null;

    const html = await res.text();
    for (const p of _META_PATTERNS) {
      const m = html.match(p);
      if (m?.[1]) {
        const found = decodeEntities(m[1].trim());
        // Goreli URL'yi mutlaka cevir.
        try {
          return new URL(found, target.href).href;
        } catch {
          return found;
        }
      }
    }
    return null;
  } catch {
    return null; // ag hatasi / zaman asimi / giris duvari
  }
}
