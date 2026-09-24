# Güvenlik İncelemesi Raporu — OptiScaler v0.9.4

**İnceleme tarihi:** 24 Eylül 2026
**İncelenen kaynak:** [optiscaler/OptiScaler](https://github.com/optiscaler/OptiScaler), etiket `v0.9.4`
(commit `7534ad00bf9e590eedb99e8dd9fd8c89dae3654f`, 18 Temmuz 2026)
**Lisans:** GPL-3.0 (bkz. [LICENSE](LICENSE))

> Bu depo, OptiScaler'ın **değiştirilmiş** bir sürümüdür (GPL-3.0 madde 5a gereği bildirilir).
> Değişiklikler aşağıda "Kapatılan sorunlar" bölümünde listelenmiştir.

---

## Özet

| Sonuç | Açıklama |
|---|---|
| ✅ Kötü amaçlı kod | **Bulunmadı.** Veri çalma, gizli ağ trafiği, uzaktan komut, başka süreçlere kod enjeksiyonu, kayıt defteri değişikliği yok. |
| ✅ Hazır ikili dosyalar | Depodaki 6 Windows ikili dosyasının hepsi **geçerli Microsoft imzalı**; paketlenen AMD ve Intel DLL'lerinin hepsi **üretici imzalı**. |
| ✅ Alt modüller | 8 alt modülün hepsi resmî depolardaki (AMD, Intel, Khronos, …) gerçek commit'lere sabitlenmiş. |
| ⚠️ Bulunan açıklar | 1 bellek taşması, 1 doğrulanmamış URL açma, 2 DLL arama yolu sorunu, 1 doğrulamasız indirme, CI yapılandırma riskleri. **Hepsi bu depoda kapatıldı.** |
| ⚠️ Kalan riskler | Aşağıda "Kapatılamayan / tasarım gereği riskler" bölümünde. En önemlisi: **çevrim içi oyunlarda ban riski** ve **RDNA2 için FSR4 INT8 DLL'inin resmî olmaması**. |

---

## 1. Yöntem

1. **Kaynak seçimi:** RX 6000 (RDNA2) için FSR4 desteği veren açık kaynak proje araştırıldı. Tek ciddi ve etkin
   geliştirilen proje OptiScaler (GPL-3.0). En son **kararlı** sürüm (`v0.9.4`) temel alındı; gecelik (nightly)
   sürüm alınmadı.
2. **Birebir içe aktarma:** Tüm dosyaların git blob özetleri upstream ile karşılaştırıldı — **birebir aynı**
   (tek fark `README.md` → `README.upstream.md`). İlk commit değiştirilmemiş hâlidir, düzeltmeler ayrı commit'tedir;
   `git diff b5a589f..` ile her değişiklik görülebilir.
3. **Statik kod incelemesi (≈470 C++ dosyası):**
   - Ağ erişimi (`WinHttp`, `InternetOpen`, `URLDownloadToFile`, soketler)
   - Süreç/kod enjeksiyonu (`CreateRemoteThread`, `WriteProcessMemory`, `VirtualAllocEx`, `ShellExecute`, `CreateProcess`)
   - Kayıt defteri yazma, dosya sistemi dışına yazma, gizli veri/telemetri anahtar kelimeleri
   - DLL yükleme yolları (`LoadLibrary*` — DLL ele geçirme / search-order hijacking)
   - Güvensiz C dizge fonksiyonları (`strcpy`, `wcscpy`, `sprintf` …)
4. **Betikler:** `setup_windows.bat`, `setup_linux.sh`, derleme öncesi/sonrası MSBuild komutları.
5. **İkili dosyalar:** Authenticode imzaları `osslsigncode` ile doğrulandı (imza zaman damgası anındaki
   sertifika zinciri, Microsoft kök sertifikalarına kadar). İmzasız `.lib` dosyaları dize ve import tablosu
   taramasıyla incelendi.
6. **Alt modüller:** Her sabitlenmiş commit resmî depodan çekilerek varlığı ve yazarı doğrulandı.
7. **CI:** GitHub Actions iş akışları; yetkiler, gizli anahtarlar, sabitlenmemiş eylemler.

---

## 2. Kapatılan sorunlar

### 2.1 Bellek taşması — `SpoofedGPUName` (Orta)
**Dosyalar:** `OptiScaler/spoofing/Dxgi_Spoofing.cpp`, `OptiScaler/spoofing/Vulkan_Spoofing.cpp`

`OptiScaler.ini` içindeki `SpoofedGPUName` değeri `std::wcscpy` / `std::strcpy` ile **boyut kontrolü olmadan**
sabit boyutlu tamponlara kopyalanıyordu (DXGI `Description` = 128 wchar, Vulkan `deviceName` = 256 bayt).
Uzun bir ad (ör. internetten indirilen "hazır ayar" ini dosyası) oyun sürecinde tampon taşmasına, çökmeye
veya en kötü durumda kod çalıştırmaya yol açabilirdi.

**Düzeltme:** 7 çağrı `wcsncpy_s(..., _TRUNCATE)` / `strncpy_s(..., _TRUNCATE)` ile değiştirildi; uzun adlar
güvenli şekilde kısaltılıyor.

### 2.2 Ağdan gelen URL'nin doğrulanmadan açılması (Orta)
**Dosya:** `OptiScaler/version_check.cpp`

Güncelleme kontrolü GitHub API'sinden gelen `html_url` değerini hiç doğrulamadan menüdeki
"Open release page" bağlantısına veriyordu; bu bağlantı `ShellExecute` ile açılır. Yanıt değiştirilirse
(ör. sisteme kök sertifika eklenmiş bir ağda/proxy'de) tıklama ile yerel bir program veya ağ paylaşımındaki
bir dosya çalıştırılabilirdi.

**Düzeltme:**
- Yalnızca `https://github.com/optiscaler/optiscaler/releases/...` ile başlayan, boşluk/tırnak/kontrol karakteri
  içermeyen URL'ler kabul ediliyor; diğerleri yok sayılıyor.
- **Güncelleme kontrolü artık varsayılan olarak KAPALI** (`CheckForUpdate=false`). Oyun süreci siz açmadıkça
  hiçbir ağ isteği yapmaz. Açmak için `OptiScaler.ini` → `CheckForUpdate=true`.

### 2.3 `*-original.dll` arama yolu ile DLL ele geçirme (Düşük)
**Dosya:** `OptiScaler/dllmain.cpp`

OptiScaler başka bir DLL'in yerine geçtiğinde (ör. `version.dll`), zincirleme için `version-original.dll`
dosyasını **yalnızca adıyla** yüklüyordu. Oyun klasöründe yoksa Windows bu adı çalışma dizininde ve `PATH`
içindeki klasörlerde de arar; `PATH`'teki yazılabilir bir klasöre bırakılan sahte bir DLL oyun içinde çalışabilirdi.

**Düzeltme:** `*-original.dll` artık yalnızca OptiScaler DLL'inin bulunduğu klasörden (tam yol ile) yükleniyor.

### 2.4 Eklenti klasörünün çalışma dizinine göre çözülmesi (Düşük)
**Dosya:** `OptiScaler/dllmain.cpp`

`[Plugins] Path=` göreli bir yol olarak verildiğinde oyunun o anki çalışma dizinine göre çözülüyordu
(başlatıcılar farklı dizinden başlatabilir). Bu klasördeki `.asi` dosyaları oyun içinde kod olarak çalışır.

**Düzeltme:** Göreli eklenti yolu artık her zaman oyun `.exe` klasörüne göre çözülüyor.

### 2.5 Kurulum betiğinde doğrulamasız indirme (Orta)
**Dosya:** `setup_windows.bat`

Betik, AMD/Intel seçildiğinde internetten `OptiPatcher.asi` dosyasını **değiştirilebilir bir "rolling"
sürümden**, hiçbir özet/imza kontrolü olmadan indiriyor ve ardından `LoadAsiPlugins=true` yaparak bu dosyanın
oyun içinde kod olarak çalışmasını açıyordu. O sürüm veya hesap ele geçirilirse kullanıcıya zararlı kod
gönderilebilirdi.

**Düzeltme:** Otomatik indirme tamamen kaldırıldı. OptiPatcher isteğe bağlıdır ve AMD'de FSR kullanımı için
gerekli değildir; gerekiyorsa elle indirilip incelenmelidir.

### 2.6 CI / tedarik zinciri (Orta)
**Dosyalar:** `.github/workflows/*`

Upstream iş akışları bu depoya aynen gelseydi: her gece otomatik **sürüm yayınlayacak** (`contents: write`),
harici imzalama servisi için gizli anahtar isteyecek ve eylemleri değiştirilebilir etiketlerle (`@v2`, `@v8`)
kullanacaktı.

**Düzeltme:** 6 iş akışı kaldırıldı, yerine tek bir `build.yml` eklendi:
- `permissions: contents: read` — yalnızca okuma yetkisi, gizli anahtar yok, otomatik sürüm yok.
- Tüm eylemler **tam commit SHA'sı** ile sabitlendi.
- `persist-credentials: false`.
- Paketlenen AMD/Intel/Microsoft DLL'lerinin **Windows üzerinde Authenticode imzası** kontrol edilir;
  imzasız veya beklenmeyen bir DLL varsa derleme **başarısız olur**.
- Paketteki her dosyanın **SHA256** özeti `SHA256SUMS.txt` olarak pakete eklenir ve derleme özetine yazılır.

---

## 3. Doğrulanan ikili dosyalar

### 3.1 Depoda bulunan Windows ikili dosyaları

| Dosya | İmzalayan | Sonuç |
|---|---|---|
| `OptiScaler/shaders/shader_tools/dxc.exe` | Microsoft Corporation | ✅ özet eşleşiyor, zincir geçerli |
| `OptiScaler/shaders/shader_tools/dxv.exe` | Microsoft Corporation | ✅ |
| `OptiScaler/shaders/shader_tools/fxc.exe` | Microsoft Corporation | ✅ |
| `OptiScaler/shaders/shader_tools/dxcompiler.dll` | Microsoft Corporation | ✅ |
| `OptiScaler/shaders/shader_tools/dxil.dll` | Microsoft Corporation | ✅ |
| `external/directx_agility_sdk/lib/D3D12Core.dll` | Microsoft Corporation | ✅ |

> Not: Bu araçlar yalnızca geliştiricinin gölgelendirici derlemesi içindir; MSBuild derlemesi bunları çalıştırmaz.

### 3.2 Paketlenen üretici DLL'leri (alt modüllerden)

| Dosya | Kaynak | İmzalayan | Sonuç |
|---|---|---|---|
| `amd_fidelityfx_upscaler_dx12.dll` | AMD FSR SDK 2.3.0 | Advanced Micro Devices | ✅ |
| `amd_fidelityfx_framegeneration_dx12.dll` | AMD FSR SDK 2.3.0 | Advanced Micro Devices | ✅ |
| `amd_fidelityfx_loader_dx12.dll` (→ `amd_fidelityfx_dx12.dll`) | AMD FSR SDK 2.3.0 | Advanced Micro Devices | ✅ |
| `amd_fidelityfx_vk.dll` | AMD FidelityFX SDK 1.1.4 | Advanced Micro Devices | ✅ |
| `libxess.dll`, `libxess_dx11.dll`, `libxess_fg.dll`, `libxell.dll` | Intel XeSS SDK 3.0.1 | Intel Corporation | ✅ |

### 3.3 İmzasız statik kütüphaneler (`.lib`)
`OptiScaler/library/**` (FSR 2.x / 3.1 statik kütüphaneleri, Detours, Vulkan, d3dx11) ve `external/freetype/freetype.lib`
imzalanamaz. Dize ve import taramasında yalnızca beklenen API'ler görüldü (dosya okuma, bellek, matematik,
`GetProcAddress`); **ağ, süreç oluşturma, enjeksiyon, kayıt defteri veya URL bulunmadı.** Detours'ta görülen
`DetourCreateProcessWithDll*` adları Microsoft Detours kütüphanesinin standart API'sidir.

### 3.4 Alt modüller

| Yol | Commit | Resmî kaynak |
|---|---|---|
| `external/FidelityFX-SDK` | `c6efa6b` | AMD FidelityFX SDK 1.1.4 |
| `external/FidelityFX-SDK-v2` | `60f4ea8` | AMD FSR SDK 2.3.0 |
| `external/xess` | `207b703` | Intel XeSS SDK 3.0.1 |
| `external/vulkan` | `d64e9e1` | Khronos Vulkan-Headers |
| `external/spdlog` | `faa0a7a` | gabime/spdlog |
| `external/simpleini` | `6048871` | brofield/simpleini |
| `external/magic_enum` | `a733a2e` | Neargye/magic_enum |
| `external/unordered_dense` | `73f3cbb` | martinus/unordered_dense |

---

## 4. Kapatılamayan / tasarım gereği riskler

Bunlar hata değil, aracın doğası gereği var olan risklerdir. **Kullanmadan önce okuyun.**

1. **Çevrim içi oyunlarda BAN riski (Yüksek).** OptiScaler oyunun içine DLL olarak girer ve fonksiyonları
   kancalar (hook). Hile karşıtı sistemler (EAC, BattlEye, Vanguard, Ricochet …) bunu hile olarak algılayabilir.
   **Çok oyunculu / çevrim içi oyunlarda KULLANMAYIN.**
2. **RDNA2 için FSR4 INT8 DLL'i resmî değildir (Yüksek).** RX 6700 XT'de FSR4 çalıştırmak için gereken INT8
   `amd_fidelityfx_upscaler_dx12.dll` dosyası AMD tarafından RDNA2 için yayımlanmamıştır; sızdırılmış AMD
   kodundan topluluk tarafından derlenmiştir. **AMD imzası taşımaz, kaynağı doğrulanamaz ve lisans durumu belirsizdir.**
   Bu nedenle bu depoya **eklenmedi**. Kullanırsanız risk size aittir — README'deki kontrol adımlarına bakın.
   Daha güvenli alternatif: `Fsr4ForceEnableInt8=true` ayarı, pakette zaten bulunan **AMD imzalı** FSR 4.1.1
   DLL'indeki GPU kontrolünü yalnızca bellekte atlatır (`proxies/FfxApi_Proxy.h`, Detours ile tek bir fonksiyonun
   `1` döndürmesi sağlanır; diskteki dosya ve imzası değişmez). Bu yol incelendi; ek bir güvenlik riski
   getirmez, ancak AMD tarafından RDNA2 için desteklenmez.
   AMD'nin açıklamasına göre FSR 4.1'in RDNA2'ye **resmî** desteği 2027 başında bekleniyor; o zaman bu risk ortadan kalkar.
