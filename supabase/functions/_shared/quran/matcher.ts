// Arapca normalizasyon + otoriter ayet eslestirme.
//
// LLM yalnizca gorseldeki Arapca metni cikarir; sure:ayet ve meal HER ZAMAN
// buradaki otoriter QURAN veri setinden gelir (uydurma ayet riski sunucuda
// kapatilir). Eslestirme: IDF-agirlikli F1 + bitisik ifade bonusu — gurultulu
// OCR metnine karsi saglamdir (nadir kelimeler agir, dolgu kelimeler hafif).
import { QURAN } from "./quran_data.ts";

export interface AyahMatch {
  reference: string; // "Bakara, 153"
  surah: number;
  ayah: number;
  arabic: string;
  meal: string;
  confidence: number; // 0..1
}

// Sure adlari (1..114) — referans etiketi icin. Diyanet/yaygin Turkce adlar.
const SURAH_NAMES = [
  "Fatiha","Bakara","Al-i Imran","Nisa","Maide","En'am","A'raf","Enfal","Tevbe",
  "Yunus","Hud","Yusuf","Ra'd","İbrahim","Hicr","Nahl","İsra","Kehf","Meryem",
  "Taha","Enbiya","Hac","Mü'minun","Nur","Furkan","Şuara","Neml","Kasas",
  "Ankebut","Rum","Lokman","Secde","Ahzab","Sebe","Fatır","Yasin","Saffat",
  "Sad","Zümer","Mü'min","Fussilet","Şura","Zuhruf","Duhan","Casiye","Ahkaf",
  "Muhammed","Fetih","Hucurat","Kaf","Zariyat","Tur","Necm","Kamer","Rahman",
  "Vakıa","Hadid","Mücadele","Haşr","Mümtehine","Saff","Cuma","Münafikun",
  "Tegabün","Talak","Tahrim","Mülk","Kalem","Hakka","Mearic","Nuh","Cin",
  "Müzzemmil","Müddessir","Kıyame","İnsan","Mürselat","Nebe","Naziat","Abese",
  "Tekvir","İnfitar","Mutaffifin","İnşikak","Büruc","Tarık","A'la","Gaşiye",
  "Fecr","Beled","Şems","Leyl","Duha","İnşirah","Tin","Alak","Kadir","Beyyine",
  "Zilzal","Adiyat","Karia","Tekasür","Asr","Hümeze","Fil","Kureyş","Maun",
  "Kevser","Kafirun","Nasr","Tebbet","İhlas","Felak","Nas",
];

export function surahName(n: number): string {
  return SURAH_NAMES[n - 1] ?? `Sure ${n}`;
}

/// Otoriter veri setinden tek ayet. `segments.ts` ayet ARALIGINI doldururken
/// (eslesmeyen ara ayetleri de gosterirken) kullanir — meal yine yalniz buradan.
export function ayahByRef(
  surah: number,
  ayah: number,
  confidence = 0,
): AyahMatch | null {
  const v = QURAN.find((x) => x.s === surah && x.a === ayah);
  if (!v) return null;
  return {
    reference: `${surahName(v.s)}, ${v.a}`,
    surah: v.s,
    ayah: v.a,
    arabic: v.ar,
    meal: v.meal,
    confidence,
  };
}

// Harekeler (teskil) U+064B–U+0652, hancerli elif U+0670, tatweel U+0640.
const DIACRITICS = /[ً-ْٰـ]/g;
// Hemze/elif varyantlari + ta marbuta/he, ye varyantlari — tek forma indir.
function unifyLetters(s: string): string {
  return s
    .replace(/[آأإٱ]/g, "ا") // آأإٱ → ا
    .replace(/ى/g, "ي") // alif maksura ى → ي
    .replace(/ة/g, "ه") // ta marbuta ة → ه
    .replace(/ؤ/g, "و") // ؤ → و
    .replace(/ئ/g, "ي"); // ئ → ي
}

