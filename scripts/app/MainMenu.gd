extends CanvasLayer

const SETTINGS_POPUP_SCENE := preload("res://scenes/ui/main_menu/SettingsPopup.tscn")
const CombatUiTheme := preload("res://scripts/ui/theme/CombatUiTheme.gd")
const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")

const MENU_ITEMS := [
	{"button": "StartButton", "frame": "StartFrame", "callback": "_on_start_pressed"},
	{"button": "ExploreButton", "frame": "ExploreFrame", "callback": "_on_continue_pressed"},
	{"button": "BossButton", "frame": "BossFrame", "callback": "_on_boss_pressed"},
	{"button": "SettingsButton", "frame": "SettingsFrame", "callback": "_on_settings_pressed"},
	{"button": "QuitButton", "frame": "QuitFrame", "callback": "_on_quit_pressed"},
]

const MENU_ANIMATION_SECONDS := 0.16
const MENU_HOVER_SCALE := 1.13
const MENU_ADJACENT_SCALE := 1.065
const HOVER_HIGHLIGHT_SIZE := Vector2(1000.0, 120.0)
const HOVER_HIGHLIGHT_COLOR := Color(0.18, 0.75, 1.0, 0.7)

@onready var ui_root: Control = $MainMenuGeneratedUI

var _menu_entries: Array[Dictionary] = []
var _hovered_menu_index := -1
var _menu_tween: Tween
var _hover_highlight: ColorRect
var _settings_popup: Control

func _ready() -> void:
	_setup_menu_buttons()
	CombatUiMotion.bind_tree(ui_root)
	_refresh_continue_button()


# 无存档时把"继续航程"置灰不可点
func _refresh_continue_button() -> void:
	var has_save := RunManager.has_saved_run()
	var button := _find_button("ExploreButton")
	if button:
		button.disabled = not has_save
	var frame := _find_control("ExploreFrame")
	if frame:
		frame.modulate = Color(1, 1, 1, 1) if has_save else Color(1, 1, 1, 0.4)


func _find_button(node_name: String) -> Button:
	return ui_root.find_child(node_name, true, false) as Button


func _find_control(node_name: String) -> Control:
	return ui_root.find_child(node_name, true, false) as Control


func _setup_menu_buttons() -> void:
	_menu_entries.clear()
	_setup_hover_highlight()

	for config in MENU_ITEMS:
		var button_name := String(config["button"])
		var frame_name := String(config["frame"])
		var button := _find_button(button_name)
		var frame := _find_control(frame_name)

		if not button:
			push_warning("MainMenu button not found: %s" % button_name)
			continue
		if not frame:
			push_warning("MainMenu frame not found: %s" % frame_name)
			continue

		CombatUiTheme.style_button(button, true)
		var index := _menu_entries.size()
		var pivot := Vector2(frame.size.x, frame.size.y * 0.5)
		frame.pivot_offset = pivot

		button.pressed.connect(Callable(self, String(config["callback"])))
		button.mouse_entered.connect(_set_menu_hover.bind(index))
		button.mouse_exited.connect(_clear_menu_hover.bind(index))

		_menu_entries.append({
			"button": button,
			"frame": frame,
			"size": frame.size,
			"pivot": pivot,
			"base_position": frame.position,
			"base_anchor": frame.position + pivot,
			"base_scale": frame.scale,
		})

	_apply_menu_layout(false)


func _setup_hover_highlight() -> void:
	var menu_buttons := _find_control("MenuButtons")
	if not menu_buttons:
		push_warning("MainMenu MenuButtons node not found for hover highlight")
		return

	_hover_highlight = ColorRect.new()
	_hover_highlight.name = "HoverHighlight"
	_hover_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_highlight.size = HOVER_HIGHLIGHT_SIZE
	_hover_highlight.position = -HOVER_HIGHLIGHT_SIZE * 0.5
	_hover_highlight.color = Color.WHITE
	_hover_highlight.modulate.a = 0.0
	_hover_highlight.material = _create_hover_highlight_material()
	menu_buttons.add_child(_hover_highlight)
	menu_buttons.move_child(_hover_highlight, 0)


func _create_hover_highlight_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec4 highlight_color = vec4(0.18, 0.75, 1.0, 0.7);

