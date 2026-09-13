# MemDoping V2 — PROJECT AUDIT

> V2 Master Spec §14'ün karşılığı. **Bu aşamada kod değiştirilmedi.**
> Amaç: çalışan mimariyi haritalamak, korunacakları sabitlemek, V2 modüllerinin
> bağlanma noktalarını ve riskleri belirlemek. Sonunda **DUR** — onay bekleniyor.

Audit tarihi: 12 Eylül 2026 · Baz commit: `1284b89` · Branch: `main` (yedek: `v2`)

---

## 1. Mevcut mimari haritası

**Yığın:** SwiftUI + `@Observable` (Observation), tek paylaşılan store. Harici bağımlılık yok.

### Uygulama akışı

```
MemDopingApp.swift (@main, 32 satır)
  └─ GameStore enjekte edilir + MusicPlayer.start()
     └─ ContentView.swift (51 satır)
        ├─ SplashView  (ilk açılış animasyonu)
        ├─ OnboardingView   ← store.hasOnboarded == false
        └─ HomeView         ← store.hasOnboarded == true
           └─ level ladder → mekaniğe göre 9 ayrı Mission ekranı
```

### Katmanlar

| Katman | Dosyalar | Sorumluluk |
|---|---|---|
| **State / kalıcılık** | `Game/GameStore.swift` (424) | XP, Memory Score, level kilidi, spaced review, tercihler, age band, adaptive difficulty. UserDefaults. |
| **İçerik modeli** | `Game/Content.swift` (741) | `GameLevel`, `MemoryTheme`, `MemoryPair`, `MemoryRoute`, `WhyDeck` + `SampleContent` + `SampleLevels` |
| **Oturum mantığı** | `Game/*Session.swift` (10 dosya) | Her mekaniğin kendi faz makinesi ve skorlaması |
| **Ekranlar** | `Views/*MissionView.swift` (9) + `HomeView`, `ProfileView`, `OnboardingView`, `NightDopingView`, `SplashView` | Sunum |
| **Paylaşılan UI** | `Views/Components.swift` (675), `MissionChrome.swift` (287) | `Brand` paleti, kartlar, `MissionIntro`, `MissionSummary`, `ConfettiView` |
| **3D / efekt** | `Symbol3DTile.swift` (300), `Hero3DView.swift` (152), `Celebration3DView.swift` (146) | SceneKit/SwiftUI tabanlı derinlik öğeleri |
| **Ses** | `Game/MusicPlayer.swift` (152) | `AVAudioEngine` + `AVAudioPlayerNode` ile **sentezlenmiş** müzik — ses dosyası yok |
| **Dil** | `Localizable.xcstrings` + `AppLocale` (Content.swift:20-35) | TR/EN, uygulama içi dil değişimi |
| **Testler** | `MemDopingTests/` (2 dosya, 23 test) | Swift Testing (`@Test`) |

Toplam: **~9.500 satır Swift**, 38 dosya.

### Level ladder nasıl üretiliyor (kritik)

`Content.swift:606-717` → `curated`: elle yazılmış **12 level**.
`Content.swift:722-736` → `all`: bu 12 şablonun **klonlanarak 100'e çıkarılması**.

```swift
let template = curated[(index - 1) % curated.count]   // 12'de bir tekrar
let step = (index - 1) / curated.count                // her turda biraz zorlaşır
levels.append(template.scaled(toIndex: index, step: step, theme: theme))
```

Yani 13–100 arası levellar, ilk 12'nin sayısal olarak ölçeklenmiş kopyaları; tema rotasyonu dışında yeni bir tasarım yok. **V2 spec'inin "100 level arka arkaya aynı akış" şikâyeti tam olarak buradan kaynaklanıyor** ve tek bir fonksiyonda toplanmış durumda.

### Mevcut level döngüsü

`MissionSession.swift:27-32`:

```
intro → learn → recall → feedback → summary
```

V2 hedefi: `HOOK → MICRO TUTORIAL → PLAY → CHALLENGE → RECALL → REWARD`

Eşleşme durumu:

| V2 fazı | Mevcut karşılık | Durum |
|---|---|---|
| Hook | — | **Yok** |
| Micro Tutorial | `intro` (`MissionIntro` + `techniqueExplanation` + `techniqueScience`) | **Var ama ters** — metin duvarı, 3-5 sn değil |
| Play | `learn` | Var |
| Challenge | — (zorluk `adapted()` ile baştan sabitleniyor) | **Level içinde yükselen tempo yok** |
| Recall | `recall` | Var, güçlü |
| Reward | `summary` + `ConfettiView` | Var ama zayıf |

---

## 2. Korunacak sistemler (DOKUNMA)

V2 spec §2 ve §15 gereği aşağıdakiler çalışıyor, test altında ve kullanıcı verisi taşıyor:

1. **`GameStore` kalıcılık şeması** — `defaultsKey = "memdoping.save.v1"` (GameStore.swift:126) ve `Snapshot` (314-330). Snapshot'taki alanların çoğu `Optional`, bu sayede eski kayıtlar açılıyor. **Yeni alan eklerken mutlaka Optional ekle, mevcut alanı silme veya tipini değiştirme.** Aksi halde tüm oyuncu ilerlemesi sessizce sıfırlanır.
2. **XP / mastery / unlock mantığı** — `complete(level:correct:total:)` (253-302). 12 test bunu koruyor (farm koruması dahil).
3. **Memory Score ve Retention** — `memoryScore` (168), `retentionScore` (209), `memoryDifficulty` (Content.swift:181-197).
4. **Spaced review kuyruğu** — `ReviewSchedule`, `scheduleReviews`, `recordReview`. Aralıklı tekrar, PACER'ın E ve R sınıflarının doğrudan karşılığı; V2'de değeri artacak.
5. **9 mekaniğin skorlama mantığı** — `*Session.swift` içindeki puanlama. `MechanicsTests.swift`'teki 11 test bunları kilitliyor.
6. **Lokalizasyon zinciri** — `AppLocale` + `.localizedContent`. Oynanış eşleşmesi kanonik (İngilizce) değer üzerinden yapılıyor; **gösterim dili ile eşleştirme değerini asla karıştırma.**
7. **Adaptive difficulty** — `adapted(_:)` (382-395). Level kimliğini bozmadan parametre kaydırıyor.

## 3. Değişecek alanlar

| # | Alan | Sorun | Dosya |
|---|---|---|---|
| D1 | **Age Path yüzeysel** | Aşağıda §4'te ayrıntılı | GameStore.swift:100-116, ContentView.swift:38-45 |
| D2 | **Level üretimi şablon klonu** | 12 şablon × 8 tur | Content.swift:722-736 |
| D3 | **Intro metin duvarı** | `techniqueExplanation` + `techniqueScience` uzun metin | MissionChrome.swift:28 (`MissionIntro`), Content.swift:201-240 |
| D4 | **Faz makinesi 10 yerde tekrar** | Her `*Session.swift` kendi `Phase` enum'unu taşıyor | `Game/*Session.swift` (10 dosya) |
| D5 | **Tek global palet** | `Brand` statik sabitler; yaş grubuna göre tema hook'u yok | Components.swift:12-37 |
| D6 | **Ödül hissi zayıf** | Sadece `ConfettiView` + özet kartı | MissionChrome.swift:115, 235 |
| D7 | **Asset hattı yok** | `Assets.xcassets` içinde yalnızca AppIcon + AccentColor | Aşağıda §6 |

---

## 4. Age Path entegrasyon noktası

**Altyapı zaten var** — ama V2 spec'inin açıkça yasakladığı biçimde.

Mevcut durumda `AgeBand` yalnızca iki şeyi etkiliyor:

```swift
// GameStore.swift:110-116 — sadece zorluk kaydırması
var ageOffset: Int {
    case .child: -2 ; case .teen, .none: 0 ; case .adult: 1
}

// ContentView.swift:38-45 — sadece sembol yuvarlaklığı
private var cartoonLevel: Double {
    case .child: 1.0 ; case .teen: 0.5 ; case .adult: 0.2 ; case .none: 0.6
}
```

