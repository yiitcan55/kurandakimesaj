// Gonderi baglantisindan gorsel cozumleme.
//
// KIRILGAN: Instagram cogu gonderide giris duvari koyar → og:image gelmez,
// hata kodu doner ve cagiran "ekran goruntusu al" fallback'ine yonlendirir.
// TikTok icin giris gerektirmeyen oEmbed uc noktasi denenir. X/Twitter,
// Facebook, cogu blog/haber sitesi og:image yayinlar → calisir. Bu yuzden link,
// galeriden SONRA gelen ikincil bir giris yoludur.
//
// GUVENLIK (SSRF): kullanicidan gelen URL sunucu tarafindan cekiliyor. Hedef
// host her adimda (yonlendirmeler dahil) dogrulanir, govde boyutu sinirlanir.
// Gorsel indirme de (fetchImage) AYNI kapidan gecer — ikinci, korumasiz bir
// fetch call-site'i birakma.

const _UA =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36";
const _HEADERS: Record<string, string> = {
  "User-Agent": _UA,
  "Accept":
    "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
  "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.5",
};

const _TIMEOUT_MS = 8000;
const _IMAGE_TIMEOUT_MS = 15000; // gorsel govdesi HTML'den buyuk, daha uzun sure.
const _MAX_REDIRECTS = 3;
const _MAX_BYTES = 512 * 1024; // og meta etiketleri <head>'de; fazlasiyla yeter.
// Dart tarafi videoyu 20MB ile siniriyor (kAyahVideoMaxBytes); tek kare gorsel
// icin yarisi fazlasiyla yeter. Sinirsiz arrayBuffer() = bellek DoS.
const _MAX_IMAGE_BYTES = 10 * 1024 * 1024;

/// Cozumleme sonucu: url doluysa basari, doluysa errorCode neden.
export type ResolveResult = { url: string | null; errorCode?: string };

function decodeEntities(s: string): string {
  return s
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&#x27;/gi, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");
}

