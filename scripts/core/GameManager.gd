extends Node
## 全局游戏管理器（Autoload 单例）

var score: int = 0
var player_hp: int = 100
const PLAYER_MAX_HP: int = 100
var elapsed: float = 0.0
var frenzy_value: float = 0.0
var frenzy_active: bool = false
var frenzy_timer: float = 0.0
const FRENZY_MAX: float = 100.0
const FRENZY_DURATION: float = 5.0
const FRENZY_DAMAGE_TAKEN_MULT: float = 0.5
const FRENZY_FIRE_RATE_MULT: float = 0.5

var bgm_player: AudioStreamPlayer
const BGM_PATH: String = "res://assets/audio/bgm.mp3"
const STUTTER_LOG_PATH: String = "user://stutter_log.txt"
const STUTTER_LOG_MIRROR_PATH: String = "res://stutter_log.txt"
const STUTTER_FPS_WARNING_THRESHOLD: int = 30
const STUTTER_SAMPLE_SECONDS: float = 1.0
const FRAME_BUDGET_FPS: float = 30.0
const FRAME_BUDGET_USEC: int = int(1000000.0 / FRAME_BUDGET_FPS)
const FRAME_BUDGET_LOG_COOLDOWN_USEC: int = 300000
const STUTTER_SINGLE_FRAME_LOG_COOLDOWN_USEC: int = 500000
const EXPENSIVE_PATHFINDING_SLOTS_PER_FRAME: int = 1

# 吸力（技能4）
var suction_active: bool = false
var suction_center: Vector2 = Vector2.ZERO
var controls_inverted: bool = false
var command_console_open: bool = false
var next_explore_room_config: Dictionary = {}

const EXPLORE_ROOM_CONFIG_KEYS: Array[String] = [
	"large_space_rock_count",
	"trap_count",
	"chest_crystal_count",
	"clutter_count",
	"colossus_family_weight",
	"paradise_family_weight",
	"warped_family_weight",
	"hell_eye_family_weight",
	"divine_family_weight",
	"enemy_spawn_interval",
	"max_patrol_enemy_count",
]

# 测试功能：游戏场景缩放（正式版移除）
var test_scale_enabled: bool = false
var test_scale_factor: float = 1.0 / 3.0
var stutter_monitor_enabled: bool = true
var frame_budget_guard_enabled: bool = true
var stutter_context: String = ""
var _stutter_sample_start_usec: int = 0
var _stutter_last_frame_usec: int = 0
var _stutter_sample_frames: int = 0
var _stutter_sample_max_frame_ms: float = 0.0
var _stutter_log_initialized: bool = false
var _frame_budget_start_usec: int = 0
var _last_budget_warning_usec: int = 0
var _last_single_frame_warning_usec: int = 0
var _deferred_work_count: int = 0
var _expensive_pathfinding_slots_used: int = 0
var _frame_budget_frame: int = -1


func _ready() -> void:
	_initialize_stutter_log()
	if DisplayServer.get_name() == "headless":
		return
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	bgm_player.stream = load(BGM_PATH)
	bgm_player.play()
	bgm_player.finished.connect(bgm_player.play)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(bgm_player):
		bgm_player.stop()
		bgm_player.stream = null
		if bgm_player.finished.is_connected(bgm_player.play):
			bgm_player.finished.disconnect(bgm_player.play)


func stop_bgm() -> void:
	if is_instance_valid(bgm_player) and bgm_player.playing:
		bgm_player.stop()


func resume_bgm() -> void:
	if is_instance_valid(bgm_player):
		bgm_player.play()


func _process(delta: float) -> void:
	_begin_frame_budget_window()
	elapsed += delta
	_update_frenzy(delta)
	_update_stutter_monitor()


func add_score(amount: int) -> void:
	score += amount


func add_frenzy(amount: float) -> void:
	if amount <= 0.0 or frenzy_active:
		return
	frenzy_value = minf(FRENZY_MAX, frenzy_value + amount)
	if frenzy_value >= FRENZY_MAX:
		_start_frenzy()


func get_frenzy_ratio() -> float:
	return clampf(frenzy_value / FRENZY_MAX, 0.0, 1.0)


func get_incoming_damage_after_frenzy(damage: int) -> int:
	if damage <= 0:
		return 0
	if not frenzy_active:
		return damage
	return maxi(1, int(ceil(float(damage) * FRENZY_DAMAGE_TAKEN_MULT)))


