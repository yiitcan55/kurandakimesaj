/// (sıra, başlık, kural, örnek, gövde) — tecvid dersleri.
const List<(int, String, String, String, String)> kTajweedSeed = [
  (1, 'Med (Uzatma)', 'Med harfleri (ا و ي) bir harekeyi uzatır.', 'قَالَ — نُوحِيهَا',
      'Med, bir sesin belirli ölçüde uzatılmasıdır. Tabii med bir elif miktarı (iki hareke) uzatılır. Med sebebi (hemze veya sükûn) geldiğinde uzatma daha da artar.'),
  (2, 'İhfâ', 'Tenvin veya sâkin nûn, ihfâ harflerinden birine geldiğinde gizlenir.', 'مِنْ قَبْلِ — أَنْدَادًا',
      'İhfâ, izhar ile idgam arasında, genizden (gunne ile) gizli bir okuyuştur. 15 ihfâ harfinden biri sâkin nûn veya tenvinden sonra gelirse uygulanır.'),
  (3, 'İdgâm', 'Sâkin nûn/tenvin, idgam harflerine (ي ر م ل و ن) kaynaştırılır.', 'مَنْ يَقُولُ — مِنْ رَبِّهِمْ',
      'İdgam, bir harfin kendinden sonraki harfe katılmasıdır. "Yermelûn" harflerinde gunneli veya gunnesiz idgam yapılır.'),
  (4, 'İklâb', 'Sâkin nûn/tenvin, "ب" harfine geldiğinde "م" sesine döner.', 'مِنْ بَعْدِ — سَمِيعٌ بَصِيرٌ',
      'İklâb, çevirme demektir. Sâkin nûn veya tenvinden sonra "ب" gelirse, nûn sesi gunne ile "mim" sesine çevrilerek okunur.'),
  (5, 'İzhâr', 'Sâkin nûn/tenvin, boğaz harflerine geldiğinde açıkça okunur.', 'مِنْ هَادٍ — عَلِيمٌ حَكِيمٌ',
      'İzhâr, açığa çıkarma demektir. Boğaz harfleri (ء ه ع ح غ خ) sâkin nûn veya tenvinden sonra gelirse, nûn sesi gizlenmeden net okunur.'),
  (6, 'Kalkale', 'Kalkale harfleri (ق ط ب ج د) sâkin olunca yankılanır.', 'قُلْ — أَحَدْ',
      'Kalkale, sâkin olan kalkale harfinin bir titreşim/yankı ile okunmasıdır. Özellikle durakta (vakıf) bu yankı daha belirgin olur.'),
  (7, 'Gunne', 'Nûn ve mîm şeddeli olduğunda genizden ses verilir.', 'إِنَّ — ثُمَّ',
      'Gunne, sesin geniz boşluğundan getirilmesidir. Şeddeli nûn (نّ) ve şeddeli mîm (مّ) iki hareke miktarı gunne ile okunur.'),
  (8, 'Vakıf (Durak)', 'Ayet sonlarında ve durak işaretlerinde nefes alınır.', 'الرَّحِيمِ ۚ — مَالِكِ',
      'Vakıf, okuyuşa ara vermektir. Mushaftaki durak işaretleri (ۖ ۗ ۚ ۛ) nerede durmanın uygun, gerekli veya yasak olduğunu gösterir. Doğru vakıf anlamı korur.'),
];
