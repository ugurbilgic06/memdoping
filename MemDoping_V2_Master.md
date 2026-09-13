# MemDoping V2 — Master Upgrade Specification

> **Durum:** V2 Revizyonu  
> **Ana ilke:** Mevcut çalışan MemDoping projesini sıfırdan yazma. Çalışan altyapıyı koru; kontrollü ve modüler biçimde yükselt.

---

## 1. V2 Ürün Kimliği

MemDoping V2 bir **eğitim uygulaması gibi görünen oyun değil**, öğrenme ve hafıza tekniklerini oynanışın içine gömen **premium bir hafıza oyunu** olacaktır.

Öncelik sırası:

1. Oyun hissi
2. Etkileşim ve animasyon
3. Görsel kalite
4. Hafıza/öğrenme mekaniği
5. Açıklama metni

Uzun ders ekranları ve yoğun yazılı anlatımlar kullanılmamalıdır.

---

## 2. Mevcut Projeyi Koruma Kuralı

- Projeyi sıfırdan yazma.
- Çalışan sistemleri gereksiz yere değiştirme.
- Mevcut kullanıcı verisi, ilerleme, skor, ödül ve temel navigasyon altyapısını mümkün olduğunca koru.
- Büyük mimari değişikliklerden önce mevcut yapıyı analiz et.
- Yeni V2 özelliklerini modüler ekle.
- İlk aşamada 100 levelın tamamını yeniden üretme.
- Önce prototip kalite kapısından geç.

---

## 3. İlk Açılış — Yaş Yolu Seçimi

Kullanıcı oyuna başlamadan önce bir deneyim yolu seçer:

### CHILD
Çocuk deneyimi.

- Çizgi/oyun karakterleri
- Daha canlı renkler
- Daha belirgin hareket ve görsel geri bildirim
- Basit ve hızlı sesli yönlendirme
- Oyunlaştırılmış dünyalar
- Minimum metin

### TEEN
Ergen/genç deneyimi.

- Çocukça olmayan modern oyun estetiği
- Daha hızlı tempo
- Challenge hissi
- Combo, streak, skor ve başarı geri bildirimi
- Daha dinamik animasyon

### ADULT
Yetişkin deneyimi.

- Premium ve daha sofistike görsel dil
- Gerektiğinde gerçekçi/dijital insan sunucu
- Daha temiz UI
- Daha stratejik görevler
- Daha az fakat kaliteli efekt

Bu üç yol **aynı oyunun yalnızca renk değiştirilmiş versiyonları olmayacaktır**.

Ortak öğrenme çekirdeğini paylaşabilirler; fakat sunum, tempo, görsel dünya, karakter, ses ve görev tasarımı yaş grubuna göre değişmelidir.

---

## 4. Level Yapısı

Mevcut sistemdeki “100 level arka arkaya aynı akış” hissi kaldırılmalıdır.

Her level temel olarak şu döngüyü kullanmalıdır:

**HOOK → MICRO TUTORIAL → PLAY → CHALLENGE → RECALL → REWARD**

### Hook
Oyuncunun dikkatini hemen yakala.

### Micro Tutorial
Uzun yazılı açıklama yerine yaklaşık **3–5 saniyelik görsel + sesli anlatım**.

### Play
Kullanıcı tekniği okuyarak değil, yaparak öğrenir.

### Challenge
Tempo veya bilişsel yük kontrollü biçimde yükselir.

### Recall
Oyuncudan aktif geri çağırma istenir.

### Reward
Başarı; hareket, ses, görsel efekt, skor, streak veya oyun ekonomisiyle hissedilir.

---

## 5. PACER Tabanlı Öğrenme/Oyun Motoru

PACER materyali V2 tasarımında temel referanslardan biri olarak kullanılacaktır.

**Önemli:** PACER yöntemi kullanıcıya uzun teorik ders olarak anlatılmayacaktır.

İlkeler mümkün olduğunca **oyun davranışlarına dönüştürülecektir.**

Örneğin:

- bilgiyi pasif okumak yerine aktif işlemek,
- ilişkiler kurmak,
- karşılaştırmak,
- yapısal bağlantıları görmek,
- görsel/uzamsal temsil kullanmak,
- aktif geri çağırmak,
- farklı bağlamlarda tekrar kullanmak.

