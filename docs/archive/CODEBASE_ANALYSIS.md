# Kelime Ve Islem V1 - Codebase Structure Analysis

## 1. MODELS DIRECTORY STRUCTURE

### Core Models Overview
The Models directory (`/Models/`) contains all data structures used throughout the app:

```
Models/
├── GameResult.swift       - Game session results
├── Achievement.swift      - Achievement/badge system
├── DailyChallenge.swift   - Daily challenge data structures
├── GameSettings.swift     - User configuration
├── LetterGame.swift       - Letter game state
├── NumberGame.swift       - Number game state
├── SavedGameState.swift   - Game state persistence
└── GameMode.swift         - Game mode enumerations
```

### Key Models Details

#### **GameResult.swift** (Game Statistics Foundation)
- **Purpose**: Records individual game session results
- **Structure**:
  ```swift
  struct GameResult: Codable, Identifiable {
      - id: UUID
      - mode: GameMode (letters or numbers)
      - score: Int
      - date: Date
      - duration: Int (seconds)
      - details: ResultDetails (enum with two cases)
  }
  
  enum ResultDetails:
      - letters: word, letters[], isValid
      - numbers: target, result?, solution, numbers[]
  ```
- **Success Criteria**:
  - Letters: Word validation result
  - Numbers: Within 10 of target number
- **Codable**: Fully serializable to UserDefaults

#### **GameStatistics.swift** (Aggregate Statistics)
- **Purpose**: Aggregate stats across all games (not a separate model file)
- **Defined in**: GameResult.swift
- **Tracks**:
  - `totalGamesPlayed`: Running count of games
  - `totalScore`: Cumulative score across all games
  - `letterGamesPlayed` & `numberGamesPlayed`: Mode-specific counts
  - `bestLetterScore` & `bestNumberScore`: Personal bests per mode
  - `longestWord`: Longest valid word created
  - `perfectNumberMatches`: Count of exact number matches
  - `lastPlayedDate`: Timestamp of most recent game
  - `averageScore`: Computed property (totalScore / totalGamesPlayed)
- **Key Methods**:
  - `update(with result: GameResult)` - Updates stats after each game
  - `reset()` - Returns fresh GameStatistics instance

#### **Achievement.swift** (Comprehensive Reward System)
- **Purpose**: Gamification and progression tracking
- **Main Structure**:
  ```swift
  struct Achievement: Identifiable, Codable {
      - id: String (unique identifier)
      - title: String (Turkish)
      - description: String (Turkish)
      - iconName: String (SF Symbols)
      - category: AchievementCategory
      - requirement: AchievementRequirement (enum)
      - isUnlocked: Bool
      - unlockedAt: Date?
      - progress: Int (current progress toward requirement)
  }
  ```
- **7 Achievement Categories**:
  1. `general`: Games played milestones (1, 10, 50, 100 games)
  2. `letters`: Word-related (first valid word, 100 words, long words, use all letters)
  3. `numbers`: Number game (perfect matches, precision)
  4. `speed`: Finish in 30 seconds or less
  5. `combo`: Consecutive successful submissions (5, 10 combos)
  6. `daily`: Daily challenge completion and streaks (1 challenge, 7-day streak)
  7. `mastery`: High score achievements (200+ points)

- **Requirement Types**:
  - `gamesPlayed(Int)` - Total games threshold
  - `validWords(Int)` - Valid letter game submissions
  - `perfectMatches(Int)` - Exact number matches
  - `wordLength(Int)` - Minimum word length
  - `speedInSeconds(Int)` - Time-based completion
  - `comboReached(Int)` - Consecutive successes
  - `dailyChallengesCompleted(Int)` - Daily challenge count
  - `consecutiveDays(Int)` - Daily streak length
  - `highScore(mode, score)` - Mode-specific score thresholds
  - `useAllLetters` - Binary achievement
  - `custom(String)` - Extensible for future achievements

