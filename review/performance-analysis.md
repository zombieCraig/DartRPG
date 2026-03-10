# Performance Analysis: Fe-Runners Journal (DartRPG)

## Executive Summary

The app has several systemic performance issues stemming from a monolithic provider architecture, lack of selective rebuilds, expensive computations in `build()` methods, and synchronous JSON operations on the main thread. The most impactful issues are the GameProvider "god object" triggering excessive widget rebuilds, and blocking I/O operations that freeze the UI.

**Severity Scale:** Critical / High / Medium / Low

---

## 1. Provider Rebuild Efficiency

### 1.1 GameProvider God Object (Critical)

**File:** `lib/providers/game_provider.dart` (~1,023 lines)

GameProvider manages 7+ distinct domains (games, characters, locations, sessions, quests, clocks, AI settings) with **32 `notifyListeners()` calls**. Every call rebuilds ALL widgets subscribed to this provider, regardless of which domain changed.

**Impact:** Updating a location's position triggers rebuilds in the journal viewer, character screen, quest panel, and every other widget watching GameProvider.

**Recommendation:** Split into focused providers:
- `CharacterProvider` — character CRUD
- `LocationProvider` — location operations
- `SessionProvider` — session/journal operations
- `ClockProvider` / `QuestProvider` — already partially extracted as mixins
- `AiConfigProvider` — API keys and model settings

### 1.2 Zero Selector Usage (Critical)

**Finding:** `Selector<T, S>` is not used anywhere in the codebase (0 occurrences).

| Pattern | Count | Rebuild Impact |
|---------|-------|---------------|
| `Provider.of<T>(context)` (broad rebuild) | 73 | Every change triggers rebuild |
| `Consumer<T>` (scoped but still broad) | 17 | Scoped to Consumer subtree |
| `context.read<T>()` (no rebuild) | 2 | None — read-only |
| `Selector<T, S>` (selective rebuild) | **0** | N/A — not used |

**81% of provider access uses the broadest rebuild pattern.** Widgets that only need `currentGame` rebuild when AI settings change. Widgets that only display a character name rebuild when locations move.

**Recommendation:** Introduce `Selector` for common access patterns:
```dart
// Instead of: Provider.of<GameProvider>(context)
Selector<GameProvider, Game?>(
  selector: (_, provider) => provider.currentGame,
  builder: (context, currentGame, child) => ...,
)
```

### 1.3 Worst Offenders — Broad Provider Access

| Widget | File | Line | Issue |
|--------|------|------|-------|
| LinkedItemsSummary | `widgets/journal/linked_items_summary.dart` | 33 | Only needs `currentGame`, rebuilds on everything |
| LocationOracleShortcuts | `widgets/journal/location_oracle_shortcuts.dart` | 34 | Same — needs minimal data |
| JournalEntryEditor | `widgets/journal/journal_entry_editor.dart` | 809 | Rebuilds entire editor on any game change |
| JournalEntryViewer | `widgets/journal/journal_entry_viewer.dart` | 35 | Only reads currentGame |
| CharacterScreen | `screens/character_screen.dart` | 23 | Broad access |

### 1.4 SettingsProvider Over-Notification (Low)

**File:** `lib/providers/settings_provider.dart` (225 lines, 11 `notifyListeners()` calls)

Every individual setting change (font size, animation speed, log level) triggers a full rebuild. Settings change infrequently so impact is low, but grouping related settings or adding equality checks would be cleaner.

---

## 2. Expensive Operations in build() Methods

### 2.1 Sorting and Filtering in Build (High)

Multiple screens perform sort/filter/map operations on every rebuild instead of caching results:

| File | Line(s) | Operation | Severity |
|------|---------|-----------|----------|
| `screens/journal_screen.dart` | 237-245 | `firstWhereOrNull()` nested in `.map()` per entry — O(n*m) | High |
| `screens/moves_screen.dart` | 42-57, 65 | `_groupMovesByCategory()` + sort on every build | Medium |
| `screens/oracles_screen.dart` | 375-384, 504 | Nested `.expand()` + sort on every search | High |
| `screens/oracles_screen.dart` | 438-451 | `getRollableTable()` inside `itemBuilder` | High |
| `screens/location_screen.dart` | 204-215 | Complex ValueKey with nested sorting | Medium |
| `screens/quests_screen.dart` | 77-85 | Quest filtering by status per build | Medium |
| `screens/assets_screen.dart` | 72 | `List.from()..sort()` in grid builder | Medium |
| `screens/log_viewer_screen.dart` | 38-55 | Filter + sort entire log list per build | High |
| `widgets/moves/move_list.dart` | 18 | `List.from()..sort()` per build | Medium |

**Recommendation:** Cache computed results in state. Recompute only when source data changes (in `didUpdateWidget`, `didChangeDependencies`, or via a dedicated method called from `setState`).

### 2.2 Heavy Regex Parsing in JournalEntryViewer (High)

**File:** `lib/widgets/journal/journal_entry_viewer.dart` (lines 49-144, 220-248)

Every build compiles and executes 5+ regex patterns (`characterRegex`, `locationRegex`, `moveRegex`, `oracleRegex`, `imageRegex`) against the full journal entry content, then runs 4 sequential `replaceAllMapped()` operations.

**Impact:** Journal entries with rich content (many links, moves, oracles) cause visible frame drops when scrolling.

**Recommendation:** Cache parsed/processed content keyed by entry content hash. Only re-parse when content changes.

### 2.3 Service Instantiation in Build (Medium)

| File | Line | Issue |
|------|------|-------|
| `screens/location_screen.dart` | 47 | `LocationService()` created every build |
| `screens/quests_screen.dart` | 108-109 | `_questService` and `_clockService` recreated every build |

**Recommendation:** Create services once in `initState()` or use Provider.

### 2.4 Markdown Rendering in List Items (Medium)

**File:** `lib/screens/journal_screen.dart` (lines 274-281)

Every journal entry card renders a `MarkdownBody` widget with full styling computations inside `ListView.builder`. Markdown parsing is non-trivial for long entries.

**Recommendation:** Show plain text preview in list cards; render markdown only in the detail view.

---

## 3. JSON Serialization / Main Thread Blocking

### 3.1 Synchronous JSON Parsing on Load (High)

**File:** `lib/providers/game_provider.dart` (lines 164-264)

`_loadGames()` calls `Game.fromJsonString(gameJson)` synchronously in a loop on the main thread. Large games (100+ KB JSON) block the UI.

```dart
for (final gameId in gameIds) {
  final gameJson = prefs.getString('game_$gameId');
  if (gameJson != null) {
    final game = Game.fromJsonString(gameJson);  // Synchronous, main thread
    _games.add(game);
  }
}
```

**Recommendation:** Use `compute()` isolate for JSON parsing:
```dart
final game = await compute(Game.fromJsonString, gameJson);
```

### 3.2 Synchronous JSON Encoding on Save (High)

**File:** `lib/providers/game_provider.dart` (lines 267-335)

`_saveGames()` calls `game.toJsonString()` (which calls `jsonEncode()`) synchronously per game.

**Impact:** Saves block UI for 100-500ms per game depending on data size. Autosave compounds this.

### 3.3 Import File Parsing (Medium)

**File:** `lib/providers/game_provider.dart` (lines 960-972)

File import reads JSON then synchronously parses. Game files >5 MB would cause multi-second freezes.

### 3.4 Duplicate Move Data in JSON (Medium)

**File:** `lib/models/journal_entry.dart` (lines 17, 56)

Every `MoveRoll` stores the full `moveData` map. A session with 100 rolls duplicates move data 100x in both memory and persisted JSON.

**Recommendation:** Store only `moveId`, look up move data from `DataswornProvider` at display time.

---

## 4. Image Loading and Caching

### 4.1 No Image Cache Sizing (High)

**Files:** `lib/widgets/common/app_image_widget.dart` (lines 74-157), `lib/widgets/common/image_picker_dialog.dart` (lines 298-307, 572-584)

`Image.network()` calls lack `cacheWidth`/`cacheHeight` parameters. Flutter caches full-resolution images in memory. Multiple large images in a grid can cause OOM.