3. **ASI eklenti yükleme.** `LoadAsiPlugins=true` yaparsanız `plugins` klasöründeki her `.asi` dosyası oyun içinde
   kod olarak çalışır. Varsayılan olarak **kapalıdır**; yalnızca güvendiğiniz dosyaları koyun.
4. **Oyun klasörüne yazma yetkisi.** DLL proxy yöntemi gereği, oyun klasörüne dosya yazabilen herkes o oyunda kod
   çalıştırabilir. Oyunları yönetici yetkisi gerektirmeyen ama başkalarının yazamadığı bir klasörde tutun.
5. **GPU taklidi (spoofing).** Varsayılan ayarda AMD kart oyuna NVIDIA gibi gösterilebilir (DLSS girişlerini açmak
   için). Bazı oyunlarda sorun çıkarabilir; `Dxgi=false` ile kapatılabilir.
6. **Derlenmiş `OptiScaler.dll` imzasızdır.** Kendi CI'nizde derlendiği için kod imzası yoktur; Windows SmartScreen
   uyarı verebilir. Bunun yerine paketteki `SHA256SUMS.txt` ve Actions derleme özetindeki özetlerle doğrulayın.

---

## 5. Upstream'i güncellerken

Yeni bir OptiScaler sürümüne geçerken bu incelemeyi tekrarlayın; özellikle:
`git diff` ile `version_check.cpp`, `dllmain.cpp` (LoadLibrary çağrıları), `spoofing/*`, `setup_windows.bat`,
yeni eklenen `.exe/.dll/.lib` dosyaları ve `.gitmodules` değişikliklerine bakın. Bu depodaki 6 düzeltmenin
yeni sürümde yeniden uygulanması gerekir (upstream'e bildirilmediyse).
