class_name CombatUiMotion
extends Node

const META_BOUND := &"combat_ui_motion_bound"
const SCALE_ENABLED_META := &"combat_ui_motion_scale_enabled"
const HOVER_SCALE := Vector2(1.035, 1.035)
const PRESS_SCALE := Vector2(0.965, 0.965)
const NORMAL_SECONDS := 0.13
const PRESS_SECONDS := 0.07
const HOVER_COLOR := Color(1.08, 1.08, 1.08, 1.0)
const DISABLED_COLOR := Color(0.68, 0.68, 0.68, 0.72)
const PANEL_ANIMATION_SECONDS := 0.3
const PANEL_ANIMATION_SCALE := Vector2(1.12, 1.12)
const PANEL_BASE_SCALE_META := &"combat_ui_motion_panel_base_scale"
const PANEL_BASE_MODULATE_META := &"combat_ui_motion_panel_base_modulate"
const PANEL_TWEEN_META := &"combat_ui_motion_panel_tween"

var _button: Button
var _base_scale := Vector2.ONE
var _base_modulate := Color.WHITE
var _was_disabled := false
var _scale_enabled := true
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


static func set_button_scale_enabled(button: Button, enabled: bool) -> void:
	button.set_meta(SCALE_ENABLED_META, enabled)


static func animate_panel_enter(panel: Control) -> void:
	if panel == null:
		return
	_stop_panel_animation(panel)
	panel.pivot_offset = panel.size * 0.5
	var base_scale := _get_panel_base_scale(panel)
	var base_modulate := _get_panel_base_modulate(panel)
	panel.scale = base_scale * PANEL_ANIMATION_SCALE
	panel.modulate = Color(base_modulate.r, base_modulate.g, base_modulate.b, 0.0)
	var tween := panel.create_tween()
	tween.set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", base_scale, PANEL_ANIMATION_SECONDS)
	tween.tween_property(panel, "modulate", base_modulate, PANEL_ANIMATION_SECONDS)
	panel.set_meta(PANEL_TWEEN_META, tween)


static func animate_first_panel_enter(root: Node) -> void:
	var panel := root.find_child("Panel", true, false) as Control
	if panel != null:
		animate_panel_enter(panel)


static func animate_panel_exit(panel: Control, on_finished: Callable = Callable()) -> void:
	if panel == null:
		if on_finished.is_valid():
			on_finished.call()
		return
	_stop_panel_animation(panel)
	panel.pivot_offset = panel.size * 0.5
	var base_scale := _get_panel_base_scale(panel)
	var base_modulate := _get_panel_base_modulate(panel)
	var tween := panel.create_tween()
	tween.set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "scale", base_scale * PANEL_ANIMATION_SCALE, PANEL_ANIMATION_SECONDS)
	tween.tween_property(panel, "modulate", Color(base_modulate.r, base_modulate.g, base_modulate.b, 0.0), PANEL_ANIMATION_SECONDS)
	if on_finished.is_valid():
		tween.chain().tween_callback(on_finished)
	panel.set_meta(PANEL_TWEEN_META, tween)


static func animate_first_panel_exit(root: Node, on_finished: Callable = Callable()) -> void:
	var panel := root.find_child("Panel", true, false) as Control
	if panel != null:
		animate_panel_exit(panel, on_finished)
	elif on_finished.is_valid():
		on_finished.call()


static func _get_panel_base_scale(panel: Control) -> Vector2:
	if not panel.has_meta(PANEL_BASE_SCALE_META):
		panel.set_meta(PANEL_BASE_SCALE_META, panel.scale)
	var base_scale: Vector2 = panel.get_meta(PANEL_BASE_SCALE_META)
	return base_scale


static func _get_panel_base_modulate(panel: Control) -> Color:
	if not panel.has_meta(PANEL_BASE_MODULATE_META):
		panel.set_meta(PANEL_BASE_MODULATE_META, panel.modulate)
	var base_modulate: Color = panel.get_meta(PANEL_BASE_MODULATE_META)
	return base_modulate


static func _stop_panel_animation(panel: Control) -> void:
	if not panel.has_meta(PANEL_TWEEN_META):
		return
	var tween := panel.get_meta(PANEL_TWEEN_META) as Tween
	if tween != null and tween.is_valid():
		tween.kill()


func _bind(button: Button) -> void:
	_button = button
	_base_scale = button.scale
	_base_modulate = button.modulate
	_was_disabled = button.disabled
	_scale_enabled = bool(button.get_meta(SCALE_ENABLED_META, true))
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
	_refresh_disabled_visual()


func _process(_delta: float) -> void:
	if not is_instance_valid(_button):
		return
	if _button.disabled == _was_disabled:
		return
	_was_disabled = _button.disabled
	_refresh_disabled_visual()


func _refresh_disabled_visual() -> void:
	if _tween:
		_tween.kill()
	if _button.disabled:
		_button.modulate = DISABLED_COLOR
		return
	_button.scale = _base_scale
	_button.modulate = _base_modulate


func _on_hovered() -> void:
	if _button.disabled:
		return
	_animate(HOVER_SCALE if _scale_enabled else Vector2.ONE, HOVER_COLOR, NORMAL_SECONDS, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _on_unhovered() -> void:
	_animate(Vector2.ONE, _base_modulate if not _button.disabled else DISABLED_COLOR, NORMAL_SECONDS, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _on_button_down() -> void:
	if _button.disabled:
		return
	_animate(PRESS_SCALE if _scale_enabled else Vector2.ONE, Color(1.16, 1.02, 1.02, 1.0), PRESS_SECONDS, Tween.TRANS_BACK, Tween.EASE_IN)


func _on_button_up() -> void:
	if _button.disabled:
		return
	var target_scale := HOVER_SCALE if _button.has_focus() and _scale_enabled else Vector2.ONE
	var target_color := HOVER_COLOR if _button.has_focus() else _base_modulate
	_animate(target_scale, target_color, NORMAL_SECONDS, Tween.TRANS_BACK, Tween.EASE_OUT)


func _on_pressed() -> void:
	if _button.disabled:
		return
	_animate(Vector2(1.06, 1.06) if _scale_enabled else Vector2.ONE, Color(1.2, 1.08, 1.08, 1.0), 0.08, Tween.TRANS_BACK, Tween.EASE_OUT)
	if _tween:
		_tween.tween_property(_button, "scale", HOVER_SCALE if _scale_enabled else Vector2.ONE, 0.12)
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
