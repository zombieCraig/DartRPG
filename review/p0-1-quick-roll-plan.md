# P0-1: Quick Roll Panel — Implementation Plan

**Priority**: P0 (Critical)
**Goal**: Reduce the most common gameplay action — rolling a move from the journal — from 5-7 clicks to 2-3 clicks.

---

## Problem Statement

The core gameplay loop is **narrate → roll → record → narrate**. Currently, rolling a move from the journal editor requires:

1. Click "Moves" toolbar button
2. MoveDialog opens → search or browse categories
3. Select a category
4. Select a move
5. Choose a stat
6. Click "Roll"
7. Review result dialog → click "Add to Journal"
8. Close dialog → resume writing

That's **7-8 interactions with 6-7 context switches**. Each switch interrupts the player's narrative flow. The Quick Roll Panel eliminates most of these by providing a persistent, lightweight panel with recently-used moves and one-tap rolling.

---

## Design Overview

### UX Concept: Slide-In Side Panel

A **right-side slide-in panel** (or bottom sheet on mobile) that:
- Opens from the journal entry toolbar (existing Moves button, or a new "Quick Roll" button)
- Stays open alongside the journal editor (not a modal dialog)
- Shows recently-used and favorited moves for fast access
- Allows one-tap rolling with remembered stat preferences
- Inserts results directly into the journal without a separate result dialog
- Supports the full move flow (stat selection, modifiers) for non-recent moves

### Key Interactions

| Action | Clicks (Current) | Clicks (Quick Roll) |
|--------|:-:|:-:|
| Roll a recently-used move with same stat | 7-8 | 2 (open panel + tap move) |
| Roll a recently-used move, different stat | 7-8 | 3 (open panel + tap move + pick stat) |
| Roll a new move | 7-8 | 4-5 (open panel + search + select + roll) |
| Roll an oracle from move result | 9-10 | 3-4 (inline in panel) |

---

## Architecture

### New Files

| File | Purpose |
|------|---------|
| `lib/widgets/journal/quick_roll_panel.dart` | Main Quick Roll Panel widget |
| `lib/widgets/journal/quick_roll_move_tile.dart` | Compact move tile with one-tap roll |
| `lib/widgets/journal/quick_roll_result_banner.dart` | Inline result display (replaces dialog) |
| `lib/services/recent_moves_service.dart` | Tracks recently-used moves and stat preferences |
| `test/widget/quick_roll_panel_test.dart` | Widget tests |
| `test/unit/recent_moves_service_test.dart` | Unit tests |

### Modified Files

| File | Change |
|------|--------|
| `lib/screens/journal_entry_screen.dart` | Add Quick Roll Panel integration (toggle, state, callbacks) |
| `lib/models/game.dart` | Add `recentMoves` and `favoriteMoves` fields to game state |
| `lib/providers/game_provider.dart` | Add methods for recent/favorite move persistence |

### No Changes Needed

| File | Reason |
|------|--------|
| `lib/services/roll_service.dart` | Already provides clean `performActionRoll()` / `performProgressRoll()` APIs |
| `lib/utils/dice_roller.dart` | Already works as standalone utility |
| `lib/models/journal_entry.dart` | `MoveRoll` model already has everything needed |
| `lib/widgets/journal/move_dialog.dart` | Kept as-is for full move browsing; Quick Roll Panel supplements it |

---

## Detailed Component Design

### 1. `RecentMovesService` (new)

Tracks recently-used moves and remembered stat preferences per game.

```dart
class RecentMoveEntry {
  final String moveId;
  final String moveName;
  final String? lastStat;       // Remembered stat preference
  final int useCount;
  final DateTime lastUsed;
  final bool isFavorite;
}

class RecentMovesService {
  // Max 10 recent moves stored per game
  static const int maxRecentMoves = 10;

  // Get recent moves sorted by lastUsed (most recent first)
  List<RecentMoveEntry> getRecentMoves(Game game);

  // Get favorite moves (user-pinned, always shown at top)
  List<RecentMoveEntry> getFavoriteMoves(Game game);

  // Record a move use (updates recency, count, and stat preference)
  void recordMoveUse(Game game, String moveId, String moveName, String? stat);

  // Toggle favorite status
  void toggleFavorite(Game game, String moveId);
}
```

**Storage**: Serialized as part of `Game.toJson()` in a `recentMoves` list. This keeps it per-game and uses existing persistence.

### 2. `QuickRollPanel` (new)

The main panel widget. Slides in from the right side of the journal editor.