Her level tasarımında şu soru sorulmalıdır:

> “Oyuncu burada hangi hafıza/öğrenme davranışını gerçekten yapıyor?”

Sadece ekrana dokunmak PACER entegrasyonu sayılmaz.

PACER PDF/referans materyali geliştirme sırasında ayrıca kaynak dosya olarak verildiğinde, mekanikler doğrudan kaynakla doğrulanmalıdır. Kaynakta olmayan bir PACER kuralı uydurulmamalıdır.

---

## 6. Mikro Anlatım Sistemi

Uzun başlangıç açıklamalarını kaldır.

Yeni mekanik tanıtımlarında öncelik:

- 3–5 saniyelik animasyon
- kısa ses
- hareketle gösterim
- karakter demonstrasyonu
- gerekirse tek cümlelik altyazı

### Child
Animasyon/çizgi karakter anlatabilir.

### Teen
Dinamik avatar, motion graphic veya oyun karakteri kullanılabilir.

### Adult
Gerçekçi dijital sunucu, premium motion design veya doğrudan görsel demonstrasyon kullanılabilir.

Amaç:

**“Oku ve sonra oyna” yerine “gör → duy → hemen yap.”**

---

## 7. Görsel ve Animasyon Kalite Hedefi

V2'nin en büyük değişikliklerinden biri görsel kalite olacaktır.

Mevcut sürümdeki eğitim uygulaması hissi azaltılmalıdır.

İstenen:

- daha fazla hareket
- daha zengin görsel feedback
- daha güçlü level girişleri
- başarılı hareketlerde tatmin edici reaksiyonlar
- geçiş animasyonları
- karakter reaksiyonları
- çevresel hareket
- combo/streak geri bildirimi
- ödül animasyonları
- gerektiğinde kamera hareketi
- derinlik ve 3D öğeler
- yaş grubuna uygun renk dünyaları

Animasyon yalnızca dekor değildir; mümkün olduğunda hafızayı, yönlendirmeyi veya ödül hissini desteklemelidir.

---

## 8. Higgsfield Üretim Hattı

Higgsfield yalnızca tutorial videosu üretmek için kullanılmamalıdır.

Uygun olduğu yerlerde şunların üretiminde kullanılabilir:

- kısa sinematikler
- karakter sahneleri
- mikro tutoriallar
- level girişleri
- başarı/ödül sahneleri
- ortam konseptleri
- görsel referanslar
- oyun asset üretimine temel olacak materyaller
- yaş gruplarına özel görsel dünyalar

Ancak gerçek zamanlı gameplay mümkün olduğunca uygulamanın kendi oyun/render yapısında kalmalıdır.

Higgsfield çıktısı performansı bozacak şekilde her etkileşimde uzaktan üretilen video bağımlılığına dönüşmemelidir.

---

## 9. Blender + 3D Kullanımı

Blender V2 üretim hattına dahil edilebilir.

Kullanım alanları:

- 3D oyun objeleri
- hafıza sarayı benzeri uzamsal alanlar
- karakterler
- çevresel sahneler
- kısa animasyonlar
- ödül objeleri
- interaktif hafıza nesneleri
- seçili level dünyaları

**Her şeyi 3D yapma.**

3D yalnızca şu durumlarda kullanılmalı:

1. oynanışı geliştiriyorsa,
2. hafıza tekniğini güçlendiriyorsa,
3. premium oyun hissini belirgin artırıyorsa.

Mobil performans, dosya büyüklüğü, FPS, pil tüketimi ve yükleme süresi önceliklidir.

---

## 10. Higgsfield + Blender + Uygulama Sorumlulukları

### Higgsfield
Görsel üretim, kısa video/sahne, konsept, karakter ve sinematik materyal.

### Blender
Optimize 3D asset, animasyon ve gerekli sahne üretimi.

### Uygulama Kodu
Gerçek zamanlı gameplay, state, skor, kullanıcı ilerlemesi, etkileşim, level mantığı ve performans.