- **Static Predefined Achievements**: 24 achievements pre-defined in `allAchievements`

#### **AchievementProgress.swift** (Achievement Tracking)
- **Purpose**: Tracks unlock status for all achievements
- **Structure**:
  ```swift
  struct AchievementProgress: Codable, Sendable {
      - achievements: [String: Achievement] (keyed by ID)
      - totalUnlocked: Int (computed property)
  }
  ```
- **Methods**:
  - `updateAchievement(_ id, progress)` - Update progress, auto-unlock at target
  - `unlockAchievement(_ id)` - Manual unlock
  - `getUnlockedAchievements()` - Sorted by unlock date
  - `getLockedAchievements()` - Sorted by progress percentage
  - `getAchievementsByCategory(_ category)` - Filtered and sorted view

#### **AchievementTracker** (Achievement Engine)
- **Purpose**: Core achievement checking logic
- **Initialization**: Singleton pattern (`AchievementTracker.shared`)
- **Key Methods**:
  - `checkAchievements(after result, with statistics)` - Called after each game
  - `checkComboAchievement(_ comboCount)` - Combo milestone checking
  - `checkDailyChallengeAchievements(stats)` - Daily challenge tracking
  - Returns: Array of newly unlocked achievements
- **Persistence Integration**: Saves progress via `PersistenceService`

#### **DailyChallenge.swift** (Daily Features)
- **DailyChallenge Structure**:
  - `id`: UUID
  - `date`: Challenge date
  - `mode`: GameMode (alternates daily)
  - `seed`: Integer based on date (deterministic)
  - `challengeData`: Either letters or numbers
  
- **Seeded Generation**: Uses `SeededRandomGenerator` for consistent daily generation
  - Letters: 3-4 vowels + consonants (9 total)
  - Numbers: Mix of small (1-10) and large (25, 50, 75, 100) numbers
  - Target: 101-999 for number challenges

- **DailyChallengeStats**:
  - `totalChallengesCompleted`
  - `currentStreak` & `longestStreak`
  - `bestScore` & `averageScore`
  - `lastCompletedDate`

- **DailyChallengeResult**: Records individual daily challenge completions

#### **SavedGameState.swift** (Game Resumption)
- **Purpose**: Persist incomplete games when app backgrounded
- **Validity**: Expires after 24 hours
- **Stores**:
  - Game type and timestamp
  - Time remaining and current score
  - Combo count
  - Game-specific state (letters/numbers)
- **Restoration Methods**:
  - `restoreLetterGame()` -> LetterGame?
  - `restoreNumberGame()` -> NumberGame?

#### **GameSettings.swift** (User Configuration)
- **Settings Fields**:
  ```swift
  - language: GameLanguage (Turkish/English)
  - letterCount: Int (6-12, default 9)
  - letterTimerDuration: Int (30-120 sec, default 60)
  - numberTimerDuration: Int (60-180 sec, default 90)
  - soundEnabled: Bool
  - useOnlineDictionary: Bool
  - difficultyLevel: DifficultyLevel (Easy/Medium/Hard)
  - selectedTheme: String
  - practiceMode: Bool (disables scoring/persistence)
  ```

- **Difficulty Levels** (affect number game difficulty):
  - Easy: 5 small + 1 large number
  - Medium: 4 small + 2 large numbers
  - Hard: 3 small + 3 large numbers

- **Default Settings**: Provided via static property

---

## 2. VIEWS/HOME DIRECTORY

### HomeView.swift Structure

**Layout Hierarchy**:
```
HomeView (ZStack with gradient background)
├── Title Section ("1 KELIME & 1 ISLEM")
├── Resume Game Button (conditional)
├── Game Mode Buttons
│   ├── Letters Game Button
│   ├── Numbers Game Button
│   └── Daily Challenge Button
├── Quick Stats (conditional - if games played)
└── Bottom Bar (3 buttons)
    ├── Achievements
    ├── Statistics
    └── Settings
```

**Key Components**:

