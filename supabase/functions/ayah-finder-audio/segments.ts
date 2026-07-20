// ASR segmentleri → ayet ARALIGI + zaman cizelgesi.
//
// Saf fonksiyon: ag yok, Deno API'si yok → `deno test` ile tamamen deterministik
// dogrulanir (bkz. segments.test.ts). Groq yalniz ham Arapca metin + zaman damgasi
// dondurur; sure:ayet ve meal HER ZAMAN otoriter `_shared/quran` veri setinden
// gelir (domain kurali — ASR/LLM ayet uydurmaz).
import {
  type AyahMatch,
  ayahByRef,
  match,
  normalizeArabic,
  surahName,
} from "../_shared/quran/matcher.ts";

/// Whisper `verbose_json` segmenti.
export interface AsrSegment {
  start: number; // saniye
  end: number; // saniye
  text: string;
}

export interface AyahRange {
  surah: number;
  fromAyah: number;
  toAyah: number;
  reference: string; // "Yasin, 58-61"
}

export interface TimelineEntry {
  startSec: number;
  endSec: number;
  surah: number;
  ayah: number;
  reference: string;
  confidence: number;
}

/// `ayah-finder` sozlesmesinin UST KUMESI — mevcut alanlar aynen, `range` ve
/// `timeline` opsiyonel eklenti (eski istemci yok sayar, yeni istemci kullanir).
export interface AudioAnalysis {
  status: "matched" | "ambiguous" | "notFound";
  extractedArabic: string;
  matches: AyahMatch[];
  range?: AyahRange;
  timeline: TimelineEntry[];
}

// ── Ayarlar (golden fixture'larla kalibre edilir) ─────────────────────────────
const MIN_WINDOW_TOKENS = 4; // bundan kisa segment komsuyla birlestirilir
const CANDIDATES_PER_WINDOW = 8; // tekrar eden ayetler (or. Rahman) icin genis liste
const ANCHOR_MIN = 0.4; // capa sayilmak icin asgari guven
const EXTEND_MIN = 0.25; // capalar araligi kurduktan SONRA komsu pencere esigi
const MATCHED_MEAN = 0.5; // capalarin ortalama guveni
const MATCHED_COVERAGE = 0.6; // pencerelerin en az %60'i aralikta olmali
const DOMINANT_SHARE = 0.6; // baskin surenin oy payi
const GAP_FILL = 2; // capalar arasi en fazla 2 ayetlik bosluk doldurulur
const MAX_RANGE = 30; // bundan genis aralik = guvenilmez → ambiguous
const WHOLE_TEXT_MIN = 0.5; // tum-metin yedeginde tek ayete oturma esigi
const WHOLE_TEXT_LEAD = 0.12; // ikinciye belirgin ustunluk
const NOT_FOUND_MAX = 0.2; // bunun altinda hicbir sey gosterme

// Tilavet oncesi soylenen, ayet OLMAYAN kaliplar — aralik belirlemede sayilmaz.
// (Besmele Fatiha 1 / Neml 30 olarak; istiaze Nahl 98 olarak sahte eslesir.)
const BASMALA = new Set(normalizeArabic("بسم الله الرحمن الرحيم").split(" "));
const ISTIAZE = new Set(
  normalizeArabic("أعوذ بالله من الشيطان الرجيم").split(" "),
);

function isRitualPrefix(tokens: string[]): boolean {
  if (tokens.length === 0 || tokens.length > 6) return false;
  return tokens.every((t) => BASMALA.has(t)) ||
    tokens.every((t) => ISTIAZE.has(t));
}

interface Window {
  start: number;
  end: number;
  text: string;
  tokens: string[];
  candidates: AyahMatch[];
  ritual: boolean;
}

/// Kisa segmentleri komsusuyla birlestir — 1-2 kelimelik parca IDF tasimaz ve
/// rastgele bir ayete yuksek guvenle oturur (yanlis capa uretir).
function buildWindows(segments: AsrSegment[]): Window[] {
  const out: Window[] = [];
  let bufText = "";
  let bufStart = 0;
  let bufEnd = 0;
  let open = false;

  const flush = () => {
    if (!open) return;
    const tokens = normalizeArabic(bufText).split(" ").filter((t) => t);
    if (tokens.length > 0) {
      out.push({
        start: bufStart,
        end: bufEnd,
        text: bufText.trim(),
        tokens,
        candidates: [],
        ritual: isRitualPrefix(tokens),
      });
    }
    bufText = "";
    open = false;
  };

  for (const s of segments) {
    if (!open) {
      bufStart = s.start;
      open = true;
    }
    bufText += " " + s.text;
    bufEnd = s.end;
    const tokens = normalizeArabic(bufText).split(" ").filter((t) => t);
    if (tokens.length >= MIN_WINDOW_TOKENS) flush();
  }
  flush(); // son (kisa kalmis) tampon da degerlendirilir
  return out;
}

