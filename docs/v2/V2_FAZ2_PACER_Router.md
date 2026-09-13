# V2 — Faz 2: PACER Router

> **Hedef cümle:** Oyuncu tekniği değil, **hangi teknik ne zaman** onu öğrensin.
> **Kapsam:** Mevcut 12 mekanik yine değişmez. Üstlerine bir karar katmanı gelir.
> **Ön koşul:** Faz 1.1 (ortak akış iskeleti). Router bir faz olarak akışa girecek.
> **Karar kaydı:** 12 Eylül — PACER'ın rolü "beşinci bir teknik" değil, **yönlendirici** olarak belirlendi.

---

## Neden bu faz var

PACER'ın kendi ilk cümlesi: *"Her bilgi aynı tür değildir."* Kaynakların üçü de çerçeveyi beş teknik listesi olarak değil, **bir sınıflandırma refleksi** olarak tanımlıyor: bilgiyle karşılaşınca önce türünü belirle, sonra o türe uygun işlemi yap.

Uygulamada bugün bu adım **hiç yok.** Elimizde beş tür için mekanikler var ama "bu hangi tür?" sorusunu soran tek bir ekran bile yok. O soru olmadan elde kalan şey PACER değil — birbirinden bağımsız on iki hafıza oyunu.

Bir de teşhis tablosu var, denetimde çıkmıştı:

| PACER | İşlem | Yürüten mekanikler |
|---|---|---|
| P | Practice | `procedure`, kısmen `retrieval` |
| A | Critique | `analogy` |
| C | Mapping | `conceptMap`, kısmen `elaboration` |
| **E** | **Sakla + iddiaya bağla** | **boş** |
| R | Sakla + aralıklı tekrar | `loci`, `story`, `chunking`, `numberShape`, `pairRecall`, `retrieval`, `review` |

Orijinal dokuz tekniğin neredeyse tamamı R kutusunda. Bu bir kusur değil — mnemonikler zaten referans bilgisi araçlarıdır. Ama uygulamanın neden "hafıza antrenmanı" gibi hissettirdiğini açıklıyor.

---

## 2.1 — `KnowledgeType` — yönlendirme katmanı

**Yapılacak:**

```
Game/KnowledgeType.swift

enum KnowledgeType { case procedural, analogous, conceptual, evidence, reference }
```

Her tür şunları taşır: soru cümlesi ("Nasıl yapılır?"), işlem adı ("Uygula"), ve o işlemi yürütebilen `LevelMechanic` listesi.

Bu, `HomeView.swift:41`'deki mevcut `switch l.mechanic` yapısının **üstüne** oturur. Mevcut switch kalır; router ona hangi mekaniğin açılacağını söyleyen katman olur.

**Kabul ölçütü:** Her `LevelMechanic`, en az bir `KnowledgeType` ile eşleşiyor. Eşleşmesi olmayan mekanik derleme zamanında yakalanıyor (switch'i `default`'suz yazın).

---

## 2.2 — Sınıflandırma mekaniği — PACER'ın omurgası

**En kritik yeni iş bu.** Ve tasarımı yanlış yapmak kolay.

**Yapılmayacak olan:** Her levelin önüne beş şıklı bir test ekranı koymak. Bu, Faz 1'de kurduğumuz her şeyi bozar — oyuncu oyuna girmeden önce sınav olur, sıkılır.

**Yapılacak olan:** Sınıflandırma **oyunun kendisi** olsun.

### Mekanik: "Ayır" (`.triage`)

- Ekrana bir bilgi parçası düşer. Bir cümle, bir adım listesi, bir benzetme, bir istatistik, bir tanım.
- Oyuncu onu beş kutudan birine atar. **Tek hareket, tek saniye.**
- Doğru attıysa: kutu açılır, o türün işlemi **kısa bir mini oyun olarak** başlar — tam bir level değil, 10–15 saniyelik bir dokunuş.
- Yanlış attıysa: ceza yok. Kutu nazikçe geri iter ve **neden oraya ait olmadığını** tek cümleyle söyler. `procedure` mekaniğindeki düzeltici kalıbın aynısı — o kalıp zaten yazıldı ve çalışıyor.

Hız arttıkça bilgi parçaları daha hızlı düşer. Bu, Faz 1.4'teki tempo yükselmesinin doğal bir uygulaması.