1. **GameModeButton** - Reusable button component
   - Displays mode icon and description
   - Styled with gradient background
   - Shadowing and corner radius

2. **QuickStatsView** - Summary of player progress
   - Total Games Played
   - Average Score
   - Best Score (across both modes)
   - Displayed only if player has played games

3. **DailyChallengeButton** - Special daily challenge entry
   - Shows 2x multiplier badge
   - Gradient background (pink/purple theme)
   - "2x" points for daily completion

4. **ResumeGameButton** - Shows when saved game exists
   - Green gradient background
   - Indicates game type being resumed

5. **BottomBarButton** - Navigation to secondary screens
   - Achievements View
   - Statistics View
   - Settings View

**State Management in HomeView**:
- `@StateObject statisticsViewModel` - Loads stats on appear
- `@State selectedMode` - Routes to game
- `@State showSettings`, `showStatistics`, `showAchievements`, `showDailyChallenge`
- `@State savedGameState` - Checks for resumable games
- `@State resumeGame` - Flag for game restoration

**Navigation Patterns**:
- `.sheet()` for modal presentations (Settings, Statistics, Achievements, Daily Challenge)
- `.fullScreenCover()` for game views (preserves saved state restoration)

---

## 3. VIEW MODELS

### LetterGameViewModel
**@MainActor class** - UI thread safety guaranteed

**Published Properties**:
- `game: LetterGame?` - Current game state
- `currentWord: String` - Player's word input
- `timeRemaining: Int` - Countdown timer
- `gameState: GameState` - playing/paused/finished/ready
- `validationMessage: String` - User feedback
- `letterCount: Int` - Current letter count
- `suggestedWords: [String]` - Alternative words when invalid
- `comboCount: Int` - Consecutive valid submissions
- `showConfetti: Bool` - Visual celebration trigger
- `commandHistory: CommandHistory` - Undo/redo stack

**Game Flow Methods**:
1. `startNewGame()` - Generate letters, reset state, start timer
2. `updateWord(_ word: String)` - Update player's word input
3. `submitWord()` async - Main game action with validation pipeline:
   - Check available letters
   - Validate against dictionary (10-second timeout)
   - Update combo on success
   - Trigger confetti for 7+ letter words
   - Save result and statistics
4. `pauseGame()` & `resumeGame()`
5. `resetGame()` - Clean up and return to ready state

**Combo System**:
- Increments on valid word
- Resets on invalid word
- Multipliers: 1x → 2x (3 combo) → 3x (5 combo) → 5x (10 combo)
- Applied to final score

**Persistence Features**:
- `saveGameState()` - Save active game to resume later
- `restoreGameState(_ savedState)` - Restore and resume
- `clearSavedGameState()` - Delete saved state
- `saveResult()` - Record game result with statistics update

**Undo/Redo Support**:
- `selectLetter(_ letter)` - Add letter with command history
- `clearWordWithCommand()` - Clear word with undo capability
- `performUndo()` & `performRedo()`

**Timer Management**:
- `DispatchSourceTimer` for accurate countdown
- Tick sound every second in last 10 seconds
- Time warning sound at 10 seconds
- Auto-submit when time expires

**Timer Duration**: Configurable, default 60 seconds (adjustable in Settings)

---

### NumberGameViewModel
**@MainActor class** - Identical thread safety pattern

**Published Properties** (Similar structure to LetterGameViewModel):
- `game: NumberGame?`
- `currentSolution: String` - Math expression
- `timeRemaining: Int`
- `gameState: GameState`
- `resultMessage: String` - Result feedback
- `showHint: Bool` - Hint display toggle
- `hintSolution: [Operation]?` - Suggested operations
- `comboCount: Int`
- `showConfetti: Bool`
- `commandHistory: CommandHistory`

**Game Flow Methods**:
1. `startNewGame()` - Generate numbers and target, reset state
2. `updateSolution(_ solution: String)` - Update expression
3. `submitSolution()` - Evaluate expression:
   - Check number usage validity
   - Evaluate math expression
   - Calculate score based on difference from target
   - Update combo based on accuracy
