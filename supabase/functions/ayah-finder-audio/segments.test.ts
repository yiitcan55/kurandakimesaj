// Calistir:  deno test --allow-read supabase/functions/ayah-finder-audio/segments.test.ts
//
// Metinler MODERN imla ile yazildi — Whisper'in uretecegi bicim budur (korpus ise
// uthmani). Testler hem imla koprusunu hem aralik/zaman cizelgesi mantigini kilitler.
import { assert, assertEquals } from "jsr:@std/assert";
import { analyze, type AsrSegment } from "./segments.ts";

/// Metin listesini 4'er saniyelik ardisik ASR segmentlerine cevirir.
function segs(texts: string[], step = 4): AsrSegment[] {
  return texts.map((text, i) => ({ start: i * step, end: (i + 1) * step, text }));
}

const BESMELE = "بسم الله الرحمن الرحيم";
const ISTIAZE = "أعوذ بالله من الشيطان الرجيم";

const YASIN_58 = "سلام قولا من رب رحيم";
const YASIN_59 = "وامتازوا اليوم أيها المجرمون";
const YASIN_60 =
  "ألم أعهد إليكم يا بني آدم أن لا تعبدوا الشيطان إنه لكم عدو مبين";
const YASIN_61 = "وأن اعبدوني هذا صراط مستقيم";

const RAHMAN_REFRAIN = "فبأي آلاء ربكما تكذبان";
const RAHMAN_14 = "خلق الإنسان من صلصال كالفخار";
const RAHMAN_15 = "وخلق الجان من مارج من نار";
const RAHMAN_17 = "رب المشرقين ورب المغربين";

Deno.test("mutlu yol: Yasin 58-61 araligi ve zaman cizelgesi", () => {
  const r = analyze(segs([YASIN_58, YASIN_59, YASIN_60, YASIN_61]));

  assertEquals(r.status, "matched");
  assertEquals(r.range?.surah, 36);
  assertEquals(r.range?.fromAyah, 58);
  assertEquals(r.range?.toAyah, 61);
  assertEquals(r.range?.reference, "Yasin, 58-61");

  // Aralikteki her ayet otoriter veriden dolu gelir (Arapca + meal bos olamaz).
  assertEquals(r.matches.map((m) => m.ayah), [58, 59, 60, 61]);
  for (const m of r.matches) {
    assert(m.arabic.length > 0, `Arapca bos: ${m.reference}`);
    assert(m.meal.length > 0, `meal bos: ${m.reference}`);
  }

  // Zaman cizelgesi zaman sirasinda ve artan ayet numarali olmali.
  assertEquals(r.timeline.map((t) => t.ayah), [58, 59, 60, 61]);
  assertEquals(r.timeline[0].startSec, 0);
  assert(r.timeline[3].endSec > r.timeline[0].endSec);
});

Deno.test("besmele + istiaze aralik disi birakilir (Fatiha'ya kaymaz)", () => {
  const r = analyze(segs([ISTIAZE, BESMELE, YASIN_58, YASIN_59, YASIN_60, YASIN_61]));

  assertEquals(r.status, "matched");
  assertEquals(r.range?.surah, 36); // Fatiha 1 / Neml 30 DEGIL
  assertEquals(r.range?.fromAyah, 58);
  assertEquals(r.range?.toAyah, 61);
  // Ritüel giris zaman cizelgesinde de yer almaz.
  assert(r.timeline.every((t) => t.surah === 36));
});

Deno.test("ayet ortasindan bolunen segmentler birlestirilir", () => {
  // Whisper bir ayeti birden cok kisa segmente boler.
  const r = analyze(segs([
    "سلام",
    "قولا من",
    "رب رحيم",
    "وامتازوا اليوم",
    "أيها المجرمون",
  ], 2));

  assertEquals(r.status, "matched");
  assertEquals(r.range?.surah, 36);
  assertEquals(r.range?.fromAyah, 58);
  assertEquals(r.range?.toAyah, 59);
});

Deno.test("tekrar eden ayet (Rahman nakarati) monoton cozulur", () => {
  const r = analyze(segs([
    RAHMAN_REFRAIN, // 55:13
    RAHMAN_14,
    RAHMAN_15,
    RAHMAN_REFRAIN, // 55:16  ← ilk kopyaya (13) DUSMEMELI
    RAHMAN_17,
    RAHMAN_REFRAIN, // 55:18
  ]));

  assertEquals(r.status, "matched");
  assertEquals(r.range?.surah, 55);
  assertEquals(r.range?.fromAyah, 13);
  assertEquals(r.range?.toAyah, 18); // son nakarat araliga dahil
  assertEquals(r.timeline.map((t) => t.ayah), [13, 14, 15, 16, 17, 18]);
});

Deno.test("tek ayetlik kisa video (capa yok) tum-metin yedegiyle bulunur", () => {
  const r = analyze(segs([YASIN_60]));

  assertEquals(r.status, "matched");
  assertEquals(r.matches.length, 1);
  assertEquals(r.matches[0].surah, 36);
  assertEquals(r.matches[0].ayah, 60);
});

Deno.test("ASR gurultusu araya girse de dogru aralik bulunur", () => {
  // Whisper tilavette kelime uydurabilir / duserebilir.
  const r = analyze(segs([
    "سلام قولا من رب كريم", // "رحيم" → "كريم" (ASR hatasi)
    "وامتازوا اليوم أيها المجرمون",
    "ألم أعهد إليكم يا بني آدم أن لا تعبدوا الشيطان",
    "وأن اعبدوني هذا صراط مستقيم",
  ]));

  assertEquals(r.status, "matched");
  assertEquals(r.range?.surah, 36);
  assertEquals(r.range?.fromAyah, 58);
  assertEquals(r.range?.toAyah, 61);
});

Deno.test("sessiz / muzikli video → notFound (yanlis ayet gosterme)", () => {
  assertEquals(analyze([]).status, "notFound");
  assertEquals(analyze(segs([""])).status, "notFound");
  assertEquals(analyze(segs(["   "])).status, "notFound");
});

Deno.test("Arapca olmayan konusma → notFound", () => {
  const r = analyze(segs([
    "Merhaba arkadaslar bugun sizlere",
    "yeni bir video hazirladim",
  ]));
  assertEquals(r.status, "notFound");
  assertEquals(r.matches.length, 0);
});

Deno.test("sadece besmele okunan video Fatiha 1'i verir (aralik uydurmaz)", () => {
  const r = analyze(segs([BESMELE]));
  // Ritüel filtre tum pencereleri eledi → tum-metin yedegi devreye girer.
  assert(r.status === "matched" || r.status === "ambiguous");
  if (r.status === "matched") {
    assertEquals(r.matches[0].surah, 1);
    assertEquals(r.matches[0].ayah, 1);
  }
});

Deno.test("matched sonucta meal ve Arapca metin ASLA bos gelmez", () => {
  const r = analyze(segs([YASIN_58, YASIN_59, YASIN_60, YASIN_61]));
  assertEquals(r.status, "matched");
  assert(r.matches.length > 0);
  for (const m of r.matches) {
    assert(m.reference.includes("Yasin"));
    assert(m.arabic.trim().length > 0);
    assert(m.meal.trim().length > 0);
  }
});