// Uthmani ↔ modern (imlaei) imla farki.
//
// Korpus (quran_data.ts) uthmani hattinda; ASR (Whisper) ise MODERN imla uretir:
// uthmani `ٱلصَّلَوٰة` → harekeler dusunce `الصلوه`, modern `الصلاة` → `الصلاه`.
// Ayni kelime, farkli iskelet → token hic eslesmez. Asagidaki kucuk kural kumesi
// bu sistematik "vav'li uzun elif" farkini kapatir.
//
// GUVENLI: normalizeArabic hem korpusa hem sorguya uygulanir, yani her iki taraf
// da ayni forma indirgenir — OCR yolu (uthmani gorsel) icin de davranis degismez.
// Onek/ek almis biçimleri de kapsasin diye alt-dizgi (substring) olarak yazildi:
// `والصلوه` → `والصلاه`.
const UTHMANI_VARIANTS: [RegExp, string][] = [
  [/صلوه/g, "صلاه"], // الصلوة / بالصلوة / والصلوة
  [/زكوه/g, "زكاه"], // الزكوة
  [/حيوه/g, "حياه"], // الحيوة
  [/مشكوه/g, "مشكاه"], // مشكوة
  [/منوه/g, "مناه"], // منوة
  [/الربوا/g, "الربا"], // الربوٰا۟
];

export function normalizeArabic(input: string): string {
  let s = unifyLetters(input.replace(DIACRITICS, ""))
    .replace(/‏|‎/g, "") // RTL/LTR isaretleri
    .replace(/[^ء-ي\s]/g, " ") // Arapca harf + bosluk disini sil
    .replace(/\s+/g, " ")
    .trim();
  for (const [re, to] of UTHMANI_VARIANTS) s = s.replace(re, to);
  return s;
}

function tokenize(s: string): string[] {
  const n = normalizeArabic(s);
  return n ? n.split(" ").filter((t) => t.length > 0) : [];
}

// ── IDF + normalize edilmis token listesi (modul yuklenince bir kez) ──────────
let _idf: Map<string, number> | null = null;
let _tokens: string[][] | null = null;

function init(): void {
  if (_idf) return;
  const df = new Map<string, number>();
  const all: string[][] = [];
  for (const v of QURAN) {
    const toks = tokenize(v.ar);
    all.push(toks);
    for (const t of new Set(toks)) df.set(t, (df.get(t) ?? 0) + 1);
  }
  const N = QURAN.length;
  const idf = new Map<string, number>();
  for (const [t, c] of df) idf.set(t, Math.log(N / c));
  _idf = idf;
  _tokens = all;
}

function weight(t: string): number {
  // Sozlukte olmayan token (OCR gurultusu) → 0 agirlik.
  return _idf!.get(t) ?? 0;
}

// En uzun bitisik ortak token dizisi (ifade bonusu icin).
function longestRun(query: string[], ayah: string[]): number {
  const set = new Set(ayah);
  let best = 0, cur = 0;
  for (const q of query) {
    if (set.has(q)) { cur++; best = Math.max(best, cur); } else cur = 0;
  }
  return best;
}

/// query (OCR Arapca) → en iyi adaylar. Bos/eslesmesiz → [].
export function match(query: string, topN = 5): AyahMatch[] {
  init();
  const qToks = tokenize(query);
  if (qToks.length === 0) return [];
  const qSet = new Set(qToks);
  const qWeight = [...qSet].reduce((a, t) => a + weight(t), 0);
  if (qWeight === 0) return [];

  const scored: { i: number; score: number }[] = [];
  for (let i = 0; i < QURAN.length; i++) {
    const aToks = _tokens![i];
    if (aToks.length === 0) continue;
    const aSet = new Set(aToks);
    let inter = 0;
    for (const t of qSet) if (aSet.has(t)) inter += weight(t);
    if (inter === 0) continue;
    const aWeight = [...aSet].reduce((a, t) => a + weight(t), 0);
    const recall = inter / qWeight;
    const precision = aWeight > 0 ? inter / aWeight : 0;
    const f1 = precision + recall > 0 ? (2 * precision * recall) / (precision + recall) : 0;
    // Bitisik ifade bonusu (0..0.5): uzun ardisik eslesme → guclu sinyal.
    const run = longestRun(qToks, aToks);
    const bonus = Math.min(0.5, (run - 1) * 0.12);
    scored.push({ i, score: f1 + Math.max(0, bonus) });
  }
  scored.sort((a, b) => b.score - a.score);

  return scored.slice(0, topN).map(({ i, score }) => {
    const v = QURAN[i];
    return {
      reference: `${surahName(v.s)}, ${v.a}`,
      surah: v.s,
      ayah: v.a,
      arabic: v.ar,
      meal: v.meal,
      confidence: Math.min(1, score),
    };
  });
}