Yani bugün Child/Teen/Adult = **aynı oyun, biraz farklı zorluk + biraz farklı çizim yuvarlaklığı.** Spec §3'ün "aynı oyunun yalnızca renk değiştirilmiş versiyonları olmayacaktır" maddesinin ihlali, tam olarak bu iki fonksiyon.

**Bağlanma noktaları (mevcut, hazır):**

- `GameStore.ageBand` — kalıcı, Snapshot'ta saklı, `setAgeBand(_:)` ile yazılıyor. **Yeni bir state'e gerek yok.**
- `OnboardingView.swift:103-116` — seçim ekranı zaten çalışıyor; V2'de "Yaş Yolu Seçimi" olarak yeniden tasarlanacak yüzey burası.
- `ContentView.swift:23` — `.environment(\.cartoonLevel, ...)` zaten bir environment enjeksiyon noktası. **Age Path'in tüm sunum katmanı buradan dağıtılabilir.**

**Önerilen yapı:** `cartoonLevel: Double` yerine bir `AgePresentation` profili enjekte et — palet, tempo, tipografi, ses seti, karakter, animasyon yoğunluğu, tutorial formatı. Böylece `Brand`'in statik paletini kırmadan yaşa göre tema mümkün olur ve her ekranı tek tek değiştirmek gerekmez.

**Ayrıca:** `SampleLevels.all` tek bir düz liste. Age Path gerçekten ayrışacaksa ladder'ın yaş yoluna göre dallanması gerekir — bu, D2 ile aynı fonksiyonda çözülmeli.

---

## 5. PACER entegrasyon noktası

Kaynak: `PACER_Metodu_Justin_Sung_Turkce_Rehber.pdf` (12 sayfa, projede mevcut).
Kaynaktaki sınıflandırma (s.2, s.11 cheat sheet):

| Sınıf | Soru | İşlem |
|---|---|---|
| **P** Procedural | Nasıl yapılır? | Practice — uygula |
| **A** Analogous | Bu bana neyi hatırlatıyor? | Critique — benzerliği, farkı, analojinin kırıldığı noktayı bul |
| **C** Conceptual | Nedir, neden böyle, nasıl bağlı? | Mapping — ağ/harita kur |
| **E** Evidence | Hangi iddiayı destekleyen veri? | Store + Rehearse — kısa kaydet, kavrama bağla |
| **R** Reference | Şimdi anlamam mı, gerektiğinde bulmam mı? | Store + Rehearse / Recall — aralıklı tekrar |

### Mevcut 9 mekaniğin PACER karşılığı

| Mekanik | PACER | Not |
|---|---|---|
| pairRecall, numberShape, loci, story, chunking | **R** | Referans bilgisini saklama/çağırma |
| retrieval | **R** (güçlü) | Aktif hatırlama — kaynağın R işlemiyle birebir |
| review (spaced) | **E + R** | Aralıklı tekrar, kaynakta açıkça önerilen işlem |
| elaboration ("Neden böyle?") | **C**'ye yakın | Tek bağlantı kuruyor, harita kurmuyor |
| interleaving | Sınıf ayrımı pratiği | PACER'ın "türü belirle" adımına (s.8) yakın |
| scene | **A**'ya yakın | Benzetme kuruyor ama **sorgulamıyor** — kaynak A için critique şart koşuyor |

### Boşluk (V2'nin asıl fırsatı)

- **P — Procedural: hiç yok.** Adım/prosedür uygulatan tek bir mekanik bile yok.
- **A — Analogous: yarım.** `scene` benzetme kurduruyor ama kaynağın istediği "benzerlik / fark / analojinin kırıldığı nokta" sorgulaması yok.
- **C — Conceptual: yarım.** `elaboration` tek bir "neden"i seçtiriyor; kaynak ilişki ağı/haritalama istiyor.
- **E, R: güçlü.** Mevcut proje neredeyse tamamen bu ikisinin üzerine kurulu.

**Sonuç:** Projede "hafıza oyunu" tarafı (E/R) olgun, "öğrenme oyunu" tarafı (P/A/C) eksik. 9 prototipin en az 3'ü P, A ve C'yi hedeflemeli — aksi halde PACER entegrasyonu spec'in yasakladığı yüzeysel biçimde kalır.

