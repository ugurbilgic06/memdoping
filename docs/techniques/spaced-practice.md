# T05 — Spaced Practice (Aralıklı Tekrar)

Durum: [RESEARCH REQUIRED tamamlandı — mekanik tasarımı EXPERT REVIEW bekliyor]

## Özet

Aynı materyali arka arkaya (massed/yığılmış) tekrar etmek yerine, tekrarları zaman içine yayarak (spaced/aralıklı) çalışmak, uzun vadeli hatırlamayı belirgin biçimde artırır. Cepeda ve ark.'nın (2006) 184 makale ve 317 deneyi kapsayan geniş meta-analizi, aralıklı tekrarın kalıcılığı tutarlı biçimde artırdığını; en iyi tekrar aralığının, bilginin ne kadar süre hatırlanması gerektiğine (retention interval) bağlı olarak değiştiğini göstermiştir — yani "ne zaman tekrar etmeli" sorusunun optimal cevabı sabit değildir, hedefe göre ayarlanmalıdır.

## Bilimsel Dayanak

1. Cepeda, N. J., Pashler, H., Vul, E., Wixted, J. T., & Rohrer, D. (2006). Distributed practice in verbal recall tasks: A review and quantitative synthesis. *Psychological Bulletin*, 132(3), 354–380.
2. Cepeda, N. J., Vul, E., Rohrer, D., Wixted, J. T., & Pashler, H. (2008). Spacing Effects in Learning: A Temporal Ridgeline of Optimal Retention. *Psychological Science*, 19(11), 1095–1102.
   - Ücretsiz PDF (yazarın kendi laboratuvar sitesi, UCSD): https://laplab.ucsd.edu/articles/Cepeda%20et%20al%202008_psychsci.pdf
3. Dunlosky, J., Rawson, K. A., Marsh, E. J., Nathan, M. J., & Willingham, D. T. (2013). Improving Students' Learning With Effective Learning Techniques. *Psychological Science in the Public Interest*, 14(1), 4–58. → **"distributed practice" HIGH utility** olarak derecelendirilmiş.

## Kanıt Gücü: **GÜÇLÜ**

Listedeki en sağlam kanıtlı iki teknikten biri ([[retrieval-practice]] ile birlikte). Onlarca yıllık, yüzlerce deneyi kapsayan meta-analizlerle desteklenir; Dunlosky ve ark. tarafından da yaş/materyal bağımsız **"yüksek fayda"** olarak sınıflandırılmıştır.

## Telif / Erişim Durumu

Cepeda 2008 makalesi yazarların kendi laboratuvar sitesinde (UCSD, laplab.ucsd.edu) ücretsiz PDF olarak barındırılıyor. Cepeda 2006 (Psychological Bulletin) dergi telifli, ücretli erişim. Tam metinler oyun içine kopyalanmayacak.

## Oyun Mekaniği Tasarımı — "Doping Zamanlayıcı" (Due Review)

Bu teknik tek bir mission içinde değil, **oyunun genel zamanlama/bildirim mimarisinde** yaşamalı — §6 Retention & Reactivation Engine ile doğrudan kesişiyor.

**Temel döngü:** Bir level tamamlandığında, o levelin öğeleri otomatik olarak bir "tekrar kuyruğuna" (due queue) girer. Sistem, mastery ve geçen süreye göre bir sonraki tekrar zamanını hesaplar (basit kural: ilk tekrar +1 gün, başarılıysa +3 gün, sonra +7 gün — kanıta dayalı "genişleyen aralık" ilkesinin basitleştirilmiş hali). Oyuncu ana ekranda "Bugün tekrar edilecek 3 öğe" gibi bir rozet görür; bu, ayrı bir mini-mission olarak (birkaç eski öğeyi hızlıca test eden) sunulur.

**Giriş/çıkış:** Ana ekranda opsiyonel, sessiz bir rozet — zorlayıcı bildirim değil (§6 "quiet hours, frequency limits" ilkesine uygun). Girişte "Bunları daha önce öğrenmiştin, hâlâ duruyor mu bakalım" gibi nazik bir çerçeveleme.

**Zorluk kademeleri:** Zorluk, aralığın kendisiyle ayarlanır — daha uzun aralıktan gelen tekrar daha zor sayılır (unutma eğrisi daha ilerlemiş). Bu, `SessionResult.difficultyWeight` mantığına yeni bir boyut ekler: "gecikme ağırlığı".

**Başarı ölçütü:** Gecikmeli recall doğruluğu (aynı günün doğruluğuna göre daha anlamlı bir kalıcılık göstergesi — Memory Score'un §2'de bahsedilen "delayed recall" bileşenine doğrudan karşılık gelir).

**Tahmini süre:** Her tekrar turu 30–60 saniye (kısa, sık, düşük sürtünmeli — günlük misyonlara doğal olarak eklenir).

## Psikolojik Uyum

- **Karanlık desen sınırı — bu tekniğin en kritik risk alanı:** Zamanlanmış tekrar mekanikleri (kolayca "her gün gel yoksa kaybedersin" tarzı zorlayıcı bir alışkanlık döngüsüne dönüşebilir). §6'nın açık talimatı: "sessiz rozet, zorlayıcı bildirim değil", "compulsive time spent değil, useful practice and satisfaction optimize edilmeli". Bu yüzden tasarımda **streak cezası yok**, bildirim opt-in ve sessiz saatlere uyumlu, geciken tekrar cezalandırılmıyor sadece ertelenmiş oluyor.
- **Kaygı/stres:** Ana ekrandaki rozetin "Bugün tekrar edilecek 3 öğe" gibi nötr/davetkâr bir dille sunulması (§6 "welcoming return sessions"), suçlayıcı bir dil ("unuttun!", "kaybediyorsun!") kullanmaması önemli — bu, kaygı yaratmadan geri dönüşü teşvik eder.
- **Özyeterlik:** Gecikmeli recall'un ayrı bir "kalıcılık skoru" olarak gösterilmesi, oyuncuya zamanla gerçekten daha iyi hatırladığını somut biçimde gösterir — bu, tekniğin kendisinin işe yaradığına dair kanıt sunarak özyeterliği pekiştirir.
- **İnaktivite sonrası nazik dönüş (§6):** Uzun süre ara veren oyuncu için zorluk otomatik ayarlanmalı ve kazanılmış ilerleme korunmalı — cezalandırıcı bir "sıfırdan başla" deneyimi §6'ya aykırı olur.
- **Etik sınır (§7):** "Vulnerable moments" (ör. oyuncunun art arda başarısız olduğu bir an) bildirim sıklığını artırmak veya satın almaya yönlendirmek için kullanılmamalı — tekrar zamanlaması yalnızca unutma eğrisine dayanmalı, davranışsal zafiyete değil.

## Bağımlılıklar

Önkoşul: [[retrieval-practice]] (tekrar turu retrieval mekaniğini kullanır — sadece zamanlaması farklı). Bu teknik bağımsız bir "level" değil, **tüm ladder'ı kesen bir sistem katmanı** olarak tasarlanmalı; §7 (adaptive difficulty) ve §6 (retention engine) ile doğrudan entegre.
