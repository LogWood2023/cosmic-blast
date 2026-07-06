# Commercial UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a commercial-grade Furnace Alert UI system across all core Godot UI screens, with ergonomic button placement and verified scene functionality.

**Architecture:** Add a shared theme/helper layer first, then refactor screen scenes in groups while preserving existing gameplay/navigation scripts. Visual geometry should be scalable Godot UI where possible, with generated or existing image assets used only for atmosphere.

**Tech Stack:** Godot 4.6.2, GDScript, `.tscn` scenes, PowerShell/RTK verification scripts.

---

## File Map

Create:

- `scripts/ui/theme/CombatUiTheme.gd`: color/style factory helpers used by UI scripts and validation.
- `scripts/ui/theme/CommercialUiVerifier.gd`: headless validation script for theme helpers, scene loading, key nodes, and minimum button sizes.
- `scenes/ui/theme/CommandButton.tscn`: reusable command button template.
- `scenes/ui/theme/AlertPanel.tscn`: reusable modal/panel template.
- `scenes/ui/theme/StatusBar.tscn`: reusable bar template.
- `scenes/ui/theme/BossCard.tscn`: reusable boss card template.
- `assets/images/ui/commercial_redesign/README.md`: asset intent and generation notes.

Modify:

- `.gitignore`: already ignores `.superpowers/` preview scratch.
- `scenes/ui/main_menu/MainMenuGeneratedUI.tscn`
- `scenes/ui/main_menu/SettingsPopup.tscn`
- `scripts/app/MainMenu.gd`
- `scenes/ui/boss_select/BossSelectUI.tscn`
- `scripts/app/BossSelect.gd`
- `scenes/ui/player_status/PlayerStatusHUD.tscn`
- `scenes/ui/BossHUD.tscn`
- `scenes/ui/world_map/WorldMapUI.tscn`
- `scenes/ui/world_map/ShopPopup.tscn`
- `scenes/ui/world_map/HangarPopup.tscn`
- `scenes/ui/world_map/EventResultPopup.tscn`
- `scenes/ui/world_map/EquipmentItemRow.tscn`
- `scenes/ui/explore/ExploreMapUI.tscn`
- `scripts/ui/ExploreMapUI.gd`
- `scenes/ui/explore/CompassMiniMap.tscn`
- `scenes/ui/explore/CommandConsolePopup.tscn`
- `scenes/ui/explore_loading/ExploreLoadingScreen.tscn`
- `scenes/ui/game_over/GameOverUI.tscn`
- `scripts/app/GameOver.gd`
- `scenes/ui/EvacuationSuccessHUD.tscn`

## Task 1: Shared Theme And Verification Harness

**Files:**
- Create: `scripts/ui/theme/CombatUiTheme.gd`
- Create: `scripts/ui/theme/CommercialUiVerifier.gd`
- Create: `assets/images/ui/commercial_redesign/README.md`
- Test: `scripts/ui/theme/CommercialUiVerifier.gd`

- [ ] **Step 1: Write verifier script first**

Create `scripts/ui/theme/CommercialUiVerifier.gd` with checks for theme colors, stylebox creation, scene loading, and minimum clickable sizes.