**Neden bu iyi bir oyun:** Sıralama/ayırma oyunları öğrenmesi saniyeler sürer, oynaması tatmin edicidir, ve her tur farklıdır çünkü içerik havuzu değişir. Aynı zamanda PACER'ın öğretmek istediği tam olarak bu refleks.

**Zor kısım — içerik:** Sınıflandırma oyunu için **etiketli bilgi parçaları havuzu** gerekiyor. Her parça: metin + doğru tür + neden o tür + neden diğerleri değil.

Başlangıç için tür başına 20 parça, toplam 100. Örnek:

| Parça | Tür | Neden |
|---|---|---|
| "Önce suyu kaynat, sonra çayı demle." | P | Adım sırası var; uygulanarak öğrenilir. |
| "Beyin bir bilgisayar gibidir." | A | Yeniyi bildiğe bağlayan benzetme. |
| "Stres, hatırlamayı zayıflatır." | C | İki kavram arasında yönlü ilişki. |
| "Bir çalışmada grup A %40 daha fazla hatırladı." | E | Bir iddiayı destekleyen veri. |
| "Suyun kaynama noktası 100 °C." | R | İzole, kesin, gerektiğinde bakılır. |

⚠️ **Sınır durumlar kasıtlı olmalı.** "Suyun kaynama noktası 100 °C" bir kimya dersinde C'nin parçası da olabilir. Oyun bunu cezalandırmamalı — ikinci tur seçeneği veya "bağlama göre değişir" kartı sunmalı. PACER kaynağının kendi uyarısı: *"Amaç her cümleyi zorla etiketlemek değildir."*

**Kabul ölçütü:** Bir tur ≤ 60 saniye. Yanlış sınıflandırma her zaman açıklamalı. Sınır durumlar için tek doğru cevap dayatılmıyor.

---

## 2.3 — E mekaniği — boş kutuyu doldurmak

**Sorun:** `ReviewRecord` yalnızca `key, themeId, word, symbol, stage, dueDate` tutuyor. Kanıtı desteklediği iddiaya bağlayan hiçbir alan yok — ki kaynakların tamamında E'yi R'den ayıran şey tam olarak bu bağ. Bağ yoksa E zaten R'dir.

### Mekanik: "Neyi Kanıtlıyor?" (`.evidence`)

Üç vuruş:

1. **Eşle** — Ekranda birkaç iddia, birkaç kanıt. Oyuncu her kanıtı desteklediği iddiaya bağlar. (Kaynak s.6: *"Yanına hangi iddiayı desteklediğini yaz."*)
2. **Sınırını çiz** — "Bu kanıt şunu da kanıtlar mı?" Kanıtın kapsadığı ve kapsamadığı çıkarımlar sunulur. (Kaynak: *"genellenebilirliğini ve sınırlarını düşün."*)
3. **Geri çağır** — Sonra iddia verilir, kanıt istenir. Ya da tersi.

**Neden oyun olarak iyi çalışır:** Bağlama hareketi `conceptMap`'te zaten var ve tutuyor. Buradaki fark, bağlananın kavram değil **iddia–kanıt** çifti olması, ve ikinci vuruşun bir tuzak barındırması: aşırı genelleme. O tuzak oyunun tadı.

**İçerik modeli:**

```swift
struct EvidenceItem {
    let symbol: String
    let text: String          // kanıtın kendisi
    let supports: String      // desteklediği iddia
    let overreach: [String]   // desteklemediği hâlde destekler görünen çıkarımlar
    let limit: String         // hangi koşulda geçerli
}
```

**Kabul ölçütü:** Oyuncu her kanıtı bir iddiaya bağlamadan fazı geçemiyor. Aşırı genelleme tuzağı en az bir kez sunuluyor.

---

## 2.4 — A ve C'nin eksik adımları

Denetimde çıkan, kaynakta olup kodda olmayan adımlar:

**A — `analogy`:**
- "Hangi yönlerden farklı?" ile "nerede bozuluyor?" şu an aynı düğmeye biniyor. Kaynak bunları ayırıyor; ayır.
- **"Genişletirsem yeni çıkarım yapabiliyor muyum?"** adımı hiç yok. Ekle: benzetmeyi bir adım ileri taşıyan doğru çıkarım ile benzetmenin taşımadığı yanlış çıkarım arasında seçim.

