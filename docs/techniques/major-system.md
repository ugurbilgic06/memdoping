# T12 — Major System (Fonetik Sayı Sistemi)

Durum: [RESEARCH REQUIRED tamamlandı — mekanik tasarımı EXPERT REVIEW bekliyor]

## Özet

300 yılı aşkın bir geçmişi olan (Stanislaus Mink von Wennsshein tarafından tanıtılmış, sonra Dr. Richard Grey tarafından geliştirilmiş) bir sistem: her rakam (0-9) sabit bir ünsüz sese atanır (ör. 1=t/d, 2=n, 3=m...); rakam dizileri bu ünsüzlerden oluşan kelimelere dönüştürülür (araya sesli harf eklenerek). Örn. "32" → m+n sesleri → "moon" gibi bir kelime. Böylece uzun sayı dizileri, [[number-system]]'e göre çok daha büyük ölçekte, somut ve imgelenebilir kelimelere çevrilebilir. [[peg-system]] ile birleştiğinde 00-99 arası çift haneli her sayı için sabit bir "kelime askısı" oluşturulabilir.

## Bilimsel Dayanak

1. Number-consonant mnemonic (Major System'in araştırma literatüründeki adı) üzerine bulunan tek doğrudan kontrollü çalışma: "Effectiveness of the Number-Consonant Mnemonic for Retention of Numeric Material in Community-Dwelling Older Adults", *Experimental Aging Research*, 23(3), 1997. PMID: 9248820. DOI: 10.1080/03610739708254284.
   - **Not:** Bu oturumda makalenin yazar isimlerini teyit edemedim (PubMed sayfası çerez uyarısı nedeniyle tam metaveri döndürmedi) — [AWAITING MATERIALS: yazar adları ve tam bibliyografya doğrulanmalı].
   - Bulgu: 36 katılımcı (60 yaş+), 17 kişi eğitim aldı, 19 kişi plasebo eğitimi aldı; 4 adet 6 haneli kombinasyon kilidi ezberletildi. **Hemen sonrasında iki grup arasında fark yok**, ama **3 gün sonra ılımlı, 7 gün sonra ise çok anlamlı bir üstünlük** eğitim alan grupta görüldü — yani sistemin asıl gücü **kalıcılıkta**, anlık performansta değil.

## Kanıt Gücü: **ORTA**

Tek bir kontrollü çalışma bulundu (yaşlı yetişkinlerde) — genç/çocuk popülasyonlarında veya farklı görev türlerinde ayrı bir doğrulama bu oturumda bulunamadı [AWAITING MATERIALS]. Bulunan çalışma olumlu ama örneklem küçük (36 kişi) ve tek bir yaş grubuna özgü. Kuramsal temeli (chunking + fonetik kodlama + imagery) sağlam üç ilkeye dayanıyor ama kendi başına geniş kanıt tabanı ince.

## Telif / Erişim Durumu

Makale Taylor & Francis (Experimental Aging Research) dergisinde, ücretli erişim. Ücretsiz tam metin bulunamadı.

## Oyun Mekaniği Tasarımı — "Ses Kodu"

**Temel döngü:** Oyuncu önce birkaç temel rakam-ses eşlemesini öğrenir (basitleştirilmiş: 1=T sesi, 2=N sesi, 3=M sesi gibi, tam sistemin küçük bir alt kümesi). İki haneli bir sayı geldiğinde ("32"), oyuncu iki sesi ("M" + "N") birleştirip bu seslerle başlayan bir kelime/imge seçer (hazır kartlardan, ör. "Ay" [Moon değil Türkçe'de farklı kurulmalı — bkz. not aşağıda]). Bu kelime bir sahneye yerleştirilir, sonra sayı bu sahne üzerinden geri çağrılır.

**Türkçeleştirme notu:** Major System İngilizce fonetiğe göre tasarlanmıştır; Türkçe için rakam-ünsüz eşlemesinin **yeniden tasarlanması** gerekir (Türkçe ses yapısına uygun, yerli bir sistem) — bu, içerik ekibi için ayrı bir [EXPERT REVIEW] gerektiren bir adım, doğrudan İngilizce sistemin çevirisi yeterli olmayabilir.

**Giriş/çıkış:** Intro'da ipucu: "Her ses bir rakama karşılık gelir — sayıyı değil, kelimeyi hatırla." Dürüst not: "Bu teknik ilk seferde fark yaratmayabilir ama birkaç gün sonra çok daha iyi hatırlamanı sağlayabilir" (araştırmanın "gecikmeli fayda" bulgusunu doğrudan yansıtan, beklenti yöneten bir mesaj).

**Zorluk kademeleri:**
- Seviye 1-2: Tek haneli rakamlar, sadece 3-4 ses-kod öğrenilir.
- Seviye 3-4: İki haneli sayılar (00-99 aralığından basit bir alt küme).
- Seviye 5+: Üç+ haneli sayılar, sesler zincirlenerek uzun sayı dizileri (ileri/yetişkin modu).

**Başarı ölçütü:** Anlık recall + **3 gün sonraki gecikmeli recall** ([[spaced-practice]] mekanizmasıyla entegre) — araştırmanın asıl bulgusu (gecikmeli üstünlük) doğrudan oyun-içi metrik olarak izlenmeli.

**Tahmini süre:** 100-120 saniye/mission (+ ilk ses-kod öğrenimi için tek seferlik ek adım).

## Bağımlılıklar

Önkoşul: [[number-system]] (basitleştirilmiş öncül), [[chunking]], [[association-imagery]]. Doğal sonraki adım: [[peg-system]] ile birleşerek 00-99 sabit kelime askıları, ardından [[pao]]'ya köprü kurar.
