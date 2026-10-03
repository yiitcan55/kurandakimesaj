# İçerik + Düzeltmeler Sürümü — Uygulama Planı

Kaynak plan: `~/.claude/plans/pasted-content-id-33fb-goal-g-rev-structured-badger.md` (onaylı) · Dal: `feat/icerik-ve-duzeltmeler` (`feat/meal-duzenle` üstüne) · Görevler: `tasks/todo.md`

## Kullanıcı kararları
Tefsir kaynağı Elmalılı · Meal Düzenle sürüme DAHİL · Orta hacim · iki mağazaya inceleme kuyruğuna gönderim (gönderimden önce açık onay).

> **Sürüm numarası düzeltmesi:** Plan "1.0.4" diyordu; bu, hafızadaki Deyiver projesinin 1.0.3'ü ile karışmıştı. Bu projede mağazadaki son sürüm 1.0.1 (build 5). Numara, yayın aşamasında App Store Connect / Play Console'a bakılarak belirlenir (beklenen: 1.0.2).

## Dokunulmaz sınırlar (her ajan prompt'una kopyalanır)
`feed_posts_moderation_guard` · `feed_select_visible` / `feed_select_admin` · `is_own_post_media` · `revoke update on profiles` · `BottomBar heightFactor: 1` · `receive_sharing_intent` 1.8.1 pini · `launchMode="singleTop"` · `test/bottom_bar_height_test.dart` · uygulama hiçbir bağlantıdan video indirmez (App Store 5.2.3).

## Maddeler
| # | Madde | Kök neden / yaklaşım | Skill → Ajan |
|---|---|---|---|
| 1 | Reels sesi sekme değişince sürüyor | `isActive` yalnız PageView konumundan; `indexedStack` dalı dispose etmez; lifecycle/Ticker/Route dinleyicisi yok | `investigate` → `error-detective`; `flutter-add-widget-test` → `ecc:tdd-guide`; `ecc:flutter-reviewer` |
| 2 | Meal altına tefsir (Elmalılı) | Şema hazır, veri yok. Kapı 0: lisanslı makine-okunur kaynak; yoksa daraltılmış kapsam | `superpowers:brainstorming`; `ecc:database-migrations`; `ecc:flutter-reviewer` |
| 3 | Dua 10 → ~40 | `seed_data.dart` `kDuaSeed` | `ecc:orch-add-feature` + Doğruluk Kapısı |
| 4 | Konuya göre ayet → konu başına 4–6 | `kTopicalSeed`, ayet metni `quran_full.json`'dan | aynı |
| 5 | Mucizeler 30 → ~45 | tekrarlar temizlenir | aynı |
| 6 | Kıssalar → peygamber başına 2–3 + 5 eksik peygamber | İsmâil, İshâk, Yâkub, Hârûn, Elyesâ | aynı |
| 7 | Tecvid 8 → ~20 | | aynı |
| 8 | Rüya 55 → ~150 | "(detaylı)" kopyaları birleşir | aynı |
| 9 | Esmaül Hüsna alt padding | önce cihazda yeniden üret | `flutter-fix-layout-issues` → `ecc:flutter-reviewer` |

## Doğruluk Kapısı (3–8)
1. sure:ayet ve Arapça `assets/quran/quran_full.json` ile kodla doğrulanır; meal aynen oradan alınır.
2. Dua/hadis kaynağı belirsizse EKLENMEZ.
3. Rüya: yalnız klasik kaynakta karşılığı olan sembol; doğrulanamaz atıf yok.
4. İmla: ç ğ ı ö ş ü â î û; `test/content_contract_test.dart` ile otomatik.
5. Şüpheli bilgi eklenmez, raporlanır.

## Yayın
Android yerel imzalı AAB → iOS Codemagic `ios-app-store` → `/claude-in-chrome` ile iki konsol. Gönderim öncesi bekleyen inceleme kontrolü + kullanıcı onayı.