```gdscript
@tool
extends SceneTree

const THEME := preload("res://scripts/ui/theme/CombatUiTheme.gd")

const SCENES := [
	"res://scenes/ui/main_menu/MainMenuGeneratedUI.tscn",
	"res://scenes/ui/main_menu/SettingsPopup.tscn",
	"res://scenes/ui/boss_select/BossSelectUI.tscn",
	"res://scenes/ui/player_status/PlayerStatusHUD.tscn",
	"res://scenes/ui/BossHUD.tscn",
	"res://scenes/ui/world_map/WorldMapUI.tscn",
	"res://scenes/ui/world_map/ShopPopup.tscn",
	"res://scenes/ui/world_map/HangarPopup.tscn",
	"res://scenes/ui/world_map/EventResultPopup.tscn",
	"res://scenes/ui/world_map/EquipmentItemRow.tscn",
	"res://scenes/ui/explore/ExploreMapUI.tscn",
	"res://scenes/ui/explore/CompassMiniMap.tscn",
	"res://scenes/ui/explore/CommandConsolePopup.tscn",
	"res://scenes/ui/explore_loading/ExploreLoadingScreen.tscn",
	"res://scenes/ui/game_over/GameOverUI.tscn",
	"res://scenes/ui/EvacuationSuccessHUD.tscn",
]

var _failures: Array[String] = []

func _init() -> void:
	_check_theme()
	_check_scenes_load()
	_check_button_sizes()
	if _failures.is_empty():
		print("Commercial UI verification passed")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)

func _check_theme() -> void:
	if THEME.DANGER_RED != Color("#ff4f6a"):
		_failures.append("DANGER_RED does not match design spec")
	var panel_style := THEME.make_panel_style()
	if panel_style == null:
		_failures.append("make_panel_style returned null")
	var button_style := THEME.make_button_style(THEME.STATE_NORMAL)
	if button_style == null:
		_failures.append("make_button_style returned null")

func _check_scenes_load() -> void:
	for scene_path in SCENES:
		var packed := load(scene_path) as PackedScene
		if packed == null:
			_failures.append("Scene failed to load: %s" % scene_path)
			continue
		var instance := packed.instantiate()
		if instance == null:
			_failures.append("Scene failed to instantiate: %s" % scene_path)
			continue
		instance.queue_free()

func _check_button_sizes() -> void:
	var scene_paths := [
		"res://scenes/ui/main_menu/MainMenuGeneratedUI.tscn",
		"res://scenes/ui/boss_select/BossSelectUI.tscn",
		"res://scenes/ui/world_map/WorldMapUI.tscn",
		"res://scenes/ui/main_menu/SettingsPopup.tscn",
		"res://scenes/ui/game_over/GameOverUI.tscn",
	]
	for scene_path in scene_paths:
		var packed := load(scene_path) as PackedScene
		if packed == null:
			continue
		var instance := packed.instantiate()
		_scan_buttons(scene_path, instance)
		instance.queue_free()

func _scan_buttons(scene_path: String, node: Node) -> void:
	if node is Button:
		var button := node as Button
		var size := button.custom_minimum_size
		if size == Vector2.ZERO and button is Control:
			size = (button as Control).size
		if size.x < 130.0 or size.y < 40.0:
			_failures.append("Button too small in %s: %s %s" % [scene_path, button.name, size])
	for child in node.get_children():
		_scan_buttons(scene_path, child)
```

- [ ] **Step 2: Run verifier and confirm it fails because theme file is missing**

Run: `rtk godot --headless --path . --script res://scripts/ui/theme/CommercialUiVerifier.gd`

Expected: fail with missing `CombatUiTheme.gd`.

- [ ] **Step 3: Implement theme helper**

Create `scripts/ui/theme/CombatUiTheme.gd`.

```gdscript
extends RefCounted

const STATE_NORMAL := "normal"
const STATE_HOVER := "hover"
const STATE_PRESSED := "pressed"
const STATE_DANGER := "danger"
const STATE_SUCCESS := "success"
const STATE_ANOMALY := "anomaly"

const DANGER_RED := Color("#ff4f6a")
const FURNACE_AMBER := Color("#ffb84d")
const COMMAND_CYAN := Color("#52e8ff")
const VOID_VIOLET := Color("#b78cff")
const ANOMALY_GREEN := Color("#65f0a3")
const DEEP_PANEL := Color("#071018")
const NEAR_BLACK := Color("#03070c")
const TEXT_MAIN := Color("#f8fbff")
const TEXT_MUTED := Color("#b7c4cf")

const MIN_BUTTON_SIZE := Vector2(190, 48)
const PRIMARY_BUTTON_SIZE := Vector2(260, 56)

static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)

static func make_panel_style(accent: Color = FURNACE_AMBER, fill_alpha: float = 0.88) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = with_alpha(DEEP_PANEL, fill_alpha)
	style.border_color = with_alpha(accent, 0.55)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 2
	style.content_margin_left = 18
	style.content_margin_top = 14
	style.content_margin_right = 18
	style.content_margin_bottom = 14
	return style

static func make_button_style(state: String = STATE_NORMAL) -> StyleBoxFlat:
	var accent := FURNACE_AMBER
	var fill := Color(0.18, 0.08, 0.06, 0.82)
	if state == STATE_HOVER:
		accent = COMMAND_CYAN
		fill = Color(0.05, 0.18, 0.22, 0.88)
	elif state == STATE_PRESSED:
		accent = DANGER_RED
		fill = Color(0.24, 0.05, 0.08, 0.94)
	elif state == STATE_ANOMALY:
		accent = VOID_VIOLET
		fill = Color(0.1, 0.07, 0.18, 0.88)
	var style := make_panel_style(accent, fill.a)
	style.bg_color = fill
	style.content_margin_left = 16
	style.content_margin_right = 16
	return style

static func make_bar_background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.025, 0.035, 0.9)
	style.border_color = Color(1, 1, 1, 0.18)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	return style

static func make_bar_fill(color: Color = FURNACE_AMBER) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	return style

static func apply_label(label: Label, size: int = 22, color: Color = TEXT_MAIN, shadow: Color = Color(0, 0, 0, 0.8)) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", shadow)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)

static func style_button(button: Button, primary: bool = false) -> void:
	button.custom_minimum_size = PRIMARY_BUTTON_SIZE if primary else MIN_BUTTON_SIZE
	button.add_theme_stylebox_override("normal", make_button_style(STATE_NORMAL))
	button.add_theme_stylebox_override("hover", make_button_style(STATE_HOVER))
	button.add_theme_stylebox_override("pressed", make_button_style(STATE_PRESSED))
	button.add_theme_stylebox_override("focus", make_button_style(STATE_HOVER))
	button.add_theme_color_override("font_color", TEXT_MAIN)
	button.add_theme_color_override("font_hover_color", TEXT_MAIN)
	button.add_theme_color_override("font_pressed_color", TEXT_MAIN)
	button.add_theme_font_size_override("font_size", 22)
```

