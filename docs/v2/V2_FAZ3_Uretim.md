# V2 — Faz 3: Üretim

> **Hedef cümle:** Eğitim uygulaması hissi bitsin; premium oyun hissi başlasın.
> **Kapsam:** Age Path'in gerçekleşmesi, 9 prototip, dış araç hattı (Higgsfield · Blender · Canva).
> **Ön koşul:** Faz 1 tamamlanmış olmalı. Faz 2 paralel yürüyebilir ama prototiplerin en az üçü PACER router'ını göstermeli.
> **Kural:** Bu faz **kalite kapısıyla biter.** Onay alınmadan 100 level üretimine geçilmez (spec §13).

---

## 3.1 — Age Path'i gerçek yapmak

**Bugünkü durum — sorunun tam tanımı:**

`AgeBand` zaten var, kalıcı, onboarding ekranı çalışıyor. Ama yalnızca iki şeyi etkiliyor:

```swift
GameStore.swift:110   ageOffset      → sadece zorluk kaydırması (-2 / 0 / +1)
ContentView.swift:38  cartoonLevel   → sadece sembol yuvarlaklığı (1.0 / 0.5 / 0.2)
```

Yani Child/Teen/Adult bugün **aynı oyunun biraz farklı zorlukta, biraz farklı yuvarlaklıkta hâli.** Spec §3 bunu açıkça yasaklıyor: *"aynı oyunun yalnızca renk değiştirilmiş versiyonları olmayacaktır."*

**Yapılacak:** `cartoonLevel: Double` yerine bir sunum profili enjekte et.

```
Views/AgePresentation.swift

struct AgePresentation {
    let palette: AgePalette          // renk dünyası
    let typography: AgeTypography    // yazı ölçeği ve ağırlığı
    let tempo: Tempo                 // geçiş hızı, bekleme süreleri
    let motion: MotionLevel          // animasyon yoğunluğu
    let narration: NarrationStyle    // karakter / avatar / sunucu / sade
    let soundSet: SoundSet           // ses paleti
    let tutorialFormat: TutorialKind // çizgi karakter / motion / doğrudan gösterim
}
```

Dağıtım noktası hazır: `ContentView.swift:23` zaten `.environment(\.cartoonLevel, …)` yapıyor. Profil aynı yerden dağıtılır, her ekranı tek tek değiştirmek gerekmez.

⚠️ **`Brand` paletini silmeyin.** `Components.swift` 675 satır ve her ekran o sabitlere bağlı. `Brand` yerinde kalır; `AgePresentation` onun **yanına** gelir ve ekranlar kademeli geçirilir.

**Üç yolun farkı — spec §3'ten, somutlaştırılmış:**

| | Child | Teen | Adult |
|---|---|---|---|
| Görsel dil | Çizgi karakter, canlı renk | Modern oyun estetiği, çocuksu değil | Premium, sofistike, temiz |
| Tempo | Yavaş, sabırlı | Hızlı, challenge hissi | Ölçülü, stratejik |
| Geri bildirim | Büyük, belirgin, sesli | Combo · streak · skor | Az ama kaliteli |
| Anlatım | Çizgi karakter anlatır | Dinamik avatar / motion | Gerçekçi dijital sunucu veya doğrudan gösterim |
| Metin | Asgari | Orta | Gerektiği kadar |

**Kabul ölçütü:** Üç yolun ekran görüntüleri yan yana konduğunda, renk farkı dışında **tempo, anlatım ve geri bildirim** farkı da görünür olmalı.

---

## 3.2 — Dış araç hattı

Spec §10'daki sorumluluk ayrımı — ve her aracın gerçekte ne kadar otomatikleştirilebileceği:

| Araç | İşi | Otomasyon durumu |
|---|---|---|
| **Higgsfield** | Sinematik, karakter sahnesi, mikro tutorial videosu, level girişi, ödül sahnesi, ortam konsepti | **Bağlayıcı yok.** İnsan eliyle üretilir, çıktı projeye elle konur. |
| **Blender** | Optimize 3D asset, hafıza sarayı alanları, karakter, ödül objesi, kısa animasyon | **Bağlayıcı yok.** İnsan eliyle üretilir, `.usdz` olarak dışa aktarılır. |
| **Canva** | 2D arayüz parçaları, ikon setleri, afiş, App Store / Play görselleri, sosyal görseller, şablonlu yaş paletleri | **Resmî MCP bağlayıcısı var** (bağlı değil). Bağlanırsa tasarım arama, içerik okuma ve dışa aktarma otomatikleşir. |
| **Uygulama kodu** | Gerçek zamanlı oynanış, state, skor, ilerleme, etkileşim, level mantığı, performans | — |

**Değişmez kural (spec §8, §9):** Gerçek zamanlı oynanış **uygulamanın kendi render'ında** kalır. Higgsfield çıktısı yalnızca ön ve arka sahnedir; her etkileşimde uzaktan üretilen videoya bağımlılık kurulmaz. 3D yalnızca oynanışı geliştiriyorsa, hafıza tekniğini güçlendiriyorsa veya premium hissi belirgin artırıyorsa kullanılır — **her şeyi 3D yapma.**

### Klasör düzeni

```
MemDoping/Resources/
  Cinematics/<age>/<levelId>.mp4        level girişi, ödül sahnesi
  Tutorials/<age>/<mechanic>.mp4        3–5 sn mikro anlatım
  Characters/<age>/…                    karakter sahneleri
  Models/<name>.usdz                    Blender çıktısı
  UI/<age>/…                            Canva çıktısı (ikon, çerçeve, rozet)
  Audio/<age>/…                         seslendirme ve efekt
```

### Bütçeler ve zorunlu geri düşüş

| Varlık | Sınır |
|---|---|
| Mikro tutorial videosu | ≤ 5 sn · ≤ 2 MB · 1080×1920 · H.265 |
| Level girişi / ödül sahnesi | ≤ 3 sn · ≤ 3 MB |
| 3D sahne | ≤ 50k üçgen · ≤ 4 doku (2048²) · 60 FPS hedefi |
| Cihaz alt sınırı | iPhone 12 |

⚠️ **Her video ve 3D varlık için geri düşüş zorunludur.** Oynatma veya yükleme başarısız olursa mevcut SwiftUI/SceneKit karşılığına düşülür ve oyun kesintisiz devam eder. Geri düşüşü olmayan varlık projeye girmez.

**En güçlü 3D adayı:** `loci` — hafıza sarayı. Uzamsal bir teknik ve bugün 2D liste olarak sunuluyor. 3D'nin oynanışı gerçekten geliştireceği tek yer büyük ihtimalle burası.

---

## 3.3 — 9 prototip

Spec §11: şimdilik 100 level üretme. Önce **3 Child · 3 Teen · 3 Adult.**

Her prototipte farklı bir şey denenmeli: oyun mekaniği, hafıza davranışı, görsel yaklaşım, animasyon yaklaşımı, tempo, ödül hissi.

**Dağıtım önerisi** — PACER router kararına uygun olarak, en az üçü yeni katmanı göstersin:

| # | Yol | Mekanik | Neyi kanıtlıyor |
|---|---|---|---|
| 1 | Child | `triage` — Ayır | Sınıflandırma bir çocuk için de oynanabilir mi |
| 2 | Child | `procedure` | Düzeltici, ceza yerine öğretim olarak çalışıyor mu |
| 3 | Child | `loci` (3D) | 3D gerçekten oynanışı geliştiriyor mu |
| 4 | Teen | `triage` — hızlı tur | Tempo yükselmesi challenge hissi veriyor mu |
| 5 | Teen | `analogy` | Sorgulama bir oyun olarak tutuyor mu |
| 6 | Teen | `chunking` — yeniden sunum | Eski mekanik yeni çerçevede canlanıyor mu |
| 7 | Adult | `conceptMap` | Harita kurmak premium hissettiriyor mu |
| 8 | Adult | `evidence` | Kanıt–iddia bağı yetişkin için ilgi çekici mi |
| 9 | Adult | `retrieval` — yeniden sunum | Sade sunum da premium olabilir mi |

