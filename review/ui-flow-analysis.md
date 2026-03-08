# UI/UX Flow Analysis: Fe-Runners Journal

**Reviewer**: UI/UX Flow Reviewer
**Date**: 2026-03-07
**Scope**: Navigation hierarchy, interaction flow, journaling experience, and UX pain points

---

## 1. Navigation Hierarchy Overview

### Full Navigation Tree

```
GameSelectionScreen [ROOT - Level 0]
├── SettingsScreen (gear icon)
│   ├── AnimationTestScreen
│   ├── LogViewerScreen
│   ├── ChangelogScreen
│   └── BookOverviewScreen
├── NewGameScreen (create game)
└── GameScreen (select game → LoadingScreen → GameScreen) [Level 1]
    ├── Tab 0: JournalScreen
    │   ├── Session creation dialog
    │   ├── Session export dialog
    │   └── JournalEntryScreen [Level 2]
    │       ├── MoveDialog → RollResultView [Level 3-4]
    │       ├── OracleDialog → OracleResultView [Level 3-4]
    │       ├── CharacterDialog (quick-create) [Level 3]
    │       ├── LocationDialog (quick-create) [Level 3]
    │       └── LinkedItemsSummary (sidebar) [Level 3]
    ├── Tab 1: CharacterScreen
    │   ├── CharacterCreateDialog → InitialAssetsDialog [Level 2-3]
    │   ├── CharacterEditDialog [Level 2]
    │   └── CharacterDetailsPanel (inline) [Level 2]
    ├── Tab 2: LocationScreen
    │   ├── LocationGraphWidget (interactive canvas) [Level 2]
    │   ├── LocationListView [Level 2]
    │   └── LocationDialog (create/edit, recursive) [Level 2-3+]
    ├── Tab 3: QuestsScreen (3 sub-tabs + Clocks)
    │   ├── QuestDialog (create/edit) [Level 2]
    │   ├── QuestProgressPanel → RollResultView [Level 2-3]
    │   ├── ClockDialog (create/edit) [Level 2]
    │   └── ClockCard (advance/reset) [Level 2]
    ├── Tab 4: MovesScreen
    │   ├── MoveDetails panel [Level 2]
    │   └── RollResultView dialog [Level 3]
    ├── Tab 5: OraclesScreen
    │   ├── OracleCategoryScreen (recursive) [Level 2-3+]
    │   ├── OracleTableScreen [Level 3]
    │   └── OracleResultDialog [Level 3-4]
    └── Tab 6: AssetsScreen
        └── AssetContentWidget [Level 2]
```

**Maximum depth**: 4 levels (Root → GameScreen → JournalEntry → MoveDialog → RollResultView)
**Navigation style**: Bottom tab bar (7 tabs) + dialog-heavy interaction model
**Transition system**: Custom cyberpunk transitions via `NavigationService` (7 transition types)

---

## 2. Common Action Tap Counts

### Core Gameplay Actions

| Action | Tap/Click Count | Path |
|--------|:-:|------|
| **Start a new game** | 3-4 | GameSelection → New Game → fill form → Create |
| **Open an existing game** | 2 | GameSelection → tap game → (loading screen auto-navigates) |
| **Create a journal entry** | 2 | Journal tab → "New Entry" button → editor opens |
| **Write and save a journal entry** | 3 | New Entry → type text → Save (or auto-save after 10s) |
| **Roll a move from journal** | 5-7 | Editor toolbar → Move button → search/select move → pick stat → Roll → "Add to Journal" → close |
| **Roll an oracle from journal** | 4-6 | Editor toolbar → Oracle button → navigate categories → select table → Roll → "Add to Journal" |
| **Roll a move from Moves tab** | 4-5 | Moves tab → select move → pick stat → Roll → (optional: Add to Journal) |
| **Roll an oracle from Oracles tab** | 3-5 | Oracles tab → navigate categories → select table → Roll |
| **Create a character** | 4-6 | Characters tab → "+" → fill form → (optional: pick image, select assets) → Create |
| **Quick-create character from journal** | 3-4 | Editor toolbar → Character button → fill name/handle → Create |
| **Create a location** | 4-5 | Locations tab → "+" → fill form → (optional: set connections) → Save |
| **Create a quest** | 4-5 | Quests tab → FAB → fill form → select character → Create |
| **Advance a clock** | 2 | Clocks sub-tab → tap clock face |
| **Create a new session** | 3 | Journal tab → session dropdown → "New Session" → name it |
| **Switch between sessions** | 2 | Journal tab → session dropdown → select session |

