const headers = {
  "content-type": "text/html; charset=utf-8",
  "cache-control": "public, max-age=3600",
  "x-content-type-options": "nosniff",
};

const shell = (title: string, body: string) => `<!doctype html>
<html lang="tr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${title} — Kur'an'da ki Mesaj</title><style>
body{margin:0;background:#08201a;color:#f3eadb;font:16px/1.65 system-ui,sans-serif}main{max-width:760px;margin:auto;padding:48px 22px}h1,h2{color:#e8cb6f}a{color:#e8cb6f}section{background:#0d2a20;border:1px solid #d4b25b55;border-radius:18px;padding:20px;margin:18px 0}li{margin:6px 0}.muted{color:#c8c1b2}</style></head>
<body><main><h1>${title}</h1>${body}<p class="muted">Son güncelleme: 21 Temmuz 2026</p></main></body></html>`;

const privacy = shell("Gizlilik Politikası", `
<p>Kur'an'da ki Mesaj bağımsız geliştiricisi, yalnızca uygulama işlevleri için gerekli verileri işler. İletişim: <a href="mailto:yiit55400@gmail.com">yiit55400@gmail.com</a>.</p>
<section><h2>İşlenen veriler</h2><ul>
<li>İsteğe bağlı hesap için e-posta ve kullanıcı kimliği; kimlik doğrulama Supabase tarafından sağlanır.</li>
<li>Namaz vakti, kıble ve cami bulma için konum cihazda işlenir; sunucuda saklanmaz.</li>
<li>Toplulukta paylaşmayı seçtiğiniz fotoğraf, video, metin, yorum ve koleksiyon verileri hesabınızla ilişkilendirilebilir.</li>
<li>Ayet Bulucu'da seçtiğiniz görsel Google Gemini ile, kısa tilavet videosu Groq Whisper ile işlenir. Video geçici özel Supabase Storage alanına yüklenir ve işlem sonunda silinmeye çalışılır. Uygulama mikrofon erişimi istemez.</li>
<li>Zikir, okuma hedefi ve benzeri kişisel ilerleme verileri öncelikle cihazda saklanır; oturum açıldığında desteklenen veriler senkronize edilebilir.</li>
</ul></section>
<section><h2>Amaç ve paylaşım</h2><p>Veriler uygulama işlevlerini, hesap senkronizasyonunu ve kullanıcı tarafından istenen AI eşleştirmesini sağlamak için kullanılır. Veriler satılmaz; reklam veya takip amacıyla kullanılmaz. Hizmet sağlayıcılar: Supabase, Google Gemini, Groq ve Apple.</p></section>
<section><h2>Saklama ve güvenlik</h2><p>Aktarım HTTPS/TLS ile korunur ve Supabase tablolarında satır düzeyi erişim kuralları uygulanır. Hesap ve bulut içeriği hesap aktifken; yerel veriler uygulama silinene kadar saklanır.</p></section>
<section><h2>Haklarınız ve silme</h2><p>KVKK kapsamındaki erişim, düzeltme ve silme taleplerinizi e-posta ile iletebilirsiniz. Hesabınızı uygulamada <strong>Ayarlar → Hesabı sil</strong> yoluyla silebilirsiniz.</p></section>
<section><h2>Topluluk</h2><p>Kullanıcı içerikleri bildirilebilir ve kullanıcılar engellenebilir. Uygunsuz içerikler incelenerek kaldırılabilir. Rüya ve zekât araçları bilgilendirme amaçlıdır.</p></section>
`);

const support = shell("Destek", `
<p>Kur'an'da ki Mesaj ile ilgili yardım, gizlilik veya hesap silme talepleri için bize ulaşın.</p>
<section><h2>İletişim</h2><p><a href="mailto:yiit55400@gmail.com">yiit55400@gmail.com</a></p><p>Yanıt hedefi: 2 iş günü.</p></section>
<section><h2>Hesap silme</h2><p>Uygulamada <strong>Ayarlar → Hesabı sil</strong> adımlarını izleyin. Uygulamaya erişemiyorsanız hesap e-postanızdan bize yazın.</p></section>
<section><h2>İçerik bildirimi</h2><p>Gönderi veya yorum menüsündeki <strong>Bildir</strong> seçeneğini kullanın. Acil durumlarda bağlantı veya ekran görüntüsüyle e-posta gönderin.</p></section>
<p><a href="./privacy">Gizlilik Politikasını görüntüle</a></p>
`);

Deno.serve((request) => {
  const path = new URL(request.url).pathname.replace(/\/$/, "");
  const page = path.endsWith("/privacy") ? privacy : path.endsWith("/support") ? support : null;
  return page
    ? new Response(page, { headers })
    : new Response("Not found", { status: 404, headers: { "content-type": "text/plain; charset=utf-8" } });
});