- [ ] **Step 4: Add asset README**

Create `assets/images/ui/commercial_redesign/README.md`.

```markdown
# Commercial UI Redesign Assets

This folder is reserved for generated or curated mood assets used by the commercial UI redesign.

Core UI geometry should remain scalable Godot UI (`Panel`, `StyleBoxFlat`, `ColorRect`, labels, and buttons). Do not bake gameplay-critical text into images.
```

- [ ] **Step 5: Run verifier**

Run: `rtk godot --headless --path . --script res://scripts/ui/theme/CommercialUiVerifier.gd`

Expected: pass or only report button-size failures for scenes not yet refactored. If button-size failures appear, keep them as red checks for later tasks.

## Task 2: Main Menu And Settings

**Files:**
- Modify: `scenes/ui/main_menu/MainMenuGeneratedUI.tscn`
- Modify: `scenes/ui/main_menu/SettingsPopup.tscn`
- Modify: `scripts/app/MainMenu.gd`
- Test: `scripts/ui/theme/CommercialUiVerifier.gd`

- [ ] **Step 1: Confirm script node dependencies**

Run: `rtk rg -n "StartButton|ExploreButton|BossButton|SettingsButton|QuitButton|StartFrame|ExploreFrame|BossFrame|SettingsFrame|QuitFrame|MenuButtons|TitleLabel" scripts/app/MainMenu.gd scenes/ui/main_menu/MainMenuGeneratedUI.tscn`

Expected: all names are present before editing.

- [ ] **Step 2: Refactor main menu scene**

Replace the diagonal stack with right-side command frames named exactly `StartFrame`, `ExploreFrame`, `BossFrame`, `SettingsFrame`, `QuitFrame`. Each frame contains the existing button names and label nodes. Use custom minimum sizes at least `300x64`, anchor the stack to the right-middle, and apply red/amber base colors with cyan hover support through `MainMenu.gd`.

- [ ] **Step 3: Update `MainMenu.gd` styling**

Preload `CombatUiTheme.gd` and call `CombatUiTheme.style_button(button, true)` inside `_setup_menu_buttons()`. Keep the existing hover spread logic. Keep all callbacks unchanged.

- [ ] **Step 4: Refactor settings popup**

Use centered `AlertPanel` style with a large title, concise body, and `CloseButton` at least `260x56`. Preserve node names `SettingsPopup`, `Shade`, `Panel`, `TitleLabel`, `SettingsMessage`, `CloseButton`.

- [ ] **Step 5: Run verifier**

Run: `rtk godot --headless --path . --script res://scripts/ui/theme/CommercialUiVerifier.gd`

Expected: main menu and settings no longer report small-button failures.

## Task 3: Boss Select Cards