func get_fire_rate_multiplier() -> float:
	return FRENZY_FIRE_RATE_MULT if frenzy_active else 1.0


func reset_run_state() -> void:
	score = 0
	player_hp = PLAYER_MAX_HP
	elapsed = 0.0
	frenzy_value = 0.0
	frenzy_active = false
	frenzy_timer = 0.0
	suction_active = false
	suction_center = Vector2.ZERO
	controls_inverted = false
	command_console_open = false
	test_scale_enabled = false


func _start_frenzy() -> void:
	frenzy_active = true
	frenzy_timer = FRENZY_DURATION
	frenzy_value = FRENZY_MAX


func _update_frenzy(delta: float) -> void:
	if not frenzy_active:
		return
	frenzy_timer = maxf(0.0, frenzy_timer - delta)
	frenzy_value = FRENZY_MAX * (frenzy_timer / FRENZY_DURATION)
	if frenzy_timer <= 0.0:
		frenzy_active = false
		frenzy_value = 0.0


func set_next_explore_room_counts(large_space_rock_count: int = -1, trap_count: int = -1, chest_crystal_count: int = -1, clutter_count: int = -1, enemy_spawn_interval: float = -1.0, max_patrol_enemy_count: int = -1) -> void:
	var config = {
		"large_space_rock_count": large_space_rock_count,
		"trap_count": trap_count,
		"chest_crystal_count": chest_crystal_count,
		"clutter_count": clutter_count,
	}
	if enemy_spawn_interval >= 0.0:
		config["enemy_spawn_interval"] = enemy_spawn_interval
	if max_patrol_enemy_count >= 0:
		config["max_patrol_enemy_count"] = max_patrol_enemy_count
	set_next_explore_room_config(config)


func set_next_explore_room_config(config: Dictionary) -> void:
	next_explore_room_config.clear()
	for key in config:
		if not EXPLORE_ROOM_CONFIG_KEYS.has(key):
			continue
		var value = float(config[key])
		next_explore_room_config[key] = value if value >= 0.0 else -1


func consume_next_explore_room_config() -> Dictionary:
	var config = next_explore_room_config.duplicate(true)
	next_explore_room_config.clear()
	return config


func difficulty() -> float:
	return clampf(elapsed / 180.0, 0.0, 1.0)


func should_defer_work(label: String = "") -> bool:
	if not frame_budget_guard_enabled:
		return false
	_ensure_frame_budget_window()
	var now := Time.get_ticks_usec()
	if now - _frame_budget_start_usec < FRAME_BUDGET_USEC:
		return false
	_deferred_work_count += 1
	if now - _last_budget_warning_usec >= FRAME_BUDGET_LOG_COOLDOWN_USEC:
		_last_budget_warning_usec = now
		_append_stutter_log_line(_format_stutter_line(
			"frame_budget_defer",
			0.0,
			0,
			float(now - _frame_budget_start_usec) / 1000000.0,
			float(now - _frame_budget_start_usec) / 1000.0,
			label
		))
	return true


func try_consume_expensive_pathfinding_slot(label: String = "") -> bool:
	if should_defer_work(label):
		return false
	if _expensive_pathfinding_slots_used >= EXPENSIVE_PATHFINDING_SLOTS_PER_FRAME:
		_deferred_work_count += 1
		return false
	_expensive_pathfinding_slots_used += 1
	return true


func frame_budget_elapsed_ms() -> float:
	_ensure_frame_budget_window()
	if _frame_budget_start_usec <= 0:
		return 0.0
	return float(Time.get_ticks_usec() - _frame_budget_start_usec) / 1000.0


func _begin_frame_budget_window() -> void:
	_frame_budget_frame = Engine.get_process_frames()
	_frame_budget_start_usec = Time.get_ticks_usec()
	_deferred_work_count = 0
	_expensive_pathfinding_slots_used = 0


func _ensure_frame_budget_window() -> void:
	var current_frame := Engine.get_process_frames()
	if _frame_budget_frame != current_frame or _frame_budget_start_usec <= 0:
		_begin_frame_budget_window()


func _initialize_stutter_log() -> void:
	_stutter_sample_start_usec = Time.get_ticks_usec()
	_stutter_last_frame_usec = _stutter_sample_start_usec
	_frame_budget_start_usec = _stutter_sample_start_usec
	_stutter_sample_frames = 0
	_stutter_sample_max_frame_ms = 0.0
	if _stutter_log_initialized:
		return
	_stutter_log_initialized = true
	_append_stutter_log_line("")
	_append_stutter_log_line("=== Stutter monitor started at %s | user_dir=%s ===" % [
		Time.get_datetime_string_from_system(),
		OS.get_user_data_dir(),
	])


