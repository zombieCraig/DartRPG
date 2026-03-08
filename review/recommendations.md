# Fe-Runners Journal: Review Synthesis & Recommendations

**Date**: 2026-03-07
**Sources**: Rulebook Analysis, UI/UX Flow Analysis, Performance Analysis

---

## Executive Summary

The Fe-Runners Journal app has a solid foundation — flexible state model, good widget organization, inline autocomplete, and automatic journaling of mechanical outcomes. However, **the core gameplay loop is broken by navigation friction**, and **the performance architecture causes unnecessary rebuilds and UI blocking**. The biggest single improvement would be streamlining the narrate-roll-record cycle so players can stay in their journal and tell their story.

---

## 1. Gameplay Flow vs. App Flow: Gap Analysis

### The Rulebook's Core Loop
The rulebook defines a simple, narrative-first loop:
1. **Narrate** the fiction (what's happening)
2. **Trigger a move** when the fiction demands it
3. **Roll and resolve** the move
4. **Apply outcomes** (adjust stats, progress, momentum)
5. **Narrate the result** (what happens next)
6. **Repeat**

The key insight: steps 1, 2, 5, and 6 are *writing*. Steps 3 and 4 are brief mechanical interruptions. The ratio is ~70% narrative / 30% mechanics. The app should mirror this — mechanics should be quick, inline interruptions to a writing flow, not separate destinations.

### Where the App Breaks the Loop

| Rulebook Flow Step | App Experience | Gap |
|---|---|---|
| Narrate the fiction | Journal editor — good | None |
| Trigger a move | Must open MoveDialog, browse/search, select | **5-7 clicks, context switch** |
| Roll and resolve | Dialog within dialog for results | **Nested dialogs, disorienting** |
| Apply outcomes | Momentum/stats not adjustable from journal | **Must navigate to Character tab** |
| Narrate the result | Back in journal editor | **Re-orientation needed** |
| Check quest progress | Ctrl+Q destroys journal context | **Lost editing state** |
| Begin a Session (advance clocks) | Must go to Quests tab → Clocks sub-tab | **No session-start workflow** |
| End a Session (catch-up milestones) | No guided end-session flow | **No session-end workflow** |

### Missing Gameplay Concepts

| Rulebook Concept | App Support | Notes |
|---|---|---|
| Factions | Not tracked | Rulebook requires 4+ factions with projects (clocks), relationships |
| World Truths | In app (under Settings) but buried | Should be more accessible during gameplay — easy reference from journal or game setup |
| Connections/NPCs | Characters exist but no relationship progress tracks | Rulebook has Make a Connection, Develop Your Relationship, Forge a Bond moves with progress tracks |
| Legacy Tracks | Not visible | Quests, Bonds, Discoveries tracks with XP — central to advancement |
| Network Route Mapping | Can use Quest tracker mechanically, but UX mismatch | Same progress track mechanic, but should have its own identity — not labeled as a "quest" |
| Artifacts | Not tracked | Develop/Utilize/Reverse Engineer artifact moves |
| Rig Health | Not tracked separately | Base Rig has its own health meter (0-5) and impact conditions |
| Session Moves | No guided flow | Begin/End a Session are formal moves with mechanical effects |

---

## 2. Prioritized Recommendations

### P0 — Critical (High impact, directly blocks core experience)

#### P0-1: Streamline the Journaling Loop ("Quick Roll Panel")
**Problem**: Rolling a move from the journal takes 5-7 clicks across 6-7 context switches.
**Solution**: Add a slide-in side panel or bottom sheet for move rolling that:
- Shows 5-8 recently used / favorited moves
- One-tap to roll with remembered stat preference
- Result inserts directly into journal without a separate result dialog
- Panel stays open for rapid successive rolls
**Impact**: Reduces the most common action from 7 to 2 clicks. Eliminates the core "journaling loop" problem.
**Effort**: Medium

#### P0-2: Flatten Dialog Stacking
**Problem**: Move rolls can trigger oracle rolls, creating 3-4 nested dialogs. Users lose orientation.
**Solution**: Replace nested dialogs with a single panel/sheet that transitions between states (move selection → roll config → result → optional oracle). Use breadcrumbs or a back button within the panel rather than stacking.
**Impact**: Eliminates disorientation. Keeps users grounded in one UI context.
**Effort**: Medium-High

#### P0-3: Add Selector-Based Provider Rebuilds
**Problem**: 73 broad `Provider.of` calls, 0 `Selector` calls. Every state change rebuilds everything.
**Solution**: Introduce `Selector<GameProvider, T>` for the top offenders:
- Journal widgets selecting only `currentGame?.sessions`
- Character screen selecting only `currentGame?.characters`
- Location screen selecting only `currentGame?.locations`
- Quest screen selecting only `currentGame?.quests`
**Impact**: Dramatically reduces unnecessary rebuilds across the entire app.
**Effort**: Medium (incremental, can target worst offenders first)

#### P0-4: Move JSON Operations Off Main Thread
**Problem**: `Game.fromJsonString()` and `game.toJsonString()` block the UI for 100-500ms per game.
**Solution**: Use `compute()` isolates for JSON encode/decode. Particularly important for autosave.
**Impact**: Eliminates save/load UI freezes.
**Effort**: Low

### P1 — High Priority (Significant improvement to experience)

#### P1-1: Add Inline Stat/Momentum Adjustment from Journal
**Problem**: After rolling a move, applying mechanical outcomes (momentum, health, supply) requires navigating to the Character tab.
**Solution**: Show current character stats in the move result panel. Allow one-tap momentum/stat adjustments directly from the result before returning to writing.
**Impact**: Keeps the narrate-roll-record loop entirely within the journal.
**Effort**: Medium

#### P1-2: Consolidate Bottom Navigation (7 → 4-5 tabs)
**Problem**: 7 tabs exceeds mobile UX guidelines. Moves, Oracles, and Assets are primarily used from within the journal, not independently.
**Solution**:
- Keep: Journal, Characters, Locations, Quests/Clocks
- Demote Moves & Oracles to journal-toolbar-only access (they're already there)
- Move Assets into the Character detail screen
**Impact**: Cleaner navigation, less cognitive load, more screen space.
**Effort**: Medium

#### P1-3: Fix Quest Shortcut Context Destruction
**Problem**: Ctrl+Q from journal does `pushReplacement` to the Quests tab, destroying journal editing state.
**Solution**: Use a modal overlay, bottom sheet, or `push` (not `pushReplacement`) so the journal entry is preserved on the navigation stack.
**Impact**: Prevents lost work and maintains flow.
**Effort**: Low

#### P1-4: Add Connection/NPC Progress Tracks
**Problem**: The rulebook's Make a Connection / Develop Your Relationship / Forge a Bond flow is a core mechanic. Characters in the app don't have relationship progress tracks.
**Solution**: Add a `connectionRank` and `connectionProgress` to character model. Show progress track in character detail. Enable "Develop Relationship" and "Forge a Bond" moves to auto-update progress.
**Impact**: Supports a core gameplay mechanic that's currently manual/untracked.
**Effort**: Medium

#### P1-5: Cache Expensive Build Computations
**Problem**: 12+ instances of sorting, filtering, regex parsing inside `build()` methods.
**Solution**: Cache computed results in state. Key targets:
- `JournalEntryViewer`: Cache regex-parsed content keyed by content hash
- `MovesScreen`: Cache grouped/sorted moves, recompute only when moves data changes
- `OraclesScreen`: Cache search results and rollable table lookups
- `JournalScreen`: Cache entry-to-session mappings
**Impact**: Smoother scrolling and screen transitions.
**Effort**: Medium

### P2 — Medium Priority (Polish and completeness)

#### P2-1: Add Session Start/End Workflow
**Problem**: "Begin a Session" and "End a Session" are formal moves with mechanical effects (advance clocks, +1 momentum, catch-up milestones). The app has no guided flow for these.
**Solution**: When creating a new session, offer an optional "Begin a Session" wizard that:
- Shows campaign clocks and prompts to advance them
- Adds +1 momentum to active character
- Generates a journal entry summarizing the session start
Similarly, offer an "End a Session" prompt when the user closes a session.
**Impact**: Supports the session bookend moves that set the narrative frame.
**Effort**: Medium

#### P2-2: Add Character Stat Reference to Move Roll Dialog
**Problem**: Users must memorize stats or tab-switch to check them before choosing which stat to roll.
**Solution**: Show the active character's stat values directly in the move roll configuration panel.
**Impact**: Eliminates a common tab-switch.
**Effort**: Low

#### P2-3: Make Loading Screen Skippable
**Problem**: 3-second forced boot animation on every game launch.
**Solution**: Allow tap-to-skip, or reduce to 1 second for returning users (show full animation only on first launch).
**Impact**: Reduces friction for frequent players.
**Effort**: Low

#### P2-4: Split GameProvider into Focused Providers
**Problem**: 1,023-line god object with 32 `notifyListeners()` across 7+ domains.
**Solution**: Extract into CharacterProvider, LocationProvider, SessionProvider, QuestProvider, ClockProvider, AiConfigProvider. Keep GameProvider as a thin coordinator.
**Impact**: Architectural foundation for all other performance improvements.
**Effort**: High (but enables P0-3 to be even more effective)

#### P2-5: Add Image Cache Sizing
**Problem**: `Image.network()` without `cacheWidth`/`cacheHeight` caches full-resolution images in memory. Risk of OOM with many images.
**Solution**: Add `cacheWidth`/`cacheHeight` based on display size and device pixel ratio.
**Impact**: Prevents memory issues on image-heavy games.
**Effort**: Low

#### P2-6: Add Faction Tracking
**Problem**: Factions are a core world-building element (4+ required at setup) but aren't tracked in the app.
**Solution**: Add a Faction model with name, type, relationships, and associated campaign clocks. Could live under a "World" tab or section.
**Impact**: Supports campaign setup and ongoing faction project tracking.
**Effort**: Medium

### P3 — Low Priority (Future enhancements)

#### P3-1: Add Legacy Track Visualization
**Problem**: Legacy tracks (Quests, Bonds, Discoveries) are the primary XP and advancement system but aren't shown in the app.
**Solution**: Add legacy track display on the character sheet with XP counters. Auto-update when quests are fulfilled or bonds forged.
**Effort**: Medium

#### P3-2: Add Route/Infiltration Progress Tracks
**Problem**: Network navigation uses Map Route progress tracks. Players can use the quest tracker for this mechanically, but it's labeled as a "quest" which is a UX mismatch — routes aren't vows.
**Solution**: Add a dedicated "Route" progress track type that shares the same underlying mechanic as quests but has its own identity, terminology, and visual treatment. Could live under Locations or as a sub-tab alongside Quests.
**Effort**: Medium

#### P3-3: Implement GameProvider dispose() and Lazy Loading
**Problem**: Memory grows monotonically — no cleanup on game switch, no dispose.
**Solution**: Add dispose(), clear old game data on switch, lazy-load full game data on demand.
**Effort**: Medium

#### P3-4: Store Move IDs Instead of Full moveData
**Problem**: Every `MoveRoll` duplicates the full move data. 100 rolls = 100 copies.
**Solution**: Store only `moveId`, look up data from `DataswornProvider` at display time.
**Effort**: Low (but requires migration)

#### P3-5: Surface World Truths for Easy Reference
**Problem**: World truths exist in the app (under Settings) but are buried. Players need to reference them during gameplay to stay consistent with their world.
**Solution**: Make truths easily accessible — e.g., a quick-reference panel from the journal, or a prominent spot in game setup. Consider showing them during new game creation flow.
**Effort**: Low

---

## 3. Implementation Roadmap

### Phase 1: Core Flow (P0 items)
**Goal**: Make the narrate-roll-record loop fast and fluid.
- P0-1: Quick Roll Panel
- P0-2: Flatten Dialog Stacking
- P0-3: Selector-based rebuilds (top offenders)
- P0-4: Isolate JSON operations

### Phase 2: Complete the Loop (P1 items)
**Goal**: Keep players in the journal for the entire gameplay loop.
- P1-1: Inline stat/momentum adjustment
- P1-2: Consolidate navigation tabs
- P1-3: Fix quest shortcut
- P1-4: Connection progress tracks
- P1-5: Cache build computations

### Phase 3: Session & World (P2 items)
**Goal**: Support the full session lifecycle and world tracking.
- P2-1: Session start/end workflow
- P2-2: Stat reference in move dialog
- P2-3: Skippable loading screen
- P2-4: Split GameProvider
- P2-5: Image cache sizing
- P2-6: Faction tracking

### Phase 4: Completeness (P3 items)
**Goal**: Full rulebook mechanic coverage.
- P3-1 through P3-5: Legacy tracks, routes, memory management, data dedup, world truths

---

## 4. Key Metrics to Track

| Metric | Current | Target | Measured By |
|--------|---------|--------|-------------|
| Clicks to roll a move from journal | 5-7 | 2-3 | Manual count |
| Max dialog nesting depth | 4 | 1-2 | Code review |
| Bottom navigation tabs | 7 | 4-5 | Visual count |
| Provider.of (broad) calls | 73 | <10 | Grep count |
| Selector (selective) calls | 0 | 50+ | Grep count |
| JSON operations on main thread | 3 | 0 | Code review |
| Rulebook mechanics coverage | ~60% | 90%+ | Feature checklist |