**Files:**
- Modify: `scenes/ui/boss_select/BossSelectUI.tscn`
- Modify: `scripts/app/BossSelect.gd`
- Create: `scenes/ui/theme/BossCard.tscn`
- Test: `scripts/ui/theme/CommercialUiVerifier.gd`

- [ ] **Step 1: Inspect current boss binding**

Run: `rtk rg -n "Boss[0-9]+Button|BackButton|pressed|change_scene|connect" scripts/app/BossSelect.gd scenes/ui/boss_select/BossSelectUI.tscn`

Expected: identify every button name the script expects.

- [ ] **Step 2: Create card template**

Create `scenes/ui/theme/BossCard.tscn` with root `Button`, minimum size `340x120`, child labels `NameLabel`, `FamilyLabel`, and `ThreatLabel`. Apply red/amber normal styling and cyan hover styling.

- [ ] **Step 3: Refactor boss select layout**

Keep button node names `Boss1Button` through the highest existing boss button so `BossSelect.gd` can still connect. Arrange them in a three-column grid inside a styled scroll/content area. Add a right-side or top details header. Make `BackButton` a fixed bottom primary command.

- [ ] **Step 4: Run verifier**

Run: `rtk godot --headless --path . --script res://scripts/ui/theme/CommercialUiVerifier.gd`

Expected: boss select scene loads and all buttons meet minimum size.

## Task 4: Combat HUD

**Files:**
- Create: `scenes/ui/theme/StatusBar.tscn`
- Modify: `scenes/ui/player_status/PlayerStatusHUD.tscn`
- Modify: `scenes/ui/BossHUD.tscn`
- Test: `scripts/ui/theme/CommercialUiVerifier.gd`

- [ ] **Step 1: Inspect scripts for node names**

Run: `rtk rg -n "ScoreLabel|LifeBar|FrenzyBar|YellowBar|RedBar|FlashBar|NameLabel|Frame|FillBar|BackBar|Label" scripts/ui scenes/ui/player_status scenes/ui/BossHUD.tscn`

Expected: list nodes that scripts mutate.

- [ ] **Step 2: Refactor player HUD**

Keep script-dependent node names. Place player status in lower-left, with compact HP/frenzy bars and score panel. Avoid center-screen overlap. Use red/amber for HP/danger and cyan for stable numeric labels.

- [ ] **Step 3: Refactor boss HUD**

Keep `FlashBar`, `RedBar`, `NamePlate`, `NameLabel`, and `Frame`. Reposition as upper-right/top-edge threat panel, readable over backgrounds, with restrained size.

- [ ] **Step 4: Run verifier**

Run: `rtk godot --headless --path . --script res://scripts/ui/theme/CommercialUiVerifier.gd`

Expected: HUD scenes load without script errors.

## Task 5: World Map, Shop, Hangar, Event Result

**Files:**
- Create: `scenes/ui/theme/AlertPanel.tscn`
- Modify: `scenes/ui/world_map/WorldMapUI.tscn`
- Modify: `scenes/ui/world_map/ShopPopup.tscn`
- Modify: `scenes/ui/world_map/HangarPopup.tscn`
- Modify: `scenes/ui/world_map/EventResultPopup.tscn`
- Modify: `scenes/ui/world_map/EquipmentItemRow.tscn`
- Test: `scripts/ui/theme/CommercialUiVerifier.gd`

- [ ] **Step 1: Inspect script dependencies**

Run: `rtk rg -n "TopBar|TitleLabel|StatsLabel|DetailsPanel|DetailsTitle|DetailsBody|EnterButton|ShopButton|HangarButton|MessageLabel|BackButton|ItemsList|CloseButton|ActionButton" scripts/app/WorldMap.gd scripts/ui/world_map scenes/ui/world_map`

Expected: know every node name that must be preserved.

- [ ] **Step 2: Refactor world map shell**

Create a tactical command layout: top status strip, large map/content area, right details panel, bottom action/message bar. Preserve all script node names.

- [ ] **Step 3: Refactor modal popups**

Shop and hangar share a large modal: title/status header, list, message area, bottom action bar. Event result uses a smaller centered alert panel. All close/confirm buttons at least `190x48`.

- [ ] **Step 4: Refactor equipment row**

Make each row a styled card with clear information hierarchy and a large `ActionButton`. Preserve `NameLabel`, `MetaLabel`, `DescriptionLabel`, and `ActionButton`.

