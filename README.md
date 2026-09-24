# FSR — RX 6700 XT için güvenliği incelenmiş OptiScaler

Bu depo, açık kaynak **[OptiScaler](https://github.com/optiscaler/OptiScaler)** projesinin (GPL-3.0) kararlı
**v0.9.4** sürümünün, **güvenlik incelemesinden geçirilmiş ve açıkları kapatılmış** bir kopyasıdır.

OptiScaler, oyunlardaki DLSS / XeSS / FSR 2-3 girdilerini yakalayıp kendi seçtiğiniz ölçekleyiciyle
(FSR 3.1, FSR 4, XeSS …) değiştirir. Böylece **RX 6700 XT (RDNA2)** gibi kartlarda, oyun yalnızca DLSS desteklese bile
FSR kullanabilir, hatta (resmî olmayan yoldan) **FSR 4** deneyebilirsiniz.

- 🔒 **Güvenlik raporu:** [SECURITY_AUDIT.md](SECURITY_AUDIT.md) — ne incelendi, ne bulundu, ne düzeltildi
- 📄 **Orijinal İngilizce README:** [README.upstream.md](README.upstream.md)
- ⚙️ **Tüm ayarlar (İngilizce):** [Config.md](Config.md), [OptiScaler.ini](OptiScaler.ini)

> [!CAUTION]
> **ÇEVRİM İÇİ / ÇOK OYUNCULU OYUNLARDA KULLANMAYIN.** Hile karşıtı sistemler (EAC, BattlEye, Vanguard …)
> OptiScaler'ı hile olarak algılayıp **hesabınızı banlayabilir.** Yalnızca tek oyunculu oyunlarda kullanın.

---

## İçindekiler
1. [Bu sürümde neler farklı?](#1-bu-sürümde-neler-farklı)
2. [RX 6700 XT'de FSR 4 — bilmeniz gerekenler](#2-rx-6700-xtde-fsr-4--bilmeniz-gerekenler)
3. [Paketi indirme](#3-paketi-indirme)
4. [Oyuna kurulum (adım adım)](#4-oyuna-kurulum-adım-adım)
5. [Oyun içinde kullanım](#5-oyun-içinde-kullanım)
6. [İsteğe bağlı: FSR 4 INT8 (resmî değil)](#6-isteğe-bağlı-fsr-4-int8-resmî-değil)
7. [Önerilen ayarlar](#7-önerilen-ayarlar-rx-6700-xt)
8. [Kaldırma](#8-kaldırma)
9. [Sorun giderme](#9-sorun-giderme)
10. [Linux / Steam Deck](#10-linux)
11. [Kendi bilgisayarında derleme](#11-kendi-bilgisayarında-derleme)
12. [Lisans ve teşekkür](#12-lisans-ve-teşekkür)

---

## 1. Bu sürümde neler farklı?

Upstream OptiScaler v0.9.4'e göre yapılan güvenlik düzeltmeleri (ayrıntı: [SECURITY_AUDIT.md](SECURITY_AUDIT.md)):

| # | Sorun | Durum |
|---|---|---|
| 1 | `SpoofedGPUName` ayarında **bellek taşması** (buffer overflow) | ✅ Düzeltildi |
| 2 | Güncelleme kontrolünde internetten gelen URL'nin **doğrulanmadan açılması** | ✅ Düzeltildi + güncelleme kontrolü varsayılan **kapalı** |
| 3 | `*-original.dll` dosyasının `PATH`/çalışma dizininden yüklenebilmesi (**DLL ele geçirme**) | ✅ Düzeltildi |
| 4 | Eklenti klasörünün çalışma dizinine göre çözülmesi | ✅ Düzeltildi |
| 5 | Kurulum betiğinin **doğrulamasız dosya indirip** kod yüklemeyi açması | ✅ Kaldırıldı |
| 6 | CI: otomatik sürüm yayını, sabitlenmemiş eylemler | ✅ Salt okunur, SHA-sabitli, imza kontrollü derleme |

Ayrıca: kötü amaçlı kod **bulunmadı**; depodaki tüm Microsoft araçları ve paketlenen tüm AMD/Intel DLL'leri
**üretici imzalı** olarak doğrulandı.

---

## 2. RX 6700 XT'de FSR 4 — bilmeniz gerekenler

AMD, FSR 4'ü resmî olarak yalnızca RX 7000/9000 kartlarda destekliyor (FSR 4.1'in RDNA2'ye **2027 başında**
geleceğini açıkladı). RX 6700 XT için üç seçeneğiniz var:

| | **A) FSR 3.1** (varsayılan) | **B) FSR 4.1.1 INT8 — AMD imzalı DLL** | **C) FSR 4.0.2c INT8 — topluluk DLL'i** |
|---|---|---|---|
| Ek dosya gerekir mi? | Hayır | Hayır (pakette var) | **Evet**, ayrıca edinilir |
| Dosya kimden? | AMD, imzalı | AMD, imzalı | Topluluk, **imzasız** |
| Nasıl açılır? | Kutudan çıktığı gibi | `Fsr4ForceEnableInt8=true` | DLL değiştirme + ayar |
| Görüntü kalitesi | İyi | Daha iyi, ama RDNA2'de **gölgelenme (ghosting)** olabilir* | Daha iyi, RDNA2 için önerilen |
| Performans maliyeti | Düşük | **Yüksek** | **Yüksek** |
| Güvenlik | ✅ Doğrulandı | ✅ Dosya doğrulandı; OptiScaler AMD'nin GPU kontrolünü bellekte atlatır | ⚠️ Doğrulanamaz |

\* OptiScaler v0.9.4 sürüm notlarına göre Windows'taki bir AMD sürücü derleyici gerilemesi, 4.1.1 INT8'de RDNA2'de
gölgelenmeye yol açıyor ve RDNA2 için şimdilik 4.0.2c öneriliyor.

**Önerim:** Önce **A** ile başlayın. FSR 4 denemek isterseniz önce **B**'yi deneyin (ek indirme yok, dosyalar AMD imzalı).
Gölgelenme sizi rahatsız ederse ve riskleri kabul ediyorsanız **C**'ye bakın. Ayrıntılar [6. bölüm](#6-isteğe-bağlı-fsr-4-int8-resmî-değil)de.

> Adrenalin'deki "AMD FSR 4 Upscaling" anahtarı yalnızca RX 7000/9000 kartlarda çıkar; RX 6700 XT'de görünmemesi normaldir.

---

## 3. Paketi indirme

Paket, bu deponun kendi kaynak kodundan GitHub Actions ile otomatik derlenir (dışarıdan hazır DLL indirilmez).

1. Bu depoda **Actions** sekmesine gidin → soldan **Build** iş akışını seçin.
2. En üstteki **yeşil tikli (✅)** çalıştırmaya tıklayın.
   - Hiç çalıştırma yoksa veya yenisini istiyorsanız: **Run workflow** → **Run workflow** (yalnızca `main` dalında görünür).
3. Sayfanın altındaki **Artifacts** bölümünden `OptiScaler_v0.9.4_secure_xxxxxxx.zip` dosyasını indirin.
4. **(Önerilir) Özeti doğrulayın:** Aynı sayfadaki özet (Summary) bölümünde `ZIP SHA256` değeri yazar.
   PowerShell'de:
   ```powershell
   Get-FileHash .\OptiScaler_v0.9.4_secure_xxxxxxx.zip -Algorithm SHA256
   ```
   Çıkan değer Summary'deki ile **aynı** olmalı.

Paket içeriği:
```
OptiScaler.dll                          ← asıl mod (kurulumda dxgi.dll vb. olarak yeniden adlandırılır)
OptiScaler.ini                          ← ayar dosyası (adını DEĞİŞTİRMEYİN)
setup_windows.bat / setup_linux.sh      ← kurulum betikleri
amd_fidelityfx_*.dll                    ← AMD FSR 3.1 / FSR SDK (AMD imzalı)
libxess*.dll, libxell.dll               ← Intel XeSS (Intel imzalı)
D3D12_Optiscaler\D3D12Core.dll          ← Windows 10 için Agility SDK (Microsoft imzalı)
Licenses\                               ← lisanslar
SHA256SUMS.txt                          ← her dosyanın özeti
```

---

## 4. Oyuna kurulum (adım adım)

**Gereksinimler:** Windows 10/11, güncel AMD Adrenalin sürücüsü, **DLSS, XeSS veya FSR 2/3** destekleyen bir oyun.
En iyi sonuç **DirectX 12** oyunlarında alınır.

### 4.1 Oyunun `.exe` klasörünü bulun
Steam'de: oyuna sağ tık → **Yönet** → **Yerel dosyalara göz at**.

- Normal oyunlar: ana `.exe` dosyasının olduğu klasör. Örnekler: `Cyberpunk 2077\bin\x64`, `HITMAN 3\Retail`
- **Unreal Engine** oyunları: `OyunAdı\Binaries\Win64` (içinde `...-Win64-Shipping.exe` olan klasör).
  **`Engine` klasörüne KURMAYIN.** Örnek: `Expedition 33\Sandfall\Binaries\Win64`

### 4.2 Dosyaları çıkarın
ZIP içindeki **tüm dosyaları** bu klasöre çıkarın (klasör yapısını bozmadan).

### 4.3 Kurulum betiğini çalıştırın
`setup_windows.bat` dosyasına çift tıklayın ve soruları yanıtlayın:

1. **Dosya adı:** `1` (**dxgi.dll**, önerilen) → Enter.
   Oyun açılmazsa sonra `winmm.dll` (Vulkan oyunları için), `version.dll` veya `d3d12.dll` deneyin.
2. **GPU:** `1` (**AMD/Intel**)
3. **DLSS girdileri kullanılsın mı?**
   - Oyun **DLSS** destekliyorsa → `1` (**Evet**). OptiScaler kartınızı oyuna NVIDIA gibi gösterir ki DLSS
     seçeneği açılsın; siz DLSS'i seçersiniz, OptiScaler arkada FSR çalıştırır. (En iyi kalite genelde bu yolla alınır.)
   - Oyunda zaten **FSR 3.1/XeSS** varsa ve onu kullanacaksanız → `2` (**Hayır**).

Betik bittiğinde `OptiScaler.dll` → `dxgi.dll` olarak yeniden adlandırılır ve kaldırma için
`Remove_OptiScaler.bat` oluşturulur.

> Elle kurulum: `OptiScaler.dll` dosyasının adını `dxgi.dll` yapmanız yeterlidir. `OptiScaler.ini` adını değiştirmeyin.

### 4.4 Windows 10 kullanıyorsanız
FSR 4 / yeni FSR bazı oyunlarda Windows 10'da çökebilir. Çözüm:
- `D3D12_Optiscaler` klasörünün oyun `.exe`'sinin yanında olduğundan emin olun,
- `OptiScaler.ini` içinde `FsrAgilitySDKUpgrade=true` yapın.

---

## 5. Oyun içinde kullanım

1. Oyunu açın, grafik ayarlarından ölçekleyici olarak **DLSS** (spoofing açıksa) veya **FSR 3.1 / XeSS** seçin.
2. Oyun içindeyken **`Insert`** tuşuna basın → OptiScaler menüsü açılır.
   (Açılmazsa `Alt + Insert` deneyin. Fare çalışmazsa ok tuşları, Tab ve Space ile gezinin.)
3. **Upscaler** listesinden seçin:
   - **DirectX 12 oyunları:** `FSR 3.X/4`
   - **DirectX 11 / Vulkan oyunları:** `FSR 3.X/4 w/Dx12`
4. **FSR** sürümünü (backend) menüden seçebilirsiniz; RX 6700 XT'de varsayılan **FSR 3.1.5**'tir.
5. Menüdeki **Sharpness / RCAS** ile keskinliği ayarlayın.
6. **`Page Up`** → FPS / performans göstergesi, **`Page Down`** → gösterge tipini değiştir.
7. Menüde **Save INI** ile ayarları kaydedin.

---

## 6. İsteğe bağlı: FSR 4 INT8 (resmî değil)

Her iki yol da AMD tarafından RX 6000 için **desteklenmez**; oyunda hata/görüntü bozulması olursa ayarı geri alın.
FSR 4 INT8, RX 6700 XT'de FSR 3.1'den belirgin şekilde daha fazla GPU süresi harcar — FPS düşerse bir alt kalite
kademesine (ör. Quality → Balanced) geçin. FSR 4, **Ultra Quality** kademesini resmî desteklemez.

> OptiScaler v0.9.4 notu: `Fsr4Update=` ayarına **dokunmayın** — desteklenmeyen kartta `true` yapmak FSR 3'e geri düşürür.

### B) AMD imzalı FSR 4.1.1 + `Fsr4ForceEnableInt8` (önerilen FSR 4 yolu)

Pakette zaten bulunan `amd_fidelityfx_upscaler_dx12.dll` AMD'nin resmî FSR 4.1.1 dosyasıdır ve INT8 modelini içerir;
ancak içindeki bir kontrol RDNA2'de bu modeli kapatır. Bu ayar, OptiScaler'ın o kontrolü **bellekte** atlatmasını
sağlar (diskteki AMD dosyası değişmez, imzası bozulmaz).

1. `OptiScaler.ini` içinde:
   ```ini
   Fsr4ForceEnableInt8=true
   Fsr4EnableWatermark=true
   ```
2. Oyunu açın, Insert menüsünde upscaler olarak `FSR 3.X/4` (DX11/Vulkan'da `FSR 3.X/4 w/Dx12`) seçin ve
   FSR sürümü olarak **4.x**'i seçin.
3. Ekrandaki filigran (watermark) **FSR4 / INT8** gösteriyorsa çalışıyor; **FSR3** gösteriyorsa geri düşmüştür.
4. Çalıştığını gördükten sonra `Fsr4EnableWatermark=false` yapın.
5. Geri almak için: `Fsr4ForceEnableInt8=auto`.

### C) Topluluk FSR 4.0.2c INT8 DLL'i (yalnızca riskleri kabul ediyorsanız)

> [!WARNING]
> Bu dosya **AMD tarafından RDNA2 için yayımlanmamıştır**, sızdırılmış AMD kaynak kodundan topluluk tarafından
> derlenmiştir, **dijital imzası yoktur** ve lisans durumu belirsizdir. Bu nedenle bu depoya **eklenmemiştir**.
> Kullanmak tamamen sizin sorumluluğunuzdadır.

1. INT8 `amd_fidelityfx_upscaler_dx12.dll` (4.0.2c) dosyasını **yalnızca** OptiScaler'ın resmî kanallarında
   (GitHub sürüm notlarındaki bağlantılar / resmî Discord) paylaşılan kaynaktan indirin. Rastgele sitelerden,
   YouTube açıklamalarından veya "tek tık kurulum" araçlarından **indirmeyin**.
2. İndirdiğiniz dosyayı kontrol edin:
   - [VirusTotal](https://www.virustotal.com)'e yükleyin.
   - Kaynağında SHA256 özeti verildiyse `Get-FileHash dosya.dll -Algorithm SHA256` ile karşılaştırın.
   - Dosyanın bir `.dll` olduğundan emin olun (`.exe`, `.bat`, `.scr` ise **açmayın**).
3. Oyun klasöründeki mevcut `amd_fidelityfx_upscaler_dx12.dll` dosyasının **yedeğini alın**
   (ör. `amd_fidelityfx_upscaler_dx12.dll.bak`), sonra yeni dosyayı yerine koyun.
4. B yolundaki 1–4. adımları uygulayın (filigranda **FSR4 / INT8** görmelisiniz).
5. Sorun olursa yedeği geri koyup `Fsr4ForceEnableInt8=auto` yapın.

---

## 7. Önerilen ayarlar (RX 6700 XT)

| Çözünürlük | FSR 3.1 | FSR 4 INT8 |
|---|---|---|
| 1080p | Quality | Quality (ağır oyunlarda Balanced) |
| 1440p | Quality / Balanced | Balanced / Performance |
| 4K | Performance | Performance / Ultra Performance |

Diğer ipuçları:
- **Güncelleme kontrolü** bu sürümde kapalıdır. Açmak isterseniz `CheckForUpdate=true`.
- **ASI eklentileri** kapalıdır (`LoadAsiPlugins=auto` = kapalı). Güvenmediğiniz `.asi` dosyalarını `plugins` klasörüne koymayın.
- MSI Afterburner / RTSS kullanıyorsanız RTSS ayarlarında **"Use Microsoft Detours API hooking"** seçeneğini açın.
- Görüntü sorunlarında menüdeki **Non-Linear** (renk uzayı) seçeneklerini deneyin.
- Log almak için: `LogLevel=0` ve `LogToFile=true` → `OptiScaler.log` oluşur.

---

## 8. Kaldırma

Oyun klasöründeki `Remove_OptiScaler.bat` dosyasını çalıştırıp `1` seçin. Elle kaldırmak için
`dxgi.dll` (veya seçtiğiniz ad), `OptiScaler.ini`, `OptiScaler.log`, `amd_fidelityfx_*.dll`, `libxess*.dll`,
`libxell.dll`, `D3D12_Optiscaler`, `Licenses` dosya/klasörlerini silin. Steam'de **Oyun dosyalarının bütünlüğünü
doğrula** ile oyunun kendi dosyaları geri yüklenir.

---

## 9. Sorun giderme

| Belirti | Çözüm |
|---|---|
| Insert'e basınca menü açılmıyor | Dosyaların `.exe` yanında olduğundan emin olun; `dxgi.dll` yerine `winmm.dll` / `version.dll` / `d3d12.dll` deneyin. |
| Oyun açılışta çöküyor | Başka bir dosya adı deneyin; ReShade / SpecialK varsa geçici kapatın; Windows 10'da `FsrAgilitySDKUpgrade=true`. |
| Oyunda DLSS seçeneği görünmüyor | Kurulumda DLSS sorusuna **Evet** deyin (`Dxgi=auto`). Bazı oyunlar ayrıca [fakenvapi](https://github.com/FakeMichau/fakenvapi) ister (bu pakete dahil değildir). |
| FSR 4 filigranı "FSR3" diyor | `Fsr4ForceEnableInt8=true` yapıldı mı, menüde FSR 4.x seçili mi kontrol edin; C yolunda DLL doğru klasörde mi bakın ([6. bölüm](#6-isteğe-bağlı-fsr-4-int8-resmî-değil)). |
| FSR 4'te gölgelenme (ghosting) | RDNA2'de 4.1.1 INT8 ile bilinen sorun; güncel Adrenalin sürücüsü kurun, olmazsa FSR 3.1'e dönün (veya riskleri kabul ederek C yolu). |
| SmartScreen uyarısı | Kendi derlemeniz imzasızdır, bu normaldir. Özeti [3. bölüm](#3-paketi-indirme)deki gibi doğrulayın. |

Oyun bazlı bilinen sorunlar ve çözümler için: [OptiScaler Uyumluluk Listesi](https://github.com/optiscaler/OptiScaler/wiki/Compatibility-List)

---

## 10. Linux

1. Dosyaları oyun klasörüne çıkarın, terminalde `./setup_linux.sh` çalıştırın.
2. Steam başlatma seçeneklerine ekleyin: `WINEDLLOVERRIDES=dxgi=n,b %COMMAND%`
   (seçtiğiniz dosya adı neyse onu yazın).
3. Vulkan oyunlarında `FSR 3.X/4 w/Dx12` için **Proton 11+** gerekir.

---

## 11. Kendi bilgisayarında derleme

Gereksinim: **Visual Studio 2022** (C++ masaüstü geliştirme iş yükü).

```powershell
git clone --recurse-submodules https://github.com/Holiflot/fsr.git
cd fsr
msbuild /m /p:Configuration=Release .
```
Çıktı: `x64\Release\a\` klasörü.

### Upstream'den güncelleme
Yeni bir OptiScaler sürümü çıktığında:
1. Yeni sürümü indirip bu depoyla karşılaştırın (`git diff`).
2. [SECURITY_AUDIT.md](SECURITY_AUDIT.md) → "Upstream'i güncellerken" bölümündeki kontrolleri tekrarlayın.
3. Bu depodaki 6 güvenlik düzeltmesini yeni sürüme yeniden uygulayın.

---

## 12. Lisans ve teşekkür

- OptiScaler **GPL-3.0** lisanslıdır ([LICENSE](LICENSE)). Bu depo değiştirilmiş bir sürümdür; değişiklikler
  [SECURITY_AUDIT.md](SECURITY_AUDIT.md) dosyasında ve git geçmişinde listelenmiştir.
- Orijinal proje ve tüm emek: [OptiScaler ekibi ve katkıcıları](https://github.com/optiscaler/OptiScaler).
- AMD FidelityFX / FSR (MIT), Intel XeSS, Microsoft DirectX Agility SDK, FreeType ve diğer bileşenlerin lisansları
  paketteki `Licenses` klasöründedir.
- Bu depo AMD, NVIDIA, Intel veya OptiScaler ekibiyle bağlantılı değildir.
