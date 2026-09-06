# T04 — Retrieval Practice (Aktif Hatırlama / Test Etkisi)

Durum: [RESEARCH REQUIRED tamamlandı — mekanik tasarımı EXPERT REVIEW bekliyor]

## Özet

Bir bilgiyi tekrar okumak yerine belleğinizden **aktif olarak çekip çıkarmaya çalışmak** (kendinizi test etmek), o bilgiyi tekrar okumaktan çok daha kalıcı hale getirir. Buna **test etkisi (testing effect)** denir. Roediger & Karpicke'nin (2006) klasik çalışmaları, tekrar test edilen materyalin — hiç ek çalışma yapılmasa bile — sadece tekrar okunan materyalden haftalar/aylar sonra çok daha iyi hatırlandığını göstermiştir. Etkinin en dikkat çekici yanı: test etme sırasında (ilk seferde) performans daha kötü hissettirebilir, ama uzun vadeli kalıcılık çok daha yüksektir.

## Bilimsel Dayanak

1. Roediger, H. L., & Karpicke, J. D. (2006). The Power of Testing Memory: Basic Research and Implications for Educational Practice. *Perspectives on Psychological Science*, 1(3), 181–210.
   - Ücretsiz PDF (yazarın kendi laboratuvar sitesi, Washington University): http://psychnet.wustl.edu/memory/wp-content/uploads/2018/04/Roediger-Karpicke-2006_PPS.pdf
2. Roediger, H. L., & Karpicke, J. D. (2006). Test-Enhanced Learning: Taking Memory Tests Improves Long-Term Retention. *Psychological Science*, 17(3), 249–255.
   - Özet/PubMed: https://pubmed.ncbi.nlm.nih.gov/16507066/
3. Dunlosky, J., Rawson, K. A., Marsh, E. J., Nathan, M. J., & Willingham, D. T. (2013). Improving Students' Learning With Effective Learning Techniques. *Psychological Science in the Public Interest*, 14(1), 4–58. → **"practice testing" HIGH utility** olarak derecelendirilmiş.

## Kanıt Gücü: **GÜÇLÜ**

Bilişsel psikolojide en sağlam, en çok replike edilmiş ve eğitim ortamlarına en doğrudan aktarılabilir bulgulardan biri. Dunlosky ve ark. (2013) tarafından yaş grubu ve materyal türünden bağımsız olarak **"yüksek fayda"** kategorisine konmuş — bu listedeki en güçlü kanıtlı iki teknikten biri (diğeri: [[spaced-practice]]).

## Telif / Erişim Durumu

Roediger & Karpicke (2006) makalesi yazarın kendi laboratuvar web sitesinde (psychnet.wustl.edu) ücretsiz PDF olarak barındırılıyor — akademik kişisel/kurum sitesi olduğu için erişim serbest, ancak tam metin oyun içine kopyalanmayacak. Dunlosky makalesi SAGE dergisinde, sadece özet ücretsiz.

## Oyun Mekaniği Tasarımı — "Şimdi Sen Söyle"

Bu teknik zaten mevcut prototipteki temel mekanizmayla (öğren → sonra sor) örtüşüyor, ancak asıl fark şurada: **mevcut recall fazı çoktan seçmeli** — tanıma (recognition) gerektiriyor, gerçek "çekip çıkarma" (recall) değil. Test etkisinin en güçlü hali serbest hatırlamadır.

**Temel döngü:** Öğrenme fazından sonra oyuncuya sembol gösterilir, ama seçenek verilmez — oyuncu kelimeyi **klavye/harf çarkı ile kendisi yazar/kurar** (ör. karışık harflerden doğru kelimeyi dizme). Yanlışsa ipucu (ilk harf) verilir, yine de kendi çabasıyla tamamlaması istenir.

**Giriş/çıkış:** Intro'da ipucu: "Cevabı görmeden önce kendin hatırlamaya çalış — zor gelse bile, bu seni güçlendiriyor." Feedback ekranında test etkisini açıklayan kısa not: "Kendi kendine test etmek, tekrar okumaktan daha güçlü çalışır."

**Zorluk kademeleri:**
- Seviye 1-2: Harfleri karışık halde sürükleyerek dizme (yarı-rehberli recall).
- Seviye 3-4: Sadece ilk harf verilir, gerisini oyuncu yazar.
- Seviye 5+: Hiç ipucu yok, tamamen serbest recall; gecikmeli tekrar test (mission bitiminde "hatırlıyor musun?" bonus turu).

**Başarı ölçütü:** Serbest recall doğruluğu (harf/kelime tam eşleşme), ilk denemede mi yoksa ipucuyla mı doğru bulunduğu ayrı izlenir (zorluk ağırlıklı puanlama zaten `GameStore`'daki `difficultyWeight` mantığına uyar).

**Tahmini süre:** 90–120 saniye/mission (yazma/dizme adımı çoktan seçmeliden daha uzun sürer).

## Psikolojik Uyum

- **Kaygı/utanç karşıtı tasarım — bu tekniğin en kritik riski burada:** Serbest recall, çoktan seçmeliden doğası gereği daha zor ve daha fazla anlık başarısızlık hissi yaratır (Roediger & Karpicke'nin bulgusu tam olarak bunu söylüyor: zor hissettirir ama işe yarar). İpucu sisteminin (ilk harf) cezasız olması ve "zor gelse bile bu seni güçlendiriyor" çerçevelemesi, §2'nin "retry without shame" ilkesini burada özellikle önemli kılıyor — aksi halde bu mekanik oyuncuyu yıldırabilir.
- **Özyeterlik:** İlk denemede mi yoksa ipucuyla mı doğru bulunduğunun ayrı izlenmesi, oyuncunun "tamamen kendi başıma yaptım" başarısını görmesini sağlar — bu, ipucu kullanılan başarıdan psikolojik olarak daha güçlü bir özyeterlik kaynağıdır.
- **Bilişsel yük yönetimi:** Kademeli ipucu azaltma (harf dizme → ilk harf → serbest) klasik scaffolding'dir; oyuncu asla "boş sayfa" ile aniden karşılaşmaz.
- **Motivasyon:** Zorluk ağırlıklı puanlama (`difficultyWeight`), oyuncunun daha zor/serbest recall'u tercih etmesi için içsel bir teşvik yaratır — bu, dışsal bir "ödül" değil, çabanın kendi içinde değerli olduğunu gösteren şeffaf bir kural (§7).
- **Etik sınır:** Yanlış cevap sonrası verilen ipucu bir "satın al" teklifiyle birleştirilmiyor — §5'in "pay-to-win" ve "paid score inflation" yasağına uygun: yardım her zaman ücretsiz ve oyun-içi kural gereği.

## Bağımlılıklar

Önkoşul: [[attention-encoding]] (öncesinde bir şeyin öğrenilmiş/kodlanmış olması gerekir). Bu teknik ladder'da **erken ve sık tekrar eden bir çekirdek mekanik** olmalı — master dokümanın "Aşama 2-3" (§3) tanımına denk düşer. [[spaced-practice]] ile birlikte kullanıldığında (gecikmeli retrieval) etkisi katlanır.
