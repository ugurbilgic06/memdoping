# MemDoping — Teknik Araştırması ve Mekanik Tasarımı Özeti

Bu doküman, [MemDoping_Master_Project.md](../MemDoping_Master_Project.md) §3'te listelenen 13 hafıza tekniğinin her biri için yapılan araştırmanın ve oyun mekaniği tasarımının özetidir. Her teknik için ayrıntılı dosya `docs/techniques/` altında bulunur.

**Durum:** Bu, §3'ün istediği `[RESEARCH REQUIRED]` adımının tamamlanmış hâli — ama hâlâ **[EXPERT REVIEW]** ve kısmen **[AWAITING MATERIALS]** aşamasında (bkz. tablo). Mekanikler doğrudan uygulamaya alınmadan önce bir uzman (bilişsel psikolog/eğitim danışmanı) incelemesi ve dilbilim/Türkçe uyarlama kontrolü öneriliyor.

## Özet tablo

| ID | Teknik | Kanıt Gücü | Ana Kaynak(lar) | Oyun Mekaniği | Önkoşul |
|---|---|---|---|---|---|
| T01 | [Attention & Encoding](techniques/attention-encoding.md) | **GÜÇLÜ** | Craik & Lockhart 1972; Craik & Tulving 1975 | Derin Bakış | — |
| T02 | [Association & Imagery](techniques/association-imagery.md) | ORTA (koşullu) | Paivio 1971; Dunlosky et al. 2013 (düşük fayda) | Canlı Sahne | T01 |
| T03 | [Chunking](techniques/chunking.md) | GÜÇLÜ (temel bilim) / ölçülmemiş (eğitim tekniği) | Miller 1956; Cowan 2001 | Öbek Kur | — |
| T04 | [Retrieval Practice](techniques/retrieval-practice.md) | **GÜÇLÜ** | Roediger & Karpicke 2006; Dunlosky et al. 2013 (yüksek fayda) | Şimdi Sen Söyle | T01 |
| T05 | [Spaced Practice](techniques/spaced-practice.md) | **GÜÇLÜ** | Cepeda et al. 2006/2008; Dunlosky et al. 2013 (yüksek fayda) | Doping Zamanlayıcı (sistem katmanı) | T04 |
| T06 | [Interleaving](techniques/interleaving.md) | ORTA-GÜÇLÜ (büyüyen) | Taylor & Rohrer 2010; Rohrer et al. 2015; Dunlosky et al. 2013 (orta fayda) | Karışık Meydan | T04 + ≥2 tema |
| T07 | [Elaboration](techniques/elaboration.md) | ORTA | Pressley et al. 1987; Dunlosky et al. 2013 (orta fayda) | Neden Böyle? | T01 |
| T08 | [Story Linking](techniques/story-linking.md) | GÜÇLÜ etki / tek çalışma, replikasyon teyit edilmedi | Bower & Clark 1969 | Zincir Hikâye | T02 |
| T09 | [Method of Loci](techniques/method-of-loci.md) | **GÜÇLÜ** | Maguire et al. 2003; Dresler et al. 2017; Ondřej et al. 2025 (meta-analiz) | Hafıza Sarayı | T02, T08 |
| T10 | [Peg System](techniques/peg-system.md) | ORTA-ZAYIF (karışık) | Roediger 1980; peg-word çocuk çalışmaları | Askı Listesi | T09, T02 |
| T11 | [Number Systems](techniques/number-system.md) | **ZAYIF** (doğrudan kanıt bulunamadı) | Dolaylı: Miller 1956, Paivio 1971 | Şekil-Sayı Kod | T03, T02 |
| T12 | [Major System](techniques/major-system.md) | ORTA (tek RCT) | Number-consonant mnemonic RCT, 1997 (Experimental Aging Research) | Ses Kodu | T11, T03, T02 |
| T13 | [PAO](techniques/pao.md) | **ZAYIF-ORTA** (dolaylı/vaka-temelli) | Dolaylı: Miller 1956, Paivio 1971, Maguire 2003 (gözlemsel) | Kişi-Eylem-Nesne Kartı | T03, T02, T09, T12 |

**Dürüstlük notu:** Kanıt gücü sütunu her teknik dosyasındaki ayrıntılı gerekçeye dayanır. En sağlam üçlü — **Retrieval Practice, Spaced Practice, Attention & Encoding/Method of Loci** — onlarca yıllık, çok sayıda deney/meta-analizle desteklenir. En zayıf ikisi — **Number Systems ve PAO** — bu araştırma turunda bağımsız akademik kanıt bulunamadığı için işaretlendi; yayına almadan önce ek literatür taraması gerekiyor.

## Bağımlılık ağacı

