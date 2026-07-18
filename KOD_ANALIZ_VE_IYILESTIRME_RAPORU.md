# Kelime ve İşlem V1 — Kod Yapısı Analizi ve İyileştirme Raporu

> Analiz tarihi: 2026-07-17 · Kapsam: `main` dalındaki tüm Swift kaynak kodu (~6.500 satır), Xcode proje dosyası, kaynak dosyaları (sözlükler, lokalizasyon)

---

## İçindekiler

1. [Genel Bakış ve Mimari](#1-genel-bakış-ve-mimari)
2. [Oyun Bölümleri ve Fonksiyonalite](#2-oyun-bölümleri-ve-fonksiyonalite)
3. [Component (Bileşen) Envanteri](#3-component-bileşen-envanteri)
4. [Tespit Edilen Sorunlar — Önem Sırasına Göre](#4-tespit-edilen-sorunlar)
5. [Geliştirilebilir Alanlar](#5-geliştirilebilir-alanlar)
6. [Hazır Düzeltme Prompt'ları](#6-hazır-düzeltme-promptları)

---

## 1. Genel Bakış ve Mimari

**"Bir Kelime Bir İşlem"** TV formatını temel alan, SwiftUI ile yazılmış bir iOS oyunu.

| Özellik | Değer |
|---|---|
| UI Framework | SwiftUI (iOS 17+ API'ler: `onChange` yeni imza) |
| Mimari | MVVM + Servis katmanı + Command pattern (undo/redo) |
| Kalıcılık | UserDefaults (JSON encode) — Core Data iskeleti var ama **kullanılmıyor** |
| Eşzamanlılık | `@MainActor` ViewModel'ler, `actor DictionaryService`, `DispatchSourceTimer`, serial `DispatchQueue` |
| Test | **Hiç test yok** (unit/UI) |
| Lokalizasyon | Kısmen — `tr.lproj` var, kod içinde hardcoded Türkçe metinlerle karışık |

### Katman yapısı

```
KelimeVeIslemV1/
├── App/KelimeVeIslemApp.swift          # Giriş noktası, servis ısındırma
├── Models/                              # 9 dosya — oyun durumu, sonuç, başarım, seviye
│   ├── LetterGame.swift                 # Harf oyunu durumu + puanlama + doğrulama
│   ├── NumberGame.swift                 # Sayı oyunu durumu + ifade ayrıştırıcı (recursive descent)
│   ├── GameResult.swift                 # Oyun sonucu + GameStatistics (XP/seviye dahil)
│   ├── Achievement.swift                # 16+ başarım tanımı + AchievementTracker (singleton)
│   ├── DailyChallenge.swift             # Seed'li günlük üretim + streak istatistikleri
│   ├── LevelSystem.swift                # 50 seviye, XP eğrisi, ödüller, zorluk modifiye edicileri
│   ├── SavedGameState.swift             # 24 saatlik oyun sürdürme
│   ├── GameSettings.swift               # Kullanıcı ayarları + zorluk seviyesi
│   └── GameMode.swift                   # letters / numbers enum
├── ViewModels/                          # 4 dosya, hepsi @MainActor ObservableObject
├── Services/
│   ├── DictionaryService.swift          # actor — TR 50.500 / EN 662 kelime + çevrimiçi API
│   ├── LetterGenerator.swift            # Frekans ağırlıklı harf üretimi
│   ├── NumberGenerator.swift            # Sayı üretimi + DFS çözücü (ipucu)
│   ├── AudioService.swift               # AVAudioEngine ile sentezlenmiş sesler + haptik
│   └── PersistenceService.swift         # UserDefaults sarmalayıcı (serial queue)
├── Views/                               # Home, LetterGame, NumberGame, DailyChallenge,
│   │                                    # Settings, Statistics, Achievements
├── Utilities/                           # ThemeManager, GameCommand (undo/redo),
│   │                                    # SharedComponents, AnimationModifiers,
│   │                                    # VisualFeedbackComponents, ErrorHandling
└── Resources/                           # turkish_words.txt (50.500), english_words.txt (662)
```

### Veri akışı

```
Oyun bitişi → GameResult oluştur → PersistenceService.saveResult()
  ├── results dizisine ekle (max 100)
  ├── GameStatistics güncelle (XP ekle → seviye atlama kontrolü → Level? döner)
  └── AchievementTracker.checkAchievements() (arka planda, sonucu ATILIYOR ⚠️)
```

---

## 2. Oyun Bölümleri ve Fonksiyonalite

### 2.1 Harf Oyunu (`LetterGameView` + `LetterGameViewModel`)

- 6–12 harf (varsayılan 9), frekans ağırlıklı üretim, ~%35 sesli harf garantisi.
- Harf karoları ile kelime kurma (dokunmatik), karıştırma, "tümünü kaldır", undo/redo (Command pattern, max 10 adım).
- Süre: ayarlardan 30–120 sn (varsayılan 60). Son 10 saniyede tik sesi + uyarı.
- Gönderimde: harf kullanılabilirlik kontrolü → sözlük doğrulama (10 sn timeout'lu) → puanlama.
- Puanlama: `uzunluk×10` + nadir harf başına +5 + 7 harf bonusu (+20) + 9 harf bonusu (+50).
- Geçersiz kelimede sözlükten 5 öneri kelime gösterimi.
- Arka plana geçişte oyun durumu kaydı, 24 saat içinde sürdürme.

### 2.2 Sayı Oyunu (`NumberGameView` + `NumberGameViewModel`)

- Zorluk ayarına göre küçük (1–10) + büyük (25/50/75/100) sayılar; hedef 101–999.
- Karo tabanlı ifade kurma; operatör sözdizimi ön-kontrolü (`handleOperatorTap`), canlı sonuç önizleme, hedefe yakınlık göstergesi.
- El yazımı recursive-descent parser (`NumberGame.evaluateExpression`) — NSExpression yerine güvenli çözüm, sıfıra bölme kontrolü var.
- Puanlama: tam isabet 100; fark ≤5 → `80−fark×10`; ≤10 → `50−fark×3`; ≤20 → `20−fark`; üzeri 0.
- İpucu: `NumberGenerator.findSolution` (DFS, derinlik 4) arka planda; bulunamazsa en yakın çözüm.

### 2.3 Günlük Meydan Okuma (`DailyChallengeView` + `DailyChallengeGameView`)

- Tarihe dayalı seed (`yıl×10000+ay×100+gün`) ile deterministik üretim; gün çift/tek ise harf/sayı modu.
- 2x puan çarpanı, streak (seri) takibi, yerel "liderlik tablosu" (aslında geçmiş kayıtları).
- Ana oyun ViewModel'lerini `customGame` init'i ile yeniden kullanıyor ancak **kendi basitleştirilmiş UI'ını** çiziyor (kod tekrarı + davranış farkları — bkz. sorunlar).

### 2.4 Seviye / XP Sistemi (`LevelSystem`, `LevelProgressView`, `LevelUpView`)

- 50 seviye, üstel XP eğrisi (taban 100, çarpan 1.15).
- Ödüller: tema, güç-yükseltme (power-up), ekstra ipucu/süre, XP boost — **tanımlı ama hiçbiri oyunda uygulanmıyor**.
- Seviyeye bağlı zorluk modifiye edicileri (`DifficultyModifiers`) tanımlı ama fiilen devrede değil (bkz. Sorun #12).

### 2.5 Başarımlar (`Achievement` + `AchievementTracker` + `AchievementsView`)

- 7 kategori, 16 tanımlı başarım; ilerleme çubuklu kart UI'ı.
- Oyun sonrası otomatik kontrol; ancak kombo, günlük ve "tüm harfleri kullan" başarımları **hiç tetiklenmiyor** (bkz. Sorun #5, #9).

### 2.6 İstatistikler / Ayarlar

- İstatistik: toplam oyun, ortalama/en iyi skor, en uzun kelime, mükemmel eşleşme sayısı, son 20 oyun, mod bazlı top 10.
- Ayarlar: dil (TR/EN), harf sayısı, süreler, ses, çevrimiçi sözlük, zorluk, tema, alıştırma modu; veri dışa/içe aktarma altyapısı mevcut (`exportData`/`importData` — deadlock'lu, bkz. Sorun #2).

---

## 3. Component (Bileşen) Envanteri

| Bileşen | Konum | Not |
|---|---|---|
| `GameModeButton`, `QuickStatsView`, `BottomBarButton`, `ResumeGameButton`, `DailyChallengeButton` | HomeView.swift | Home'a gömülü — ayrı dosyaya taşınabilir |
| `PlayingView`, `LetterTilesView` | LetterGameView.swift | 90×90 sabit karo, 3 sütun grid |
| `NumberPlayingView`, `NumberTilesView`, `OperatorButtonsView`, `ActionButtonsView`, `HintView` | NumberGameView.swift | |
| `GameReadyView`, `ScoreView`, `TimerView`, `LoadingOverlay`, `PrimaryGameButton`, `GrowingButton` | SharedComponents.swift (622 satır) | İyi paylaşım; dosya büyümüş |
| `EnhancedTimerView`, `ComboView`, `ConfettiView`, `NumberProximityIndicator`, `WordLengthIndicator`, `LetterFrequencyIndicator` | VisualFeedbackComponents.swift | |
| `SpringTileButtonStyle`, particle/score-popup modifier'ları | AnimationModifiers.swift | |
| `CommandHistory` + 5 komut sınıfı | GameCommand.swift | ViewModel'e `weak` referanslı |
| `ThemeManager` + `ThemeColors` | ThemeManager.swift | Singleton, tema desteği |
| `DailyChallengeLetterGameView`, `DailyChallengeNumberGameView`, `DailyChallengeResultSheet`, `DailyChallengeLetterTilesView` | DailyChallengeGameView.swift | Ana oyun UI'ının kopyası — birleştirilmeli |

---

## 4. Tespit Edilen Sorunlar

### 🔴 KRİTİK (derleme / kilitlenme / temel işlev)

**S1. Seviye sistemi dosyaları Xcode target'ında değil → proje derlenmiyor**
`LevelSystem.swift`, `LevelUpView.swift`, `LevelProgressView.swift` diskte var ama `project.pbxproj` içindeki Sources build phase'de **yok**. Oysa `GameResult.swift:76` (`Level`, `LevelSystem.shared`), `HomeView.swift:57` (`LevelProgressView`), `LetterGameViewModel.swift:35` (`Level?`), `LetterGameView.swift:95` (`LevelUpView`) bu tipleri kullanıyor. Bu üç dosya target'a eklenmeden proje derlenemez. (Kök dizindeki `COMPILATION_FIX.md` vb. notlar bu geçmişi doğruluyor.)

**S2. `PersistenceService.exportData()/importData()` kesin deadlock**
`PersistenceService.swift:298-337` — `exportData()` `queue.sync` bloğu içinde `loadResults()`, `loadStatistics()`, `loadSettings()` çağırıyor; bu üç metodun her biri **aynı serial queue üzerinde tekrar `queue.sync`** yapıyor → iç içe sync = kalıcı kilitlenme. `importData()` da aynı şekilde `saveStatistics()`/`saveSettings()` çağırıyor. Ayarlardan veri dışa/içe aktarma denenirse uygulama donar.

**S3. Günlük meydan okumada zamanlayıcı hiç başlamıyor**
`LetterGameViewModel.swift:99` ve `NumberGameViewModel.swift:79`'daki `startGameTimer()` **projede hiçbir yerden çağrılmıyor**. `customGame` init'i `gameState = .playing` yapıyor ama timer kurulmuyor → günlük oyunda süre hiç akmıyor, `TimerView` sabit değer gösteriyor, oyun yalnızca elle gönderimle bitiyor. "Hız Şeytanı" başarımı da (≤30 sn) bu modda anlamsızlaşıyor.

**S4. İlk açılışta sesler kapalı geliyor**
`AudioService.swift:57-58` — `UserDefaults.standard.bool(forKey:)` anahtar yokken `false` döner; `isSoundEnabled`/`isMusicEnabled` ilk kurulumda `false` başlıyor. Ses seviyeleri için "0 ise varsayılan ata" düzeltmesi yapılmış (satır 63-64) ama bool'lar unutulmuş. Ayrıca `GameSettings.soundEnabled` ile `AudioService.isSoundEnabled` **iki ayrı doğruluk kaynağı** ve senkronize edilmiyor.

**S5. Kombo sistemi yapısal olarak işlevsiz (ölü mekanik)**
Her iki oyunda da `submitWord()`/`submitSolution()` ilk gönderimde `gameState = .finished` yapıyor (`LetterGameViewModel.swift:175`, `NumberGameViewModel.swift:139`) ve `startNewGame()` `comboCount = 0` ile başlıyor. Yani **combo hiçbir zaman 1'i geçemez**: `comboMultiplier` (2x/3x/5x) asla devreye girmez, `comboMilestone` sesleri (3/5/10 eşiği) asla çalmaz, `combo_5`/`combo_10` başarımları kazanılamaz. Üstelik `AchievementTracker.checkComboAchievement()` zaten hiçbir yerden çağrılmıyor. Ya combo oyunlar arası taşınmalı (seri başarılı oyun) ya da tek oyun içinde çoklu gönderime izin verilmeli — tasarım kararı gerekiyor.

### 🟠 YÜKSEK (yanlış davranış / veri bozulması)

**S6. Sayı oyununda "sil" çok haneli sayıları bozuyor**
`NumberGameView.swift:260-271` — `handleDelete()` **tek karakter** siliyor. Çözümde "100" varken silme "10" bırakır; `usedNumberIndices.popLast()` ile 100'ün karosu serbest kalır ama ifadede havuzda olmayan "10" sayısı kalır → gönderimde "geçersiz sayı" hatası veya yanlış doğrulama. `handleRedo()` (satır 290-308) yalnızca son karaktere bakarak sayıyı tek hane sanıyor ve `game.numbers.firstIndex(of:)` her zaman ilk kopyayı bulduğundan yinelenen sayılarda indeks takibi bozuluyor. Aynı hatalı kalıp `LetterGameView.swift:399-407`'deki redo'da da var (yinelenen harflerde `firstIndex(of:)`).

**S7. Türkçe büyük/küçük harf dönüşümü locale'siz**
`LetterGame.updateWord`, `DictionaryService.validateWord/loadDictionarySync` vb. her yerde `uppercased()` locale parametresiz kullanılıyor. Türkçede `"i".uppercased()` → `"I"` (doğrusu `"İ"`), `"ı"` da sorunlu. Karo tabanlı giriş büyük harf olduğundan çoğu akış kurtuluyor ama: (a) TDK API'sine kelime **büyük harfle** gönderiliyor (`sozluk.gov.tr/gts?ara=KEDİ`) — API küçük harf bekler, çevrimiçi doğrulama fiilen her zaman `false` döner; (b) gelecekte klavye girişi eklenirse tüm doğrulama kırılır. `uppercased(with: Locale(identifier: "tr_TR"))` kullanılmalı, API'ye küçük harf gönderilmeli.

**S8. Başarım sistemi yarım bağlanmış**
- `PersistenceService.swift:195` — `checkAchievements`'in döndürdüğü yeni başarımlar `let _ =` ile **atılıyor**; kazanılan başarım için hiçbir bildirim/toast gösterilmiyor.
- `checkDailyChallengeAchievements` hiçbir yerden çağrılmıyor → `daily_first`, `daily_streak_7` kazanılamaz.
- `use_all_letters` başarımı hiçbir yerde kontrol edilmiyor.
- `Achievement.swift:330` — `words_100` "geçerli kelime" yerine `letterGamesPlayed` ile sayılıyor (geçersiz oyunlar da sayaç artırıyor; kodda "Simplified tracking" notu var).

**S9. Günlük meydan okuma ana sistemlerle entegrasyonsuz**
- `DailyChallengeGameView.swift:82,311` — `GameSettings.default` kullanılıyor: kullanıcının dili, ses tercihi, süre ayarı yok sayılıyor (EN kullanıcıya TR sözlükle doğrulama yapılır).
- ViewModel'in `saveResult()`'ı `isDailyChallenge: false` ile çağrılıyor → 2x XP bonusu (`LevelSystem.calculateXP`) hiçbir zaman uygulanmıyor; skor çarpanı yalnızca view katmanında `score * 2` ile taklit ediliyor.
- Sayı modunda `ForEach(numbers, id: \.self)` (satır 402) — yinelenen sayılarda çakışan ID'ler → SwiftUI görünüm hataları; ayrıca kullanılan sayı takibi yok, **aynı sayı sınırsız kullanılabiliyor** (ana oyunla çelişen kural).
- Harf modunda karo seçimi `viewModel.updateWord` ile doğrudan yapılıyor — command pattern/undo atlanıyor.
- `completeChallenge` başarım kontrolü çağırmıyor (bkz. S8).

**S10. `GameStatistics.longestWord` geçersiz kelimelerle kirlenebiliyor**
`GameResult.swift:108-110` — `longestWord` güncellemesi `isValid` kontrolünün **dışında**: sözlükte olmayan 12 harflik rastgele dizilim "en uzun kelime" istatistiği olur.

**S11. Seviye tabanlı zorluk fiilen devre dışı / tutarsız**
- `LetterGameViewModel.swift:148` ve `NumberGameViewModel.swift:111` — `settings.letterTimerDuration > 0` her zaman doğru olduğundan `difficulty.letterTimeSeconds`/`numberTimeSeconds` **asla kullanılmıyor** (ölü kod).
- `LevelSystem.swift:318` — seviye 1–9 için `minLetterCount` 4–5 üretir; `startNewGame` bunu geçersiz sayıp 9'a resetler (satır 126-129) → seviye zorluğu rastgele bozuluyor.
- `allowedOperations` (seviye 5'e kadar yalnız +−, 15'e kadar ÷ yok) **hiç uygulanmıyor** — UI her zaman 4 operatörü sunuyor.
- Sayı oyununda hedef `difficulty.targetNumberRange`'den (seviye), sayılar `settings.difficultyLevel`'dan (kullanıcı ayarı) geliyor — iki zorluk sistemi karışmış; seviye 1'de hedef 10–60 iken 25/50/75/100'lü havuz anlamsız kolaylık/uyumsuzluk yaratıyor.

**S12. Ana thread'de tekrarlayan senkron disk I/O**
`LetterGameView.swift:138` ve `NumberGameView.swift:142` — `headerView` **her render'da** `PersistenceService.shared.loadSettings()` çağırıyor (queue.sync + JSON decode). `startNewGame` de main thread'de `loadStatistics()` yapıyor. Ayrıca her kayıtta gereksiz `defaults.synchronize()` (Apple'ın kaldırılmasını önerdiği çağrı).

### 🟡 ORTA

**S13. İngilizce sözlük fiilen kullanılamaz** — TR 50.500 kelimeye karşın EN yalnız 662 kelime (`english_words.txt`). İngilizce modda çoğu geçerli kelime "sözlükte yok" sayılır.

**S14. Sayı oyunu Countdown kurallarını zorunlu kılmıyor** — parser ara sonuçlarda tam sayı/negatif kontrolü yapmıyor; `Int(result)` kesirli sonucu sessizce kırpıyor (ör. `7/2*4 = 14` yerine `Double` akışıyla 14.0→14 doğru ama `7/2 = 3.5` ara değeri klasik kurallarda geçersizdir; `5/2` sonucu 2.5→2 olarak "geçerli" görünebilir). Skor ve ipucu çözücü (yalnız tam bölmeye izin veren) ile oyuncu değerlendirmesi (kesirli bölmeye izin veren) **farklı kural setleri** kullanıyor.

**S15. `findClosestSolution` bölme işlemini hiç denemiyor** (`NumberGenerator.swift:177-181`) — en yakın çözüm ipuçları eksik kalabiliyor; `findSolution` da ilk bulduğu çözümü döndürüyor (en kısa/en şık değil).

**S16. Ölü kod / yetim dosyalar**
- `Views/Home/DailyChallengeView.swift` — target dışı, içinde `TODO: Navigate to actual daily challenge flow` olan eski kopya (aynı isimli struct ile çakışma riski).
- `Persistence.swift` + `KelimeVeIslemV1.xcdatamodeld` (Core Data, `Item` entity) — hiç kullanılmıyor ama target'ta derleniyor.
- ViewModel'lerdeki `cancellables` setleri hiç kullanılmıyor; `LetterGameView`'daki `isTextFieldFocused` artık işlevsiz (giriş salt karo tabanlı).
- Kök dizinde 5 adet geçici çalışma notu (`COMPILATION_FIX.md`, `FIX_NOTES.md`, `ENHANCEMENTS.md`, ...) ve `.DS_Store`, `xcuserdata/` git'te.

**S17. Lokalizasyon yapısı bozuk** — `Resources/Localizable.strings.en` / `.tr` dosyaları `.lproj` klasöründe değil (iOS bunları asla yüklemez); yalnız `tr.lproj/Localizable.strings` gerçek. Kodda `NSLocalizedString` ile hardcoded Türkçe metinler karışık; `GameSettings.language` UI dilini değil yalnız sözlüğü değiştiriyor.

**S18. `saveResult` süre hesabı kırılgan** — `duration = settings.letterTimerDuration - timeRemaining` (`LetterGameViewModel.swift:475`): sürdürülen oyunlarda ve ayar değişikliğinde yanlış; alıştırma modunda `999999` hack'i (kayıt yapılmadığı için maskeleniyor). Gerçek geçen süreyi ölçmek daha doğru.

**S19. `SeededRandomGenerator` zayıf** (`DailyChallenge.swift:174-195`) — düşük bitleri zayıf LCG + `% n` modulo bias; ayrıca `UInt64(seed)` negatif seed'de crash eder (mevcut seed formülünde oluşmaz ama kırılgan). Tüm oyuncularda aynı gün aynı bulmaca hedefi doğru çalışıyor; kalite iyileştirilebilir.

**S20. Liderlik tablosu adlandırması yanıltıcı** — `saveDailyChallengeLeaderboard` skorla sıralamadan en son 50 kaydı tutuyor; tek oyunculu cihazda "leaderboard" değil geçmiş listesi. Sıralama/adlandırma netleştirilmeli.

**S21. `NumberGameViewModel.init` ayarları asenkron yüklüyor** (`NumberGameViewModel.swift:51-63`) — `Task { @MainActor in ... }` ile sonradan atama; kullanıcı hemen oyuna başlarsa varsayılan ayarlarla oynayabilir (yarış durumu). `LetterGameViewModel` senkron yüklüyor — tutarsızlık.

**S22. Undo/redo durumu iki yerde tutuluyor** — `usedLetterIndices`/`usedNumberIndices` View'da `@State`, kelime/çözüm ViewModel'de; undo butonu `performUndo()` sonrası `currentWord`'e bakarak indeks düşürüyor (`LetterGameView.swift:379-383`) — `ClearWordCommand` undo'sunda (kelime geri gelir) indeks listesi boş kalır → karolar seçili görünmez ama kelime dolu. Seçim durumu ViewModel'e taşınmalı.

### 🟢 DÜŞÜK

- `GameReadyView` "9 harf alacaksınız" derken seviye sistemi rastgele 6–9 üretebilir (bilgi tutarsızlığı).
- `withTimeout` global serbest fonksiyon — timeout'ta `AppError.networkError("Operation timed out")` dönüyor; çevrimdışı sözlük araması için yanıltıcı hata türü.
- `parseAPIResponse` sozluk.gov.tr'nin hata yanıtını (`{"error": ...}` sözlük objesi) sessizce `false`'a çeviriyor — S7 ile birleşince çevrimiçi doğrulama tamamen kör.
- `LetterGameViewModel.settings` `public var` — dışarıdan mutasyona açık; `letterCount` validasyonu iki yerde kopyalanmış.
- `AchievementTracker.checkAchievements`'te her başarım için elle yazılmış tekrar eden bloklar (~80 satır) — veri güdümlü tek döngüye indirilebilir.
- `print()` tabanlı loglama her yerde (bazıları bozuk emoji kodlamalı: `âœ…`) — `os.Logger`'a geçilmeli.
- `LetterTilesView` 90×90 sabit karo + 3 sütun: 12 harfte küçük ekranlarda taşma riski; `GeometryReader`/uyarlanabilir grid önerilir.
- Erişilebilirlik kısmen var (bazı `accessibilityLabel`'lar İngilizce, bazıları Türkçe — tutarsız).

---

## 5. Geliştirilebilir Alanlar

1. **Test altyapısı** — Saf mantık zaten izole: `NumberGame` parser'ı, `LetterGame.canUseLetters/calculateScore`, `NumberGenerator` çözücüsü, `DailyChallengeStats.update` (streak), `LevelSystem` XP eğrisi birim testler için mükemmel adaylar. Önce S1–S6 düzeltmelerini kilitleyen regresyon testleri yazılmalı.
2. **Persistence modernizasyonu** — UserDefaults'ta 100 oyun sonucu JSON'ı büyüyor; SwiftData/Core Data (iskelet zaten var) veya dosya tabanlı depoya geçiş + `async/await` API; `queue.sync` yerine actor.
3. **Oyun döngüsü tasarımı** — Combo'yu anlamlı kılmak için tur tabanlı oyun (klasik formattaki gibi N tur harf + N tur sayı), ya da süre bitene kadar çoklu kelime gönderimi.
4. **Günlük meydan okumayı ana oyun UI'ı ile birleştirme** — `DailyChallengeGameView`'daki ~500 satırlık kopya UI yerine `LetterGameView`/`NumberGameView`'a "challenge modu" parametresi.
5. **Seviye ödüllerini gerçeğe bağlama** — temalar `ThemeManager`'a, ekstra ipucu/süre oyun başlangıcına, XP boost `calculateXP`'ye bağlanmalı; aksi halde ödül ekranı boş vaat.
6. **Sözlük iyileştirme** — EN kelime listesini büyütme (ör. SCOWL/ENABLE listesi), TR listeye özel isim/kısaltma filtresi, ikili arama yerine mevcut `Set` iyi; `findWords` için harf-frekans ön-indeksleme.
7. **Game Center / paylaşım** — gerçek liderlik tablosu, günlük sonucu paylaşma (Wordle tarzı emoji grid).
8. **Tam lokalizasyon** — String Catalog (`.xcstrings`) ile TR/EN; `GameSettings.language` yalnız sözlük dilini değil UI dilini de yönetmeli veya ayrım netleşmeli.
9. **Ses dosyaları** — sentezlenmiş ton yerine kısa örneklenmiş SFX; arka plan müziği için telifsiz parça (altyapı `MusicType` ile hazır).
10. **CI** — GitHub Actions ile `xcodebuild build test` (S1 benzeri "dosya target'ta yok" hatalarını anında yakalar).

---

## 6. Hazır Düzeltme Prompt'ları

> Aşağıdaki prompt'lar bağımsız çalışma paketleri olarak sıralanmıştır (önerilen uygulama sırasıyla). Her birini olduğu gibi bir AI kod asistanına (Claude Code vb.) verebilirsiniz.

---

### PROMPT 1 — Derleme ve kilitlenme blokerleri (S1, S2)

```
KelimeVeIslemV1 iOS projesinde iki kritik bloker var, ikisini de düzelt:

1) Xcode target eksikleri: KelimeVeIslemV1/Models/LevelSystem.swift,
   KelimeVeIslemV1/Views/Home/LevelUpView.swift ve
   KelimeVeIslemV1/Views/Home/LevelProgressView.swift dosyaları diskte mevcut
   ama KelimeVeIslemV1.xcodeproj/project.pbxproj içindeki Sources build
   phase'e ekli değil; GameResult.swift, HomeView.swift ve her iki oyun
   ViewModel'i bu tipleri kullandığı için proje derlenmiyor. Bu üç dosyayı
   pbxproj'a (PBXBuildFile + PBXFileReference + ilgili PBXGroup + Sources
   build phase) elle ve mevcut ID formatına uygun şekilde ekle. Ayrıca
   Views/Home/DailyChallengeView.swift dosyası target dışı kalmış eski bir
   kopya (aynı isimli struct, içinde TODO var) — bu dosyayı tamamen sil.

2) PersistenceService deadlock: PersistenceService.swift içinde exportData()
   ve importData() kendi queue.sync bloklarının İÇİNDEN yine queue.sync
   kullanan loadResults()/loadStatistics()/loadSettings()/saveStatistics()/
   saveSettings() metodlarını çağırıyor; aynı serial queue'da iç içe sync
   kesin deadlock. Kilitli bölge içinden çağrılabilen, queue kullanmayan
   private *_locked yardımcıları çıkararak (veya okuma/yazma mantığını
   tek seviyeye indirerek) deadlock'u kaldır. Tüm defaults.synchronize()
   çağrıları gereksiz — hepsini kaldır.

Değişiklik sonrası projenin derlendiğini doğrula (xcodebuild mevcutsa),
davranış değişikliği yaratma.
```

---

### PROMPT 2 — Günlük meydan okuma zamanlayıcısı ve entegrasyonu (S3, S9)

```
KelimeVeIslemV1'de günlük meydan okuma (DailyChallengeGameView.swift) modunda
şu hataları düzelt:

1) Zamanlayıcı hiç başlamıyor: LetterGameViewModel ve NumberGameViewModel'in
   customGame init'i gameState=.playing yapıyor ama startGameTimer() hiçbir
   yerden çağrılmıyor. DailyChallengeLetterGameView ve
   DailyChallengeNumberGameView onAppear'da viewModel.startGameTimer()
   çağıracak şekilde bağla; süre bittiğinde otomatik gönderimin çalıştığını
   ve sonuç ekranının açıldığını doğrula.

2) Kullanıcı ayarları yok sayılıyor: her iki view GameSettings.default ile
   ViewModel kuruyor. PersistenceService.shared.loadSettings() ile gerçek
   ayarları (özellikle dil ve süreler) kullan.

3) 2x XP uygulanmıyor: ViewModel saveResult() içinde GameResult'ı
   isDailyChallenge:false ile üretiyor; günlük modda true geçilmesini
   sağlayacak bir mekanizma ekle (ör. ViewModel'e isDailyChallenge bayrağı)
   ve view katmanındaki elle "score * 2" çarpımıyla çifte çarpan
   oluşmadığından emin ol — çarpan tek bir yerde uygulanmalı.

4) Sayı modunda kural ihlali: LazyVGrid ForEach(numbers, id:\.self)
   yinelenen sayılarda ID çakıştırıyor ve kullanılan sayı takibi olmadığı
   için aynı sayı sınırsız kullanılabiliyor. Ana NumberGameView'daki gibi
   indeks tabanlı ForEach + usedNumberIndices takibi ekle; kullanılan karo
   devre dışı kalsın.

5) completeChallenge (DailyChallengeViewModel) başarımları tetiklemiyor:
   AchievementTracker.shared.checkDailyChallengeAchievements(stats:) çağır
   ve dönen yeni başarımları kullanıcıya göstermek üzere @Published bir
   alanda yayınla.
```

---

### PROMPT 3 — Ses sistemi ilk açılış ve tek doğruluk kaynağı (S4)

```
KelimeVeIslemV1/Services/AudioService.swift'te ilk kurulum hatasını düzelt:
init içinde UserDefaults.standard.bool(forKey:) anahtar yokken false
döndüğünden isSoundEnabled ve isMusicEnabled ilk açılışta kapalı başlıyor
(ses seviyeleri için benzer düzeltme yapılmış ama bool'lar unutulmuş).
UserDefaults.standard.object(forKey:) == nil kontrolüyle ilk açılışta
her ikisini true başlat.

Ayrıca ses açık/kapalı bilgisi iki yerde tutuluyor: GameSettings.soundEnabled
(SettingsView'un yazdığı) ve AudioService.isSoundEnabled (çalma kararını
veren). Tek doğruluk kaynağı AudioService olacak şekilde birleştir:
SettingsView toggle'ı AudioService.shared.isSoundEnabled'a bağlansın,
GameSettings.soundEnabled alanını kaldır veya salt-okunur köprü yap;
mevcut kullanıcı ayarlarını migrate et.
```

---

### PROMPT 4 — Kombo sistemini gerçek bir mekaniğe dönüştürme (S5)

```
KelimeVeIslemV1'de kombo sistemi yapısal olarak ölü: her oyun tek gönderimle
gameState=.finished oluyor ve startNewGame comboCount'u sıfırlıyor, bu yüzden
comboCount asla 1'i geçemiyor; comboMultiplier (2x/3x/5x), combo milestone
sesleri ve combo_5/combo_10 başarımları hiçbir zaman tetiklenmiyor
(AchievementTracker.checkComboAchievement zaten hiç çağrılmıyor).

Şu tasarımı uygula: combo, ARDIŞIK BAŞARILI OYUNLAR arasında taşınsın.
- comboCount'u ViewModel yeniden başlatmalarına dayanıklı olacak şekilde
  PersistenceService üzerinden sakla (mod bazlı değil, global tek sayaç).
- Geçerli kelime / hedefe ≤5 yakınlık combo'yu +1 artırsın; geçersiz kelime,
  >5 fark veya günün ilk oyunundan bağımsız olarak başarısız gönderim
  sıfırlasın.
- startNewGame combo'yu SIFIRLAMASIN; yalnızca yükleyip göstersin.
- Skor çarpanı mevcut comboMultiplier eşikleriyle (3→2x, 5→3x, 10→5x)
  uygulanmaya devam etsin ve sonuç ekranında "combo bonusu" satırı görünsün.
- Gönderim sonrası AchievementTracker.shared.checkComboAchievement(comboCount)
  çağır ve dönen başarımları UI'da yayınla.
- ComboView'un ana ekranda/oyun başında mevcut seriyi göstermesini sağla.
Her iki oyun ViewModel'inde de aynı davranışı uygula ve testler ekle.
```

---

### PROMPT 5 — Sayı oyunu giriş bütünlüğü (S6, S22)

```
KelimeVeIslemV1 sayı oyununda ifade düzenleme hataları var:

1) NumberGameView.handleDelete tek karakter siliyor: çözümde "100" varken
   silme "10" bırakıyor ve usedNumberIndices bozuluyor. Silme işlemi
   token-bazlı olmalı: son eklenen öğe çok haneli bir sayıysa sayının
   TAMAMI silinmeli ve o sayının karo indeksi serbest bırakılmalı;
   operatör/parantez ise tek karakter silinmeli.

2) handleRedo son karaktere bakıp tek haneli sayı varsayıyor ve
   game.numbers.firstIndex(of:) her zaman ilk kopyayı bulduğu için
   yinelenen sayılarda karo takibi şaşıyor.

Kalıcı çözüm olarak ifadeyi String yerine token listesi olarak modelle:
NumberGameViewModel'e [SolutionToken] (number(value:Int, tileIndex:Int),
operator(String), paren) tut; currentSolution String'i bu listeden türet;
usedNumberIndices'ı View @State'inden çıkarıp ViewModel'de tokenlardan
hesaplanan computed property yap; Command pattern'daki
NumberSelectionCommand/OperatorSelectionCommand/ClearSolutionCommand
token bazında çalışsın. Aynı yaklaşımı LetterGameView'daki
usedLetterIndices/undo-redo senkron sorununa da uygula (harf seçimi
tileIndex ile ViewModel'de tutulsun; yinelenen harflerde
letters.firstIndex(of:) hatası kalksın).
```

---

### PROMPT 6 — Türkçe locale ve çevrimiçi sözlük (S7)

```
KelimeVeIslemV1'de tüm büyük/küçük harf dönüşümleri locale'siz yapılıyor;
Türkçede "i".uppercased() "I" ürettiği için (doğrusu "İ") potansiyel
doğrulama hataları ve bozuk TDK API çağrıları oluşuyor.

1) Projede geçen tüm uppercased()/lowercased() çağrılarını bul; kelime/harf
   işleyen her yerde (LetterGame.updateWord, canUseLetters,
   DictionaryService.validateWord/loadDictionarySync/findWords,
   LetterGameViewModel.updateWord) dil parametresine göre
   uppercased(with: Locale(identifier: "tr_TR")) / "en_US" kullanan tek bir
   String extension'a (örn. gameUppercased(for: GameLanguage)) geçir.

2) DictionaryService.makeAPIURL: sozluk.gov.tr'ye kelime BÜYÜK harfle
   gönderiliyor ve parseAPIResponse hata yanıtını ({"error": ...} sözlük
   objesi) sessizce false sayıyor. Kelimeyi Türkçe locale ile küçük harfe
   çevirip gönder; yanıtta hem başarı dizisini hem hata objesini açıkça
   ayır; ağ hatasında yerel sözlük sonucuna güvenilir şekilde geri düş
   (şu an çevrimiçi yol timeout olursa kelime yerel sözlükte olsa bile
   false dönme akışı var — validateWord'de önce yerel, sonra çevrimiçi
   sırası korunmalı ama çevrimiçi hata durumu yerel sonucu ezmemeli).

3) Bu dönüşümler için birim testler ekle: "istanbul"→"İSTANBUL",
   "ILIK"→canUseLetters doğru eşleşme, EN modda "i"→"I".
```

---

### PROMPT 7 — Seviye/zorluk sisteminin gerçekten çalışması (S11, S18)

```
KelimeVeIslemV1'de seviye tabanlı zorluk sistemi (LevelSystem.swift
DifficultyModifiers) tanımlı ama fiilen devre dışı. Düzelt:

1) LetterGameViewModel.startNewGame ve NumberGameViewModel.startNewGame'de
   "settings.xTimerDuration > 0 ? settings : difficulty" koşulu her zaman
   settings'i seçiyor (süre daima >0). Kural şu olsun: kullanıcı ayarı
   varsayılan değerdeyse (60/90) seviye zorluğunun süresi kullanılsın;
   kullanıcı süreyi elle değiştirmişse kullanıcı ayarı kazansın. Bunu
   GameSettings'e "usesCustomTimers: Bool" (Settings'te süre değiştirilince
   true) ekleyerek belirsizliği kaldır.

2) LevelSystem.getDifficulty seviye 1-9 için minLetterCount 4-5 üretiyor;
   LetterGameViewModel bunu geçersiz sayıp 9'a resetliyor. Harf sayısı
   aralığını oyunun desteklediği 6...12 bandına sıkıştır
   (min(max(6, hesaplanan), 12)) ve ViewModel'deki kopyalanmış doğrulama
   bloklarını tek yardımcıya indir.

3) allowedOperations hiç uygulanmıyor: NumberGameView'daki
   OperatorButtonsView'a izinli operatör listesi geçir; seviye <5'te ×,
   <15'te ÷ butonları gizlensin/devre dışı kalsın ve ifade doğrulaması da
   izinsiz operatörü reddetsin.

4) Sayı oyununda hedef seviyeden (difficulty.targetNumberRange), sayı havuzu
   kullanıcı ayarından (settings.difficultyLevel) geliyor — iki zorluk
   sistemi çakışıyor. Tek kaynak seç: seviye sistemi hedef VE havuz
   kompozisyonunu belirlesin; settings.difficultyLevel yalnızca
   practiceMode'da geçerli olsun. 

5) saveResult'taki duration hesabını (settings süresi - timeRemaining)
   gerçek geçen süreyle değiştir: oyun başlangıcında Date kaydet, gönderimde
   farkı al; alıştırma modundaki 999999 hack'ini de "timer yok" durumunu
   açıkça modelleyerek kaldır.
```

---

### PROMPT 8 — Başarım sisteminin tamamlanması (S8, S10)

```
KelimeVeIslemV1 başarım sistemini tamamla:

1) Kazanılan başarımlar kullanıcıya hiç gösterilmiyor:
   PersistenceService.checkAchievementsInternal sonucu atıyor (let _ =).
   saveResult dönüşüne yeni açılan başarımları da ekle (Level? yerine
   (levelUp: Level?, achievements: [Achievement]) benzeri bir sonuç tipi),
   ViewModel'lerde @Published newAchievements alanında yayınla ve oyun
   view'larında kısa bir "Başarım Kazanıldı" toast/banner'ı göster
   (LevelUpView'a benzer, mevcut tema bileşenleriyle).

2) use_all_letters başarımı hiçbir yerde kontrol edilmiyor: geçerli kelime
   havuzdaki TÜM harfleri kullandığında tetiklenmesini
   AchievementTracker.checkAchievements'a ekle (ResultDetails.letters'ta
   word.count == letters.count karşılaştırması).

3) words_100 / first_valid_word sayaçları letterGamesPlayed ile
   (geçersiz oyunlar dahil) artıyor: GameStatistics'e validWordsCount alanı
   ekle, yalnız isValid sonuçlarda artır, başarımlar bu alandan beslensin;
   mevcut kullanıcı verisi için makul migration yap (validWordsCount yoksa
   letterGamesPlayed'den başlat).

4) GameStatistics.update'te longestWord isValid kontrolünün dışında
   güncelleniyor — geçersiz kelimeler istatistiği kirletiyor; if isValid
   bloğunun içine taşı.

5) AchievementTracker.checkAchievements'taki elle yazılmış tekrar eden
   ~80 satırlık blokları, (achievementId, progressValue) çiftleri üzerinde
   dönen tek bir veri güdümlü döngüye indirger; updateAchievement'in unlock
   ANINI yakalayıp newlyUnlocked'a eklemesini progress karşılaştırmasıyla
   (öncesi kilitli/sonrası açık) yap — mevcut "== eşik değeri" kalıbı,
   eşiğin üzerinden atlayan güncellemelerde bildirimi kaçırıyor.

Tüm değişiklikler için birim test ekle.
```

---

### PROMPT 9 — Sayı oyunu kurallarının netleştirilmesi (S14, S15)

```
KelimeVeIslemV1 sayı oyununda oyuncu değerlendirmesi ile ipucu çözücü farklı
kural setleri kullanıyor; klasik Countdown/Bir Kelime Bir İşlem kurallarına
sabitle:

1) NumberGame.evaluateExpression/parser: her ara işlem sonucu pozitif tam
   sayı olmalı. Bölme yalnız kalansız bölünüyorsa, çıkarma sonucu negatif
   değilse geçerli olsun; aksi halde anlaşılır bir hata mesajıyla
   (örn. "7/2 tam bölünmüyor") ifade geçersiz sayılsın. Double tabanlı
   değerlendirmedeki Int(result) sessiz kesmesini kaldır.

2) NumberGenerator.findClosestSolution possibleResults listesine ÷ işlemini
   ekle (findSolution'daki tam bölme koşullarıyla aynı), böylece ipuçları
   eksiksiz olsun.

3) findSolution ilk çözümü döndürüyor; en az işlem adımlı çözümü tercih
   etmesi için iteratif derinleştirme (depth 1'den 4'e artan aramayı zaten
   findClosestSolution yapıyor) findSolution'a da uygulansın.

4) Parser için birim test paketi ekle: geçerli/geçersiz ifadeler, parantez,
   sıfıra bölme, kalanlı bölme reddi, negatif ara sonuç reddi,
   usesOnlyAvailableNumbers yinelenen sayı senaryoları.
```

---

### PROMPT 10 — Performans ve kod hijyeni (S12, S16, S17, S20, S21)

```
KelimeVeIslemV1'de performans ve hijyen temizliği yap:

1) LetterGameView ve NumberGameView headerView'ları her render'da
   PersistenceService.shared.loadSettings() çağırıyor (main thread'de
   queue.sync + JSON decode). Süre toplamını ViewModel'de bir kez hesaplayıp
   @Published/let olarak view'a ver; render yolunda hiçbir disk I/O kalmasın.

2) NumberGameViewModel.init ayarları Task ile asenkron yüklüyor (yarış
   durumu) — LetterGameViewModel gibi senkron yüklet.

3) Kullanılmayan Core Data iskeletini kaldır: Persistence.swift,
   KelimeVeIslemV1.xcdatamodeld ve pbxproj referansları (uygulama tamamen
   UserDefaults kullanıyor). ViewModel'lerdeki boş cancellables setlerini ve
   LetterGameView'daki işlevsiz isTextFieldFocused'ı da sil.

4) Depo temizliği: kök dizindeki geçici çalışma notlarını
   (COMPILATION_FIX.md, FIX_NOTES.md, FIX_COMPILATION_ERRORS.md,
   ENHANCEMENTS.md, CODEBASE_ANALYSIS.md) docs/ altına taşı veya sil;
   .DS_Store ve xcuserdata/ dosyalarını git'ten çıkar ve .gitignore ekle.

5) Bozuk lokalizasyon dosyalarını düzelt: Resources/Localizable.strings.en
   ve .tr iOS tarafından asla yüklenmiyor; içeriklerini gerçek
   en.lproj/tr.lproj yapısına (veya tek String Catalog'a) taşı, pbxproj'u
   güncelle. Kod içindeki hardcoded Türkçe UI metinlerini kademeli olarak
   NSLocalizedString'e almak için en sık görünen 20 metinle başla.

6) saveDailyChallengeLeaderboard "en son 50 kayıt" tutuyor ama adı
   leaderboard: skora göre sıralı top-50 tutacak şekilde düzelt VEYA
   adlandırmayı history olarak değiştir (UI metniyle birlikte) — hangisi
   ürün niyetine uygunsa onu seç ve tutarlı uygula.

7) Tüm print() loglarını os.Logger kategorilerine geçir; bozuk emoji
   kodlamalı (âœ…) satırları düzelt.
```

---

### PROMPT 11 — Test altyapısı ve CI (S13 hariç tüm düzeltmelerin güvencesi)

```
KelimeVeIslemV1'e test hedefi ve CI ekle:

1) KelimeVeIslemV1Tests unit test target'ı oluştur (pbxproj'a ekle). Öncelikli
   test alanları: NumberGame ifade parser'ı (geçerli/geçersiz/parantez/bölme),
   LetterGame.canUseLetters + calculateScore, NumberGenerator.findSolution /
   findClosestSolution, DailyChallengeStats.update streak mantığı (ardışık
   gün, gün atlama, aynı gün tekrar), LevelSystem XP eğrisi ve
   checkLevelUp, SeededRandomGenerator determinizmi (aynı seed → aynı dizi),
   DictionaryService.findWords harf frekans kontrolü.

2) Persistence katmanını test edilebilir yap: PersistenceService'e
   UserDefaults(suiteName:) enjeksiyonu ekle; deadlock düzeltmesinin
   regresyon testini (exportData/importData'nın ana thread'de tamamlandığı)
   timeout'lu test ile yaz.

3) .github/workflows/ci.yml ekle: macOS runner'da xcodebuild ile iOS
   Simulator hedefine build + test. Bu, "dosya diskte var ama target'ta yok"
   türü hataları (LevelSystem.swift vakası) anında yakalayacak.
```

---

### PROMPT 12 — İngilizce sözlük ve dil deneyimi (S13)

```
KelimeVeIslemV1'de İngilizce mod fiilen oynanamaz durumda: turkish_words.txt
50.500 kelime içerirken english_words.txt yalnız 662 kelime. 

1) english_words.txt'yi kamu malı bir İngilizce kelime listesiyle
   (örn. ENABLE/SCOWL türevi, yalnız 2-12 harfli, özel isim ve kısaltma
   içermeyen, büyük harfe normalize edilmiş) 50-80 bin kelimeye genişlet.
2) DictionaryService yüklemesinin büyüyen dosyayla ana thread'i
   bloklamadığını doğrula (yükleme zaten actor içinde; app init'te
   Task ile ısındırma korunmalı) ve yükleme süresini ölç.
3) Dil seçiminin uçtan uca tutarlılığını kontrol et: LetterGenerator EN
   frekans tablosunu, günlük meydan okuma ise şu an SADECE Türkçe harf
   üretiyor (DailyChallenge.generateChallenge) — EN kullanıcı için de
   dile uygun üretim yap veya günlük modun her zaman TR olduğunu UI'da
   açıkça belirt.
```

---

## Önerilen Uygulama Sırası

| Sıra | Prompt | Neden önce |
|---|---|---|
| 1 | PROMPT 1 | Proje derlenmeden hiçbir şey doğrulanamaz; deadlock veri kaybettirir |
| 2 | PROMPT 11 | Sonraki tüm düzeltmeler için güvenlik ağı |
| 3 | PROMPT 2, 3 | Kullanıcıya en görünür hatalar (süre akmıyor, ses yok) |
| 4 | PROMPT 5, 6 | Oyun içi doğruluk (giriş bütünlüğü, Türkçe doğrulama) |
| 5 | PROMPT 4, 8 | Mekaniklerin (combo, başarım) gerçekten çalışır hale gelmesi |
| 6 | PROMPT 7, 9 | Zorluk/kural tutarlılığı |
| 7 | PROMPT 10, 12 | Hijyen, performans, içerik |