**Layout (desktop/tablet)**:
```
┌─────────────────────────────────────────────────────┐
│ Journal Editor (shrinks)    │ Quick Roll Panel (320px)│
│                             │                         │
│ [text editing area]         │ ⭐ Favorites             │
│                             │ ┌─────────────────────┐ │
│                             │ │ Face Danger [Edge] ▶│ │
│                             │ │ Secure Advntg [Wits]▶│ │
│                             │ └─────────────────────┘ │
│                             │                         │
│                             │ 🕐 Recent                │
│                             │ ┌─────────────────────┐ │
│                             │ │ Compel [Heart]    ▶ │ │
│                             │ │ Gather Info [Wits] ▶│ │
│                             │ │ Aid Your Ally [?]  ▶│ │
│                             │ └─────────────────────┘ │
│                             │                         │
│                             │ [Search all moves...]   │
│                             │                         │
│                             │ ── Result ──────────── │
│                             │ Face Danger: STRONG HIT │
│                             │ d6(4)+Edge(3)=7         │
│                             │ vs d10(3), d10(5)       │
│                             │ [Insert] [Roll Again]   │
│                             └─────────────────────────┘
└─────────────────────────────────────────────────────┘
```

**Layout (mobile)**: Bottom sheet, half-screen height, same content in vertical scroll.

**Key behaviors**:
- **One-tap roll**: Tapping a move with a remembered stat immediately rolls and shows the inline result. No dialog.
- **Stat chooser**: If the move has no remembered stat (first use, or `[?]` indicator), tapping shows a compact stat chip row inline before rolling.
- **Inline result**: Result appears at the bottom of the panel (not a separate dialog). Shows outcome, dice values, and action buttons.
- **Auto-insert**: After rolling, the result text is automatically inserted at the cursor position in the journal editor. A snackbar confirms.
- **Panel persistence**: Panel stays open between rolls for rapid successive rolling.
- **Search fallback**: A search bar at the bottom allows finding any move (falls back to full MoveDetails flow within the panel).

### 3. `QuickRollMoveTile` (new)

A compact, tappable move row for the Quick Roll Panel.

```
┌──────────────────────────────────────┐
│ ⭐ Face Danger         [Edge ▼]  [▶] │
│    Action roll                       │
└──────────────────────────────────────┘
```

- Move name (bold)
- Remembered stat shown as chip (tappable to change)
- Roll type indicator (subtle)
- Play button or tap-anywhere to roll
- Long-press to toggle favorite
- Shows character's current stat value in the chip (e.g., "Edge (3)")

### 4. `QuickRollResultBanner` (new)

Inline result display that replaces the `RollResultView` dialog.

```
┌──────────────────────────────────────┐
│ ✅ STRONG HIT                        │
│ d6(4) + Edge(3) = 7                 │
│ vs d10(3), d10(5)                   │
│                                      │
│ [Insert ✓] [Roll Again] [Details]   │
│ [Burn Momentum (7→2)]              │
└──────────────────────────────────────┘
```

- Outcome with color coding (green/yellow/red)
- Compact dice breakdown
- Match indicator when challenge dice match
- **Insert**: Calls `onInsertText()` with `moveRoll.getFormattedText()`
- **Roll Again**: Re-rolls same move + stat
- **Details**: Opens full `RollResultView` dialog for outcome descriptions, embedded oracles
- **Burn Momentum**: Shown when applicable (same logic as existing `RollResultView`)

### 5. Journal Entry Screen Integration

Changes to `journal_entry_screen.dart`:

```dart
// New state
bool _quickRollPanelOpen = false;

// In build(), wrap the editor in a Row (desktop) or use an overlay (mobile):
Row(
  children: [
    Expanded(child: _buildEditor()),  // existing editor
    if (_quickRollPanelOpen)
      SizedBox(
        width: 320,
        child: QuickRollPanel(
          onMoveRollAdded: (moveRoll) {
            setState(() { _moveRolls.add(moveRoll); });
          },
          onInsertText: _insertTextAtCursor,
          onClose: () => setState(() { _quickRollPanelOpen = false; }),
        ),
      ),
  ],
)
```

The existing Moves toolbar button toggles the Quick Roll Panel instead of opening `MoveDialog`. A long-press (or secondary button) still opens the full `MoveDialog` for complete move browsing.

### 6. Game Model Changes

Add to `Game`:

```dart
List<Map<String, dynamic>> recentMoves;  // Serialized RecentMoveEntry list
```

This is a lightweight addition — just a list of `{moveId, moveName, lastStat, useCount, lastUsed, isFavorite}` maps persisted alongside existing game data.

---

## Implementation Steps

### Step 1: RecentMovesService + Game Model (Small, foundational)

1. Add `recentMoves` field to `Game` model with JSON serialization
2. Create `RecentMovesService` with in-memory logic + persistence through `Game`
3. Add `recordMoveUse()` and `toggleFavorite()` methods to `GameProvider`
4. Write unit tests for `RecentMovesService`

### Step 2: QuickRollMoveTile + QuickRollResultBanner (UI building blocks)

1. Create `QuickRollMoveTile` widget — compact move display with stat chip
2. Create `QuickRollResultBanner` widget — inline result with action buttons
3. Wire up `RollService` calls (reuse existing `performActionRoll`, `performProgressRoll`)
4. Handle momentum burn flow inline
5. Write widget tests

### Step 3: QuickRollPanel (Main panel assembly)

