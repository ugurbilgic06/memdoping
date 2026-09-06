# T06 — Interleaving (İç İçe Geçmiş / Karışık Pratik)

Durum: [RESEARCH REQUIRED tamamlandı — mekanik tasarımı EXPERT REVIEW bekliyor]

## Özet

Aynı türden problemleri/öğeleri art arda (bloklar halinde) çalışmak yerine, farklı türleri karıştırarak (iç içe geçirerek) çalışmak, kısa vadede daha zor ve yavaş hissettirse de uzun vadeli hatırlamayı ve **doğru yöntemi doğru duruma uygulama becerisini** güçlendirir. Taylor & Rohrer'in (2010) çalışmasında çocuklar dört tür matematik problemini bloklu ya da karışık sırayla çalıştı: karışık pratik, bir gün sonraki testte doğruluğu **ikiye katladı** — hata analizleri, kazancın "her problemi doğru yöntemle eşleştirme" becerisinden geldiğini gösterdi (bloklu çalışanlar hangi yöntemi kullanacaklarını unutuyor, sadece o anki tek yöntemi tekrarlıyorlardı).

## Bilimsel Dayanak

1. Taylor, K., & Rohrer, D. (2010). The effects of interleaved practice. *Applied Cognitive Psychology*, 24(6), 837–848.
2. Rohrer, D., Dedrick, R. F., & Stershic, S. (2015). Interleaved practice improves mathematics learning. *Journal of Educational Psychology*, 107(3), 900–908.
   - Ücretsiz PDF (ERIC — ABD Eğitim Bakanlığı kamu arşivi): https://files.eric.ed.gov/fulltext/ED557355.pdf
3. Dunlosky, J., Rawson, K. A., Marsh, E. J., Nathan, M. J., & Willingham, D. T. (2013). Improving Students' Learning With Effective Learning Techniques. *Psychological Science in the Public Interest*, 14(1), 4–58. → **"interleaved practice" MODERATE (orta) utility** olarak derecelendirilmiş (2013'te göreceli az sayıda çalışma olduğu için ihtiyatlı).

## Kanıt Gücü: **ORTA-GÜÇLÜ (büyüyen kanıt tabanı)**

Dunlosky ve ark. (2013) 2013 itibarıyla "orta" derecelendirmiş, ama Rohrer'in sonraki çalışmaları (2015 dahil) matematik eğitiminde özellikle güçlü ve tutarlı sonuçlar üretmeye devam etmiş. Dürüst çerçeveleme: kanıt tabanı retrieval/spaced kadar eski ve geniş değil, ama büyüyor ve özellikle "yöntem seçme/ayırt etme" gerektiren görevlerde (matematik, kategori ayırt etme) güçlü.

## Telif / Erişim Durumu

Rohrer, Dedrick & Stershic (2015) makalesi ERIC'te (ABD Eğitim Bakanlığı'nın kamuya açık, ücretsiz akademik arşivi) tam metin olarak mevcut — ERIC kamu erişimine açık bir federal kaynak, bu nedenle rights_status netliği yüksek. Taylor & Rohrer (2010), Wiley dergisinde, ücretli erişim.

## Oyun Mekaniği Tasarımı — "Karışık Meydan"

Mevcut prototipteki Level 5 zaten "Interleaving" etiketini taşıyor ama mekanik olarak diğer levellerden farksız (aynı quiz). Gerçek etkiyi yakalamak için görevin kendisi **birden fazla tema/tip arasında geçiş yapmayı zorunlu kılmalı**.

**Temel döngü:** Tek bir mission içinde 2-3 farklı tema (ör. hayvanlar + yiyecek + uzay) karıştırılarak sorulur — art arda aynı temadan iki soru gelmez. Oyuncu her soruda önce "hangi tema/kategori" olduğunu tanımalı, sonra doğru cevabı seçmeli (iki aşamalı: ayırt etme + hatırlama).

**Giriş/çıkış:** Intro'da uyarı: "Bu tur karışık — ilk başta zor gelebilir, bu normal ve iyi bir işaret." (Kısa vadeli performans düşüşünün beklenen ve faydalı olduğunu baştan çerçevelemek, oyuncunun hayal kırıklığını önler — §2 "feedback... without shame" ilkesi.)

**Zorluk kademeleri:**
- Seviye 1-2: 2 tema karışık, temalar görsel olarak renk-kodlu (ayırt etmeyi kolaylaştırıcı ipucu).
- Seviye 3-4: 3 tema karışık, renk ipucu kaldırılır.
- Seviye 5+: Temalar + zorluk seviyeleri karışık (kolay ve zor sorular da iç içe) — tam "gerçek sınav" simülasyonu.

**Başarı ölçütü:** Ham doğruluk + "yöntem/kategori seçim hatası" ayrı izlenir (yanlış temaya ait cevap seçme oranı düşmeli, bu Taylor & Rohrer'deki asıl bulgunun oyun-içi karşılığı).

**Tahmini süre:** 100–130 saniye/mission (tema geçişleri ek bilişsel yük getirir, biraz daha uzun sürebilir).

## Bağımlılıklar

Önkoşul: en az 2 farklı tema/teknik için [[retrieval-practice]] tarzı bir temel mekaniğin oyuncu tarafından zaten öğrenilmiş olması gerekir (aksi halde karıştırma anlamsızlaşır). Master dokümanın §3 "Aşama 4: Combine approved techniques across varied contexts" tanımına doğrudan karşılık gelir.
