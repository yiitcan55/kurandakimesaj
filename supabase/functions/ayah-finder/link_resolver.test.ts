// Calistir:  deno test --allow-read supabase/functions/ayah-finder/link_resolver.test.ts
import { assert, assertEquals } from "jsr:@std/assert";
import { fetchImage, isBlockedHost, resolvePostImage } from "./link_resolver.ts";

/// fetch'i gecici olarak stub'lar (gercek ag cagrisi yok), testten sonra geri yukler.
async function withFetch<T>(
  handler: (url: string) => Response,
  fn: () => Promise<T>,
): Promise<T> {
  const orig = globalThis.fetch;
  globalThis.fetch = ((input: string | URL) =>
    Promise.resolve(handler(String(input)))) as typeof fetch;
  try {
    return await fn();
  } finally {
    globalThis.fetch = orig;
  }
}

function html(body: string): Response {
  return new Response(body, {
    headers: { "content-type": "text/html; charset=utf-8" },
  });
}

Deno.test("og:image meta etiketinden gorsel URL'si cikarilir", async () => {
  const page = html(
    `<html><head><meta property="og:image" content="https://cdn.example.com/pic.jpg"></head></html>`,
  );
  const r = await withFetch(
    () => page,
    () => resolvePostImage("https://example.com/post/1"),
  );
  assertEquals(r, { url: "https://cdn.example.com/pic.jpg" });
});

Deno.test("og:image yoksa twitter:image yedek olarak kullanilir", async () => {
  const page = html(
    `<html><head><meta name="twitter:image" content="https://cdn.example.com/tw.jpg"></head></html>`,
  );
  const r = await withFetch(
    () => page,
    () => resolvePostImage("https://example.com/post/2"),
  );
  assertEquals(r, { url: "https://cdn.example.com/tw.jpg" });
});

Deno.test("goreli gorsel URL'si sayfanin host'una gore mutlaklastirilir", async () => {
  const page = html(
    `<html><head><meta property="og:image" content="/img/a.jpg"></head></html>`,
  );
  const r = await withFetch(
    () => page,
    () => resolvePostImage("https://example.com/post/3"),
  );
  assertEquals(r, { url: "https://example.com/img/a.jpg" });
});

Deno.test("TikTok oEmbed yanitindan thumbnail_url cikarilir", async () => {
  const r = await withFetch(
    (url) => {
      if (url.includes("/oembed")) {
        return new Response(
          JSON.stringify({ thumbnail_url: "https://p16.tiktokcdn.com/thumb.jpg" }),
          { headers: { "content-type": "application/json" } },
        );
      }
      throw new Error("beklenmeyen istek: " + url);
    },
    () => resolvePostImage("https://www.tiktok.com/@user/video/123"),
  );
  assertEquals(r, { url: "https://p16.tiktokcdn.com/thumb.jpg" });
});

// Gorsel indirme eskiden korumasiz duz fetch'ti: public og:image → 302 →
// 169.254.169.254 (bulut metadata) otomatik takip ediliyordu.
Deno.test("fetchImage: gorsel indirmede yonlendirme ic aga gidemez", async () => {
  const r = await withFetch(
    () =>
      new Response(null, {
        status: 302,
        headers: { location: "http://169.254.169.254/latest/meta-data/" },
      }),
    () => fetchImage("https://cdn.example.com/pic.jpg"),
  );
  assertEquals(r, { errorCode: "blocked_host" });
});

// Eskiden arrayBuffer() sinirsizdi → bellek DoS. Akis sinirda kesilmeli.
Deno.test("fetchImage: bitmeyen govde boyut sinirinda kesilir", async () => {
  const chunk = new Uint8Array(1024 * 1024);
  const body = new ReadableStream({ pull: (c) => c.enqueue(chunk) });
  const r = await withFetch(
    () => new Response(body, { headers: { "content-type": "image/jpeg" } }),
    () => fetchImage("https://cdn.example.com/huge.jpg"),
  );
  assertEquals(r, { errorCode: "too_large" });
});

// Gercek Instagram/TikTok sayfalari gomulu JSON state ile 1MB+ gelir ve
// content-length BILDIRIR. Erken eleme truncate bayragini yok sayarsa, og:image
// <head>'de acikca dururken cozumleme "too_large" ile olurdu. (Deno'nun sentetik
// Response'u content-length'i kendisi eklemedigi icin bu dal ancak basligi elle
// set edince tetikleniyor — eski testler bunu kaciriyordu.)
Deno.test("buyuk content-length bildiren HTML sayfasinda og:image yine bulunur", async () => {
  const page = new Response(
    `<html><head><meta property="og:image" content="https://cdn.example.com/big.jpg"></head></html>`,
    {
      headers: {
        "content-type": "text/html; charset=utf-8",
        "content-length": String(4 * 1024 * 1024), // 4 MB > _MAX_BYTES (512 KB)
      },
    },
  );
  const r = await withFetch(
    () => page,
    () => resolvePostImage("https://www.instagram.com/p/abc/"),
  );
  assertEquals(r, { url: "https://cdn.example.com/big.jpg" });
});

Deno.test("isBlockedHost SSRF hedeflerinin hepsini reddeder", () => {
  const blocked = [
    "127.0.0.1",
    "localhost",
    "10.0.0.5",
    "172.16.0.1",
    "192.168.1.1",
    "169.254.169.254",
    "0.0.0.0",
    "::1",
    "::ffff:127.0.0.1",
    "fc00::1",
    "foo.local",
  ];
  for (const h of blocked) {
    assert(isBlockedHost(h), `engellenmeliydi: ${h}`);
  }
});

Deno.test("isBlockedHost normal genel hostlari kabul eder", () => {
  const allowed = ["www.tiktok.com", "instagram.com", "example.com"];
  for (const h of allowed) {
    assert(!isBlockedHost(h), `kabul edilmeliydi: ${h}`);
  }
});
