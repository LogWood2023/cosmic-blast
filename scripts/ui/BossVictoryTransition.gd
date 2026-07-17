extends Node
## Scene-independent cover for every scene handoff.
##
## Normal scene changes fade through a frozen frame. Boss victories use the
## same cover while keeping the reward picker on one continuous backdrop.

const BLACK_FADE_COLOR := Color(0.0, 0.0, 0.0, 1.0)
const BLACK_FADE_ALPHA := 0.76
const FALLBACK_FADE_ALPHA := 1.0
const HOLD_SLICE_ALPHA := 0.18
const CYAN_COLOR := Color(0.22, 0.90, 1.0, 0.92)
const RED_COLOR := Color(1.0, 0.16, 0.28, 0.86)
const AMBER_COLOR := Color(1.0, 0.72, 0.26, 0.90)
const BOSS_REWARD_POPUP_SCENE := preload("res://scenes/ui/world_map/BossRewardPopup.tscn")
const COVER_IN_DURATION := 0.68
const COVER_OUT_DURATION := 0.62
const GENERIC_TITLE := "星域跃迁"
const GENERIC_STATUS := "正在同步目标区域"
const BOSS_STATUS := "连接已稳定，奖励通道已开启"
const SLICE_SPECS: Array[Dictionary] = [
	{"y": 0.16, "height": 5.0, "color": CYAN_COLOR},
	{"y": 0.27, "height": 14.0, "color": RED_COLOR},
	{"y": 0.39, "height": 4.0, "color": AMBER_COLOR},
	{"y": 0.48, "height": 24.0, "color": CYAN_COLOR},
	{"y": 0.59, "height": 7.0, "color": RED_COLOR},
	{"y": 0.71, "height": 16.0, "color": CYAN_COLOR},
	{"y": 0.83, "height": 4.0, "color": AMBER_COLOR},
]

var _layer: CanvasLayer
var _root: Control
var _frozen_frame: TextureRect
var _has_frozen_frame := false
var _black_fade: ColorRect
var _scanlines: Array[ColorRect] = []
var _slices: Array[ColorRect] = []
var _title: Label
var _status: Label
var _title_rest_position := Vector2.ZERO
var _status_rest_position := Vector2.ZERO
var _is_transitioning := false
var _is_boss_victory_transition := false
var _waiting_for_settlement := false
var _waiting_for_boss_reward := false
var _is_claiming_boss_reward := false
var _boss_reward_popup: Control
var _settlement_popup_specs: Array[Dictionary] = []
var _active_settlement_popup: Control
var _transition_title := GENERIC_TITLE
var _transition_status := GENERIC_STATUS


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_waiting_for_boss_reward() -> bool:
	return _waiting_for_boss_reward


func is_waiting_for_settlement() -> bool:
	return _waiting_for_settlement


func is_transitioning() -> bool:
	return _is_transitioning


func change_scene_to_file(scene_path: String) -> void:
	_play_to_scene(scene_path, false, [], GENERIC_TITLE, GENERIC_STATUS)


func play_boss_victory_to_scene(scene_path: String) -> void:
	_play_to_scene(scene_path, true, [], GameCopy.text(&"ui.boss_victory.title"), BOSS_STATUS)


func play_settlement_to_scene(scene_path: String, popup_specs: Array[Dictionary], title: String = "结算传输", status: String = "正在核验回收清单") -> void:
	_play_to_scene(scene_path, false, popup_specs, title, status)


