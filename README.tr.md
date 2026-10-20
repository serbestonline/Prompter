<p align="center">
  <img src="assets/icon.png" width="160" alt="Prompter simgesi">
</p>

<h1 align="center">Prompter</h1>

<p align="center">
  Kameranın hemen altında duran, macOS için sade ve hafif bir teleprompter.
</p>

<p align="center">
  <a href="README.md">English</a> · <b>Türkçe</b>
</p>

---

Kamerayla kayıt alırken metni okumak için yapıldı. Pencere ekranın üst ortasında, kameranın hemen altında açılır ve diğer pencerelerin üstünde kalır. Gözünüz kameradan fazla uzaklaşmadan metni okursunuz. Tek bir Swift/AppKit uygulamasıdır. Xcode projesi ya da başka bir bağımlılık gerektirmez.

## Özellikler

- **Her zaman üstte**: Kameranın altında, bütün masaüstlerinde ve tam ekran uygulamaların üstünde görünür.
- **Akıcı kaydırma**: Hız ayarlanabilir. Fare tekerleğiyle elle kaydırınca kaydırma bıraktığınız yerden devam eder.
- **Ayar çubuğu**: Fareyi pencerenin üzerine getirince altta açılır. Buradan şunlar ayarlanır:
  - arka plan rengi ve saydamlığı,
  - yazı rengi ve boyutu,
  - kaydırma hızı,
  - başlat/durdur ve dosya aç düğmeleri.
- **Yerinde düzenleme**: Metne tıklayınca imleç tıkladığınız yere gelir, doğrudan yazarsınız. Esc düzenlemeyi bitirir.
- **Metin yükleme**: `⌘V` ile panodan yapıştırabilir ya da `⌘O` ile `.txt`/`.md` dosyası açabilirsiniz.
- **Ayarlar kalıcı**: Metin, renkler, yazı boyutu, hız ve pencerenin yeri uygulamayı kapatıp açınca aynı kalır.

## Kurulum

### İndirerek (önerilen)

1. [Son sürüm sayfasından](https://github.com/serbestonline/Prompter/releases/latest) **`Prompter-<sürüm>.dmg`** dosyasını indirin.
2. Dosyayı açın ve **Prompter**'ı **Applications** (Uygulamalar) klasörüne sürükleyin.
3. Prompter'ı Uygulamalar klasöründen açın.

**macOS 13 veya üstü** gerekir. Hem Apple Silicon hem Intel Mac'lerde doğrudan çalışır.

> **İlk açılış:** Prompter Apple tarafından onaylanmadığı (notarize edilmediği) için macOS ilk açılışta uygulamayı doğrulayamadığını söyler. **Sistem Ayarları › Gizlilik ve Güvenlik** bölümünde aşağı kaydırıp **Yine de Aç**'a tıklayın. Bunu bir kez yapmanız yeterli.
> Ya da Terminal'de karantina işaretini kaldırın: `xattr -dr com.apple.quarantine /Applications/Prompter.app`

### Kaynaktan derleyerek

Gereksinimler: macOS 13 veya üstü ve Xcode Command Line Tools.

```bash
xcode-select --install          # Command Line Tools yüklü değilse

git clone https://github.com/serbestonline/Prompter.git
cd Prompter
./build.sh --install            # derler ve ~/Applications altına kurar
open ~/Applications/Prompter.app
```

| Komut | Sonuç |
|---|---|
| `./build.sh` | Apple Silicon + Intel için tek bir `build/Prompter.app` derler |
| `./build.sh --install` | Ayrıca `~/Applications` altına kurar |
| `./build.sh --dmg` | Ayrıca sürükle-bırak kurulumlu `build/Prompter-<sürüm>.dmg` üretir ([uv](https://docs.astral.sh/uv/) gerekir) |

Sürüm numarası `build.sh` dosyasının başında tanımlı.

## Kullanım

| Tuş | İşlev |
|---|---|
| `Space` | Başlat / durdur |
| `↑` `↓` | Hızı artır / azalt |
| `+` `−` | Yazıyı büyüt / küçült (Türkçe klavyede `*` da büyütür) |
| `←` `→` | Birkaç satır geri / ileri |
| `R` | Başa dön |
| `Esc` | Durdur / düzenlemeyi bitir |
| `⌘V` | Panodaki metni yükle (mevcut metnin yerine geçer) |
| `⌘O` | Metin dosyası aç |
| `⌘Q` | Çık |

Pencereyi üst kenarından tutup taşıyabilir, kenarlarından çekip boyutunu değiştirebilirsiniz.

Tüm ayarları sıfırlamak için:

```bash
defaults delete com.serbest.prompter
```

## Proje yapısı

```text
Sources/
├── main.swift          # uygulama, pencere, kaydırma, klavye ve düzenleme
├── ControlBar.swift    # fareyle açılan ayar çubuğu ve HoverView
├── MainMenu.swift      # düzenleme kısayolları için Düzen menüsü
└── ColorStore.swift    # renkleri UserDefaults'a yazar / okur
scripts/
├── make_icon.swift             # uygulama simgesini çizer (1024×1024 PNG)
├── make_dmg_background.swift   # DMG penceresinin arka planını çizer (1x + 2x)
└── dmg_settings.py             # dmgbuild için DMG pencere düzeni
assets/
└── icon.png
build.sh                        # derleme, simge, imzalama, kurma, DMG
```

## Bilinen sorunlar

- Renk paneli açıkken uygulama kapatılırsa, macOS paneli bir sonraki açılışta geri getirir. Panel açık olduğu sürece ayar çubuğu gizlenmez. Paneli kapatınca düzelir.

## Lisans

[MIT](LICENSE)