4. `requestHint()` - Background solver for solutions

**Hint System**:
- Runs `NumberGenerator.findSolution()` on background thread
- Falls back to `findClosestSolution()` if exact match unavailable
- Updates UI safely via `@MainActor`

**Scoring in Number Game**:
- Perfect match (0 difference): 100 points
- Close (≤5): 80 - (difference × 10) points
- Medium (≤10): 50 - (difference × 3) points
- Far (≤20): 20 - difference points
- Too far (>20): 0 points

**Combo Rules**:
- Increment on perfect match (0 difference) or close match (≤5 difference)
- Reset on far miss (>5 difference) or invalid expression
- Same multipliers as letter game

**Timer Duration**: Configurable, default 90 seconds

---

### StatisticsViewModel
**@MainActor class** - UI-safe statistics aggregation

**Published Properties**:
- `statistics: GameStatistics` - Aggregate stats
- `recentResults: [GameResult]` - Last 20 games
- `topLetterScores: [GameResult]` - Top 10 letter scores
- `topNumberScores: [GameResult]` - Top 10 number scores
- `isLoading: Bool`
- `error: AppError?`

**Key Methods**:
- `init()` - Load from persistence
- `loadData()` - Refresh all statistics
- `refresh()` - Wrapper for loadData()
- `clearAllResults()` - Nuclear option to wipe all game data
- `formatResult(_ result)` - Display formatting
- `formatDate(_ date)` - Date string conversion

**Computed Properties**:
- `hasPlayedGames: Bool` - Check if user has any history
- `formattedAverageScore: String` - 1 decimal place
- `formattedLastPlayed: String` - Relative date format (e.g., "2 days ago")

**View Integration**: Shows statistics in StatisticsView with charts and detailed breakdowns

---

### DailyChallengeViewModel
**@MainActor class** - Daily challenge coordination

**Published Properties**:
- `todayChallenge: DailyChallenge` - Today's challenge
- `stats: DailyChallengeStats` - Player's daily stats
- `leaderboard: [DailyChallengeResult]` - Historical results
- `showChallengeGame: Bool` - Game view visibility
- `todayResult: DailyChallengeResult?` - Today's completion

**Key Methods**:
- `init()` - Load today's challenge and stats
- `startChallenge()` - Begin daily challenge
- `completeChallenge(with result)` - Save completion and update stats
- `refresh()` - Reload data and check for new day

**Streak Tracking**:
- Automatically tracks consecutive day completions
- Resets when a day is skipped
- Longest streak recorded separately

---

### AchievementsViewModel (in AchievementsView.swift)
**@MainActor class** - Embedded in view file

**Published Properties**:
- `progress: AchievementProgress` - All achievement states

**Key Methods**:
- `init()` - Load progress from AchievementTracker
- `refresh()` - Reload from tracker

---

## 4. GAME STATISTICS TRACKING & DATA PERSISTENCE

### Persistence Architecture

**PersistenceService** - Singleton pattern (`PersistenceService.shared`)

**Underlying Storage**: 
- `UserDefaults.standard` wrapped in thread-safe dispatch queue
- Persistent queue: `DispatchQueue(label: "com.kelimeveislem.persistence", qos: .userInitiated)`

**Stored Data Structures**:

1. **Settings** (key: `gameSettings`)
   - Encoded as JSON using `JSONEncoder`
   - Fallback to `.default` if corrupted

2. **Statistics** (key: `gameStatistics`)
   - Updated after every game result
   - Fallback to fresh `GameStatistics()` if corrupted
   - Auto-clears on corruption

3. **Game Results** (key: `gameResults`)
   - Stored as `[GameResult]` array
   - Max 100 most recent results (FIFO queue)
   - Results inserted at index 0 (newest first)
   - Includes detailed result info for each game