1. Create `QuickRollPanel` combining tiles, search, and result banner
2. Implement favorites section (pinned at top)
3. Implement recents section (sorted by last used)
4. Implement search with filtering (reuse move search logic from `MoveDialog`)
5. Implement stat selection flow for first-time moves
6. Handle progress rolls (show quest selector or manual progress inline)
7. Handle no-roll moves (simple perform button)
8. Write widget tests

### Step 4: Journal Integration (Wiring it together)

1. Modify `journal_entry_screen.dart` to add panel toggle state
2. Add responsive layout (side panel on desktop, bottom sheet on mobile)
3. Change Moves toolbar button to toggle Quick Roll Panel
4. Add keyboard shortcut (Ctrl+M now toggles Quick Roll Panel)
5. Wire up `onMoveRollAdded` and `onInsertText` callbacks
6. Record move usage after each roll (updates recents)
7. Update existing `MoveDialog` access (long-press or "Browse All" link in panel)

### Step 5: Sentient AI + Edge Cases

1. Handle Sentient AI triggers from Quick Roll Panel (show dialog when triggered)
2. Handle oracle rolls from move outcomes (link to "Details" flow)
3. Handle progress rolls with quest selection
4. Test with no main character selected (show error)
5. Test with empty move list (graceful empty state)
6. Test auto-save interaction (panel state shouldn't trigger autosave)

### Step 6: Polish

1. Add panel open/close animation (slide from right)
2. Add dice roll animation in result banner (brief, <500ms)
3. Ensure panel works correctly on all platforms (web, desktop, mobile)
4. Test with screen readers / accessibility
5. Update keyboard shortcut help text

---

## Decisions and Trade-offs

### Side Panel vs. Bottom Sheet
**Decision**: Side panel on desktop/tablet, bottom sheet on mobile.
**Rationale**: Side panel keeps the journal editor visible and usable while rolling. Bottom sheet is the mobile convention for secondary panels. The panel width (320px) leaves ample editor space on desktop.

### Auto-Insert vs. Manual Insert
**Decision**: Auto-insert after rolling, with an "Undo" option.
**Rationale**: The whole point is reducing clicks. If the user rolls from the Quick Roll Panel, they almost certainly want the result in their journal. Auto-inserting with a snackbar "Undo" covers the rare case where they don't.
**Alternative considered**: Require clicking "Insert" button. Rejected because it adds a click to every roll.

### Keep MoveDialog
**Decision**: Keep the existing `MoveDialog` as a secondary access path.
**Rationale**: The Quick Roll Panel optimizes for speed with known moves. Players still need a way to browse all moves by category, read full descriptions, and discover new moves. The full dialog serves that purpose. Access via long-press on toolbar button or "Browse All Moves" link in panel.

### Recent Moves Storage
**Decision**: Store in `Game` model (per-game, persisted via SharedPreferences).
**Rationale**: Different games may use different moves frequently. Per-game storage is natural. Max 10 entries keeps the data small. No database migration needed.

### Inline Result vs. Result Dialog
**Decision**: Inline result in panel by default, with "Details" button to open full dialog.
**Rationale**: Most rolls don't need the full result view — the player wants to see the outcome and continue writing. The "Details" button provides access to outcome descriptions, embedded oracles, and other rich content when needed.

---

## Testing Strategy

### Unit Tests
- `RecentMovesService`: recording, ordering, max limit, favorites, stat memory
- `Game` serialization: `recentMoves` round-trips through JSON correctly

### Widget Tests
- `QuickRollMoveTile`: renders correctly, tap triggers roll, long-press toggles favorite
- `QuickRollResultBanner`: shows correct outcome, action buttons work, momentum burn flow
- `QuickRollPanel`: shows favorites and recents, search filters moves, stat selection flow
- `JournalEntryScreen` integration: panel opens/closes, results insert into editor

### Manual Testing
- Full flow: open journal → open panel → roll → verify inserted text → roll again
- Mobile layout: bottom sheet behavior, scroll, dismiss
- Keyboard: Ctrl+M toggles panel, panel doesn't steal editor focus
- Edge cases: no character, no moves loaded, empty recents

---

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Panel steals focus from editor | Medium | Careful focus management; panel uses `FocusScope` to avoid capturing editor focus |
| Responsive layout breaks on small screens | Medium | Use `LayoutBuilder` to switch between side panel and bottom sheet at breakpoint |
| Auto-insert breaks editor undo stack | Low | Use same `_insertTextAtCursor` method already used by `MoveDialog` |
| Recent moves data bloats game JSON | Low | Hard cap at 10 entries; each entry is ~100 bytes |
| Sentient AI dialog interaction | Low | Reuse existing `SentientAiDialog.show()` — no change needed |

---

## Success Criteria

1. Rolling a recently-used move from the journal takes **2 taps** (open panel + tap move)
2. Rolling any move takes **≤ 4 taps** (open panel + search + select + roll)
3. Result is inserted into journal **without a separate dialog**
4. Panel **stays open** for rapid successive rolls
5. No regressions in existing `MoveDialog` flow
6. All new code has unit/widget test coverage