func _update_stutter_monitor() -> void:
	if not stutter_monitor_enabled:
		return
	var now := Time.get_ticks_usec()
	if _stutter_sample_start_usec <= 0:
		_stutter_sample_start_usec = now
		_stutter_last_frame_usec = now
	_stutter_sample_frames += 1
	if _stutter_last_frame_usec > 0:
		var last_frame_ms := float(now - _stutter_last_frame_usec) / 1000.0
		_stutter_sample_max_frame_ms = maxf(_stutter_sample_max_frame_ms, last_frame_ms)
		if last_frame_ms > 1000.0 / FRAME_BUDGET_FPS and now - _last_single_frame_warning_usec >= STUTTER_SINGLE_FRAME_LOG_COOLDOWN_USEC:
			_last_single_frame_warning_usec = now
			_write_stutter_log(
				float(STUTTER_FPS_WARNING_THRESHOLD),
				last_frame_ms / 1000.0,
				"single_frame_over_budget"
			)
	_stutter_last_frame_usec = now
	var elapsed_usec := now - _stutter_sample_start_usec
	if elapsed_usec < int(STUTTER_SAMPLE_SECONDS * 1000000.0):
		return
	var sample_seconds := float(elapsed_usec) / 1000000.0
	var fps := float(_stutter_sample_frames) / maxf(sample_seconds, 0.001)
	if fps < float(STUTTER_FPS_WARNING_THRESHOLD):
		_write_stutter_log(fps, sample_seconds, "low_fps_window")
	_stutter_sample_start_usec = now
	_stutter_last_frame_usec = now
	_stutter_sample_frames = 0
	_stutter_sample_max_frame_ms = 0.0


func _write_stutter_log(fps: float, sample_seconds: float, reason: String) -> void:
	_append_stutter_log_line(_format_stutter_line(
		reason,
		fps,
		_stutter_sample_frames,
		sample_seconds,
		_stutter_sample_max_frame_ms,
		""
	))


func _format_stutter_line(reason: String, fps: float, frames: int, sample_seconds: float, max_frame_ms: float, label: String) -> String:
	var scene: Node = get_tree().current_scene
	var scene_name: String = scene.name if scene else "<none>"
	var scene_path: String = scene.scene_file_path if scene and not scene.scene_file_path.is_empty() else "<dynamic>"
	var enemies: int = _count_active_stutter_enemies()
	var projectiles: int = get_tree().get_nodes_in_group(&"force_field_projectiles").size()
	var total_nodes: int = _count_nodes(scene) if scene else 0
	return "%s | reason=%s label=%s context=%s fps=%.1f frames=%d seconds=%.3f max_frame_ms=%.2f budget_elapsed_ms=%.2f deferred=%d scene=%s path=%s enemies=%d projectiles=%d nodes=%d score=%d hp=%d elapsed=%.2f" % [
		Time.get_datetime_string_from_system(),
		reason,
		label,
		stutter_context,
		fps,
		frames,
		sample_seconds,
		max_frame_ms,
		frame_budget_elapsed_ms(),
		_deferred_work_count,
		scene_name,
		scene_path,
		enemies,
		projectiles,
		total_nodes,
		score,
		player_hp,
		elapsed,
	]


func _append_stutter_log_line(line: String) -> void:
	var wrote := _append_line_to_file(STUTTER_LOG_PATH, line)
	var mirrored := _append_line_to_file(STUTTER_LOG_MIRROR_PATH, line)
	if not wrote and not mirrored:
		push_warning("[StutterMonitor] 无法写入卡顿日志: %s 或 %s" % [STUTTER_LOG_PATH, STUTTER_LOG_MIRROR_PATH])
		return


func _append_line_to_file(path: String, line: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if not file:
		return false
	file.seek_end()
	file.store_line(line)
	file.flush()
	return true


func _count_nodes(root: Node) -> int:
	var count := 1
	for child in root.get_children():
		count += _count_nodes(child)
	return count


func _count_active_stutter_enemies() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group(&"enemies"):
		if not is_instance_valid(enemy):
			continue
		if enemy.is_queued_for_deletion():
			continue
		if enemy.is_in_group(&"defense_turrets"):
			continue
		if enemy.get_meta(&"explore_pooled_enemy", false) and not bool(enemy.get("_explore_pool_active")):
			continue
		count += 1
	return count