4. **Daily Challenge Stats** (key: `dailyChallengeStats`)
   - Streak information
   - Best and average scores
   - Challenge completion count

5. **Daily Challenge Leaderboard** (key: `dailyChallengeLeaderboard`)
   - Top 50 daily challenge results
   - Sorted by score

6. **Today's Challenge Result** (key: `todayChallengeResult`)
   - Only today's challenge result
   - Expires at midnight
   - Auto-cleared if from previous day

7. **Saved Game State** (key: `savedGameState`)
   - Single resumable game
   - Expires after 24 hours
   - Auto-cleared on load if expired

8. **Achievement Progress** (key: `achievementProgress`)
   - All achievements with unlock states
   - Progress counts toward requirements
   - Unlock timestamps

### Flow: Game Result → Statistics Update → Achievement Check

**Step 1**: Game ends, `GameResult` created
```swift
let result = GameResult(
    mode: .letters,
    score: finalScore,
    duration: timeTaken,
    details: resultDetails
)
```

**Step 2**: Save via `persistenceService.saveResult(result)`
```
Thread-safe queue:
  1. Load existing [GameResult] array
  2. Insert new result at index 0
  3. Keep only first 100 results
  4. Encode and save to UserDefaults
  5. Immediately call updateStatisticsInternal()
  6. Immediately call checkAchievementsInternal()
```

**Step 3**: Update statistics
```swift
statistics.update(with: result)
// Increments totalGamesPlayed, totalScore
// Updates mode-specific counters
// Stores in UserDefaults
```

**Step 4**: Check achievements (runs async in background)
```swift
AchievementTracker.shared.checkAchievements(
    after: result,
    with: statistics
)
// Returns newly unlocked achievements
// Saves updated progress
```

### Data Access Patterns

**Quick Access Helpers**:
- `getRecentResults(limit: 10)` - Last N results
- `getResultsByMode(_ mode)` - Filter by game type
- `getTopScores(mode, limit: 10)` - Sorted by score

**Statistics Loading**:
- `loadStatistics()` - Returns `GameStatistics`
- Called by `StatisticsViewModel.init()`
- Called on each statistics view refresh

### Backup & Export

**Export Function**: `exportData()` -> `Data`
- Creates `BackupData` structure with results, statistics, settings
- Includes version ("2.0") and export timestamp
- Encodes to JSON

**Import Function**: `importData(from data)` throws
- Decodes `BackupData` from JSON
- Overwrites local results, statistics, settings

### Error Handling

**Corruption Recovery**:
- Failed JSON decode → Auto-clear corrupted field
- Prints warning to console
- Returns safe default (empty array or default struct)
- No app crash

**Thread Safety**:
- All persistence operations use `queue.sync` for reads
- Results in potential 100ms blocking on main thread if used from main
- Recommendations: Load in `onAppear`, refresh in background

---

## 5. REWARD & ACHIEVEMENT SYSTEM

### Complete Achievement Taxonomy

**24 Pre-Defined Achievements**:

**General Category** (4 achievements):
1. "İlk Adım" (First Step) - Play 1 game
2. "Yolculuk Başlasın" (Journey Begins) - Play 10 games
3. "Deneyimli Oyuncu" (Experienced Player) - Play 50 games
4. "Efsane" (Legend) - Play 100 games

**Letter Game Category** (4 achievements):
5. "İlk Kelime" (First Word) - Create 1 valid word
6. "Kelime Ustası" (Word Master) - Create 100 valid words
7. "Uzun Kelime Ustası" (Long Word Master) - Create 9+ letter word
8. "Tüm Harfleri Kullan" (Use All Letters) - Use all available letters in one word

**Number Game Category** (2 achievements):
9. "İlk Mükemmel Eşleşme" (First Perfect Match) - Exact target number once
10. "Hassasiyet Ustası" (Precision Master) - Exact match 10 times

**Speed Category** (1 achievement):
11. "Hız Şeytanı" (Speed Demon) - Complete game in ≤30 seconds