const _META_PATTERNS: RegExp[] = [
  /<meta[^>]+property=["']og:image(?::secure_url|:url)?["'][^>]+content=["']([^"']+)["']/i,
  /<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image(?::secure_url|:url)?["']/i,
  /<meta[^>]+name=["']twitter:image(?::src)?["'][^>]+content=["']([^"']+)["']/i,
  /<meta[^>]+content=["']([^"']+)["'][^>]+name=["']twitter:image(?::src)?["']/i,
];

// --- SSRF: host dogrulama -----------------------------------------------

// WHATWG IPv4 ayristirmasi (nokta-dortlu + kisa/onlu/sekizli/onaltili bicimler:
// "2130706433", "0177.0.0.1", "0x7f.1"). URL sinifi bunlari zaten normalize
// eder; burada isBlockedHost dogrudan cagrildiginda da tutarli olsun diye var.
function parseIPv4(host: string): number | null {
  const parts = host.split(".");
  if (parts.length === 0 || parts.length > 4) return null;
  const nums: number[] = [];
  for (const p of parts) {
    let n: number;
    if (/^0[xX][0-9a-fA-F]+$/.test(p)) n = parseInt(p.slice(2), 16);
    else if (/^0[0-7]+$/.test(p)) n = parseInt(p.slice(1), 8);
    else if (/^\d+$/.test(p)) n = parseInt(p, 10);
    else return null;
    if (!Number.isFinite(n)) return null;
    nums.push(n);
  }
  const last = nums.pop()!;
  if (nums.some((n) => n > 255)) return null;
  if (last >= 2 ** (8 * (4 - nums.length))) return null;
  let out = last;
  nums.forEach((n, i) => out += n * 2 ** (8 * (3 - i)));
  return out >>> 0;
}

function isBlockedV4(n: number): boolean {
  const a = n >>> 24, b = (n >>> 16) & 255;
  if (a === 0) return true; // 0.0.0.0/8
  if (a === 10) return true; // 10/8 ozel
  if (a === 127) return true; // loopback
  if (a === 169 && b === 254) return true; // link-local (169.254.169.254 metadata)
  if (a === 172 && b >= 16 && b <= 31) return true; // 172.16/12 ozel
  if (a === 192 && b === 168) return true; // 192.168/16 ozel
  if (a === 100 && b >= 64 && b <= 127) return true; // 100.64/10 CGNAT
  if (a >= 224) return true; // 224/4 multicast + 240/4 ayrilmis + 255.255.255.255
  return false;
}

/// Hostname ic aga / loopback'e / bulut metadata'sina isaret ediyor mu?
/// Saf fonksiyon — DNS sorgusu yapmaz, yalniz literal ve isim kontrolu.
/// DNS yeniden baglamayi (public isim → ozel IP) parseTarget kapatir.
export function isBlockedHost(hostname: string): boolean {
  let h = hostname.trim().toLowerCase();
  if (h.endsWith(".")) h = h.slice(0, -1); // koklu FQDN: "example.com."
  if (h.startsWith("[") && h.endsWith("]")) h = h.slice(1, -1); // IPv6 literal
  if (h === "") return true;

  if (h.includes(":")) {
    // IPv4-gomulu bicimler: ::ffff:127.0.0.1 / ::ffff:7f00:1
    const dotted = h.match(/(\d+\.\d+\.\d+\.\d+)$/);
    if (dotted) {
      const n = parseIPv4(dotted[1]);
      if (n !== null) return isBlockedV4(n);
    }
    const mapped = h.match(/^::ffff:([0-9a-f]{1,4}):([0-9a-f]{1,4})$/);
    if (mapped) {
      return isBlockedV4(
        ((parseInt(mapped[1], 16) << 16) | parseInt(mapped[2], 16)) >>> 0,
      );
    }
    const first = parseInt(h.split(":")[0] || "0", 16);
    if (!Number.isFinite(first)) return true; // tanimsiz bicim → engelle
    if (first === 0) return true; // ::, ::1, ::ffff:* — public adres yok
    if ((first & 0xfe00) === 0xfc00) return true; // fc00::/7 ULA
    if ((first & 0xffc0) === 0xfe80) return true; // fe80::/10 link-local
    if ((first & 0xff00) === 0xff00) return true; // ff00::/8 multicast
    return false;
  }

  const v4 = parseIPv4(h);
  if (v4 !== null) return isBlockedV4(v4);

  // Ic isimler ve tek parcali (noktasiz) hostlar — public olarak cozulmezler.
  if (!h.includes(".")) return true; // "localhost", "intranet", ...
  return /\.(localhost|local|internal|lan|home\.arpa)$/.test(h);
}

// --- Ag: her adimda dogrulanan, boyutu sinirli cekme ----------------------

// String kontrolu yetmez: saldirgan kendi public domain'inin A kaydini
// 169.254.169.254'e ayarlayabilir (DNS rebinding) — isim tertemiz gorunur,
// fetch ic adrese baglanir. Cozup donen HER adresi ayni kurallardan gecir.
// ponytail: cozumleme ile baglanti arasinda kayit degisebilir (TOCTOU tam
// kapanmiyor); kapatmak icin cozulen IP'ye baglanip Host basligini elle set
// etmek gerek, fetch buna izin vermiyor.
// Bu on-kontrol fetch'in AbortSignal butcesinin DISINDA kalir; yavas bir
// cozumleyici toplam sureyi 8s/15s'in otesine tasimasin diye kendi kisa siniri.
const _DNS_TIMEOUT_MS = 2000;

async function hasBlockedAddress(hostname: string): Promise<boolean> {
  // Zaten IP literali (isBlockedHost baktI) → DNS'e sormaya gerek yok.
  if (hostname.startsWith("[") || parseIPv4(hostname) !== null) return false;
  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
    // A ve AAAA paralel: sirali beklemek gecikmeyi iki katina cikariyordu.
    // Tek bir kaydin yokluğu (AAAA icin NXDOMAIN normaldir) hata degil → [].
    const lookup = Promise.all(
      (["A", "AAAA"] as const).map((t) =>
        Deno.resolveDns(hostname, t).catch(() => [] as string[])
      ),
    );
    const guard = new Promise<never>((_, reject) => {
      timer = setTimeout(
        () => reject(new Error("dns_timeout")),
        _DNS_TIMEOUT_MS,
      );
    });
    const results = await Promise.race([lookup, guard]);
    return results.some((addrs) => addrs.some(isBlockedHost));
  } catch {
    // ponytail: FAIL-OPEN. Iki neden: (1) izin yok / Deno.resolveDns edge
    // runtime'da yok, (2) cozumleyici zaman asimina ugradi. Deno Deploy API
    // listesinde destekleniyor ama Supabase user worker'inin kisitli API
    // yuzeyi belgesiz; cozulemiyorsa string kontroluyle devam ederiz.
    // Sessiz degil — prod'da DNS kontrolunun kapali oldugu gorulebilsin diye
    // loglaniyor (skeptik denetim bulgusu).
    console.warn(
      `link_resolver: DNS on-kontrolu yapilamadi (${hostname}) — yalniz string kontroluyle devam ediliyor.`,
    );
    return false;
  } finally {
    clearTimeout(timer);
  }
}

async function parseTarget(raw: string, base?: string): Promise<URL | null> {
  let u: URL;
  try {
    u = new URL(raw, base);
  } catch {
    return null;
  }
  if (u.protocol !== "http:" && u.protocol !== "https:") return null;
  if (isBlockedHost(u.hostname)) return null;
  if (await hasBlockedAddress(u.hostname)) return null;
  return u;
}

// redirect:"manual" → her atlamayi yeniden dogrula (public URL → 302 → metadata
// uc noktasi saldirisi bu yuzden kapali).
async function fetchGuarded(
  start: URL,
  timeoutMs = _TIMEOUT_MS,
): Promise<{ res: Response; url: URL } | { errorCode: string }> {
  let target = start;
  for (let hop = 0; hop <= _MAX_REDIRECTS; hop++) {
    let res: Response;
    try {
      res = await fetch(target.href, {
        headers: _HEADERS,
        redirect: "manual",
        signal: AbortSignal.timeout(timeoutMs),
      });
    } catch (e) {
      return {
        errorCode: (e as Error)?.name === "TimeoutError"
          ? "timeout"
          : "fetch_failed",
      };
    }
    if (res.status >= 300 && res.status < 400) {
      const loc = res.headers.get("location");
      await res.body?.cancel().catch(() => {});
      if (!loc) return { errorCode: "fetch_failed" };
      const next = await parseTarget(loc, target.href);
      if (!next) return { errorCode: "blocked_host" };
      target = next;
      continue;
    }
    if (!res.ok) {
      await res.body?.cancel().catch(() => {});
      return { errorCode: "fetch_failed" }; // 403/404/giris duvari
    }
    return { res, url: target };
  }
  return { errorCode: "too_many_redirects" };
}

// Govdeyi akis halinde oku, sinirda kes. Content-Length varsa onceden ele
// (ama ona guvenme: saldirgan yalan soyleyebilir, sayac akista tutuluyor).
// truncate=true → sinir asilirsa ilk `max` bayt (og etiketleri <head>'de),
// truncate=false → null (yarim gorsel ise yaramaz, "too_large" demek).
async function readCappedBytes(
  res: Response,
  max: number,
  truncate: boolean,
): Promise<Uint8Array | null> {
  // Erken elemeyi YALNIZ truncate=false (gorsel) yolunda yap. HTML yolunda
  // buyuk Content-Length normaldir (Instagram/TikTok gomulu JSON state ile 1MB+
  // gelir) ve og:image zaten <head>'de — burada erken cikmak, etiket sayfada
  // acikca dururken cozumlemeyi "too_large" ile oldururdu.
  const declared = Number(res.headers.get("content-length"));
  if (!truncate && Number.isFinite(declared) && declared > max) {
    await res.body?.cancel().catch(() => {});
    return null;
  }
  const reader = res.body?.getReader();
  if (!reader) return null;
  const chunks: Uint8Array[] = [];
  let total = 0;
  while (total <= max) { // max+1'inci bayt gelirse sinir gercekten asilmistir
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(value);
    total += value.length;
  }
  await reader.cancel().catch(() => {});
  if (total > max && !truncate) return null;
  const n = Math.min(total, max);
  const buf = new Uint8Array(n);
  let off = 0;
  for (const c of chunks) {
    if (off >= n) break;
    const part = c.subarray(0, n - off);
    buf.set(part, off);
    off += part.length;
  }
  return buf;
}

async function readCapped(res: Response, max: number): Promise<string | null> {
  const buf = await readCappedBytes(res, max, true);
  return buf === null ? null : new TextDecoder().decode(buf);
}

// TikTok: og:image giris duvarinin arkasinda, oEmbed acik. Baska saglayici yok.
async function tiktokThumbnail(postUrl: string): Promise<string | null> {
  const api = new URL("https://www.tiktok.com/oembed");
  api.searchParams.set("url", postUrl);
  const r = await fetchGuarded(api);
  if ("errorCode" in r) return null;
  const body = await readCapped(r.res, 64 * 1024);
  if (!body) return null;
  try {
    const thumb = JSON.parse(body)?.thumbnail_url;
    return typeof thumb === "string" && thumb ? thumb : null;
  } catch {
    return null;
  }
}

/// Gonderi URL'sinden gorsel URL'si cikar (TikTok oEmbed → og:image /
/// twitter:image). Bulunamazsa {url:null, errorCode:...}.
export async function resolvePostImage(url: string): Promise<ResolveResult> {
  const target = await parseTarget(url);
  if (!target) {
    // Ayrimi koru: sema/bicim hatasi mi, engellenen host mu? parseTarget yalniz
    // bu iki nedenle null doner — sema uyuyorsa geri kalan tek neden hostun
    // (isim ya da cozulen IP olarak) engellenmis olmasi.
    try {
      const u = new URL(url);
      if (u.protocol === "http:" || u.protocol === "https:") {
        return { url: null, errorCode: "blocked_host" };
      }
    } catch { /* gecersiz URL */ }
    return { url: null, errorCode: "invalid_url" };
  }

  if (/(^|\.)tiktok\.com$/.test(target.hostname)) {
    const thumb = await tiktokThumbnail(target.href);
    if (thumb) {
      const abs = await parseTarget(thumb, target.href);
      if (abs) return { url: abs.href };
    }
    // oEmbed tutmadi → asagidaki og:image hattina dus.
  }

  const r = await fetchGuarded(target);
  if ("errorCode" in r) return { url: null, errorCode: r.errorCode };
  const { res, url: final } = r;

  const ct = res.headers.get("content-type") ?? "";
  // Dogrudan gorsel linki ise (yonlendirmeler sonrasi) URL'nin kendisi gorseldir.
  if (ct.startsWith("image/")) {
    await res.body?.cancel().catch(() => {});
    return { url: final.href };
  }
  if (!ct.includes("text/html")) {
    await res.body?.cancel().catch(() => {});
    return { url: null, errorCode: "not_html" }; // video/* dahil
  }

  const html = await readCapped(res, _MAX_BYTES);
  if (html === null) return { url: null, errorCode: "too_large" };

  for (const p of _META_PATTERNS) {
    const m = html.match(p);
    if (!m?.[1]) continue;
    const found = decodeEntities(m[1].trim());
    // Goreli URL'yi mutlaklastir + gorsel hedefini de dogrula (og:image
    // saldirgan kontrolunde olabilir; cagiran onu tekrar indiriyor).
    const abs = await parseTarget(found, final.href);
    if (abs) return { url: abs.href };
    return { url: null, errorCode: "blocked_host" };
  }
  return { url: null, errorCode: "link_unresolved" }; // og:image yok
}

/// Cozulmus gorsel URL'sini indir. resolvePostImage ile AYNI kapidan gecer:
/// manual redirect + her hop'ta host/IP dogrulama + boyut siniri. (Eskiden
/// index.ts bunu korumasiz duz fetch ile yapiyordu → og:image public kalip
/// 302 ile metadata servisine yonlendiren SSRF acigi.)
export async function fetchImage(
  raw: string,
): Promise<{ bytes: Uint8Array; mime: string } | { errorCode: string }> {
  const target = await parseTarget(raw);
  if (!target) return { errorCode: "blocked_host" };
  const r = await fetchGuarded(target, _IMAGE_TIMEOUT_MS);
  if ("errorCode" in r) return r;
  const mime = r.res.headers.get("content-type") ?? "image/jpeg";
  if (!mime.startsWith("image/")) {
    await r.res.body?.cancel().catch(() => {});
    return { errorCode: "link_unresolved" };
  }
  const bytes = await readCappedBytes(r.res, _MAX_IMAGE_BYTES, false);
  if (bytes === null) return { errorCode: "too_large" };
  return { bytes, mime };
}
