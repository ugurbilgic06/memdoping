# MemDoping — Deneme Logo/App Icon Notları

Durum: **DENEME** — bu, uygulamaya gerçekten işletilmiş ama nihai olmayan bir App Icon. Beğenilmezse aşağıdaki adımlarla kolayca değiştirilebilir.

## Tasarım kısıtları (MemDoping_Master_Project.md §1'den)

- İsim uyumu: "Mem" (hafıza) + "Doping" (motive edici bir "boost/güçlendirme" metaforu — ilaç/tıbbi tedavi çağrışımı **değil**).
- §1: "The name does not imply drugs, medical treatment, or biological enhancement." → **Şırınga, hap, tıbbi haç gibi hiçbir sembol kullanılmadı.** "Doping" fikri evrensel bir "enerji/güç artışı" sembolü olan **yıldırım/bolt** ile temsil edildi (spor/oyun markalarında yaygın, zararsız bir görsel dil).
- Hedef kitle çocuk-genç-yetişkin (§1) → sade, yuvarlak hatlı, oyun havasında, korkutucu/klinik olmayan bir görsel dil tercih edildi.
- Küçük boyutta (App Store/ana ekran, ~60-120px) okunaklı olma zorunluluğu (Apple HIG) → üç konsept de 120px'de test edildi.

## Renk paleti

| Rol | Renk | Hex |
|---|---|---|
| Arka plan (koyu uç) | Derin indigo/mor | `#4C1D95` / `#4338CA` / `#3B0764` (konsepte göre değişir) |
| Arka plan (açık uç) | Canlı mor | `#6D28D9` / `#7C3AED` |
| Vurgu / "doping" enerjisi | Sıcak sarı-amber | `#FFC93C` |
| Ön plan / kontrast | Kırık beyaz | `#F5F3FF` |

**Neden mor+sarı:** Mor, hafıza/bilişsel gelişim uygulamalarında (Peak, Elevate gibi) sık kullanılan, "zihin/odak" çağrışımı yapan, klinik olmayan bir renk. Sarı-amber ise yüksek kontrastla "enerji/boost" hissini taşıyor ve mor üzerinde küçük boyutta bile göz alıcı kalıyor. İkisi birlikte "ciddi ama oyunsu" bir denge kuruyor — tıbbi (beyaz/yeşil/mavi-klinik) değil, oyunsu (canlı, kontrast) bir palet.

## Üç konsept

### Konsept A — "Beyin + Yıldırım" — **SEÇİLEN**
`concept-a-brain-bolt.svg` / `.png`

Yuvarlak, bulut benzeri bir beyin silüeti (üst üste binen aynı renkli dairelerden oluşan, dikişsiz bir "brain cloud") üzerinden geçen sarı bir yıldırım. Beyin = "Mem" (hafıza), yıldırım = "Doping" (enerji/boost). En doğrudan ve en okunaklı kavram eşleşmesi; 120px'de bile hem bulut/beyin hem yıldırım net seçiliyor.

**Neden seçildi:** İsimle en dolaysız/gösterge-değeri en yüksek eşleşme (metafor için ekstra açıklama gerektirmiyor), küçük boyutta net, oyunsu ve yuvarlak hatları çocuk-yetişkin geniş kitleye uygun, hiçbir tıbbi/ilaç çağrışımı yok.

### Konsept B — "M-Bolt Monogram"
`concept-b-m-bolt.svg` / `.png`

Kalın, yuvarlak köşeli bir "M" harfi (Mem/MemDoping'in baş harfi); harfin ortasındaki köşegen çizgiler bir yıldırım zikzağı gibi şekillendirilmiş. En sade/en yüksek ölçeklenebilirliğe sahip konsept (harfler küçük boyutta genelde en iyi okunur) ama "M" tek başına markaya özgü değil — birçok farklı uygulama da aynı harfle başlayabilir, kavramsal bağ (hafıza/doping) daha az doğrudan.

### Konsept C — "Neuron Spark"
`concept-c-neuron-spark.svg` / `.png`

Bir rozet/madalya halkası içinde, merkeze yakınsayan nöron/düğüm ağı ve ortada sarı bir enerji kıvılcımı — "sinir ağı + enerji" fikri, oyun içi başarı rozetlerine benzer bir estetik. En zayıf yönü: küçük boyutta (120px) düğüm-çizgi detayları görsel olarak karışıyor ve genel "yapay zeka/ağ" ikonografisine çok benziyor — MemDoping'e özgü bir imza bırakmıyor.

## Nasıl değiştirilir

1. Yeni bir konsept istiyorsanız: `docs/branding/*.svg` dosyalarından birini kopyalayıp düzenleyin (düz SVG, harici font/görsel bağımlılığı yok) veya sıfırdan yeni bir `.svg` yazın.
2. PNG'ye çevirin (1024×1024 yeterli, gerisini Xcode/sips ölçekler):
   ```
   rsvg-convert -w 1024 -h 1024 yeni-logo.svg -o yeni-logo-1024.png
   ```
   (`rsvg-convert` yoksa: `brew install librsvg`)
3. Yeni 1024 PNG'yi App Icon klasörüne kopyalayıp mac boyutlarını yeniden üretin:
   ```
   ICONSET=MemDoping/MemDoping/Assets.xcassets/AppIcon.appiconset
   cp yeni-logo-1024.png "$ICONSET/appicon-1024.png"
   sips -z 512 512 "$ICONSET/appicon-1024.png" --out "$ICONSET/appicon-512.png"
   sips -z 256 256 "$ICONSET/appicon-1024.png" --out "$ICONSET/appicon-256.png"
   sips -z 128 128 "$ICONSET/appicon-1024.png" --out "$ICONSET/appicon-128.png"
   sips -z 64 64   "$ICONSET/appicon-1024.png" --out "$ICONSET/appicon-64.png"
   sips -z 32 32   "$ICONSET/appicon-1024.png" --out "$ICONSET/appicon-32.png"
   sips -z 16 16   "$ICONSET/appicon-1024.png" --out "$ICONSET/appicon-16.png"
   ```
   `Contents.json` dosya adlarını değiştirmediğiniz sürece (hepsi `appicon-*.png` adında) tekrar düzenlemeye gerek yok — sadece dosyaların içeriğini değiştirmiş olursunuz.
4. Xcode'da temiz bir build alıp (Cmd+Shift+K, sonra Cmd+B) simülatörde ana ekranda ikonu kontrol edin.

## Bilinen sınırlamalar (dürüstlük notu)

- Bu bir **placeholder/deneme** logo — profesyonel bir marka tasarımcısı incelemesi, trademark taraması (Master doküman §1'de zaten belirtilen "trademark/legal review pending" şartı) ve gerçek App Store/Google Play boyut testleri yapılmadı.
- Işık/koyu/tint (dark/tinted) modları için ayrı sanat üretilmedi — üçü de aynı görseli kullanıyor; iOS 18+'ın otomatik tint/dark dönüşümü görsel kaliteyi garanti etmez, ayrı varyant tasarımı ileride gerekebilir.
- Adaptive/dinamik ikon (widget, Siri vb.) için ayrı katmanlı format (Icon Composer) hazırlanmadı.
