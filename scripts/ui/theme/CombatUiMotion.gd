class_name CombatUiMotion
extends Node

const META_BOUND := &"combat_ui_motion_bound"
const HOVER_SCALE := Vector2(1.035, 1.035)
const PRESS_SCALE := Vector2(0.965, 0.965)
const NORMAL_SECONDS := 0.13
const PRESS_SECONDS := 0.07
const HOVER_COLOR := Color(1.08, 1.08, 1.08, 1.0)
const DISABLED_COLOR := Color(0.68, 0.68, 0.68, 0.72)
const PANEL_ENTER_SECONDS := 0.18

var _button: Button
var _base_scale := Vector2.ONE
var _base_modulate := Color.WHITE
var _tween: Tween


static func bind_tree(root: Node) -> void:
	for child in root.get_children():
		if child is Button:
			bind_button(child)
		bind_tree(child)


static func bind_button(button: Button) -> void:
	if button.has_meta(META_BOUND):
		return
	var driver := CombatUiMotion.new()
	driver.name = "CombatUiMotion"
	button.add_child(driver)
	button.set_meta(META_BOUND, true)
	driver._bind(button)


static func animate_panel_enter(panel: Control) -> void:
	if panel == null:
		return
	panel.pivot_offset = panel.size * 0.5
	var base_scale := panel.scale
	var base_modulate := panel.modulate
	panel.scale = base_scale * 0.94
	panel.modulate = Color(base_modulate.r, base_modulate.g, base_modulate.b, 0.0)
	var tween := panel.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", base_scale, PANEL_ENTER_SECONDS)
	tween.tween_property(panel, "modulate", base_modulate, PANEL_ENTER_SECONDS)


static func animate_first_panel_enter(root: Node) -> void:
	var panel := root.find_child("Panel", true, false) as Control
	if panel != null:
		animate_panel_enter(panel)


func _bind(button: Button) -> void:
	_button = button
	_base_scale = button.scale
	_base_modulate = button.modulate
	button.mouse_entered.connect(_on_hovered)
	button.mouse_exited.connect(_on_unhovered)
	button.focus_entered.connect(_on_hovered)
	button.focus_exited.connect(_on_unhovered)
	button.button_down.connect(_on_button_down)
	button.button_up.connect(_on_button_up)
	button.pressed.connect(_on_pressed)
	call_deferred("_refresh_pivot")


func _refresh_pivot() -> void:
	if not is_instance_valid(_button):
		return
	_button.pivot_offset = _button.size * 0.5
	if _button.disabled:
		_button.modulate = DISABLED_COLOR


func _on_hovered() -> void:
	if _button.disabled:
		return
	_animate(HOVER_SCALE, HOVER_COLOR, NORMAL_SECONDS, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _on_unhovered() -> void:
	_animate(Vector2.ONE, _base_modulate if not _button.disabled else DISABLED_COLOR, NORMAL_SECONDS, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _on_button_down() -> void:
	if _button.disabled:
		return
	_animate(PRESS_SCALE, Color(1.16, 1.02, 1.02, 1.0), PRESS_SECONDS, Tween.TRANS_BACK, Tween.EASE_IN)


func _on_button_up() -> void:
	if _button.disabled:
		return
	var target_scale := HOVER_SCALE if _button.has_focus() else Vector2.ONE
	var target_color := HOVER_COLOR if _button.has_focus() else _base_modulate
	_animate(target_scale, target_color, NORMAL_SECONDS, Tween.TRANS_BACK, Tween.EASE_OUT)


func _on_pressed() -> void:
	if _button.disabled:
		return
	_animate(Vector2(1.06, 1.06), Color(1.2, 1.08, 1.08, 1.0), 0.08, Tween.TRANS_BACK, Tween.EASE_OUT)
	if _tween:
		_tween.tween_property(_button, "scale", HOVER_SCALE, 0.12)
		_tween.tween_property(_button, "modulate", HOVER_COLOR, 0.12)


func _animate(target_scale: Vector2, target_modulate: Color, seconds: float, transition: Tween.TransitionType, ease: Tween.EaseType) -> void:
	if not is_instance_valid(_button):
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_trans(transition)
	_tween.set_ease(ease)
	_tween.tween_property(_button, "scale", _base_scale * target_scale, seconds)
	_tween.tween_property(_button, "modulate", target_modulate, seconds)
