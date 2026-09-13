# V2 — Faz 1: Oynanabilirlik

> **Hedef cümle:** Oyuncu sıkılmadan oynasın.
> **Kapsam:** Mevcut 12 mekaniğin hiçbiri değişmez. Değişen şey, onların **çerçevesi.**
> **Süre tahmini:** En büyük iş 1.1; gerisi ona bağlı ve hızlı.
> **Ön koşul:** Yok. Bu faz tek başına ayakta durur ve tamamlandığında oyun bugünkünden belirgin biçimde daha iyi hissettirir.

---

## Neden önce bu

V2 spec'inin öncelik sırası açık: **oyun hissi → etkileşim → görsel kalite → hafıza mekaniği → açıklama.** Elimizdeki proje bu sıranın tam tersine kurulmuş: mekanik ve açıklama olgun, oyun hissi zayıf.

Teşhis tek bir yerde toplanıyor. Bugünkü akış:

```
intro (metin duvarı) → learn → recall → feedback → summary
```

Bu akış 100 level boyunca **birebir aynı.** Zorluk `adapted()` ile level başlarken bir kez ayarlanıyor, sonra sabit kalıyor. Yani oyuncu 40. levelde 4. leveldekiyle aynı ritmi yaşıyor, sadece sayılar büyümüş oluyor. Sıkılmanın kaynağı içerik tekrarı değil, **ritim tekrarı.**

Hedef akış (spec §4):

```
HOOK → MICRO TUTORIAL → PLAY → CHALLENGE → RECALL → REWARD
```

---

## 1.1 — Ortak akış iskeleti (`MissionFlow`)

**Sorun:** Faz makinesi 10 ayrı dosyada tekrar ediyor (`Game/*Session.swift`). HOOK ve REWARD fazlarını eklemek şu an 10 ayrı düzenleme demek. Biri unutulursa akış tutarsızlaşır ve bu tür hatalar test edilmediği sürece fark edilmez.

**Yapılacak:**

- `Game/MissionFlow.swift` — ortak protokol. Her session'ın sağladığı asgari yüzey: `phase`, `level`, `accuracy`, `correctCount`, `totalQuestions`, `passedMastery`, `showSummary()`, `makeRetry()`.
- Faz enum'u ortaklaşır ve genişler: `hook`, `tutorial`, `play`, `challenge`, `recall`, `feedback`, `summary`.
- **`hook`, `tutorial` ve `challenge` atlanabilir olmalı.** Bir mekanik bunları sağlamıyorsa akış sessizce sonraki faza geçer. Böylece 12 mekanik tek seferde taşınmak zorunda kalmaz.
- `Views/MissionScaffold.swift` — fazları saran tek görünüm. Geçiş animasyonu, ilerleme göstergesi, çıkış butonu, arka plan burada toplanır. Bugün her `*MissionView.swift` bunları kendi kopyalıyor.

**Kabul ölçütü:** Mevcut 12 mekanik, davranışları değişmeden bu iskelet üzerinden çalışıyor. 23 mevcut test geçiyor. Yeni faz eklemek tek dosya değişikliği.

**Risk:** Orta. Saf refactor ama geniş yüzeye dokunuyor. Mekanikleri **tek seferde** değil, birer birer taşıyın; her taşımadan sonra o mekaniğin testini çalıştırın.

---

## 1.2 — HOOK (2–3 saniye)

**Sorun:** Oyuncu bir levele girdiğinde ilk gördüğü şey bir brifing. Dikkat çekilmeden bilgi veriliyor.

**Yapılacak:** Level açıldığında, brifingden **önce**, 2–3 saniyelik bir dikkat kancası. Brifing değil, meydan okuma.

Kanca kalıpları (mekaniğe göre seçilir):

| Kalıp | Nasıl | Hangi mekanikte |
|---|---|---|
| Meydan sorusu | "Bu 9 haneyi 15 saniyede tutabilir misin?" | chunking, numberShape |
| Ani gösterim | Kartlar bir saniye açılır, kapanır | pairRecall, scene |
| Yanlış kurulum | Ekranda hatalı bir sıra durur, "burada bir sorun var" | procedure |
| Çelişki | "Elektrik suya benzer. Nerede benzemez?" | analogy |
| Dağınık ağ | Bağlantısız düğümler ekrana saçılır, merkeze çekilir | conceptMap |

**Kural:** Kanca hiçbir zaman 3 saniyeyi geçmez ve **atlanabilir**. Tekrar oynayan oyuncu aynı kancayı ikinci kez izlemek zorunda kalmamalı.

**Kabul ölçütü:** Her mekanik için en az bir kanca tanımlı. Kanca süresi ölçülüyor ve 3 sn sınırı testle korunuyor.

---

## 1.3 — MICRO TUTORIAL — metin duvarını yıkmak

**Sorun:** `MissionChrome.swift` içindeki `MissionIntro`, `techniqueExplanation` ve `techniqueScience` metinlerini bir arada gösteriyor. Bunlar iyi yazılmış ama uzun. Spec'in değişmez kuralı: **NO long tutorial walls.**

**Yapılacak:**

- Yeni mekanik tanıtımı: **3–5 saniyelik gösterim + tek cümle.**
- Gösterim öncelik sırası: hareket → ses → tek cümlelik altyazı. Metin en son çare.
- Mevcut uzun metinler silinmez, **"Nasıl çalışır?" katlanır bölümüne taşınır.** İsteyen okur. Varsayılan kapalı.
- `techniqueScience` aynı şekilde "Arkasındaki araştırma" altına iner.
- Aynı mekanik ikinci kez geldiğinde tutorial **hiç gösterilmez** — sadece kanca ve oyun. Bu tek başına tekrar hissini belirgin biçimde azaltır.

