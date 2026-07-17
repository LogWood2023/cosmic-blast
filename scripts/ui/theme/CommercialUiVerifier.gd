@tool
extends SceneTree

const THEME := preload("res://scripts/ui/theme/CombatUiTheme.gd")

const UI_ROOT := "res://scenes/ui"
const DRAWN_UI_SCRIPTS := [
	"res://scripts/ui/HealthBar.gd",
	"res://scripts/ui/HellEyeProgressRing.gd",
]
const MOTION_SCRIPT := "res://scripts/ui/theme/CombatUiMotion.gd"
const THEME_COMPONENT_SCENES := {
	"res://scenes/ui/theme/CommandButton.tscn": ["CommandButton"],
	"res://scenes/ui/theme/AlertPanel.tscn": ["AlertPanel", "TitleLabel", "Content", "ConfirmButton"],
	"res://scenes/ui/theme/StatusBar.tscn": ["StatusBar", "BackBar", "FillBar", "Label"],
	"res://scenes/ui/theme/BossCard.tscn": ["BossCard", "NameLabel", "FamilyLabel", "ThreatLabel"],
}
const MOTION_BINDING_SCRIPTS := [
	"res://scripts/app/MainMenu.gd",
	"res://scripts/app/BossSelect.gd",
	"res://scripts/app/WorldMap.gd",
	"res://scripts/app/GameOver.gd",
	"res://scripts/ui/main_menu/SettingsPopup.gd",
	"res://scripts/ui/world_map/ShopPopup.gd",
	"res://scripts/ui/world_map/HangarPopup.gd",
	"res://scripts/ui/world_map/EquipmentItemRow.gd",
	"res://scripts/ui/EvacuationSuccessHUD.gd",
]
const PANEL_ENTER_SCRIPTS := [
	"res://scripts/ui/main_menu/SettingsPopup.gd",
	"res://scripts/ui/world_map/ShopPopup.gd",
	"res://scripts/ui/world_map/HangarPopup.gd",
	"res://scripts/ui/EvacuationSuccessHUD.gd",
]

var _failures: Array[String] = []


func _init() -> void:
	var scenes := _collect_ui_scenes()
	_check_theme()
	_check_theme_component_scenes()
	_check_scene_files_exist(scenes)
	_check_button_sizes(scenes)
	_check_button_connectivity(scenes)
	_check_label_text_fit(scenes)
	_check_drawn_ui_colors()
	_check_motion_bindings()
	_check_charm_equipment_ui()
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


func _check_theme_component_scenes() -> void:
	for scene_path in THEME_COMPONENT_SCENES.keys():
		_require_scene_text(scene_path, THEME_COMPONENT_SCENES[scene_path])
		var packed := load(scene_path) as PackedScene
		if packed == null:
			_failures.append("Theme component scene failed to load: %s" % scene_path)
			continue
		var instance := packed.instantiate()
		if instance == null:
			_failures.append("Theme component scene failed to instantiate: %s" % scene_path)
			continue
		instance.queue_free()


func _collect_ui_scenes() -> Array[String]:
	var scenes: Array[String] = []
	_collect_ui_scenes_recursive(UI_ROOT, scenes)
	return scenes