**C — `conceptMap`:**
- Düğümler yalnızca merkeze bağlanıyor. Kaynak *"aralarındaki ilişkileri çiz"* diyor — **düğüm–düğüm** bağlar ekle.
- **Haritayı yeniden düzenleme** adımı yok. Ekle: yeni bir bilgi gelir, mevcut harita artık yetmez, oyuncu bir bağı değiştirir. Kaynak: *"ilk haritanın kusursuz olması gerekmez."*

**Kabul ölçütü:** Her iki mekanikte de kaynak maddeleri tek tek karşılanmış; karşılanmayan varsa kodda `// PACER: karşılanmadı —` yorumuyla işaretli.

---

## 2.5 — `techniqueScience` metinlerini düzeltmek

**Sorun (kendi hatam olarak kaydedildi):** Üç yeni mekaniğin `techniqueScience` metinlerine "PACER şunu der" yazdım. O alan projede Craik & Lockhart, Roediger & Karpicke, Bower & Clark gibi **hakemli** kaynaklar taşıyor ve §9 aşırı iddia yasağı var. Bir uygulayıcı çerçevesini araştırma kılığında sunmak o sınırı ihlal ediyor.

**Yapılacak:** PACER yapıyı belirlesin, güvenilirliği literatür taşısın.

| Mekanik | Yerine gelecek dayanak |
|---|---|
| `procedure` | Test etkisi ve yardımsız uygulama — Roediger & Karpicke (projede zaten atıflı) |
| `conceptMap` | Kavram haritalama meta-analizi — Nesbit & Adesope 2006 |
| `analogy` | Analojik akıl yürütme ve yapısal hizalama — Gentner |
| `evidence` | Ayrıntılandırma ve kaynak izleme literatürü |
| `triage` | **Doğrudan dayanak yok.** Metin bunu açıkça söylesin: bu bir düzenleme çerçevesi. |

⚠️ **Atıfları yazmadan önce doğrulayın.** Yukarıdakiler yönlendirme; her biri için gerçek bulgu ve gücü kontrol edilmeli. Projenin mevcut metinleri "modest", "conditional", "evidence is thin" gibi dürüst güç etiketleri kullanıyor — o alışkanlığı sürdürün.

---

## Dokunulacak dosyalar

```
YENİ    Game/KnowledgeType.swift          yönlendirme katmanı
YENİ    Game/TriageSession.swift          sınıflandırma mekaniği
YENİ    Views/TriageMissionView.swift
YENİ    Game/EvidenceSession.swift        E mekaniği
YENİ    Views/EvidenceMissionView.swift
YENİ    Game/TriageContent.swift          100 etiketli bilgi parçası
DEĞİŞİR Game/Content.swift                yeni mekanikler, ağırlıklar, atıflar
DEĞİŞİR Game/AnalogySession.swift         farklılık/kırılma ayrımı + çıkarım adımı
DEĞİŞİR Game/ConceptMapSession.swift      düğüm–düğüm bağ + yeniden düzenleme
DEĞİŞİR Views/HomeView.swift              iki switch satırı
```

⚠️ **`GameStore.Snapshot` yine değişmeyecek.** Yeni mekanikler runtime'da üretiliyor; kayıt şemasına dokunmaya gerek yok. Yeni leveller ladder'ın **sonuna** eklenir (16, 17…), mevcut indeksler yeniden numaralanmaz.

---

## Bu faz bittiğinde

Beş PACER kutusu da dolu. Oyuncu yalnızca teknikleri değil, **hangi durumda hangisine uzanacağını** çalışıyor. Uygulama, PACER'dan ilham alan bir oyun olmaktan çıkıp PACER'ı öğreten bir oyuna dönüşüyor.

## Kalite kapısı

- [ ] Beş türün her biri en az bir mekanikle yürütülüyor
- [ ] Sınıflandırma turu ≤ 60 sn ve her yanlış açıklamalı
- [ ] Sınır durumlarda tek doğru cevap dayatılmıyor
- [ ] E mekaniğinde kanıt–iddia bağı zorunlu
- [ ] A ve C'nin kaynak maddeleri tek tek karşılanmış veya işaretlenmiş
- [ ] `techniqueScience` metinlerinde PACER'a araştırma muamelesi yapılmıyor
- [ ] Oyuncu ilerlemesi kayıpsız
