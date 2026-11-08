-- Groq (ayah-finder-audio) kaldırıldı (2026-11-08): videonun sesi artık CİHAZDA
-- tanınıyor (Android VideoSpeechChannel.kt, iOS AppDelegate.swift), video hiçbir
-- yere yüklenmiyor. Geçici yükleme kovası `ayah-audio`nun politikaları düşürülür;
-- politikasız kova RLS default-deny ile tamamen erişilemez olur.
--
-- Kova SQL ile SİLİNMEZ: Supabase depolama tablolarından doğrudan silmeyi
-- engelliyor ("use the Storage API"). Boş kova Storage API ile ayrıca silinir.
drop policy if exists "ayah_audio_write_own" on storage.objects;
drop policy if exists "ayah_audio_read_own" on storage.objects;
drop policy if exists "ayah_audio_delete_own" on storage.objects;