Harici üretim araçları uygulamanın temel çalışma mantığını kırmamalıdır.

---

## 11. İlk Üretim: 9 Premium Prototip

Şimdilik 100 levelı yeniden üretme.

Önce yalnızca:

- **3 Child**
- **3 Teen**
- **3 Adult**

olmak üzere toplam **9 premium prototip level** üret.

Her prototipte mümkün olduğunca farklı:

- temel oyun mekaniği,
- hafıza davranışı,
- görsel yaklaşım,
- animasyon yaklaşımı,
- tempo,
- ödül hissi

test edilmelidir.

---

## 12. Prototip Level Şablonu

Her prototip için aşağıdakileri tanımla:

**Age Path:**  
Child / Teen / Adult

**Memory Objective:**  
Oyuncunun geliştirmeye çalıştığı hafıza/öğrenme davranışı.

**PACER/learning principle:**  
Kaynak materyalle doğrulanmış ilgili ilke.

**Core Gameplay:**  
Oyuncunun yaptığı temel eylem.

**3–5 sec Tutorial:**  
Görsel + sesli mikro anlatım.

**Visual World:**  
Levelın sanat ve ortam yaklaşımı.

**Animation:**  
Gameplay'i destekleyen hareketler.

**Higgsfield Role:**  
Varsa hangi asset/sahne üretilecek.

**Blender Role:**  
Varsa hangi 3D asset/animasyon kullanılacak.

**Reward:**  
Level sonunda oyuncunun başarıyı nasıl hissedeceği.

**Performance Budget:**  
Mobil performans açısından gerekli sınırlar.

---

## 13. Kalite Kapısı

9 prototip tamamlandığında otomatik olarak 100 level üretimine geçme.

Önce değerlendirme yap:

- Gerçekten oyun gibi mi?
- Eğlenceli mi?
- Tekrar oynama isteği yaratıyor mu?
- Üç yaş yolu gerçekten farklı mı?
- PACER/öğrenme ilkesi oynanışa gömülü mü?
- Tutorial yeterince kısa mı?
- Animasyon oynanışı güçlendiriyor mu?
- Mobil performans iyi mi?
- Görsel kalite premium seviyeye yaklaştı mı?

Bu aşama onaylanmadan ölçekleme yapılmaz.

---

## 14. İlk Teknik Görev — PROJECT AUDIT

Herhangi bir büyük V2 kod değişikliğinden önce:

1. Mevcut projeyi analiz et.
2. Kod değiştirme.
3. Çalışan mimariyi haritala.
4. Korunacak sistemleri belirle.
5. Değiştirilecek alanları belirle.
6. Yeni modüllerin nereye ekleneceğini belirle.
7. Age Path entegrasyon noktasını belirle.
8. PACER/gameplay motorunun entegrasyon noktasını belirle.
9. Higgsfield asset hattını belirle.
10. Blender/3D asset hattını belirle.
11. Riskleri Critical / High / Medium / Low olarak sınıflandır.
12. En düşük riskli uygulama sırasını öner.

Sonra **DUR.**

Onay alınmadan büyük refactor veya 100-level üretimi başlatma.

---

## 15. Değişmez V2 Kuralları

- **DO NOT rewrite from scratch.**
- **DO NOT destroy working systems.**
- **GAME FIRST.**
- **NO long tutorial walls.**
- **SHOW, SPEAK, PLAY.**
- **Child / Teen / Adult are distinct experiences.**
- **PACER principles must become gameplay, not textbook pages.**
- **Use Higgsfield beyond tutorial videos where it adds value.**
- **Use Blender/3D selectively and purposefully.**
- **Prototype 9 levels first.**
- **Do not scale before quality approval.**
- **Mobile performance is non-negotiable.**

---

# Execution Order

1. Project Audit
2. Age Architecture
3. PACER-to-Gameplay Mapping
4. Visual / Animation System
5. Higgsfield Asset Pipeline
6. Blender / 3D Pipeline
7. Design 9 Prototype Levels
8. Implement Prototype Framework
9. Build 9 Prototypes
10. Quality Review
11. Only after approval: design the 100+ level expansion

---

**END — MemDoping V2 Master Upgrade Specification**