**Her prototip için doldurulacak şablon (spec §12):**

```
Age Path:              Child / Teen / Adult
Memory Objective:      Geliştirilmeye çalışılan davranış
PACER ilkesi:          Kaynakla doğrulanmış madde (sayfa numarasıyla)
Core Gameplay:         Oyuncunun yaptığı temel eylem
3–5 sn Tutorial:       Görsel + sesli mikro anlatım
Visual World:          Sanat ve ortam yaklaşımı
Animation:             Oynanışı destekleyen hareketler
Higgsfield Role:       Hangi sahne/asset (yoksa "yok")
Blender Role:          Hangi 3D asset (yoksa "yok")
Canva Role:            Hangi 2D parça (yoksa "yok")
Reward:                Başarı nasıl hissedilecek
Performance Budget:    Sınırlar
Fallback:              Dış varlık yüklenmezse ne olur
```

⚠️ **PACER ilkesi satırı boş bırakılamaz ve kaynakta doğrulanmalıdır.** Spec §5: kaynakta olmayan bir PACER kuralı uydurulmaz. Doğrulanamıyorsa satır `// PACER: doğrulanmadı` olarak işaretlenir.

---

## 3.4 — Kalite kapısı

9 prototip bittiğinde **otomatik olarak 100 level üretimine geçilmez.** Önce şu sorular cevaplanır (spec §13):

- [ ] Gerçekten oyun gibi mi?
- [ ] Eğlenceli mi?
- [ ] Tekrar oynama isteği yaratıyor mu?
- [ ] Üç yaş yolu gerçekten farklı mı — yoksa renk farkı mı?
- [ ] PACER ilkesi oynanışa gömülü mü, yoksa üstüne mi yapıştırılmış?
- [ ] Tutorial yeterince kısa mı?
- [ ] Animasyon oynanışı güçlendiriyor mu, yoksa süs mü?
- [ ] Mobil performans iyi mi? (60 FPS, pil, yükleme süresi, paket boyutu)
- [ ] Görsel kalite premium seviyeye yaklaştı mı?

**Bu aşama onaylanmadan ölçekleme yapılmaz.** Onay sonrası iş, denetim raporundaki D2 maddesi: ladder'ın şablon klonlamadan çıkarılıp yeniden tasarlanması.

---

## Dokunulacak dosyalar

```
YENİ    Views/AgePresentation.swift       yaş sunum profili
YENİ    Views/AgeTheme.swift              palet · tipografi · hareket
YENİ    Resources/…                       dış araç çıktıları
YENİ    docs/v2/prototypes/P01…P09.md     her prototipin şablonu
DEĞİŞİR ContentView.swift                 cartoonLevel → AgePresentation (Views/ altında değil, kök)
DEĞİŞİR Views/OnboardingView.swift        yaş yolu seçim ekranı yeniden tasarım
DEĞİŞİR Views/Components.swift            Brand yanına AgeTheme; Brand silinmez
```

⚠️ **`GameStore.Snapshot` yine değişmeyecek.** `ageBand` zaten kayıtlı ve yeterli; sunum profili ondan türetilir, ayrıca saklanmaz.

---

## Bu faz bittiğinde

Üç yaş yolu gerçekten farklı deneyimler. Dokuz prototip, ölçeklemeden önce neyin tuttuğunu ve neyin tutmadığını gösteriyor. Dış araç hattı kurulmuş ve her varlığın bir geri düşüşü var.

Ve en önemlisi: **100 level üretmeden önce doğru şeyi ürettiğimizi biliyoruz.**