void fragment() {
	vec4 item_color = COLOR;
	float fade = clamp(1.0 - abs(UV.x - 0.5) * 2.0, 0.0, 1.0);
	COLOR = vec4(highlight_color.rgb, highlight_color.a * fade * item_color.a);
}
"""

	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("highlight_color", HOVER_HIGHLIGHT_COLOR)
	return material


func _set_menu_hover(index: int) -> void:
	_hovered_menu_index = index
	_apply_menu_layout(true)


func _clear_menu_hover(index: int) -> void:
	if _hovered_menu_index != index:
		return
	_hovered_menu_index = -1
	_apply_menu_layout(true)


func _apply_menu_layout(animated: bool) -> void:
	if _menu_tween:
		_menu_tween.kill()
		_menu_tween = null

	if _menu_entries.is_empty():
		return

	var target_anchors: Array[Vector2] = []
	var target_scales: Array[Vector2] = []

	for i in range(_menu_entries.size()):
		var entry := _menu_entries[i]
		target_anchors.append(entry["base_anchor"])
		target_scales.append(_get_menu_scale(i))

	if _hovered_menu_index >= 0:
		_spread_menu_anchors(target_anchors, target_scales)

	if animated:
		_menu_tween = create_tween()
		_menu_tween.set_parallel(true)
		_menu_tween.set_trans(Tween.TRANS_QUAD)
		_menu_tween.set_ease(Tween.EASE_OUT)

	_apply_hover_highlight(target_anchors, target_scales, animated)

	for i in range(_menu_entries.size()):
		var entry := _menu_entries[i]
		var frame := entry["frame"] as Control
		var pivot := entry["pivot"] as Vector2
		var target_position := target_anchors[i] - pivot
		var target_scale := target_scales[i]
		if _hovered_menu_index >= 0:
			var distance: int = abs(i - _hovered_menu_index)
			frame.z_index = 20 - distance
		else:
			frame.z_index = 0
		if animated:
			_menu_tween.tween_property(frame, "position", target_position, MENU_ANIMATION_SECONDS)
			_menu_tween.tween_property(frame, "scale", target_scale, MENU_ANIMATION_SECONDS)
		else:
			frame.position = target_position
			frame.scale = target_scale


func _apply_hover_highlight(target_anchors: Array[Vector2], target_scales: Array[Vector2], animated: bool) -> void:
	if not _hover_highlight:
		return

	var target_alpha := 0.0
	var target_position := _hover_highlight.position
	if _hovered_menu_index >= 0:
		var entry := _menu_entries[_hovered_menu_index]
		var size := entry["size"] as Vector2
		var anchor := target_anchors[_hovered_menu_index]
		var scale := target_scales[_hovered_menu_index]
		var highlight_center := Vector2(anchor.x - size.x * scale.x * 0.5, anchor.y)
		target_position = highlight_center - HOVER_HIGHLIGHT_SIZE * 0.5
		target_alpha = 1.0

	if animated and _menu_tween:
		if target_alpha > 0.0 and is_zero_approx(_hover_highlight.modulate.a):
			_hover_highlight.position = target_position
		else:
			_menu_tween.tween_property(_hover_highlight, "position", target_position, MENU_ANIMATION_SECONDS)
		_menu_tween.tween_property(_hover_highlight, "modulate:a", target_alpha, MENU_ANIMATION_SECONDS)
	else:
		_hover_highlight.position = target_position
		_hover_highlight.modulate.a = target_alpha


func _get_menu_scale(index: int) -> Vector2:
	var entry := _menu_entries[index]
	var base_scale := entry["base_scale"] as Vector2

	if _hovered_menu_index < 0:
		return base_scale

	var distance: int = abs(index - _hovered_menu_index)
	if distance == 0:
		return base_scale * MENU_HOVER_SCALE
	if distance == 1:
		return base_scale * MENU_ADJACENT_SCALE
	return base_scale


func _spread_menu_anchors(target_anchors: Array[Vector2], target_scales: Array[Vector2]) -> void:
	for i in range(_hovered_menu_index - 1, -1, -1):
		var gap := _get_base_gap(i, i + 1)
		var upper_half := _get_scaled_half_height(i, target_scales)
		var lower_half := _get_scaled_half_height(i + 1, target_scales)
		target_anchors[i].y = target_anchors[i + 1].y - lower_half - upper_half - gap

	for i in range(_hovered_menu_index + 1, _menu_entries.size()):
		var gap := _get_base_gap(i - 1, i)
		var upper_half := _get_scaled_half_height(i - 1, target_scales)
		var lower_half := _get_scaled_half_height(i, target_scales)
		target_anchors[i].y = target_anchors[i - 1].y + upper_half + lower_half + gap


func _get_scaled_half_height(index: int, target_scales: Array[Vector2]) -> float:
	var entry := _menu_entries[index]
	var size := entry["size"] as Vector2
	return size.y * target_scales[index].y * 0.5


func _get_base_gap(upper_index: int, lower_index: int) -> float:
	var upper := _menu_entries[upper_index]
	var lower := _menu_entries[lower_index]
	var upper_size := upper["size"] as Vector2
	var lower_size := lower["size"] as Vector2
	var upper_scale := upper["base_scale"] as Vector2
	var lower_scale := lower["base_scale"] as Vector2
	var upper_anchor := upper["base_anchor"] as Vector2
	var lower_anchor := lower["base_anchor"] as Vector2
	var upper_bottom := upper_anchor.y + upper_size.y * upper_scale.y * 0.5
	var lower_top := lower_anchor.y - lower_size.y * lower_scale.y * 0.5
	return lower_top - upper_bottom


func _on_start_pressed() -> void:
	RunManager.clear_saved_run()  # 开新局丢弃旧存档
	GameManager.reset_run_state()
	RunManager.start_new_run()
	get_tree().change_scene_to_file("res://scenes/app/WorldMap.tscn")


func _on_continue_pressed() -> void:
	if not RunManager.load_saved_run():
		_refresh_continue_button()  # 存档意外缺失/损坏，刷新按钮状态
		return
	get_tree().change_scene_to_file("res://scenes/app/WorldMap.tscn")


func _on_boss_pressed() -> void:
	RunManager.cancel_run()
	GameManager.score = 0
	GameManager.player_hp = GameManager.PLAYER_MAX_HP
	GameManager.elapsed = 0.0
	get_tree().change_scene_to_file("res://scenes/app/BossSelect.tscn")


func _on_settings_pressed() -> void:
	if is_instance_valid(_settings_popup):
		return
	_settings_popup = SETTINGS_POPUP_SCENE.instantiate() as Control
	add_child(_settings_popup)
	_settings_popup.connect("closed", _on_settings_popup_closed)


func _on_settings_popup_closed() -> void:
	_settings_popup = null


func _on_quit_pressed() -> void:
	get_tree().quit()