### Multi-Step Gameplay Sequences

| Sequence | Total Taps | Assessment |
|----------|:-:|-----------|
| **"I want to make a move and journal the result"** (from Journal) | 7-9 | Too many steps for the most common action |
| **"I want to make a move and journal the result"** (from Moves tab) | 6-8 | Requires tab switch + move flow + "Add to Journal" |
| **"I want to roll an oracle and use the result in my story"** | 5-7 | Reasonable but could be tighter |
| **"I want to create a character, give them assets, and mention them in my journal"** | 10-15 | Long but inherently complex; quick-create from journal helps |
| **"I want to update quest progress and roll for completion"** | 3-4 | Well-streamlined |
| **"I want to record a location I just discovered and connect it to my current location"** | 5-7 | Reasonable |

---

## 3. Journaling Experience Assessment

### Strengths

1. **Rich inline editor**: The journal editor supports @character and #location mentions with autocomplete (Tab/Enter), reducing the need to leave the editor to reference game entities.

2. **Toolbar integration**: 11 toolbar buttons provide direct access to moves, oracles, characters, locations, quests, and formatting — all without leaving the journal entry screen.

3. **Quick-create dialogs**: Characters and locations can be created inline from the journal editor without navigating to their respective tabs.

4. **Auto-save**: 10-second inactivity timer auto-saves entries, preventing data loss.

5. **Keyboard shortcuts**: Ctrl+M (moves), Ctrl+Q (quests), Ctrl+N (new entry) speed up power-user workflows.

6. **Linked items tracking**: The LinkedItemsSummary sidebar shows all characters, locations, move rolls, and oracle rolls associated with the current entry.

7. **Automatic journaling**: Clock completion, quest completion, and quest progress rolls automatically generate journal entries with metadata, keeping the story record complete without manual effort.

### Weaknesses

1. **Move rolling is too many clicks**: The most frequent gameplay action (roll a move → record it) takes 5-7 clicks from the journal editor. The flow is: toolbar button → MoveDialog → search/browse → select move → configure stat/modifier → Roll → review result → "Add to Journal" → close dialog. This is the single biggest UX friction point.

2. **Dialog stacking**: Rolling a move that triggers an oracle creates nested dialogs (MoveDialog → RollResultView → OracleDialog → OracleResultView). Users can end up 3-4 dialogs deep, which is disorienting.

3. **Tab switching for context**: If a user is writing a journal entry and wants to check their character stats before choosing which stat to roll, they must either: (a) leave the entry screen entirely (losing context), or (b) rely on memory. There's no character stat reference available within the move roll dialog.

4. **No "recent moves" shortcut**: Every move roll starts from the full move list. There's no way to quickly re-roll a frequently used move (e.g., Face Danger, Secure an Advantage) without navigating the full selection flow each time.

5. **Oracle navigation depth**: Oracles use recursive category navigation (OracleCategoryScreen can push itself onto the stack). Users drilling into nested oracle categories can lose track of where they are in the hierarchy.

6. **Journal ↔ Quests disconnect**: The quest button in journal entry (Ctrl+Q) does a `pushReplacement` to GameScreen tab 3, which **replaces** the journal entry screen entirely. Users lose their editing context and must navigate back to their entry.

7. **No inline move result preview**: When adding a move roll to a journal entry, the result is inserted as formatted text. But the user can't preview how it will look in the entry before committing.

---

## 4. Navigation Pain Points

### 4.1 The "Journaling Loop" Problem

The core gameplay loop is: **narrate → roll → record → narrate**. Currently this loop is broken by navigation:

```
Journal Entry (editing)
  → Click "Roll Move" (opens dialog)
    → Browse/search moves (new context)
      → Select move (new panel)
        → Configure roll (stat selection)
          → View result (new dialog)
            → Click "Add to Journal" (returns to editor)
              → Resume writing
```

Each `→` is a context switch. The user's narrative flow is interrupted 6-7 times for a single move roll. **This is the most critical UX issue.**