**Kabul ölçütü:** Bir levele girişten ilk etkileşime kadar geçen süre **5 saniyenin altında.** Tanıdık mekanikte 3 saniyenin altında.

**Not:** Videolu mikro anlatım Faz 3'ün işi. Bu fazda gösterim SwiftUI animasyonuyla yapılır — asset hattı beklenmez.

---

## 1.4 — CHALLENGE — level içinde tempo yükselmesi

**Bu maddenin sıkılmaya etkisi en büyük olanı, ve şu an kodda hiç karşılığı yok.**

**Sorun:** `GameStore.adapted(_:)` zorluğu level başlarken bir kez ayarlıyor. Level boyunca hiçbir şey değişmiyor. Oyuncu ilk sorudan son soruya kadar aynı bilişsel yükü taşıyor — ki bu, kolay geldiğinde can sıkıcı, zor geldiğinde yıldırıcı.

**Yapılacak:** Level içinde kademeli yükselme. Üç kaldıraç, mekaniğe göre seçilir:

| Kaldıraç | Örnek |
|---|---|
| Destek azaltma | İlk sorularda 4 şık, sonrakilerde 3, sonda 2 |
| Tempo | Çalışma süresi soru başına kısalır |
| Yük | Son turda iki öğe birden sorulur |

**Kritik kural:** Yükselme **başarıya bağlı** olmalı, süreye değil. Zorlanan oyuncuyu hızlandırmak spec'in "utandırmadan tekrar" ilkesine aykırı. Art arda iki hata → yükselme durur, hatta bir kademe geri iner.

**Kabul ölçütü:** Bir levelin ilk ve son sorusu ölçülebilir biçimde farklı zorlukta. Zorlanan oyuncuda yükselme tetiklenmiyor — testle korunuyor.

---

## 1.5 — REWARD — başarının hissedilmesi

**Sorun:** Bugün ödül `ConfettiView` + özet kartı. Doğru cevap ile yanlış cevap arasındaki his farkı zayıf.

**Yapılacak:**

- **Combo / streak geri bildirimi:** Art arda doğrularda büyüyen görsel ve işitsel yanıt. Kesildiğinde ceza yok, sadece sıfırlama.
- **Anlık tepki:** Her doğru cevapta tatmin edici bir tepki — mevcut `SparkBurst` ve `Symbol3DTile.celebrate` altyapısı zaten var, yeterince kullanılmıyor.
- **Değişken ödül:** Her doğru cevapta aynı animasyon değil. Üç–dört varyant arasında dönüşüm, arada bir daha büyük bir tepki. Sabit ödül üç oturumda görünmez hale gelir.
- **Geçiş animasyonları:** Faz değişimlerinde süreklilik hissi. `MissionScaffold` bunu tek yerden verir.
- **Kapanış:** Level sonu "bitti" değil "kazandın" hissi vermeli; XP ve Memory Score sayaçları anında değil **sayarak** dolmalı.

**Kabul ölçütü:** Doğru ve yanlış cevap, sesli/görsel olarak ilk saniyede ayırt edilebiliyor. Ardışık başarı görsel olarak birikiyor.

**Sınır:** `reduceMotion` açıkken tüm bunlar sade karşılıklarına düşer. Mevcut kod bu kontrolü zaten her yerde yapıyor; bozmayın.

---

## 1.6 — Oturum temposu ve durma noktası

- Hedef oturum uzunluğu: **Child ≤ 3 dk, Teen ≤ 4 dk, Adult ≤ 5 dk.** Bir level bu süreyi aşıyorsa `questionCount` fazladır.
- Her level sonunda **net bir durma noktası.** Spec §2: "manageable choices, milestones, clear stopping point."
- "Bir tane daha" teklifi olsun ama zorlamasın; kapatmak tek dokunuş olmalı.

---

## Dokunulacak dosyalar

```
YENİ    Game/MissionFlow.swift            ortak protokol + faz enum'u
YENİ    Views/MissionScaffold.swift       fazları saran tek görünüm
YENİ    Views/MissionHook.swift           kanca kalıpları
DEĞİŞİR Views/MissionChrome.swift         MissionIntro → mikro anlatım + katlanır detay
DEĞİŞİR Game/*Session.swift (12)          iskelete taşınır, birer birer
DEĞİŞİR Views/*MissionView.swift (12)     scaffold'a taşınır, birer birer
DEĞİŞİR Game/GameStore.swift              SADECE level içi zorluk için; Snapshot'a dokunma
```

⚠️ **`GameStore.Snapshot` şeması değişmeyecek.** Level içi yükselme oturum içinde yaşar, kaydedilmez. Yeni alan gerekirse `Optional` olarak eklenir, mevcut alan silinmez.

---

## Bu faz bittiğinde

Oyun bugünkü içerikle, bugünkü 12 mekanikle, **belirgin biçimde daha az sıkıcı.** Hiçbir yeni level yazılmadı, hiçbir asset üretilmedi, hiçbir mekanik değişmedi.

Bu faz tek başına yayınlanabilir bir iyileştirmedir. Faz 2 ve 3 gecikse bile değeri durur.

## Kalite kapısı

- [ ] Levele girişten ilk etkileşime < 5 sn (tanıdık mekanikte < 3 sn)
- [ ] Bir levelin ilk ve son sorusu farklı zorlukta
- [ ] Zorlanan oyuncuda tempo yükselmiyor
- [ ] Ardışık doğrularda görsel birikim var
- [ ] `reduceMotion` açıkken her şey sade ve çalışır
- [ ] Mevcut 23 test + yeni testler geçiyor
- [ ] Oyuncu ilerlemesi kayıpsız (eski kayıtla açılıp devam edilebiliyor)