```
T01 Attention & Encoding (temel, önkoşulsuz)
├── T02 Association & Imagery
│   ├── T07 Elaboration
│   ├── T08 Story Linking
│   │   └── T09 Method of Loci ─┐
│   │         └── T10 Peg System │
│   │               └── T11 Number Systems ──┐
│   │                     └── T12 Major System │
│   │                           └── T13 PAO ◄──┘  (T13, T09 ve T12'yi de gerektirir)
│   └── (T09, T13 T02'yi de doğrudan kullanır)
├── T04 Retrieval Practice
│   └── T05 Spaced Practice (sistem katmanı — tüm ladder'ı keser)
│         └── T06 Interleaving (+ en az 2 farklı tema/teknik önce öğrenilmiş olmalı)
└── T03 Chunking (bağımsız; T02 ile birleşerek T11→T12→T13 zincirine girdi sağlar)
```

`T03 Chunking` ve `T04 Retrieval Practice` doğrudan `T01`'e bağlı değil ama onunla birlikte kullanıldığında güçlenir; ağaçta ayrı kollar olarak gösterildi çünkü kendi başlarına da çalışabilirler.

## Öncelik sırası (uygulama/level tasarımı için önerilen sıra)

Master dokümanın §3'teki 5 aşamalı tasarım modeliyle hizalı:

1. **Aşama 1 — Orientation (temel):** T01 Attention & Encoding. Tek kural, yüksek rehberlik.
2. **Aşama 2 — Tek teknik, azalan ipucu:** T03 Chunking, T04 Retrieval Practice. İkisi de bağımsız, güçlü kanıtlı, basit mekanikler.
3. **Aşama 3 — Artan karmaşıklık + gecikmeli hatırlama:** T05 Spaced Practice. Bu bir "level" değil, tüm ladder'ı kesen bir **sistem katmanı** olarak inşa edilmeli (bkz. `GameStore` genişletmesi).
4. **Aşama 4 — Teknikleri birleştirme, karışık bağlam:** T02 Association & Imagery, T06 Interleaving, T07 Elaboration, T08 Story Linking.
5. **Aşama 5 — Bağımsız strateji, kümülatif görevler:** T09 Method of Loci → T10 Peg System → T11 Number Systems → T12 Major System → T13 PAO (kanıt gücü azalan, karmaşıklık artan sıra — en sağlam ve en basit önce, en spekülatif ve en karmaşık en son).

**Kısa vadeli öneri:** İlk üretim turunda T01, T03, T04, T05 (sistem katmanı) ve T09'u (en güçlü kanıtlı mnemonik sistem) tamamlamak, geri kalan 8 tekniği ikinci dalgaya bırakmak — bu, hem kanıt gücünü hem de master dokümanın "önce doğrula, sonra genişlet" ilkesini (§11) karşılar.

## Tamamlanmamış / ek çalışma gerektiren noktalar

- **T11 (Number Systems) ve T13 (PAO):** Doğrudan akademik kanıt bulunamadı — [AWAITING MATERIALS]. Yayın öncesi ek literatür taraması ve mümkünse bir bilişsel psikoloji danışmanının görüşü gerekiyor.
- **T08 (Story Linking):** Tek kaynak (Bower & Clark, 1969); bağımsız güncel replikasyon bulunamadı — [AWAITING MATERIALS].
- **T12 (Major System):** Tek RCT'nin yazar isimleri bu oturumda teyit edilemedi (PubMed sayfası tam meta veri döndürmedi) — [AWAITING MATERIALS: bibliyografya teyidi].
- **Türkçeleştirme:** T12 (Major System) özellikle — rakam-ses eşlemesi İngilizce fonetiğe göre kurulmuş, Türkçe için ayrıca tasarlanmalı [EXPERT REVIEW].
- **Telif:** Hiçbir kaynağın tam metni oyun içine kopyalanmadı/kopyalanmamalı; tüm mekanikler bulguların *özgün oyunlaştırılmış yorumu*. Bazı "ücretsiz PDF" bağlantıları bu oturumda erişim/sertifika sorunları nedeniyle doğrulanamadı — kullanım öncesi manuel teyit önerilir.
- **Yaş/dil uyarlaması:** Hiçbir mekanik için henüz çocuk/genç/yetişkin ayrımına göre ayrıntılı zorluk kalibrasyonu yapılmadı — bu, pilot testlerle belirlenmesi gereken bir sonraki adım (§7).

## Sonraki adım

Bu doküman onaylandıktan sonra sıradaki iş: **Aşama A**'ya (gerçek oyun motoru — ses/haptik/animasyon) dönmek ve ardından T01/T03/T04/T05/T09'u ilk üretim dalgası olarak `Content.swift`/`GameStore.swift` şemasına uygulamak.
