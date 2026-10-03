package com.kurandakimesaj.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.util.Log
import android.webkit.MimeTypeMap
import com.ryanheise.audioservice.AudioServiceActivity
import java.io.File

// AudioServiceActivity, FlutterActivity'den türer; arka plan ses servisinin
// activity'ye bağlanabilmesi için gerekli. Manifest'teki activity ADI
// değişmedi — deep-link ve paylaşım intent-filter'ları o ada bağlı.
class MainActivity : AudioServiceActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        sanitizeShareIntent(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        sanitizeShareIntent(intent)
        super.onNewIntent(intent)
    }

    /**
     * Paylaşım niyetini Flutter ve eklentiler görmeden ÖNCE düzeltir. İki kök
     * neden, ikisi de Dosyalar (DocumentsUI) uygulamasından paylaşımda ortaya
     * çıkıyor:
     *
     * 1. Niyet veri URI'si taşıyorsa Flutter onu derin bağlantı sanıp rota
     *    olarak açmaya çalışır → "Page Not Found". SEND niyetinde veri URI'sinin
     *    bizim için anlamı yok; içerik EXTRA_STREAM'de.
     * 2. receive_sharing_intent 1.8.1, ExternalStorage "primary" belge URI'sinde
     *    dosyayı KOPYALAMAZ, ham `/storage/emulated/0/...` yolunu döndürür.
     *    Depolama iznimiz olmadığı için eklentinin MediaMetadataRetriever çağrısı
     *    yakalanmayan istisna fırlatır ve activity HİÇ açılamaz (çökme). Dosyayı
     *    URI izniyle kendi önbelleğimize kopyalayıp niyeti o kopyaya çeviriyoruz;
     *    böylece yol hem okunabilir hem de uygulamaya ait (çıkışta silinebilir).
     *
     * Eklenti 1.8.1'e pinli (1.9.0 compileSdk 37 istiyor), o yüzden düzeltme
     * burada. Diğer URI türlerini eklenti zaten önbelleğe kopyalıyor.
     */
    private fun sanitizeShareIntent(intent: Intent?) {
        if (intent?.action != Intent.ACTION_SEND) return
        if (intent.data != null) intent.setDataAndType(null, intent.type)

        @Suppress("DEPRECATION")
        val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM) ?: return
        if (uri.authority != EXTERNAL_STORAGE_DOCS) return
        try {
            // ponytail: ana iş parçacığında kopyalar (eklentinin diğer URI'lerdeki
            // davranışıyla aynı); çok büyük dosyada ANR riski — gerekirse arka plana al.
            val target = File(cacheDir, displayName(uri, intent.type))
            val input = contentResolver.openInputStream(uri)
                ?: throw IllegalStateException("akış açılamadı")
            input.use { src -> target.outputStream().use { src.copyTo(it) } }
            intent.putExtra(Intent.EXTRA_STREAM, Uri.fromFile(target))
        } catch (e: Exception) {
            // Okunamayan dosyayı eklentiye bırakmak activity'yi çökertir; paylaşımı
            // düşürüp uygulamayı normal açıyoruz.
            Log.w(TAG, "Paylaşılan dosya kopyalanamadı: $uri", e)
            intent.action = Intent.ACTION_MAIN
            intent.removeExtra(Intent.EXTRA_STREAM)
        }
    }

    /** Sağlayıcının verdiği ad güvenilmez: dizin parçaları atılır (yol kaçışı). */
    private fun displayName(uri: Uri, mimeType: String?): String {
        val name = contentResolver
            .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { c -> if (c.moveToFirst()) c.getString(0) else null }
        name?.let { File(it).name }?.takeIf { it.isNotBlank() }?.let { return it }
        val ext = MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType)
        return "paylasim_${System.currentTimeMillis()}" + (ext?.let { ".$it" } ?: "")
    }

    private companion object {
        const val TAG = "MainActivity"
        const val EXTERNAL_STORAGE_DOCS = "com.android.externalstorage.documents"
    }
}