- [ ] **Step 5: Run verifier**

Run: `rtk godot --headless --path . --script res://scripts/ui/theme/CommercialUiVerifier.gd`

Expected: world map and popups load; button sizes meet requirements.

## Task 6: Exploration UI

**Files:**
- Modify: `scenes/ui/explore/ExploreMapUI.tscn`
- Modify: `scripts/ui/ExploreMapUI.gd`
- Modify: `scenes/ui/explore/CompassMiniMap.tscn`
- Modify: `scenes/ui/explore/CommandConsolePopup.tscn`
- Test: `scripts/ui/theme/CommercialUiVerifier.gd`

- [ ] **Step 1: Add styled map frame support**

In `ExploreMapUI.gd`, update `_draw()` to draw a red/amber outer frame, cyan inner content line, title strip, and legend area around `_map_rect()`. Keep reward/turret syncing unchanged.

- [ ] **Step 2: Refactor minimap placement/style**

Keep minimap lower-right but ensure it has consistent commercial frame treatment and does not overlap critical bottom HUD clusters.

- [ ] **Step 3: Refactor command console**

Convert the console into a bottom terminal with visible shell frame, large readable input, cyan caret/focus, and red/amber border. Preserve `CommandDialogPanel`, `CommandDialogLabel`, `CommandInputPanel`, and `CommandInputEdit`.

- [ ] **Step 4: Run verifier**

Run: `rtk godot --headless --path . --script res://scripts/ui/theme/CommercialUiVerifier.gd`

Expected: exploration scenes load.

## Task 7: Loading, Game Over, Evacuation Success

**Files:**
- Modify: `scenes/ui/explore_loading/ExploreLoadingScreen.tscn`
- Modify: `scenes/ui/game_over/GameOverUI.tscn`
- Modify: `scripts/app/GameOver.gd`
- Modify: `scenes/ui/EvacuationSuccessHUD.tscn`
- Test: `scripts/ui/theme/CommercialUiVerifier.gd`

- [ ] **Step 1: Refactor loading palette**

Keep existing loading nodes and spinner animation. Align colors to red/amber core with cyan progress text and readable tip panel.

- [ ] **Step 2: Refactor game over**

Create a centered result panel with title, final score, restart button, and optional menu/back button if supported by `GameOver.gd`. Preserve `RestartButton` and `_on_restart_button_pressed`.

- [ ] **Step 3: Refactor evacuation success**

Use success cyan as primary accent, amber secondary details, large `EvacuateButton`, and centered safe result panel.

- [ ] **Step 4: Run verifier**

Run: `rtk godot --headless --path . --script res://scripts/ui/theme/CommercialUiVerifier.gd`

Expected: all result/loading scenes load; buttons meet size checks.

## Task 8: Final Verification

**Files:**
- Modify as needed based on failures.

- [ ] **Step 1: Run commercial verifier**

Run: `rtk godot --headless --path . --script res://scripts/ui/theme/CommercialUiVerifier.gd`

Expected: `Commercial UI verification passed`.

- [ ] **Step 2: Run project**

Run: `rtk godot --headless --path . --quit-after 5`

Expected: project starts without scene parse errors.

- [ ] **Step 3: Visual check**

Open the Godot project or run key scenes and inspect:

- Main menu: right-side large command buttons, no tiny click targets.
- Boss select: card grid, back button fixed and large.
- Combat HUD: lower-left player cluster and upper-right boss threat panel do not cover central play area.
- World map/popups: actions grouped, modal buttons reachable.
- Result/loading states: commercial style matches B core with A/C accents.

- [ ] **Step 4: Document verification**

Update this plan or final response with exact commands run and observed results.

## Self-Review

Spec coverage:

- Visual system: Task 1 and all screen tasks.
- Shared components: Tasks 1, 3, 4, 5.
- Interaction layout rules: verifier plus all screen tasks.
- Main menu/settings: Task 2.
- Boss select: Task 3.
- Combat HUD: Task 4.
- World map/shop/hangar/event/equipment: Task 5.
- Exploration UI: Task 6.
- Loading/game over/evacuation: Task 7.
- Testing and verification: Task 8.

Placeholder scan: no `TBD`, `TODO`, or deferred implementation language is used.

Type consistency: theme helper names and verifier constants are consistent across tasks.