func _collect_ui_scenes_recursive(path: String, scenes: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		_failures.append("Could not open UI scene directory: %s" % path)
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var child_path := path.path_join(entry)
		if dir.current_is_dir():
			_collect_ui_scenes_recursive(child_path, scenes)
		elif entry.ends_with(".tscn"):
			scenes.append(child_path)
		entry = dir.get_next()
	dir.list_dir_end()


func _check_scene_files_exist(scenes: Array[String]) -> void:
	if scenes.is_empty():
		_failures.append("No UI scenes found under %s" % UI_ROOT)
		return
	for scene_path in scenes:
		if not FileAccess.file_exists(scene_path):
			_failures.append("Scene file missing: %s" % scene_path)


func _check_button_sizes(scenes: Array[String]) -> void:
	for scene_path in scenes:
		_scan_button_sizes_from_scene(scene_path)


func _check_button_connectivity(scenes: Array[String]) -> void:
	for scene_path in scenes:
		_scan_button_connectivity_from_scene(scene_path)


func _scan_button_connectivity_from_scene(scene_path: String) -> void:
	if scene_path.begins_with("res://scenes/ui/theme/"):
		return
	var file := FileAccess.open(scene_path, FileAccess.READ)
	if file == null:
		_failures.append("Could not read scene for button connectivity: %s" % scene_path)
		return
	var text := file.get_as_text()
	var button_names := _extract_button_names(text)
	for button_name in button_names:
		if text.contains("signal=\"pressed\"") and (text.contains("from=\"%s\"" % button_name) or text.contains("/%s\" to=" % button_name)):
			continue
		if _button_has_script_binding(button_name):
			continue
		_failures.append("Button has no visible pressed connection or script binding in %s: %s" % [scene_path, button_name])


func _extract_button_names(scene_text: String) -> Array[String]:
	var names: Array[String] = []
	for line in scene_text.split("\n"):
		line = line.strip_edges()
		if line.begins_with("[node ") and line.contains("type=\"Button\""):
			var name := _extract_quoted_value(line, "name")
			if name != "":
				names.append(name)
	return names


func _button_has_script_binding(button_name: String) -> bool:
	var roots := ["res://scripts/app", "res://scripts/ui"]
	for root in roots:
		if _directory_scripts_contain(root, button_name):
			return true
	return false


func _directory_scripts_contain(path: String, button_name: String) -> bool:
	var dir := DirAccess.open(path)
	if dir == null:
		return false
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var child_path := path.path_join(entry)
		if dir.current_is_dir():
			if _directory_scripts_contain(child_path, button_name):
				dir.list_dir_end()
				return true
		elif entry.ends_with(".gd"):
			var file := FileAccess.open(child_path, FileAccess.READ)
			if file != null and file.get_as_text().contains(button_name):
				dir.list_dir_end()
				return true
		entry = dir.get_next()
	dir.list_dir_end()
	return false


func _check_label_text_fit(scenes: Array[String]) -> void:
	for scene_path in scenes:
		_scan_labels_from_scene(scene_path)


func _scan_labels_from_scene(scene_path: String) -> void:
	var file := FileAccess.open(scene_path, FileAccess.READ)
	if file == null:
		_failures.append("Could not read scene for label scan: %s" % scene_path)
		return

	var current_label := ""
	var text := ""
	var font_size := 16
	var autowrap := false
	var layout_mode := -1
	var offset_left := 0.0
	var offset_top := 0.0
	var offset_right := NAN
	var offset_bottom := NAN

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.begins_with("[node "):
			_flush_label_fit(scene_path, current_label, text, font_size, autowrap, layout_mode, offset_left, offset_top, offset_right, offset_bottom)
			current_label = ""
			text = ""
			font_size = 16
			autowrap = false
			layout_mode = -1
			offset_left = 0.0
			offset_top = 0.0
			offset_right = NAN
			offset_bottom = NAN
			if line.contains("type=\"Label\""):
				current_label = _extract_quoted_value(line, "name")
		elif current_label != "":
			if line.begins_with("layout_mode = "):
				layout_mode = int(_parse_float_value(line))
			elif line.begins_with("text = "):
				text = _extract_assignment_string(line)
			elif line.begins_with("theme_override_font_sizes/font_size = "):
				font_size = int(_parse_float_value(line))
			elif line.begins_with("autowrap_mode = "):
				autowrap = true
			elif line.begins_with("offset_left = "):
				offset_left = _parse_float_value(line)
			elif line.begins_with("offset_top = "):
				offset_top = _parse_float_value(line)
			elif line.begins_with("offset_right = "):
				offset_right = _parse_float_value(line)
			elif line.begins_with("offset_bottom = "):
				offset_bottom = _parse_float_value(line)

	_flush_label_fit(scene_path, current_label, text, font_size, autowrap, layout_mode, offset_left, offset_top, offset_right, offset_bottom)


func _flush_label_fit(scene_path: String, label_name: String, text: String, font_size: int, autowrap: bool, layout_mode: int, offset_left: float, offset_top: float, offset_right: float, offset_bottom: float) -> void:
	if label_name == "" or text == "" or is_nan(offset_right) or is_nan(offset_bottom):
		return
	if layout_mode != 0:
		return
	var size := Vector2(abs(offset_right - offset_left), abs(offset_bottom - offset_top))
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var estimated_text_width := _estimate_label_text_width(text, font_size)
	var estimated_line_height := float(font_size) * 1.35
	if not autowrap and estimated_text_width > size.x * 1.02:
		_failures.append("Label likely overflows horizontally in %s: %s text_width=%.1f rect_width=%.1f" % [scene_path, label_name, estimated_text_width, size.x])
	if autowrap:
		var lines := maxi(1, int(ceil(estimated_text_width / maxf(1.0, size.x))))
		if float(lines) * estimated_line_height > size.y * 1.08:
			_failures.append("Label likely overflows vertically in %s: %s lines=%d line_height=%.1f rect_height=%.1f" % [scene_path, label_name, lines, estimated_line_height, size.y])


func _estimate_label_text_width(text: String, font_size: int) -> float:
	var width := 0.0
	for i in text.length():
		var code := text.unicode_at(i)
		if code <= 0x7f:
			width += float(font_size) * (0.34 if char(code) == " " else 0.56)
		else:
			width += float(font_size)
	return width


func _check_drawn_ui_colors() -> void:
	for script_path in DRAWN_UI_SCRIPTS:
		var file := FileAccess.open(script_path, FileAccess.READ)
		if file == null:
			_failures.append("Could not read drawn UI script: %s" % script_path)
			continue
		var text := file.get_as_text()
		if not text.contains("#ff4f6a"):
			_failures.append("Drawn UI missing Furnace Alert danger token: %s" % script_path)


func _check_motion_bindings() -> void:
	if not FileAccess.file_exists(MOTION_SCRIPT):
		_failures.append("Missing UI motion driver: %s" % MOTION_SCRIPT)
	else:
		var motion_file := FileAccess.open(MOTION_SCRIPT, FileAccess.READ)
		var motion_text := motion_file.get_as_text() if motion_file != null else ""
		if not motion_text.contains("bind_button") or not motion_text.contains("animate_panel_enter"):
			_failures.append("UI motion driver missing button or panel animation helpers")
	for script_path in MOTION_BINDING_SCRIPTS:
		var file := FileAccess.open(script_path, FileAccess.READ)
		if file == null:
			_failures.append("Could not read motion binding script: %s" % script_path)
			continue
		var text := file.get_as_text()
		if not text.contains("CombatUiMotion"):
			_failures.append("UI script missing motion binding: %s" % script_path)
	for script_path in PANEL_ENTER_SCRIPTS:
		var file := FileAccess.open(script_path, FileAccess.READ)
		if file == null:
			_failures.append("Could not read panel enter script: %s" % script_path)
			continue
		if not file.get_as_text().contains("animate_first_panel_enter"):
			_failures.append("Popup/result UI missing panel enter animation: %s" % script_path)


func _check_charm_equipment_ui() -> void:
	_require_scene_text("res://scenes/ui/world_map/EquipmentItemRow.tscn", ["CrestSlot", "IconTexture", "CategoryLabel", "EffectLabel", "FlavorLabel", "CardButton", "ActionButton"])
	_require_scene_text("res://scenes/ui/world_map/HangarPopup.tscn", ["CharmBay", "CharmSlots", "ItemsScroll", "CloseButton"])
	_require_scene_text("res://scripts/ui/world_map/HangarPopup.gd", ["_refresh_compute_slots", "辅助装备", "算力"])


func _require_scene_text(path: String, required: Array) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_failures.append("Could not read required UI file: %s" % path)
		return
	var text := file.get_as_text()
	for token in required:
		if not text.contains(token):
			_failures.append("Required UI token missing in %s: %s" % [path, token])


func _scan_button_sizes_from_scene(scene_path: String) -> void:
	var file := FileAccess.open(scene_path, FileAccess.READ)
	if file == null:
		_failures.append("Could not read scene: %s" % scene_path)
		return

	var current_button := ""
	var custom_minimum := Vector2.ZERO
	var offset_right := NAN
	var offset_bottom := NAN
	var offset_left := 0.0
	var offset_top := 0.0

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.begins_with("[node "):
			_flush_button_size(scene_path, current_button, custom_minimum, offset_left, offset_top, offset_right, offset_bottom)
			current_button = ""
			custom_minimum = Vector2.ZERO
			offset_right = NAN
			offset_bottom = NAN
			offset_left = 0.0
			offset_top = 0.0
			if line.contains("type=\"Button\""):
				current_button = _extract_quoted_value(line, "name")
		elif current_button != "":
			if line.begins_with("custom_minimum_size = Vector2"):
				custom_minimum = _parse_vector2(line)
			elif line.begins_with("offset_left = "):
				offset_left = _parse_float_value(line)
			elif line.begins_with("offset_top = "):
				offset_top = _parse_float_value(line)
			elif line.begins_with("offset_right = "):
				offset_right = _parse_float_value(line)
			elif line.begins_with("offset_bottom = "):
				offset_bottom = _parse_float_value(line)

	_flush_button_size(scene_path, current_button, custom_minimum, offset_left, offset_top, offset_right, offset_bottom)


func _flush_button_size(scene_path: String, button_name: String, custom_minimum: Vector2, offset_left: float, offset_top: float, offset_right: float, offset_bottom: float) -> void:
	if button_name == "":
		return
	var size := custom_minimum
	if size == Vector2.ZERO and not is_nan(offset_right) and not is_nan(offset_bottom):
		size = Vector2(abs(offset_right - offset_left), abs(offset_bottom - offset_top))
	# Compact icon controls and filter chips are intentional in the current UI.
	# CardButton is an anchored overlay whose static offsets do not express its runtime size.
	if scene_path.ends_with("EquipmentItemRow.tscn") and button_name == "CardButton":
		return
	if size.x < 40.0 or size.y < 38.0:
		_failures.append("Button too small in %s: %s %s" % [scene_path, button_name, size])


func _extract_quoted_value(line: String, key: String) -> String:
	var marker := key + "=\""
	var start := line.find(marker)
	if start < 0:
		return ""
	start += marker.length()
	var end := line.find("\"", start)
	if end < 0:
		return ""
	return line.substr(start, end - start)


func _parse_vector2(line: String) -> Vector2:
	var start := line.find("(")
	var end := line.find(")", start)
	if start < 0 or end < 0:
		return Vector2.ZERO
	var parts := line.substr(start + 1, end - start - 1).split(",")
	if parts.size() < 2:
		return Vector2.ZERO
	return Vector2(float(parts[0].strip_edges()), float(parts[1].strip_edges()))


func _parse_float_value(line: String) -> float:
	var parts := line.split("=")
	if parts.size() < 2:
		return 0.0
	return float(parts[1].strip_edges())


func _extract_assignment_string(line: String) -> String:
	var start := line.find("\"")
	if start < 0:
		return ""
	start += 1
	var end := line.rfind("\"")
	if end < start:
		return ""
	return line.substr(start, end - start)