**Recommendation**: Consider a streamlined "quick roll" panel that slides in from the side or bottom, showing recently-used moves with one-tap rolling. The result could be inserted directly without a separate result dialog.

### 4.2 The Seven-Tab Problem

The bottom navigation has 7 tabs: Journal, Characters, Locations, Quests, Moves, Oracles, Assets. This is a lot for a bottom bar — mobile UX guidelines typically recommend 3-5 tabs maximum.

**Issues**:
- Tab labels may be truncated or icons-only on small screens
- Users must remember which tab contains what
- Some tabs (Moves, Oracles) are primarily used *from within* the journal, not independently
- Assets tab is used infrequently (only during character creation/advancement)

**Recommendation**: Consider consolidating:
- Moves and Oracles could be accessible primarily from the journal toolbar (they already are) and demoted from top-level tabs
- Assets could be folded into the Character screen
- This would reduce to 4-5 tabs: Journal, Characters, Locations, Quests

### 4.3 Redundant Access Paths

Several features have multiple access paths that could confuse users:

| Feature | Access Path 1 | Access Path 2 | Access Path 3 |
|---------|--------------|--------------|--------------|
| **Roll a move** | Moves tab | Journal toolbar button | Keyboard shortcut (Ctrl+M) |
| **Roll an oracle** | Oracles tab | Journal toolbar button | Within move roll dialog |
| **Create character** | Characters tab | Journal toolbar quick-create | — |
| **Create location** | Locations tab | Journal toolbar quick-create | — |
| **View quests** | Quests tab | Journal keyboard shortcut (Ctrl+Q) | — |

Having multiple paths isn't inherently bad, but the **experience differs** between paths. Rolling a move from the Moves tab vs. from the journal toolbar produces different post-roll options ("Add to Journal" only appears when rolling from journal context). This inconsistency may confuse users.

### 4.4 Location Graph Complexity

The location graph uses a force-directed layout with custom gesture handling (pan, zoom, tap, long-press). This is visually impressive but:

- **Mobile usability concerns**: Force-directed graphs with touch gestures can be frustrating on small screens
- **Two view modes**: Users must discover the list/graph toggle; the graph is default but the list may be more practical
- **Recursive location creation**: LocationDialog can open itself to create connected locations, leading to arbitrary dialog nesting depth

### 4.5 Loading Screen Gate

Every game launch shows a `LoadingScreen` with a minimum 3-second animated boot sequence. While thematic, this is a forced wait that slows access to the actual game content. Returning users who switch between games frequently will feel this friction.

### 4.6 Quest Screen Sub-tabs

The Quests screen has 4 sub-tabs (Ongoing, Completed, Forsaken, Clocks) plus a character selector dropdown. Clocks being under Quests is a reasonable grouping, but:

- The character selector only appears for quest tabs, not clocks — this conditional UI may confuse users
- The FAB changes behavior based on active sub-tab (creates quest vs. creates clock) with no visual indication of the change

---

## 5. Widget Organization Assessment

### Well-Organized Areas

- **Feature directories**: Each major feature (journal, character, locations, quests, clocks, moves, oracles) has its own widget subdirectory with related widgets, dialogs, forms, panels, and service classes. This is clean and maintainable.

- **Service layer separation**: Business logic is extracted into service classes (CharacterService, LocationService, QuestService, ClockService, OracleService, RollService) rather than embedded in widgets.

- **Common widgets**: Shared components (EmptyStateWidget, SearchTextField, AppImageWidget, ImagePickerDialog) prevent duplication.

- **Dialog organization**: Character widgets have a proper `dialogs/` and `panels/` subdirectory structure that other features could emulate.

### Areas for Improvement

- **Standalone widget files**: ~25 widget files sit directly in `/widgets/` without subdirectories (animation widgets, painters, asset widgets, settings widgets). These could be organized into `animations/`, `assets/`, `settings/` subdirectories.

- **Journal widget count**: The journal directory has 11 files covering editor, viewer, toolbar, autocomplete, linked items, move dialog, oracle shortcuts, quick-add dialogs, rich text, and more. This reflects the complexity of the journaling experience but also suggests the editor may be trying to do too much in one screen.

---

## 6. State-Driven Navigation Constraints

### Required Navigation Order

