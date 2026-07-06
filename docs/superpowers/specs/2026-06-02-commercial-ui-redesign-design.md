# Commercial UI Redesign Design

## Goal

Refactor the game's core UI into a commercial-grade, cohesive sci-fi interface. The chosen direction is Furnace Alert as the core visual language, with Orbital Command used for readability and Void Cathedral used sparingly for boss/anomaly accents.

The redesign must include both visual styling and layout ergonomics. Buttons and interactive controls need larger, predictable hit areas, clear hover/pressed states, and positions that are easy to reach without sacrificing composition.

## Visual System

The base mood is high-pressure arcade combat: dark panels, red-orange warning energy, strong contrast, and a sense of launch-control urgency. Cyan is reserved for confirmation, focus, hover, selected states, and stable data boundaries. Purple/green anomaly colors are rare and used for special bosses, strange events, or occult cosmic states.

Primary palette:

- Danger red: `#ff4f6a`
- Furnace amber: `#ffb84d`
- Command cyan: `#52e8ff`
- Void violet: `#b78cff`
- Anomaly green: `#65f0a3`
- Deep panel: `#071018`
- Near black overlay: `#03070c`

Typography should use a technical, compact look. In Godot, prefer a consistent theme font if one is available in the project; otherwise use default fonts with controlled size, color, shadow, and uppercase technical labels. Avoid AI-generated text baked into images.

## Shared Components

Create a reusable UI foundation instead of styling every screen independently.

- `CombatUiTheme.gd`: constants and helpers for colors, common font sizes, spacing, panel styleboxes, bar styleboxes, and button states.
- `AlertPanel.tscn`: reusable sci-fi panel with optional title strip, severity state, and content slot.
- `CommandButton.tscn`: large command button with stable size, number/status text, hover cyan confirmation, and red/amber base style.
- `StatusBar.tscn`: HP, boss, frenzy, loading, and progress bar component with delayed/flash support where scripts need it.
- `SectionHeader.tscn`: compact title/kicker header for panels and screen sections.
- `BossCard.tscn`: boss selection card with name, family, threat label, accent color, and large click target.

These components should rely mostly on Godot `StyleBoxFlat`, `Panel`, `ColorRect`, and labels so they scale cleanly. Generated bitmap assets are allowed for large mood backgrounds, loading decorations, or non-textural surface detail, but not for core text or essential button geometry.

## Interaction Layout Rules

Every clickable element must be easy to hit and visually stable.

- Standard command buttons should be at least `190x48`.
- Primary commands should be at least `260x56`.
- Hover and pressed effects must not change layout size.
- Main actions belong in predictable button groups: right-side command stack, bottom action bar, or card grid.
- Combat HUD must stay near screen edges and avoid the player's active movement area.
- Popups should keep content in the center/left and actions in a bottom or lower-right action zone.
- The design should target the current 1920x1080 UI artboard while keeping anchors sensible for viewport scaling.

## Screen Designs

### Main Menu

Refactor `scenes/ui/main_menu/MainMenuGeneratedUI.tscn` and preserve `scripts/app/MainMenu.gd` behavior.

The current diagonal button stack should become a clearer right-side command stack or right-middle stepped stack. The title stays left/upper-left with launch-control framing. Buttons use the new `CommandButton` style and large click targets. Hover uses cyan confirmation light, while the base menu reads red/amber.

The settings popup continues to be opened from `MainMenu.gd`; only its style and layout change.

### Boss Select

Refactor `scenes/ui/boss_select/BossSelectUI.tscn`.

Replace small default buttons with a three-column card grid. Each boss card should expose a large click area, visible hover/selected state, boss family grouping, and accent color. The screen title and details panel should sit in a stable top/side area. Back stays as a fixed bottom action button.

The existing `scripts/app/BossSelect.gd` scene loading logic should be preserved. Node names used by that script must remain available or be adapted carefully.

### Combat HUD

Refactor `scenes/ui/hud.tscn`, `scenes/ui/player_status/PlayerStatusHUD.tscn`, and `scenes/ui/BossHUD.tscn`.

Player status should sit in a compact lower-left cluster: HP, frenzy, score, and urgent warnings. Boss status should sit in the upper-right or top edge, depending on battle readability. Bars need strong contrast and should remain readable over space backgrounds. Damage/low-health states may pulse red/amber briefly; normal state should stay calmer.

The HUD should not block the player, dense bullet zones, or boss telegraphs. Size and opacity must be restrained during gameplay.

### World Map

Refactor `scenes/ui/world_map/WorldMapUI.tscn`.

Use a full tactical command interface: top status strip, large map/content zone, right details panel, and bottom action/message area. Buttons must be grouped and sized consistently. The details panel should use `AlertPanel` and `SectionHeader` styling.

Preserve `scripts/app/WorldMap.gd` logic and node access patterns.

### Shop, Hangar, Event Result, Equipment Rows

Refactor:

- `scenes/ui/world_map/ShopPopup.tscn`
- `scenes/ui/world_map/HangarPopup.tscn`
- `scenes/ui/world_map/EventResultPopup.tscn`
- `scenes/ui/world_map/EquipmentItemRow.tscn`

Shop and hangar should share a large modal layout: title/status header, scrollable equipment list, message area, and fixed bottom action bar. Equipment rows should become card-like rows with clear name/meta/description hierarchy and a large action button. Event results should use a smaller centered alert panel with clear confirm action.

### Exploration UI

Refactor `scenes/ui/explore/ExploreMapUI.tscn`, `scripts/ui/ExploreMapUI.gd`, `scenes/ui/explore/CompassMiniMap.tscn`, and `scenes/ui/explore/CommandConsolePopup.tscn`.

The full map overlay should gain a styled frame, title/status strip, visible drag bounds, and legend treatment for rewards, turrets, evacuation, and enemy paths. The minimap should remain compact in the lower-right but should look like the same UI family. The command console should become a bottom command terminal with red/amber shell and cyan caret/focus.

### Loading and Result States

Refactor:

- `scenes/ui/explore_loading/ExploreLoadingScreen.tscn`
- `scenes/ui/game_over/GameOverUI.tscn`
- `scenes/ui/EvacuationSuccessHUD.tscn`

The loading screen already has custom art; align it to the new palette and typography. Game over should become a dramatic red/amber result panel with final score and large restart/menu actions. Evacuation success should use cyan as the stable/safe success signal with amber details.

### Settings

Refactor `scenes/ui/main_menu/SettingsPopup.tscn`.

The current placeholder should become a polished modal shell even if settings remain minimal. It needs a clear title, concise message, and large close button. If new settings are added later, the panel should already support rows/toggles/sliders.

## Asset Generation

Use generated bitmap assets only where they materially improve mood:

- optional main menu background overlay or command-frame texture
- loading screen decorative panel texture
- result popup ambience texture

Do not generate UI text in images. Do not replace scalable component geometry with bitmap-only buttons if a Godot stylebox can achieve the same result.

Generated project assets should be saved under `assets/images/ui/commercial_redesign/` with non-destructive filenames.

## Testing and Verification

Verification must include:

- Godot project parse/run check.
- Scene load checks for every refactored UI scene.
- Manual or scripted visual checks at 1920x1080.
- Interaction checks for main menu, boss select, settings popup, world map popup buttons, and game over restart.
- Layout checks that buttons are large enough and HUD does not cover the central play area.

The redesign is complete only when all listed core UI scenes have the shared commercial style, improved layout ergonomics, and verified functionality.

