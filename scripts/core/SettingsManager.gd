extends Node

signal settings_changed

const SETTINGS_PATH := "user://settings.cfg"
const CONTROL_ACTIONS: Array[StringName] = [&"move_up", &"move_left", &"move_down", &"move_right", &"shoot", &"dash"]
const WINDOW_SIZES: Array[Vector2i] = [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
const CURSOR_ASSETS := {
	Input.CURSOR_ARROW: {"path": "res://assets/images/cursors/cursor_arrow.png", "hotspot": Vector2(6, 3)},
	Input.CURSOR_POINTING_HAND: {"path": "res://assets/images/cursors/cursor_point.png", "hotspot": Vector2(24, 3)},
	Input.CURSOR_DRAG: {"path": "res://assets/images/cursors/cursor_drag.png", "hotspot": Vector2(24, 24)},
	Input.CURSOR_MOVE: {"path": "res://assets/images/cursors/cursor_move.png", "hotspot": Vector2(24, 24)},
	Input.CURSOR_IBEAM: {"path": "res://assets/images/cursors/cursor_ibeam.png", "hotspot": Vector2(24, 24)},
	Input.CURSOR_HSIZE: {"path": "res://assets/images/cursors/cursor_hsize.png", "hotspot": Vector2(24, 24)},
}

var master_volume := 0.85
var music_volume := 0.70
var sfx_volume := 0.85
var fullscreen := false
var vsync_enabled := true
var window_size_index := 0
var screen_shake_strength := 1.0
var reduced_effects := false
var auto_fire := false
var _default_bindings: Dictionary = {}


func _ready() -> void:
	_capture_default_bindings()
	_ensure_audio_buses()
	_load_settings()
	_apply_all()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	_save_and_notify()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	_save_and_notify()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_audio()
	_save_and_notify()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_display()
	_save_and_notify()


func set_vsync_enabled(value: bool) -> void:
	vsync_enabled = value
	_apply_display()
	_save_and_notify()


func set_window_size_index(value: int) -> void:
	window_size_index = clampi(value, 0, WINDOW_SIZES.size() - 1)
	_apply_display()
	_save_and_notify()


func set_auto_fire(value: bool) -> void:
	auto_fire = value
	_save_and_notify()


func set_screen_shake_strength(value: float) -> void:
	screen_shake_strength = clampf(value, 0.0, 1.0)
	CameraFeedback.intensity_scale = screen_shake_strength
	_save_and_notify()


func set_reduced_effects(value: bool) -> void:
	reduced_effects = value
	get_tree().call_group(&"quality_particles", &"apply_quality")
	_save_and_notify()


func set_binding(action: StringName, event: InputEvent) -> void:
	if not CONTROL_ACTIONS.has(action):
		return
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	_save_and_notify()


func reset_to_defaults() -> void:
	apply_settings(get_default_settings())


func get_binding_text(action: StringName) -> String:
	return format_binding_text(InputMap.action_get_events(action))


func format_binding_text(events: Array) -> String:
	if events.is_empty():
		return "未绑定"
	var labels: Array[String] = []
	for event in events:
		labels.append(event.as_text())
	return " / ".join(labels)


func get_settings_snapshot() -> Dictionary:
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"fullscreen": fullscreen,
		"vsync_enabled": vsync_enabled,
		"window_size_index": window_size_index,
		"screen_shake_strength": screen_shake_strength,
		"reduced_effects": reduced_effects,
		"auto_fire": auto_fire,
		"bindings": _get_bindings(),
	}


func get_default_settings() -> Dictionary:
	return {
		"master_volume": 0.85,
		"music_volume": 0.70,
		"sfx_volume": 0.85,
		"fullscreen": false,
		"vsync_enabled": true,
		"window_size_index": 0,
		"screen_shake_strength": 1.0,
		"reduced_effects": false,
		"auto_fire": false,
		"bindings": _duplicate_bindings(_default_bindings),
	}