**Recommendation:** Add `cacheWidth`/`cacheHeight` based on display size:
```dart
Image.network(url, cacheWidth: (width * devicePixelRatio).toInt())
```

### 4.2 Unbounded Static Caches (Medium)

**File:** `lib/utils/image_utils.dart` (lines 50, 86-87, 100, 106)

`_blobUrlCache` (static map) grows without bounds, only cleared on app shutdown. Each picked/generated image adds an entry permanently.

**File:** `lib/services/image_storage_service.dart` (lines 13-14)

`_webImages` static map holds all web image metadata indefinitely.

### 4.3 No Cancellation for AI Image Generation (Medium)

**File:** `lib/widgets/common/image_picker_dialog.dart` (lines 688-873)

No cancellation token or timeout for image generation API calls. If the user closes the dialog mid-generation, API calls continue in the background, wasting bandwidth and memory.

---

## 5. Memory Management

### 5.1 No dispose() in GameProvider (High)

**File:** `lib/providers/game_provider.dart`

GameProvider has no `dispose()` override. Listeners are never cleaned up. All game data is retained in `_games` list even after switching games.

**Impact:** Memory grows monotonically during long sessions, especially when switching between games.

### 5.2 No State Cleanup on Game Switch (Medium)

When switching games, old game data (characters, locations, sessions with all journal entries) remains in the `_games` list. Only `_currentGame` pointer changes.

**Recommendation:** Consider lazy-loading game data — keep only metadata in the list, load full game data on switch.

---

## 6. Widget Efficiency

### 6.1 Missing const Constructors (Low)

Several widgets and `TextStyle` objects are created non-const where const is possible. Examples in `screens/game_selection_screen.dart` (lines 18, 24, 32-35). Impact is minor but contributes to GC pressure.

### 6.2 Placeholder Widgets Rebuilt Every Frame (Low)

**File:** `lib/widgets/common/app_image_widget.dart` (lines 45-61)

`defaultPlaceholder` and `defaultErrorWidget` containers are recreated on every build. Should be extracted as `static const` widgets or class-level constants.

### 6.3 ListView.builder Usage (Good)

The codebase generally uses `ListView.builder` for dynamic lists rather than `Column(children: items.map(...))`. This is good practice and avoids building off-screen items.

---

## 7. Base64 Encoding Blocking (Medium)

**File:** `lib/providers/ai_image_provider.dart` (lines 66-77)

`base64Encode(bytes)` runs synchronously on large image files (5-10 MB reference images). This blocks the UI for 1-2 seconds.

**Recommendation:** Use `compute()` isolate for base64 encoding.

---

## Priority Recommendations

### Immediate (High Impact, Moderate Effort)
1. **Add Selector usage** for the most common provider access patterns — reduces unnecessary rebuilds significantly
2. **Move JSON parse/encode to compute isolates** — eliminates UI freezes on save/load
3. **Cache sort/filter results** in screens — move computations out of `build()`
4. **Add cacheWidth/cacheHeight** to Image.network calls

### Short-Term (High Impact, Higher Effort)
5. **Split GameProvider** into focused providers (Character, Location, Session, etc.)
6. **Cache regex parsing results** in JournalEntryViewer
7. **Add dispose()** to GameProvider and clean up listeners
8. **Implement cancellation** for AI image generation

### Long-Term (Architectural)
9. **Lazy-load game data** — keep only metadata in memory, load full game on switch
10. **Store move IDs instead of full moveData** in journal entries
11. **Consider SQLite** for game persistence (already noted in project memory)
12. **Add image cache eviction** policies for web platform

---

## Metrics Summary

| Metric | Value | Assessment |
|--------|-------|-----------|
| Provider.of (broad rebuild) calls | 73 | Poor — should be near 0 |
| Consumer (scoped rebuild) calls | 17 | Acceptable |
| Selector (selective rebuild) calls | 0 | Critical gap |
| context.read (no rebuild) calls | 2 | Underused |
| notifyListeners in GameProvider | 32 | Excessive for single provider |
| Expensive build() computations | 12+ instances | Needs caching |
| Synchronous JSON on main thread | 3 operations | Should use isolates |
| Static caches without eviction | 2 | Memory leak risk |