func _play_to_scene(scene_path: String, is_boss_victory: bool, popup_specs: Array[Dictionary], title: String, status: String) -> void:
	if _is_transitioning or scene_path.is_empty():
		return
	_is_transitioning = true
	_is_boss_victory_transition = is_boss_victory
	_waiting_for_settlement = is_boss_victory or not popup_specs.is_empty()
	_settlement_popup_specs = popup_specs.duplicate(true)
	_transition_title = title
	_transition_status = status
	_ensure_overlay()
	_update_overlay_copy()
	_capture_current_frame()
	_reset_overlay()
	_root.show()

	# Give the full-screen Control one frame to acquire its viewport-sized rect.
	await get_tree().process_frame
	var cover_tween := create_tween().set_parallel(true)
	cover_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	cover_tween.tween_property(_black_fade, "color:a", _get_black_fade_alpha(), COVER_IN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	cover_tween.tween_property(_title, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	cover_tween.tween_property(_status, "modulate:a", 0.82, 0.28).set_delay(0.12)
	cover_tween.tween_property(_title, "position:x", _title_rest_position.x + 12.0, 0.14).from(_title_rest_position.x - 18.0)
	cover_tween.tween_property(_status, "position:x", _status_rest_position.x - 10.0, 0.16).from(_status_rest_position.x + 16.0)
	for index in range(_slices.size()):
		var slice := _slices[index]
		var slice_tween := create_tween()
		slice_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		slice_tween.tween_interval(0.055 * float(index))
		slice_tween.tween_property(slice, "modulate:a", 1.0, 0.06)
		slice_tween.tween_property(slice, "modulate:a", HOLD_SLICE_ALPHA, 0.20)
	for index in range(_scanlines.size()):
		var scanline := _scanlines[index]
		var scanline_tween := create_tween()
		scanline_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		scanline_tween.tween_interval(0.04 * float(index % 5))
		scanline_tween.tween_property(scanline, "modulate:a", 0.24, 0.12)
	await cover_tween.finished

	_waiting_for_boss_reward = _is_boss_victory_transition and RunManager.has_pending_boss_reward()
	_waiting_for_settlement = _waiting_for_boss_reward or not _settlement_popup_specs.is_empty()
	var change_error := get_tree().change_scene_to_file(scene_path)
	if change_error != OK:
		push_error("执行体结算转场无法加载场景：%s" % scene_path)
		_waiting_for_boss_reward = false
		_waiting_for_settlement = false
		_settlement_popup_specs.clear()
		await _reveal_overlay()
		return

	# The WorldMap is ready under the opaque cover. If this is a boss victory, the
	# reward picker is attached to the cover itself, then the map is revealed only
	# after the player confirms a reward.
	await get_tree().process_frame
	if _waiting_for_boss_reward:
		_show_boss_reward_popup()
		return
	if not _settlement_popup_specs.is_empty():
		_show_next_settlement_popup()
		return
	_waiting_for_settlement = false
	await _reveal_overlay()


func _show_next_settlement_popup() -> void:
	if is_instance_valid(_active_settlement_popup):
		return
	if _settlement_popup_specs.is_empty():
		_finish_settlement_sequence()
		return
	var spec: Dictionary = _settlement_popup_specs.pop_front()
	var popup_scene := spec.get("scene") as PackedScene
	if popup_scene == null:
		push_warning("结算弹窗配置缺少有效场景，已跳过。")
		call_deferred("_show_next_settlement_popup")
		return
	_active_settlement_popup = popup_scene.instantiate() as Control
	if not is_instance_valid(_active_settlement_popup):
		push_warning("结算弹窗实例化失败，已跳过：%s" % popup_scene.resource_path)
		call_deferred("_show_next_settlement_popup")
		return
	_root.add_child(_active_settlement_popup)
	var completion_signal := StringName(spec.get("completion_signal", &"closed"))
	if not _active_settlement_popup.has_signal(completion_signal):
		push_warning("结算弹窗 %s 缺少完成信号 %s，已跳过。" % [_active_settlement_popup.name, completion_signal])
		_active_settlement_popup.queue_free()
		_active_settlement_popup = null
		call_deferred("_show_next_settlement_popup")
		return
	_active_settlement_popup.connect(completion_signal, _on_settlement_popup_completed.bind(_active_settlement_popup), CONNECT_ONE_SHOT)
	if _active_settlement_popup.has_method("setup"):
		_active_settlement_popup.callv("setup", Array(spec.get("setup_args", [])))


func _on_settlement_popup_completed(popup: Control) -> void:
	if popup != _active_settlement_popup:
		return
	_active_settlement_popup = null
	if is_instance_valid(popup):
		popup.queue_free()
	call_deferred("_show_next_settlement_popup")


func _finish_settlement_sequence() -> void:
	await _reveal_overlay()
	_notify_settlement_sequence_completed()


func _notify_settlement_sequence_completed() -> void:
	var current_scene := get_tree().current_scene
	if is_instance_valid(current_scene) and current_scene.has_method("on_settlement_sequence_completed"):
		current_scene.call("on_settlement_sequence_completed")


func _show_boss_reward_popup() -> void:
	var summary := RunManager.get_pending_boss_reward_summary()
	if summary.is_empty():
		_waiting_for_boss_reward = false
		_reveal_overlay()
		return
	_boss_reward_popup = BOSS_REWARD_POPUP_SCENE.instantiate() as Control
	_root.add_child(_boss_reward_popup)
	_boss_reward_popup.reward_selected.connect(_on_boss_reward_selected)
	_boss_reward_popup.call("setup", summary)


func _on_boss_reward_selected(item_id: String) -> void:
	if _is_claiming_boss_reward:
		return
	_is_claiming_boss_reward = true
	var result := RunManager.claim_boss_reward(item_id)
	if not bool(result.get("ok", false)):
		_is_claiming_boss_reward = false
		return
	if is_instance_valid(_boss_reward_popup) and _boss_reward_popup.has_method("finish_selection"):
		_boss_reward_popup.call("finish_selection")
		await get_tree().create_timer(0.3, true).timeout
	_boss_reward_popup = null
	_waiting_for_boss_reward = false

	if bool(result.get("is_final", false)):
		RunManager.finish_run(true)
		var change_error := get_tree().change_scene_to_file(RunManager.GAME_OVER_SCENE)
		if change_error != OK:
			push_error("无法切换至远征结算场景：%s" % RunManager.GAME_OVER_SCENE)
		else:
			await get_tree().process_frame
	else:
		RunManager.save_run()
		var current_scene := get_tree().current_scene
		if is_instance_valid(current_scene) and current_scene.has_method("on_boss_reward_claimed"):
			current_scene.call("on_boss_reward_claimed", result)
	await _reveal_overlay()
	_notify_settlement_sequence_completed()


func _reveal_overlay() -> void:
	var reveal_tween := create_tween().set_parallel(true)
	reveal_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	reveal_tween.tween_property(_black_fade, "color:a", 0.0, COVER_OUT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _has_frozen_frame:
		reveal_tween.tween_property(_frozen_frame, "modulate:a", 0.0, COVER_OUT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	reveal_tween.tween_property(_title, "modulate:a", 0.0, 0.22)
	reveal_tween.tween_property(_status, "modulate:a", 0.0, 0.28)
	for scanline in _scanlines:
		reveal_tween.tween_property(scanline, "modulate:a", 0.0, 0.24)
	for slice in _slices:
		reveal_tween.tween_property(slice, "modulate:a", 0.0, 0.24)
	await reveal_tween.finished
	_root.hide()
	_is_transitioning = false
	_is_boss_victory_transition = false
	_is_claiming_boss_reward = false
	_waiting_for_settlement = false
	_waiting_for_boss_reward = false
	_settlement_popup_specs.clear()
	_active_settlement_popup = null


func _ensure_overlay() -> void:
	if is_instance_valid(_root):
		return
	_layer = CanvasLayer.new()
	_layer.name = "BossVictoryTransitionLayer"
	_layer.layer = 500
	add_child(_layer)

	_root = Control.new()
	_root.name = "BossVictoryTransition"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_layer.add_child(_root)

	_frozen_frame = TextureRect.new()
	_frozen_frame.name = "FrozenBossFrame"
	_frozen_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frozen_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_frozen_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_frozen_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_frozen_frame)

	_black_fade = ColorRect.new()
	_black_fade.name = "BlackFade"
	_black_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black_fade.color = BLACK_FADE_COLOR
	_root.add_child(_black_fade)

	for index in range(18):
		var scanline := ColorRect.new()
		var y := float(index) / 18.0
		scanline.set_anchors_preset(Control.PRESET_TOP_WIDE)
		scanline.anchor_top = y
		scanline.anchor_bottom = y
		scanline.offset_top = 0.0
		scanline.offset_bottom = 1.0 if index % 3 else 2.0
		scanline.color = Color(0.34, 0.90, 1.0, 1.0)
		scanline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(scanline)
		_scanlines.append(scanline)

	for spec in SLICE_SPECS:
		var slice := ColorRect.new()
		var height := float(spec["height"])
		slice.set_anchors_preset(Control.PRESET_TOP_WIDE)
		slice.anchor_top = float(spec["y"])
		slice.anchor_bottom = float(spec["y"])
		slice.offset_top = -height * 0.5
		slice.offset_bottom = height * 0.5
		slice.color = spec["color"] as Color
		slice.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(slice)
		_slices.append(slice)

	_title = _make_label(GameCopy.text(&"ui.boss_victory.title"), 46, CYAN_COLOR)
	_title.set_anchors_preset(Control.PRESET_CENTER)
	_title.offset_left = -440.0
	_title.offset_top = -62.0
	_title.offset_right = 440.0
	_title.offset_bottom = -6.0
	_root.add_child(_title)
	_title_rest_position = _title.position

	_status = _make_label("连接已稳定，奖励通道已开启", 16, AMBER_COLOR)
	_status.set_anchors_preset(Control.PRESET_CENTER)
	_status.offset_left = -440.0
	_status.offset_top = 4.0
	_status.offset_right = 440.0
	_status.offset_bottom = 32.0
	_root.add_child(_status)
	_status_rest_position = _status.position

	_root.hide()


func _make_label(text: String, font_size: int, font_color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.92))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _update_overlay_copy() -> void:
	_title.text = _transition_title
	_status.text = _transition_status


func _reset_overlay() -> void:
	_black_fade.color = BLACK_FADE_COLOR
	_black_fade.color.a = 0.0
	_frozen_frame.modulate.a = 1.0
	_title.modulate.a = 0.0
	_status.modulate.a = 0.0
	_title.position = _title_rest_position
	_status.position = _status_rest_position
	for scanline in _scanlines:
		scanline.modulate.a = 0.0
	for slice in _slices:
		slice.modulate.a = 0.0


func _capture_current_frame() -> void:
	if DisplayServer.get_name() == "headless":
		_has_frozen_frame = false
		_frozen_frame.hide()
		return
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		_has_frozen_frame = false
		_frozen_frame.hide()
		return
	_frozen_frame.texture = ImageTexture.create_from_image(image)
	_has_frozen_frame = true
	_frozen_frame.show()


func _get_black_fade_alpha() -> float:
	return BLACK_FADE_ALPHA if _has_frozen_frame else FALLBACK_FADE_ALPHA
