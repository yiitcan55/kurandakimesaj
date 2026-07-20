// Calistir:  deno test --allow-read supabase/functions/_shared/quran/matcher.test.ts
import { assert, assertEquals } from "jsr:@std/assert";
import { match, normalizeArabic } from "./matcher.ts";

Deno.test("normalizeArabic harekeleri ve tatweeli temizler", () => {
  // Hareke + tatweel iceren metin → sade forma iner.
  const out = normalizeArabic("الرَّحْمَٰنِ");
  assertEquals(out, "الرحمن");
});

Deno.test("hemze/elif varyantlari birlesir", () => {
  assertEquals(normalizeArabic("أنا إنا آمن"), "انا انا امن");
});

Deno.test("tam besmele Fatiha 1'i bulur", () => {
  const r = match("بسم الله الرحمن الرحيم");
  assert(r.length > 0, "en az bir aday donmeli");
  assertEquals(r[0].surah, 1);
  assertEquals(r[0].ayah, 1);
});

Deno.test("gurultulu/eksik metin dogru ayeti ust sirada bulur", () => {
  // DIKKAT: bu sorgu Bakara 153 DEGIL, Bakara 45'tir. Bakara 45 tam olarak
  // "وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ..." diye BASLAR (vav'li). Bakara 153'te ayni
  // kelime vav'siz gecer ("...ءَامَنُوا اسْتَعِينُوا..."). Test eskiden 153 bekliyordu ve
  // hatalıydi; matcher bastan beri dogru cevabi veriyordu.
  const r = match("واستعينوا بالصبر والصلاة");
  assert(r.length > 0);
  assertEquals(r[0].surah, 2);
  assertEquals(r[0].ayah, 45);
});

Deno.test("Bakara 153 kendi ayirt edici metniyle bulunur", () => {
  const r = match("يا أيها الذين آمنوا استعينوا بالصبر والصلاة إن الله مع الصابرين");
  assert(r.length > 0);
  assertEquals(r[0].surah, 2);
  assertEquals(r[0].ayah, 153);
});

Deno.test("alakasiz metin bos veya dusuk guven doner", () => {
  const r = match("xyz123 qwerty");
  assertEquals(r.length, 0);
});

// ── ASR dayanikliligi: Whisper MODERN imla uretir, korpus uthmani ────────────
// Bu blok ses hattinin (ayah-finder-audio) temel varsayimini kilitler.

Deno.test("uthmani vav'li uzun elif modern imlaya normalize olur", () => {
  // Korpus: ٱلصَّلَوٰة → الصلوه · Modern (Whisper): الصلاة → الصلاه
  assertEquals(normalizeArabic("الصَّلَوٰةِ"), normalizeArabic("الصلاة"));
  assertEquals(normalizeArabic("وَالصَّلَوٰةِ"), normalizeArabic("والصلاة"));
  assertEquals(normalizeArabic("ٱلزَّكَوٰةَ"), normalizeArabic("الزكاة"));
  assertEquals(normalizeArabic("ٱلْحَيَوٰةُ"), normalizeArabic("الحياة"));
});

Deno.test("modern imlali (ASR ciktisi gibi) ayetler dogru bulunur", () => {
  // Whisper'in uretecegi yazimla — korpus uthmani oldugu halde eslesmeli.
  const cases: [string, number, number][] = [
    ["الحمد لله رب العالمين", 1, 2],
    ["ذلك الكتاب لا ريب فيه هدى للمتقين", 2, 2],
    ["سلام قولا من رب رحيم", 36, 58],
    ["فبأي آلاء ربكما تكذبان", 55, 13],
    ["قل هو الله أحد", 112, 1],
    ["وأقيموا الصلاة وآتوا الزكاة واركعوا مع الراكعين", 2, 43],
  ];
  for (const [q, s, a] of cases) {
    const r = match(q, 1);
    assert(r.length > 0, `aday bulunamadi: ${q}`);
    assertEquals(r[0].surah, s, `sure hatali: ${q}`);
    assertEquals(r[0].ayah, a, `ayet hatali: ${q}`);
  }
});