/// Pencereye baskin sureden ayet ata — MONOTON tercihle.
///
/// Tilavet ilerledikce ayet numarasi artar. Tekrar eden ayetlerde (or. Rahman'in
/// "فبأي آلاء ربكما تكذبان" nakarati 31 kez) `match()` skorlari birebir esit olan
/// kopyalarin EN ERKENINI dondurur; monoton tercih ayni pencereyi bir SONRAKI
/// kopyaya oturtur. Guven farki belirginse (>TIE) monotonluk zorlanmaz — yanlis
/// bir erken capa sonraki dogru eslesmeleri bloklamasin diye.
const TIE = 0.05;

function assignMonotonic(
  windows: Window[],
  surah: number,
): Map<Window, AyahMatch> {
  const picks = new Map<Window, AyahMatch>();
  let last = 0;
  for (const w of windows) {
    const cands = w.candidates.filter((c) => c.surah === surah);
    if (cands.length === 0) continue;
    const best = cands[0]; // candidates skora gore sirali
    const forward = cands.find(
      (c) => c.ayah >= last && c.confidence >= best.confidence - TIE,
    );
    const pick = forward ?? best;
    picks.set(w, pick);
    last = pick.ayah;
  }
  return picks;
}

/// Sirali ayet numaralarindan en buyuk "bitisik" kume (aralar ≤ GAP_FILL).
/// Tilavet tek surede artan ardisik ayetlerdir → tek bir sicrayan capa (yanlis
/// eslesme) aralig i sisirmesin diye kume disi birakilir.
function largestCluster(nums: number[]): number[] {
  if (nums.length === 0) return [];
  const sorted = [...new Set(nums)].sort((a, b) => a - b);
  let best: number[] = [];
  let cur: number[] = [sorted[0]];
  for (let i = 1; i < sorted.length; i++) {
    if (sorted[i] - sorted[i - 1] <= GAP_FILL + 1) {
      cur.push(sorted[i]);
    } else {
      if (cur.length > best.length) best = cur;
      cur = [sorted[i]];
    }
  }
  if (cur.length > best.length) best = cur;
  return best;
}

function notFound(text: string): AudioAnalysis {
  return { status: "notFound", extractedArabic: text, matches: [], timeline: [] };
}

/// Capa bulunamadiginda: tum dokumu tek parca olarak eslestir (kisa video /
/// tek ayet senaryosu). Mevcut `ayah-finder` esikleriyle ayni sozlesme.
function wholeTextFallback(text: string): AudioAnalysis {
  const all = match(text, 5);
  if (all.length === 0) return notFound(text);
  const best = all[0].confidence;
  const second = all[1]?.confidence ?? 0;
  if (best >= WHOLE_TEXT_MIN && best - second >= WHOLE_TEXT_LEAD) {
    const m = all[0];
    return {
      status: "matched",
      extractedArabic: text,
      matches: [m],
      range: {
        surah: m.surah,
        fromAyah: m.ayah,
        toAyah: m.ayah,
        reference: m.reference,
      },
      timeline: [],
    };
  }
  if (best < NOT_FOUND_MAX) return notFound(text);
  return { status: "ambiguous", extractedArabic: text, matches: all, timeline: [] };
}

function rangeRef(surah: number, from: number, to: number): string {
  const name = surahName(surah);
  return from === to ? `${name}, ${from}` : `${name}, ${from}-${to}`;
}