func apply_settings(settings: Dictionary, save: bool = true) -> void:
	master_volume = clampf(float(settings.get("master_volume", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(settings.get("music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(settings.get("sfx_volume", sfx_volume)), 0.0, 1.0)
	fullscreen = bool(settings.get("fullscreen", fullscreen))
	vsync_enabled = bool(settings.get("vsync_enabled", vsync_enabled))
	window_size_index = clampi(int(settings.get("window_size_index", window_size_index)), 0, WINDOW_SIZES.size() - 1)
	screen_shake_strength = clampf(float(settings.get("screen_shake_strength", screen_shake_strength)), 0.0, 1.0)
	reduced_effects = bool(settings.get("reduced_effects", reduced_effects))
	auto_fire = bool(settings.get("auto_fire", auto_fire))
	_apply_bindings(settings.get("bindings", {}))
	_apply_all()
	if save:
		_save_settings()


func _capture_default_bindings() -> void:
	for action in CONTROL_ACTIONS:
		_default_bindings[action] = _duplicate_events(InputMap.action_get_events(action))


func _ensure_audio_buses() -> void:
	_ensure_audio_bus(&"Music")
	_ensure_audio_bus(&"SFX")


func _ensure_audio_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, &"Master")


func _apply_all() -> void:
	_apply_custom_cursors()
	_apply_audio()
	_apply_display()
	CameraFeedback.intensity_scale = screen_shake_strength
	get_tree().call_group(&"quality_particles", &"apply_quality")
	settings_changed.emit()


func _apply_custom_cursors() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for shape in CURSOR_ASSETS:
		var cursor: Dictionary = CURSOR_ASSETS[shape]
		var texture := load(String(cursor["path"])) as Texture2D
		if texture:
			Input.set_custom_mouse_cursor(texture, shape, cursor["hotspot"])


func _apply_audio() -> void:
	_set_bus_volume(&"Master", master_volume)
	_set_bus_volume(&"Music", music_volume)
	_set_bus_volume(&"SFX", sfx_volume)


func _apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED)
	if not fullscreen:
		DisplayServer.window_set_size(WINDOW_SIZES[window_size_index])


func _set_bus_volume(bus_name: StringName, value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, value <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.001)))


func _get_bindings() -> Dictionary:
	var bindings: Dictionary = {}
	for action in CONTROL_ACTIONS:
		bindings[String(action)] = _duplicate_events(InputMap.action_get_events(action))
	return bindings


func _duplicate_bindings(bindings: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for action in CONTROL_ACTIONS:
		var events: Array = bindings.get(action, bindings.get(String(action), []))
		result[String(action)] = _duplicate_events(events)
	return result


func _duplicate_events(events: Array) -> Array:
	var result: Array = []
	for event in events:
		if event is InputEvent:
			result.append(event.duplicate())
	return result


func _apply_bindings(bindings: Dictionary) -> void:
	for action in CONTROL_ACTIONS:
		if not bindings.has(action) and not bindings.has(String(action)):
			continue
		var events: Array = bindings.get(action, bindings.get(String(action), []))
		InputMap.action_erase_events(action)
		for event in events:
			if event is InputEvent:
				InputMap.action_add_event(action, event.duplicate())


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	master_volume = clampf(float(config.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(config.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)
	fullscreen = bool(config.get_value("display", "fullscreen", fullscreen))
	vsync_enabled = bool(config.get_value("display", "vsync_enabled", vsync_enabled))
	window_size_index = clampi(int(config.get_value("display", "window_size_index", window_size_index)), 0, WINDOW_SIZES.size() - 1)
	screen_shake_strength = clampf(float(config.get_value("accessibility", "screen_shake_strength", screen_shake_strength)), 0.0, 1.0)
	reduced_effects = bool(config.get_value("accessibility", "reduced_effects", reduced_effects))
	auto_fire = bool(config.get_value("controls", "auto_fire", auto_fire))
	for action in CONTROL_ACTIONS:
		if not config.has_section_key("controls", String(action)):
			continue
		var events: Array = config.get_value("controls", String(action), [])
		InputMap.action_erase_events(action)
		for event in events:
			if event is InputEvent:
				InputMap.action_add_event(action, event)


func _save_and_notify() -> void:
	_save_settings()
	settings_changed.emit()


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", 1)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "vsync_enabled", vsync_enabled)
	config.set_value("display", "window_size_index", window_size_index)
	config.set_value("accessibility", "screen_shake_strength", screen_shake_strength)
	config.set_value("accessibility", "reduced_effects", reduced_effects)
	config.set_value("controls", "auto_fire", auto_fire)
	for action in CONTROL_ACTIONS:
		config.set_value("controls", String(action), InputMap.action_get_events(action))
	if config.save(SETTINGS_PATH) != OK:
		push_warning("Unable to save game settings: %s" % SETTINGS_PATH)
