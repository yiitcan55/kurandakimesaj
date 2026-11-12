# Meallere tefsir ekleme — Muhtasar Tefsir (QuranEnc) — şartname (2026-11-09)

## Karar (kullanıcı, 2026-11-09)

İstek: "meallere tefsir eklenecek, Diyanet API'sından". Diyanet'in herkese açık bir tefsir API'si yok. Kullanıcı kararı: **açık lisanslı tefsir — QuranEnc.com'daki Türkçe "Muhtasar Kur'an-ı Kerim Tefsiri Türkçe Tercümesi"** (`turkish_mokhtasar`).

## Kaynak

- `GET https://quranenc.com/api/v1/translation/sura/turkish_mokhtasar/{1..114}` → `{"result":[{"id","sura","aya","arabic_text","translation","footnotes"}]}` (sayılar string).
- Toplam 6236 ayet; her ayetin tefsiri `translation` alanındadır. `footnotes` bu kaynakta boş geliyor (betik doluysa aynen ayrı alanda saklar).
- Başlık: "Muhtasar Kur'an-ı Kerim Tefsiri Türkçe Tercümesi" — yayıncı: QuranEnc.com.

## Yeniden yayın koşulları (uyulacak)

1. İçerik DEĞİŞTİRİLMEZ, eklenmez, silinmez (trim bile yok; `tool/fetch_tafsir.dart` metni aynen yazar).
2. Yayıncı ve kaynak (QuranEnc.com) açıkça anılır → tefsir gösterilen her yerde "Kaynak: Muhtasar Kur'an-ı Kerim Tefsiri Türkçe Tercümesi — QuranEnc.com".
3. Sürüm anılır; güncel sürüme göre güncellenir.
4. Uygunsuz reklam yok.

## Neden paketli varlık

Mevcut `tool/fetch_quran.dart` → `assets/quran/quran_full.json` kalıbı: betikle çekilip uygulamayla paketlenir (`assets/quran/tafsir_muhtasar_tr.json`, ≈1,9 MB).

- **Çevrimdışı çalışır** (uygulama çevrimdışı öncelikli).
- **Ağ/IP sızıntısı yok:** kullanıcı cihazı QuranEnc'e hiç istek atmaz; gizlilik beyanı (`PRIVACY_POLICY.md`) değişmez, yalnızca tefsir kaynağı cümlesi eklenir.
- Çalışma zamanı API bağımlılığı, hız sınırı ve kesinti riski yok.

## Tasarım

- `tool/fetch_tafsir.dart` → `{"meta":{"title","source","key","fetched"},"tafsir":{"s:a":"..."}}` (+ doluysa `"footnotes"`). 6236 ayet değilse hata verir.
- `lib/data/tafsir.dart`: `tafsirProvider` (`FutureProvider<Tafsir>`; `rootBundle.loadString` + `Isolate.run(jsonDecode)`). `Tafsir` = ayet haritası + meta (başlık/kaynak/fetched) + `sourceLine`. Hata `debugPrint` ile loglanır ve yeniden fırlatılır; yeniden deneme kapalı.
- `AyahNote` (okuyucu, Günün Ayeti, Konuya Göre; imza değişmedi): mevcut "Kısa açıklama" korunur, altına katlanabilir "Tefsir" (varsayılan kapalı) + kaynak satırı. Tefsir her ayette vardır; yüklenmediyse/hatada bölüm çizilmez, uygulama çökmez. `_TafsirSection` bir `ConsumerWidget`'tır; ProviderScope şarttır (testler ProviderScope ile pompalar).
- Tefsir başlığı veri yüklenirken de çizilir (okuyucu kaydırması kaymasın).
- Günün Ayeti "Anla" sayfası: kısa açıklamanın altında Muhtasar metni + aynı kaynak satırı; ikisi de yoksa eski "Bu ayet için henüz açıklama eklenmedi." mesajı.

## Açık soru

- **Sürüm numarası:** API sürüm bilgisi vermiyor; koşul 3 için şimdilik yalnız çekilme tarihi (`meta.fetched`) tutuluyor, arayüzde gösterilmiyor. QuranEnc'ten sürüm bilgisi/uygun anma biçimi sorulmalı; güncelleme = `dart run tool/fetch_tafsir.dart` + sürüm notu.
- `footnotes` alanı bu kaynakta boş; ileride dolarsa arayüzde gösterim ayrıca kararlaştırılmalı.

## Doğrulama

`test/tafsir_test.dart`: varlık sözleşmesi (6236 anahtar, hepsi dolu, 114 surenin tüm ayetleri, "1:1" birebir başlangıcı), AyahNote (katlı başlar, açılınca metin + kaynak satırı, hata dayanıklılığı), Günün Ayeti "Anla".