**Bağlanma noktası:** `LevelMechanic` enum'u (Content.swift:46-72) + `HomeView.swift:41-50` switch'i. Yeni mekanik eklemek = enum'a case + Session + View + switch satırı. **Mevcut hiçbir mekaniğe dokunmadan genişletilebilir** — bu, projenin en güçlü mimari özelliği.

⚠️ `LevelMechanic` `String` raw value taşıyor ama `GameLevel` Codable değil, ladder runtime'da üretiliyor. Yani **yeni mekanik eklemek kayıt şemasını bozmuyor.** Doğrulandı.

---

## 6. Higgsfield asset hattı

**Mevcut durum: hat yok.** `Assets.xcassets` içinde yalnızca `AppIcon.appiconset` (7 png) ve `AccentColor`. Oyundaki tüm görseller SF Symbols, emoji ve prosedürel SwiftUI çizimi. Müzik de dosya değil, `AVAudioEngine` ile sentezleniyor.

Bu, V2'nin en büyük **yeni** inşa alanı. Öneri:

```
MemDoping/Resources/
  Cinematics/<age>/<levelId>.mp4       — level girişi, ödül sahnesi
  Tutorials/<age>/<mechanic>.mp4       — 3-5 sn mikro anlatım
  Characters/<age>/...                 — karakter sahneleri
  Audio/<age>/...                      — VO + efekt
```