1. **Must create/select a game** before anything else (enforced by GameSelectionScreen as root)
2. **Must have a session** to create journal entries (auto-created with new games)
3. Characters, locations, quests, clocks are all **optional and independent** — no forced creation order

### Good: No Circular Dependencies

The state architecture doesn't force users into any particular workflow order. A user can:
- Journal first, create characters later
- Create locations without characters
- Roll moves without quests
- Create clocks independently of quests

This flexibility supports different play styles and is a strong point of the architecture.

### Concern: GameProvider as Bottleneck

All UI state mutations flow through GameProvider (~1500 lines). While this centralizes persistence, it means:
- Any provider restructuring affects all screens
- Testing individual features requires mocking the entire GameProvider
- Performance: every `notifyListeners()` rebuilds all consumers, even if unrelated state changed

---

## 7. Summary of Key Findings

### Top 5 UX Pain Points (Priority Order)

1. **Move rolling from journal takes too many steps** (5-7 clicks for the most common action). A quick-roll panel or recent-moves shortcut would dramatically improve flow.

2. **Dialog stacking creates disorientation** — move rolls can trigger oracle rolls, creating 3-4 nested dialogs. Users lose track of their position.

3. **Seven bottom tabs exceed mobile UX guidelines** — Moves, Oracles, and Assets could be demoted from top-level tabs since they're primarily accessed contextually.

4. **Quest shortcut from journal destroys editing context** — Ctrl+Q does `pushReplacement`, losing the current journal entry state.

5. **3-second loading screen gate** on every game launch adds unnecessary friction for returning users.

### Top 5 UX Strengths

1. **Inline autocomplete** (@character, #location) keeps journaling flow smooth
2. **Quick-create dialogs** for characters/locations from journal editor
3. **Automatic journaling** of clock completions, quest completions, and progress rolls
4. **No forced workflow order** — flexible state model lets users play however they want
5. **Keyboard shortcuts** (Ctrl+M, Ctrl+Q, Ctrl+N) for power users

### Recommendations Summary

| Priority | Recommendation | Impact | Effort |
|----------|---------------|--------|--------|
| **P0** | Add "recent/favorite moves" quick-roll from journal | High — reduces most common action from 7 to 2-3 clicks | Medium |
| **P0** | Replace dialog stacking with slide-in panels or bottom sheets | High — eliminates disorientation from nested dialogs | High |
| **P1** | Consolidate bottom tabs from 7 to 4-5 | Medium — cleaner navigation, less cognitive load | Medium |
| **P1** | Fix quest shortcut to not destroy journal context (use overlay or split view) | Medium — prevents lost work | Low |
| **P2** | Make loading screen skippable or reduce to 1 second for returning users | Low-Medium — reduces friction | Low |
| **P2** | Add character stat reference to move roll dialog | Medium — eliminates tab-switching during rolls | Low |
| **P3** | Organize standalone widget files into subdirectories | Low — code maintainability only | Low |

---

## 8. Appendix: File Reference

### Screens (19 files)
`dart_rpg/lib/screens/`: game_selection_screen, game_screen, journal_screen, journal_entry_screen, character_screen, location_screen, quests_screen, moves_screen, oracles_screen, assets_screen, settings_screen, game_settings_screen, loading_screen, new_game_screen, home_screen, log_viewer_screen, book_overview_screen, changelog_screen, animation_test_screen

### Widget Directories (7 feature areas, ~119 files total)
- `widgets/journal/` (11 files) — Editor, viewer, toolbar, autocomplete, move/oracle dialogs, quick-add
- `widgets/character/` (24 files) — Cards, forms, dialogs, panels, services
- `widgets/locations/` (18 files) — Graph visualization, list view, dialog, services
- `widgets/quests/` (8 files) — Cards, forms, dialog, progress, tabs
- `widgets/clocks/` (8 files) — Cards, forms, dialog, animation, tabs
- `widgets/moves/` (9 files) — List, details, roll panels, result view
- `widgets/oracles/` (5 files) — Dialog, category list, table list, result view
- `widgets/common/` (4 files) — Shared UI components

### Providers (7 files)
`dart_rpg/lib/providers/`: game_provider, datasworn_provider, settings_provider, image_manager_provider, ai_image_provider, clock_operations_mixin, quest_operations_mixin

### Transitions (1 file)
`dart_rpg/lib/transitions/`: navigation_service