**Combo Category** (2 achievements):
12. "Kombo Ustası" (Combo Master) - 5 combo streak
13. "Ateş Topu" (Fireball) - 10 combo streak

**Daily Challenge Category** (2 achievements):
14. "Günlük Zorluk" (Daily Challenge) - Complete 1 daily challenge
15. "Haftalık Seri" (Weekly Streak) - Complete 7 consecutive daily challenges

**Mastery Category** (1 achievement):
16. "Yüksek Skor" (High Score) - Achieve 200+ points in single game

### Achievement Unlock Mechanism

**AchievementTracker** - Singleton responsible for:

1. **Checking after each game**:
   ```swift
   checkAchievements(after result: GameResult, with statistics: GameStatistics) 
   -> [Achievement] // Newly unlocked
   ```
   - Compares statistics and result against requirement types
   - Updates progress counters
   - Unlocks when progress >= targetValue
   - Returns array of newly unlocked achievements for UI notification

2. **Checking combo achievements**:
   ```swift
   checkComboAchievement(_ comboCount: Int) -> [Achievement]
   ```
   - Called from game view when combo reached
   - Checks 5 and 10 combo thresholds

3. **Checking daily challenge achievements**:
   ```swift
   checkDailyChallengeAchievements(stats: DailyChallengeStats) -> [Achievement]
   ```
   - Tracks daily completion count and streak

### Progress Tracking

**Achievement Progress Properties**:
- `progress: Int` - Current count toward requirement
- `progressPercentage: Double` - 0.0 to 1.0 for UI bars
- `targetValue: Int` - Threshold from requirement enum
- `isUnlocked: Bool` - Achievement status
- `unlockedAt: Date?` - When unlocked

**Progress Update**: 
- `updateProgress(_ newProgress: Int)` - Updates and auto-unlocks
- `unlock()` - Manual unlock with timestamp

### UI Representation

**AchievementsView** displays:
- **Header**: "{X} / {total}" unlocked count with progress bar
- **Category Filter**: 7 category tabs + "All" filter
- **Achievement Cards**: 
  - For locked: Title, description, progress bar, progress text
  - For unlocked: Title, description, unlock date, star badge
  - Color coding: Gold gradient for unlocked, gray for locked
  - Icon from SF Symbols

**HomeView Integration**:
- "Başarımlar" (Achievements) button opens AchievementsView as sheet
- Quick access from main screen

### Persistence of Achievements

**Storage**: `AchievementProgress` → UserDefaults
- Saved async via `PersistenceService`
- Loaded on app start
- Reloaded when AchievementsView opens

---

## SUMMARY TABLE: Cross-Model Data Relationships

| Model | Purpose | Persistence | Updated By | Used By |
|-------|---------|-----------|-----------|---------|
| GameResult | Individual game record | UserDefaults (100 max) | LetterGameVM, NumberGameVM | StatisticsVM, PersistenceService |
| GameStatistics | Aggregate metrics | UserDefaults | PersistenceService (from GameResult) | StatisticsVM, HomeView, AchievementTracker |
| Achievement | Definition of achievement | Hardcoded static | - | AchievementTracker, AchievementsView |
| AchievementProgress | Unlock status for all achievements | UserDefaults | AchievementTracker | AchievementsView, AchievementTracker |
| DailyChallenge | Today's challenge | Generated on-demand | DailyChallengeViewModel | DailyChallengeView |
| DailyChallengeStats | Daily play metrics | UserDefaults | DailyChallengeViewModel | StatisticsView |
| DailyChallengeResult | Individual daily completion | UserDefaults (50 max leaderboard) | DailyChallengeViewModel | DailyChallengeViewModel |
| SavedGameState | Resumable game state | UserDefaults (1, expires 24h) | LetterGameVM, NumberGameVM | HomeView, LetterGameView, NumberGameView |
| GameSettings | User preferences | UserDefaults | SettingsView | All game ViewModels |