Kurallar (spec §8'den):

- Gerçek zamanlı gameplay **uygulamanın kendi render'ında kalır** — Higgsfield çıktısı yalnızca ön/arka sahne.
- Her etkileşimde uzaktan video çağrısı **yok**; tüm asset'ler bundle'da veya on-demand resource olarak yerel.
- Video = `AVPlayerLayer`, ilk kare önceden yüklenmiş; oynatma başarısız olursa **mevcut statik intro'ya düşülmeli** (fallback zorunlu).
- Bütçe önerisi: mikro tutorial ≤ 5 sn, ≤ 2 MB, 1080×1920, H.265.

---

## 7. Blender / 3D hattı

**Mevcut 3D:** `Symbol3DTile.swift` (300), `Hero3DView.swift` (152), `Celebration3DView.swift` (146) — prosedürel, dosya asset'i yok.

Öneri: `Resources/Models/*.usdz`, RealityKit/SceneKit ile yüklenir. Spec §9 gereği 3D yalnızca (a) oynanışı geliştiriyorsa, (b) hafıza tekniğini güçlendiriyorsa, (c) premium hissi belirgin artırıyorsa.

**En güçlü aday: `loci` (hafıza sarayı).** Uzamsal teknik zaten 3D'yi hak ediyor; bugün 2D liste olarak sunuluyor.

Performans sınırı önerisi: sahne başına ≤ 50k üçgen, ≤ 4 doku (2048²), 60 FPS hedefi, cihaz alt sınırı iPhone 12.

---

## 8. Risk sınıflandırması

### CRITICAL

| Risk | Etki | Önlem |
|---|---|---|
| **`Snapshot` şemasının bozulması** | Tüm oyuncu ilerlemesi sessizce silinir. `load()` hata verince `return` ediyor, kullanıcı uyarı almıyor (GameStore.swift:355-358) | Yeni alanlar yalnızca `Optional`. Mevcut alan silme/tip değiştirme yasak. Migration testi yaz. |
| **`Content.swift` ladder'ının yeniden yazılması** | `highestUnlockedLevel` mevcut index'lere bağlı; ladder yeniden numaralanırsa oyuncu yanlış levele düşer | Eski index aralığını koru, yeni içeriği üstüne ekle |

### HIGH

| Risk | Etki | Önlem |
|---|---|---|
| **Faz makinesinin 10 dosyada tekrarı (D4)** | HOOK/MICRO-TUTORIAL/REWARD eklemek 10 ayrı düzenleme demek; biri unutulursa tutarsız akış | Önce ortak `MissionFlow` protokolü + shared chrome; sonra mekanikler tek tek taşınır |
| **`Brand` statik paletinin kırılması (D5)** | 675 satırlık `Components.swift` ve tüm ekranlar bu sabitlere bağlı | `Brand`'i silme; yanına `AgeTheme` ekleyip environment'tan dağıt, ekranları kademeli geçir |
| **Video/3D'nin FPS ve boyutu** | Spec: "mobil performans pazarlık dışı" | Her asset için bütçe + fallback zorunlu |

### MEDIUM

- Age Path dallanması ladder'ı 3'e katlarsa içerik bakım maliyeti 3× olur → önce 9 prototip, sonra karar.
- Yeni mekaniklerin (P/A/C) skorlaması `memoryDifficulty` tablosuna eklenmeli, yoksa Memory Score çarpıklaşır (Content.swift:181-197).
- `.claude/` klasörü git'te takipsiz — `.gitignore`'a eklenmeli.

### LOW

- Lokalizasyon: yeni metinler `Localizable.xcstrings`'e girmezse İngilizce görünür.
- `MusicPlayer` sentezi yerine dosya gelirse `scenePhase` start/stop mantığı gözden geçirilmeli.

---

## 9. Önerilen en düşük riskli uygulama sırası

Her adım kendi başına derlenir ve geri alınabilir. Hiçbiri mevcut kayıtları bozmaz.

| # | Adım | Neden burada | Risk |
|---|---|---|---|
| 0 | `v2` branch'i (yapıldı) + `.gitignore`'a `.claude/` | Geri dönüş noktası | — |
| 1 | **`AgePresentation` profilini ekle**, `cartoonLevel` yerine environment'tan dağıt. Davranış birebir aynı kalsın | Saf refactor, görsel değişiklik yok, Age Path'in omurgası kurulur | Low |
| 2 | **Ortak `MissionFlow` + shared chrome** — HOOK ve REWARD fazlarını *boş geçilebilir* olarak tanımla, mevcut 10 session'ı bu iskelete bağla | Faz eklemenin maliyetini 10×'den 1×'e düşürür | Med |
| 3 | **Micro Tutorial bileşeni** — `MissionIntro`'yu 3-5 sn'lik animasyon + tek cümle altyazıya indir; uzun metin "Detay" altına gizlensin | Spec'in en net şikâyeti; tek bileşende çözülür | Low |
| 4 | **Reward katmanını güçlendir** — combo/streak geri bildirimi, geçiş animasyonları | Görünür kalite sıçraması, oynanış mantığına dokunmaz | Low |
| 5 | **Prototip çerçevesi** — `PrototypeLevel` tanımı (spec §12 şablonu), ana ladder'dan **ayrı** bir listede | Mevcut 100 level'a hiç dokunmadan denemeye izin verir | Low |
| 6 | **9 prototipi üret** — 3 Child / 3 Teen / 3 Adult; en az 3'ü P, A ve C sınıflarını hedeflesin | Asıl iş | Med |
| 7 | Higgsfield + Blender asset'lerini prototiplere bağla (fallback zorunlu) | Asset üretimi paralel yürüyebilir | Med |
| 8 | **Kalite kapısı** (spec §13) | — | — |
| 9 | Onay sonrası: ladder genişletmesi ve Age Path dallanması | Ancak onaydan sonra | High |

**Not:** 1–5 arası adımlar mevcut oyunu bozmadan yapılabilir; 6'ya kadar kullanıcı hiçbir gerileme görmez.

---

## 10. Ek: PACER boşlukları dolduruldu (12 Eylül)

Audit sonrası alınan karar: ölçeklemeden önce §5'teki **P / A / C** boşluklarını kapat.
Üç yeni mekanik eklendi. Mevcut mekaniklerin hiçbirine, `GameStore`'a ve kayıt şemasına dokunulmadı.

| PACER | Mekanik | Oyuncu ne yapıyor | Kaynak |
|---|---|---|---|
| **P** Procedural → Practice | `.procedure` — "Do It Yourself" | Prosedürü bir kez izler, sonra **kaynağa bakmadan** sırayla uygular. Yanlış hamlede ceza değil **düzeltici** çıkar; sadece ilk denemede doğru olanlar sayılır. Tepside prosedüre ait olmayan "tuzak" adımlar var. | Rehber s.3, s.11 |
| **A** Analogous → Critique | `.analogy` — "Where It Breaks" | Benzetme hakkındaki iddiaları **tutuyor / kırılıyor** diye ayırır, sonra hangi benzetmenin nerede kırıldığını hatırlar. Sonunda "daha iyisi kurulabilir mi" notu. | Rehber s.4, s.11 |
| **C** Conceptual → Mapping | `.conceptMap` — "Map It" | Her kavramı merkeze bağlar ve **ilişkiyi adlandırır** (causes / increases / decreases / requires / example of), sonra harita kapalıyken ilişkileri geri çağırır. | Rehber s.5, s.11 |

**Neden mevcut mekaniklerden farklılar:** `.story` rastgele sıra ezberletir, `.procedure` ise nedensel sıra uygulatır ve hatayı açıklar. `.scene` benzetme *kurar*, `.analogy` benzetmeyi *sorgular*. `.elaboration` tek bir "neden" seçtirir, `.conceptMap` etiketli bir ağ kurdurur.

**Eklenen dosyalar:**

```
Game/ProcedureSession.swift      Views/ProcedureMissionView.swift
Game/AnalogySession.swift        Views/AnalogyMissionView.swift
Game/ConceptMapSession.swift     Views/ConceptMapMissionView.swift
```

**Değiştirilen dosyalar:** `Content.swift` (yeni modeller, örnek içerik, level 13-15, ağırlıklar, açıklamalar), `HomeView.swift` (3 satır switch), iki test dosyası.

**Riske karşı alınan önlemler:**

- Yeni leveller ladder'ın **sonuna** eklendi (13, 14, 15) — 1-12 arası hiçbir level yeniden numaralanmadı, kayıtlı `highestUnlockedLevel` anlamını koruyor. Test: `addingPacerLevelsDidNotRenumberTheExistingLadder`.
- `GameStore.swift` hiç değişmedi → `Snapshot` şeması bozulmadı, §8'deki CRITICAL risk oluşmadı.
- `scaled()` ve `varying()` yeni içerik alanlarını taşıyacak biçimde genişletildi; aksi halde üretilen klon leveller sessizce varsayılan desteye düşerdi. Test: `scalingAndAdaptingPreservePacerContent`.
- Sayaç, diğer zamanlı mekaniklerdeki gibi oturumda tutuluyor (`tickStudyTimer`), görünümde değil.
- 9 yeni test yazıldı (3 P, 3 A, 3 C) + 4 entegrasyon testi.

**Bilinerek kabul edilen etki:** `curated` 12'den 15'e çıktığı için 16-100 arası üretilen leveller artık 15 şablon üzerinden dönüyor. Oyuncu ilerlemesi etkilenmez, ama 13+ levellerin içeriği değişti — zaten §3 D2'de yeniden tasarlanacak alan.

**Derlenmedi.** Bu ortamda Swift araç zinciri yok; ayraç dengesi ve sembol tanımları statik olarak doğrulandı. İlk build'i Xcode'da almanız gerekiyor.

---

## 11. DUR — onay bekleniyor

Spec §14: *"Sonra DUR. Onay alınmadan büyük refactor veya 100-level üretimi başlatma."*

Karar verilmesi gerekenler:

1. Uygulama sırası (§9) onaylanıyor mu, yoksa başka bir sıra mı?
2. Adım 1 ve 2 (saf refactor) başlatılsın mı?
3. 9 prototipin mekanik dağılımı: P/A/C boşluğunu doldurmak öncelikli mi, yoksa mevcut mekaniklerin premium sunumu mu önce?
4. Age Path ladder'ı gerçekten 3'e dallanacak mı, yoksa ortak ladder + yaşa göre sunum mu?

---

*Bu audit sırasında hiçbir kaynak dosya değiştirilmedi. Tek yeni dosya bu rapordur.*

*Not: Audit sırasında `FeedbackEngine.swift` dosyasında dışarıdan gelen 1 satırlık bir değişiklik (dosya sonuna boş satır) tespit edildi — audit kaynaklı değil, muhtemelen Xcode/Codex tarafı.*