/// ASR segmentleri → dogrulanmis ayet araligi.
export function analyze(segments: AsrSegment[]): AudioAnalysis {
  const fullText = segments.map((s) => s.text).join(" ").trim();
  if (normalizeArabic(fullText).length === 0) return notFound(fullText);

  const windows = buildWindows(segments);
  for (const w of windows) w.candidates = match(w.text, CANDIDATES_PER_WINDOW);

  // Aralik belirlemede yalniz ayet olan, aday uretebilen pencereler sayilir.
  const scored = windows.filter((w) => !w.ritual && w.candidates.length > 0);
  if (scored.length === 0) return wholeTextFallback(fullText);

  // ── Baskin sure oylamasi (guven agirlikli) ─────────────────────────────────
  const votes = new Map<number, number>();
  let total = 0;
  for (const w of scored) {
    const top = w.candidates[0];
    votes.set(top.surah, (votes.get(top.surah) ?? 0) + top.confidence);
    total += top.confidence;
  }
  let dominant = 0;
  let domVotes = 0;
  for (const [s, v] of votes) {
    if (v > domVotes) {
      domVotes = v;
      dominant = s;
    }
  }
  const share = total > 0 ? domVotes / total : 0;
  if (dominant === 0 || share < DOMINANT_SHARE) return wholeTextFallback(fullText);

  // ── Monoton atama → capalar ───────────────────────────────────────────────
  // ONEMLI: monotonluk aralik hesabindan ONCE uygulanir. Aksi halde tekrar eden
  // ayetlerin HEPSI ilk kopyaya capalanir ve aralik son tekrari kapsamaz
  // (Rahman 13-18 → yanlislikla 13-17).
  const picks = assignMonotonic(scored, dominant);
  const anchors = scored
    .filter((w) => (picks.get(w)?.confidence ?? 0) >= ANCHOR_MIN)
    .map((w) => ({ w, m: picks.get(w)! }));
  if (anchors.length < 2) return wholeTextFallback(fullText);

  const cluster = largestCluster(anchors.map((a) => a.m.ayah));
  let fromAyah = cluster[0];
  let toAyah = cluster[cluster.length - 1];

  // ── Aralik genisletme (baglam yardimi) ────────────────────────────────────
  // Baskin sure + aralik GUCLU capalarla kurulduktan sonra, ona bitisik ZAYIF bir
  // pencere neredeyse kesin dogrudur: ASR tek kelimeyi yanlis duyunca (or. Yasin 58
  // "رحيم" → "كريم") guven 0.4'un altina duser ve ayet aralik disi kalirdi. Burada
  // esik EXTEND_MIN'e iner — ama YALNIZ zaten dogrulanmis araligin komsulugunda.
  const weak = scored
    .map((w) => picks.get(w))
    .filter((m): m is AyahMatch => !!m && m.confidence >= EXTEND_MIN);
  for (let grew = true; grew;) {
    grew = false;
    for (const m of weak) {
      if (m.ayah < fromAyah && m.ayah >= fromAyah - GAP_FILL) {
        fromAyah = m.ayah;
        grew = true;
      } else if (m.ayah > toAyah && m.ayah <= toAyah + GAP_FILL) {
        toAyah = m.ayah;
        grew = true;
      }
    }
  }
  if (toAyah - fromAyah + 1 > MAX_RANGE) return wholeTextFallback(fullText);

  // Zaman cizelgesi + kapsam: araliga dusen TUM (capa + genisletilmis) pencereler.
  const inRange = scored
    .map((w) => ({ w, m: picks.get(w)! }))
    .filter(({ m }) =>
      m && m.confidence >= EXTEND_MIN && m.ayah >= fromAyah && m.ayah <= toAyah
    );
  // Kalite kapisi capalarla olculur — zayif pencereler barajı dusurmesin.
  const strong = inRange.filter(({ m }) => m.confidence >= ANCHOR_MIN);
  if (strong.length < 2) return wholeTextFallback(fullText);
  const meanConf = strong.reduce((s, a) => s + a.m.confidence, 0) / strong.length;
  const coverage = inRange.length / scored.length;
  if (meanConf < MATCHED_MEAN || coverage < MATCHED_COVERAGE) {
    return wholeTextFallback(fullText);
  }

  // ── Zaman cizelgesi ───────────────────────────────────────────────────────
  // SINIR: adaylar CANDIDATES_PER_WINDOW ile sinirli — cok uzun tekrar zincirinde
  // son kopyalar aday listesine giremeyip erken bir kopyaya duser (kabul edilir:
  // sure dogru kalir, yalniz tekrar indeksi sasabilir).
  const timeline: TimelineEntry[] = [];
  for (const { w, m } of inRange) {
    const prev = timeline[timeline.length - 1];
    if (prev && prev.surah === m.surah && prev.ayah === m.ayah) {
      prev.endSec = w.end; // ayni ayete dusen ardisik pencereler birlesir
      prev.confidence = Math.max(prev.confidence, m.confidence);
    } else {
      timeline.push({
        startSec: w.start,
        endSec: w.end,
        surah: m.surah,
        ayah: m.ayah,
        reference: m.reference,
        confidence: m.confidence,
      });
    }
  }

  // ── Aralikteki TUM ayetler (bosluklar otoriter veriden doldurulur) ─────────
  const confByAyah = new Map<number, number>();
  for (const a of inRange) {
    confByAyah.set(
      a.m.ayah,
      Math.max(confByAyah.get(a.m.ayah) ?? 0, a.m.confidence),
    );
  }
  const matches: AyahMatch[] = [];
  for (let a = fromAyah; a <= toAyah; a++) {
    const m = ayahByRef(dominant, a, confByAyah.get(a) ?? 0);
    if (m) matches.push(m);
  }
  if (matches.length === 0) return wholeTextFallback(fullText);

  return {
    status: "matched",
    extractedArabic: fullText,
    matches,
    range: {
      surah: dominant,
      fromAyah,
      toAyah,
      reference: rangeRef(dominant, fromAyah, toAyah),
    },
    timeline,
  };
}
