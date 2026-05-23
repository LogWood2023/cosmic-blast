extends Node2D

const ROOM_SIZE: Vector2 = Vector2(10800, 10800)
const VIEW_SIZE: Vector2 = Vector2(1920, 1080)
const BACKGROUND_TILE_SIZE: Vector2 = Vector2(1080, 1080)
const BACKGROUND_GRID_SIZE: Vector2 = Vector2(3, 3)
const SPACE_ROCK_MIN_COUNT: int = 15
const SPACE_ROCK_MAX_COUNT: int = 25
const SPACE_ROCK_BASE_RADIUS: float = 600.0
const SPACE_ROCK_MIN_SCALE: float = 0.5
const SPACE_ROCK_MAX_SCALE: float = 1.2
const SPACE_ROCK_MIN_DISTANCE: float = 1500.0
const SPACE_ROCK_EDGE_MARGIN: float = 900.0
const SMALL_SPACE_ROCK_MIN_COUNT: int = 3
const SMALL_SPACE_ROCK_MAX_COUNT: int = 10
const SMALL_SPACE_ROCK_MIN_RADIUS: float = 10.0
const SMALL_SPACE_ROCK_MAX_RADIUS: float = 50.0
const SMALL_SPACE_ROCK_MIN_DISTANCE: float = 100.0
const ISOLATION_BAND_MIN_COUNT: int = 5
const ISOLATION_BAND_MAX_COUNT: int = 20
const ISOLATION_BAND_MAX_DISTANCE: float = 3000.0
const ISOLATION_BAND_WIDTH: float = 100.0
const CHEST_MIN_COUNT: int = 1
const CHEST_MAX_COUNT: int = 5
const ORE_VEIN_MIN_COUNT: int = 5
const ORE_VEIN_MAX_COUNT: int = 15
const TURRET_MIN_COUNT: int = 20
const TURRET_MAX_COUNT: int = 40
const TURRET_MAX_ATTEMPTS: int = 10
const TURRET_SURFACE_INSET: float = 48.0
const TURRET_MIN_DISTANCE: float = 1000.0
const REWARD_MIN_DISTANCE: float = 2000.0
const REWARD_MAX_ATTEMPTS: int = 10
const REWARD_BAND_CLEARANCE: float = 180.0
const ORE_VEIN_SURFACE_INSET: float = 48.0
const CHEST_EDGE_EXCLUSION_RATIO: float = 0.125
const PLAYER_SPAWN_MARGIN: float = 120.0
const PLAYER_SPAWN_CLEARANCE: float = 120.0
const LOAD_STAGE_TEXTURES: float = 0.05
const LOAD_STAGE_LARGE_ROCKS: float = 0.35
const LOAD_STAGE_SMALL_ROCKS: float = 0.85
const LOAD_STAGE_ISOLATION_BANDS: float = 0.91
const LOAD_STAGE_TURRETS: float = 0.95
const LOAD_STAGE_REWARDS: float = 0.98
const LOAD_STAGE_DONE: float = 1.0
const LARGE_ROCKS_PER_FRAME: int = 60
const SMALL_ROCK_PARENTS_PER_FRAME: int = 1

const SPACE_ROCK_SCENE := preload("res://scenes/SpaceRock.tscn")
const ISOLATION_BAND_SCENE := preload("res://scenes/IsolationBand.tscn")
const ELECTRIC_ISOLATION_BAND_SCENE := preload("res://scenes/ElectricIsolationBand.tscn")
const DEFENSE_TURRET_SCENE := preload("res://scenes/DefenseTurret.tscn")
const EXPLORE_REWARD_SCENE := preload("res://scenes/ExploreReward.tscn")
const CHEST_TEXTURE_PATHS: Array[String] = [
	"res://assets/images/rewards/chest_01.png",
	"res://assets/images/rewards/chest_02.png",
	"res://assets/images/rewards/chest_03.png",
]
const ORE_VEIN_TEXTURE_PATHS: Array[String] = [
	"res://assets/images/rewards/ore_01.png",
	"res://assets/images/rewards/ore_02.png",
	"res://assets/images/rewards/ore_03.png",
]
const ISOLATION_BAND_TILE_PATHS: Array[Array] = [
	[
		"res://assets/images/isolation_band_tiles/space_elevator_1_cutout.png",
		"res://assets/images/isolation_band_tiles/space_elevator_2_cutout.png",
		"res://assets/images/isolation_band_tiles/space_elevator_3_cutout.png",
	],
]
const SPACE_ROCK_TEXTURE_PATHS: Array[String] = [
	"res://assets/images/asteroid/space_rock_1_cutout.png",
	"res://assets/images/asteroid/space_rock_2_cutout.png",
	"res://assets/images/asteroid/space_rock_3_cutout.png",
	"res://assets/images/asteroid/space_rock_4_cutout.png",
	"res://assets/images/asteroid/space_rock_5_cutout.png",
]
const ELECTRIC_ISOLATION_ENDPOINT_PATHS: Array[String] = [
	"res://assets/images/electric_isolation/lightning_rod_01.png",
	"res://assets/images/electric_isolation/lightning_rod_02.png",
	"res://assets/images/electric_isolation/lightning_rod_03.png",
]

@onready var player: Area2D = $player
@onready var camera: Camera2D = $Camera2D
@onready var background_tiles: Node2D = $BackgroundTiles
@onready var isolation_bands: Node2D = $IsolationBands
@onready var space_rocks: Node2D = $SpaceRocks
@onready var turrets: Node2D = $Turrets
@onready var rewards: Node2D = $Rewards
@onready var map_ui: Control = $UILayer/ExploreMapUI
@onready var loading_screen: Control = $UILayer/LoadingScreen
@onready var loading_bar: ProgressBar = $UILayer/LoadingScreen/Panel/ProgressBar
@onready var loading_label: Label = $UILayer/LoadingScreen/Panel/Label
@onready var ui_layer: CanvasLayer = $UILayer

var _space_rock_textures: Array[Texture2D] = []
var _isolation_band_tile_sets: Array[Array] = []
var _chest_textures: Array[Texture2D] = []
var _ore_vein_textures: Array[Texture2D] = []
var _large_rocks: Array[Node2D] = []
var _large_rock_positions: Array[Vector2] = []
var _large_attempts: int = 0
var _large_rock_target_count: int = 0
var _small_parent_index: int = 0
var _command_layer: Control
var _command_dialog_panel: ColorRect
var _command_dialog_label: RichTextLabel
var _command_input_panel: ColorRect
var _command_input_edit: LineEdit
var _command_dialog_tween: Tween
var _command_history: Array[String] = []


func _ready() -> void:
	player.movement_bounds = Rect2(Vector2.ZERO, ROOM_SIZE)
	player.blocked_by_space_rocks = true
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(ROOM_SIZE.x)
	camera.limit_bottom = int(ROOM_SIZE.y)
	camera.position = player.position
	camera.make_current()
	randomize()
	player.visible = false
	_setup_command_ui()
	_start_room_setup()


func _process(_delta: float) -> void:
	camera.global_position = player.global_position
	_update_background_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if GameManager.command_console_open:
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_TAB:
			map_ui.toggle()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_toggle_command_console()
			get_viewport().set_input_as_handled()


func _setup_command_ui() -> void:
	if _command_layer:
		return
	_command_layer = Control.new()
	_command_layer.name = "CommandLayer"
	_command_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_command_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_command_layer.z_index = 4000
	ui_layer.add_child(_command_layer)

	_command_dialog_panel = ColorRect.new()
	_command_dialog_panel.name = "CommandDialogPanel"
	_command_dialog_panel.color = Color(0, 0, 0, 0.92)
	_command_dialog_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_command_dialog_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_command_dialog_panel.offset_left = 0.0
	_command_dialog_panel.offset_right = 0.0
	_command_dialog_panel.offset_top = -200.0
	_command_dialog_panel.offset_bottom = -100.0
	_command_dialog_panel.visible = false
	_command_layer.add_child(_command_dialog_panel)

	_command_dialog_label = RichTextLabel.new()
	_command_dialog_label.name = "CommandDialogLabel"
	_command_dialog_label.bbcode_enabled = false
	_command_dialog_label.scroll_active = false
	_command_dialog_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_command_dialog_label.add_theme_font_size_override(&"normal_font_size", 24)
	_command_dialog_label.add_theme_color_override(&"default_color", Color.WHITE)
	_command_dialog_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_command_dialog_label.offset_left = 24.0
	_command_dialog_label.offset_top = 18.0
	_command_dialog_label.offset_right = -24.0
	_command_dialog_label.offset_bottom = -18.0
	_command_dialog_panel.add_child(_command_dialog_label)

	_command_input_panel = ColorRect.new()
	_command_input_panel.name = "CommandInputPanel"
	_command_input_panel.color = Color(0, 0, 0, 1.0)
	_command_input_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_command_input_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_command_input_panel.offset_left = 0.0
	_command_input_panel.offset_right = 0.0
	_command_input_panel.offset_top = -100.0
	_command_input_panel.offset_bottom = 0.0
	_command_input_panel.visible = false
	_command_layer.add_child(_command_input_panel)

	_command_input_edit = LineEdit.new()
	_command_input_edit.name = "CommandInputEdit"
	_command_input_edit.placeholder_text = "输入指令，以 / 开头"
	_command_input_edit.caret_blink = true
	_command_input_edit.add_theme_font_size_override(&"font_size", 28)
	_command_input_edit.add_theme_color_override(&"font_color", Color.WHITE)
	_command_input_edit.add_theme_color_override(&"font_placeholder_color", Color(1, 1, 1, 0.5))
	_command_input_edit.set_anchors_preset(Control.PRESET_FULL_RECT)
	_command_input_edit.offset_left = 20.0
	_command_input_edit.offset_top = 18.0
	_command_input_edit.offset_right = -20.0
	_command_input_edit.offset_bottom = -18.0
	_command_input_edit.text_submitted.connect(_on_command_text_submitted)
	_command_input_panel.add_child(_command_input_edit)

	_command_layer.visible = true


func _toggle_command_console() -> void:
	if GameManager.command_console_open:
		_submit_command(_command_input_edit.text)
		return
	if _command_dialog_tween and _command_dialog_tween.is_running():
		_command_dialog_tween.kill()
	GameManager.command_console_open = true
	_command_input_panel.visible = true
	_command_dialog_panel.visible = true
	_command_dialog_panel.modulate.a = 1.0
	_refresh_command_dialog()
	_command_input_edit.text = ""
	_command_input_edit.grab_focus()


func _on_command_text_submitted(text: String) -> void:
	_submit_command(text)


func _submit_command(text: String) -> void:
	var command = text.strip_edges()
	if command.is_empty():
		_close_command_console()
		return
	var response = _execute_command(command)
	_close_command_console()
	_append_command_dialog(command, response)


func _execute_command(command: String) -> String:
	if not command.begins_with("/"):
		return "指令必须以 / 开头。输入 /help 查看可用指令。"
	if command == "/help":
		return "/展示陷阱：切换小地图中的炮台与电击隔离带端点显示"
	if command == "/展示陷阱":
		var enabled = map_ui.toggle_turret_trap_mode()
		return "已开启陷阱显示。" if enabled else "已关闭陷阱显示。"
	return "未知指令：%s\n输入 /help 查看可用指令。" % command


func _refresh_command_dialog() -> void:
	if _command_history.is_empty():
		_command_dialog_label.text = ""
		return
	_command_dialog_label.text = "\n\n".join(_command_history)
	_command_dialog_label.call_deferred("scroll_to_line", max(0, _command_dialog_label.get_line_count() - 1))


func _append_command_dialog(command: String, response: String) -> void:
	if _command_dialog_tween and _command_dialog_tween.is_running():
		_command_dialog_tween.kill()
	_command_dialog_panel.visible = true
	_command_dialog_panel.modulate.a = 1.0
	_command_history.append("> %s\n%s" % [command, response])
	while _command_history.size() > 8:
		_command_history.pop_front()
	_refresh_command_dialog()
	_command_dialog_tween = create_tween()
	_command_dialog_tween.tween_interval(1.0)
	_command_dialog_tween.tween_property(_command_dialog_panel, "modulate:a", 0.0, 1.0)
	_command_dialog_tween.tween_callback(func(): _command_dialog_panel.visible = false)


func _close_command_console() -> void:
	GameManager.command_console_open = false
	if is_instance_valid(_command_input_panel):
		_command_input_panel.visible = false
	if is_instance_valid(_command_input_edit):
		_command_input_edit.release_focus()
		_command_input_edit.text = ""


func _update_background_position() -> void:
	var camera_max = ROOM_SIZE - VIEW_SIZE
	var camera_top_left = Vector2(
		clampf(player.global_position.x - VIEW_SIZE.x * 0.5, 0.0, camera_max.x),
		clampf(player.global_position.y - VIEW_SIZE.y * 0.5, 0.0, camera_max.y)
	)
	var background_size = BACKGROUND_TILE_SIZE * BACKGROUND_GRID_SIZE
	var background_max = background_size - VIEW_SIZE
	var background_pos = Vector2(
		camera_top_left.x / maxf(1.0, camera_max.x) * background_max.x,
		camera_top_left.y / maxf(1.0, camera_max.y) * background_max.y
	)
	background_tiles.global_position = camera_top_left - background_pos


func _setup_room() -> void:
	_load_space_rock_textures()
	var large_rocks = _spawn_large_space_rocks()
	_spawn_small_space_rocks(large_rocks)
	_spawn_isolation_bands(large_rocks)
	_spawn_defense_turrets(large_rocks)
	_spawn_rewards(large_rocks)
	_place_player_randomly()


func _start_room_setup() -> void:
	loading_screen.visible = true
	_set_loading_progress(0.0, "正在加载太空石材质...")
	_load_room_async()


func _load_room_async() -> void:
	_load_space_rock_textures()
	_large_rock_target_count = randi_range(SPACE_ROCK_MIN_COUNT, SPACE_ROCK_MAX_COUNT)
	_set_loading_progress(LOAD_STAGE_TEXTURES, "正在生成大块太空石...")
	await get_tree().process_frame
	while _large_rocks.size() < _large_rock_target_count and _large_attempts < _large_rock_target_count * 200:
		for _i in range(LARGE_ROCKS_PER_FRAME):
			if _large_rocks.size() >= _large_rock_target_count or _large_attempts >= _large_rock_target_count * 200:
				break
			_try_spawn_large_space_rock()
		var count_progress = float(_large_rocks.size()) / float(_large_rock_target_count)
		var attempt_progress = float(_large_attempts) / float(_large_rock_target_count * 200)
		var p = maxf(count_progress, attempt_progress)
		_set_loading_progress(lerpf(LOAD_STAGE_TEXTURES, LOAD_STAGE_LARGE_ROCKS, p), "正在生成大块太空石...")
		await get_tree().process_frame
	_set_loading_progress(LOAD_STAGE_LARGE_ROCKS, "正在生成小块太空石...")
	await get_tree().process_frame
	while _small_parent_index < _large_rocks.size():
		for _i in range(SMALL_ROCK_PARENTS_PER_FRAME):
			if _small_parent_index >= _large_rocks.size():
				break
			_spawn_small_space_rocks_for_parent(_large_rocks[_small_parent_index])
			_small_parent_index += 1
		var p = float(_small_parent_index) / maxf(1.0, float(_large_rocks.size()))
		_set_loading_progress(lerpf(LOAD_STAGE_LARGE_ROCKS, LOAD_STAGE_SMALL_ROCKS, p), "正在生成小块太空石...")
		await get_tree().process_frame
	_set_loading_progress(LOAD_STAGE_SMALL_ROCKS, "正在生成隔离带...")
	await get_tree().process_frame
	_spawn_isolation_bands(_large_rocks)
	_set_loading_progress(LOAD_STAGE_ISOLATION_BANDS, "正在生成电击隔离带...")
	await get_tree().process_frame
	_spawn_electric_isolation_bands(_large_rocks)
	_set_loading_progress(LOAD_STAGE_ELECTRIC_ISOLATION_BANDS, "正在生成自动防卫炮台...")
	await get_tree().process_frame
	_spawn_defense_turrets(_large_rocks)
	_set_loading_progress(LOAD_STAGE_TURRETS, "正在生成奖励...")
	await get_tree().process_frame
	_spawn_rewards(_large_rocks)
	_set_loading_progress(LOAD_STAGE_REWARDS, "正在决定玩家出生点...")
	await get_tree().process_frame
	_place_player_randomly()
	camera.position = player.position
	camera.global_position = player.global_position
	_update_background_position()
	player.visible = true
	_set_loading_progress(LOAD_STAGE_DONE, "加载完成")
	await get_tree().process_frame
	loading_screen.visible = false


func _set_loading_progress(value: float, text: String) -> void:
	loading_bar.value = clampf(value * 100.0, 0.0, 100.0)
	loading_label.text = "%s %d%%" % [text, int(loading_bar.value)]


func _load_space_rock_textures() -> void:
	_space_rock_textures.clear()
	for path in SPACE_ROCK_TEXTURE_PATHS:
		var tex = load(path)
		if tex is Texture2D:
			_space_rock_textures.append(tex)
	_isolation_band_tile_sets.clear()
	for paths in ISOLATION_BAND_TILE_PATHS:
		var textures: Array[Texture2D] = []
		for path in paths:
			var tex = load(path)
			if tex is Texture2D:
				textures.append(tex)
		if not textures.is_empty():
			_isolation_band_tile_sets.append(textures)
	_chest_textures.clear()
	for path in CHEST_TEXTURE_PATHS:
		var tex = load(path)
		if tex is Texture2D:
			_chest_textures.append(tex)
	_ore_vein_textures.clear()
	for path in ORE_VEIN_TEXTURE_PATHS:
		var tex = load(path)
		if tex is Texture2D:
			_ore_vein_textures.append(tex)
	_electric_endpoint_textures.clear()
	for path in ELECTRIC_ISOLATION_ENDPOINT_PATHS:
		var tex = load(path)
		if tex is Texture2D:
			_electric_endpoint_textures.append(tex)


func _spawn_large_space_rocks() -> Array[Node2D]:
	var large_rocks: Array[Node2D] = []
	var placed: Array[Vector2] = []
	var attempts: int = 0
	var target_count = randi_range(SPACE_ROCK_MIN_COUNT, SPACE_ROCK_MAX_COUNT)
	while placed.size() < target_count and attempts < target_count * 200:
		attempts += 1
		var pos = Vector2(
			randf_range(SPACE_ROCK_EDGE_MARGIN, ROOM_SIZE.x - SPACE_ROCK_EDGE_MARGIN),
			randf_range(SPACE_ROCK_EDGE_MARGIN, ROOM_SIZE.y - SPACE_ROCK_EDGE_MARGIN)
		)
		if not _is_space_rock_position_valid(pos, placed):
			continue
		var rock = SPACE_ROCK_SCENE.instantiate()
		rock.position = pos
		rock.radius = SPACE_ROCK_BASE_RADIUS * randf_range(SPACE_ROCK_MIN_SCALE, SPACE_ROCK_MAX_SCALE)
		rock.visual_rotation = randf_range(0.0, TAU)
		if not _space_rock_textures.is_empty():
			rock.texture = _space_rock_textures.pick_random()
		space_rocks.add_child(rock)
		large_rocks.append(rock)
		placed.append(pos)
	return large_rocks


func _try_spawn_large_space_rock() -> void:
	_large_attempts += 1
	var pos = Vector2(
		randf_range(SPACE_ROCK_EDGE_MARGIN, ROOM_SIZE.x - SPACE_ROCK_EDGE_MARGIN),
		randf_range(SPACE_ROCK_EDGE_MARGIN, ROOM_SIZE.y - SPACE_ROCK_EDGE_MARGIN)
	)
	if not _is_space_rock_position_valid(pos, _large_rock_positions):
		return
	var rock = SPACE_ROCK_SCENE.instantiate()
	rock.position = pos
	rock.radius = SPACE_ROCK_BASE_RADIUS * randf_range(SPACE_ROCK_MIN_SCALE, SPACE_ROCK_MAX_SCALE)
	rock.visual_rotation = randf_range(0.0, TAU)
	if not _space_rock_textures.is_empty():
		rock.texture = _space_rock_textures.pick_random()
	space_rocks.add_child(rock)
	_large_rocks.append(rock)
	_large_rock_positions.append(pos)


func _spawn_small_space_rocks(large_rocks: Array[Node2D]) -> void:
	for large_rock in large_rocks:
		_spawn_small_space_rocks_for_parent(large_rock)


func _spawn_small_space_rocks_for_parent(large_rock: Node2D) -> void:
	var count = randi_range(SMALL_SPACE_ROCK_MIN_COUNT, SMALL_SPACE_ROCK_MAX_COUNT)
	var placed: Array[Vector2] = []
	var attempts: int = 0
	while placed.size() < count and attempts < count * 20:
		attempts += 1
		var angle = randf_range(0.0, TAU)
		var distance = randf_range(large_rock.radius * 1.1, large_rock.radius * 1.5)
		var pos = large_rock.get_base_position() + Vector2(cos(angle), sin(angle)) * distance
		if not _is_small_space_rock_position_valid(pos, placed):
			continue
		var rock = SPACE_ROCK_SCENE.instantiate()
		rock.position = pos
		rock.radius = randf_range(SMALL_SPACE_ROCK_MIN_RADIUS, SMALL_SPACE_ROCK_MAX_RADIUS)
		rock.use_simple_collision = true
		rock.visual_rotation = randf_range(0.0, TAU)
		if not _space_rock_textures.is_empty():
			rock.texture = _space_rock_textures.pick_random()
		space_rocks.add_child(rock)
		placed.append(pos)


func _spawn_electric_isolation_bands(large_rocks: Array[Node2D]) -> void:
	if large_rocks.size() < 2:
		return
	var target_count = randi_range(ELECTRIC_ISOLATION_BAND_MIN_COUNT, ELECTRIC_ISOLATION_BAND_MAX_COUNT)
	var connected: Array[String] = []
	for _i in range(target_count):
		var a_index = randi_range(0, large_rocks.size() - 1)
		var candidates: Array[int] = []
		var a = large_rocks[a_index]
		for b_index in range(large_rocks.size()):
			if b_index == a_index:
				continue
			var b = large_rocks[b_index]
			if a.get_base_position().distance_to(b.get_base_position()) <= ISOLATION_BAND_MAX_DISTANCE:
				var key = _band_key(a_index, b_index)
				if not connected.has(key):
					candidates.append(b_index)
		if candidates.is_empty():
			continue
		var b_index = candidates.pick_random()
		var b = large_rocks[b_index]
		var key = _band_key(a_index, b_index)
		var a_center = a.get_base_position()
		var b_center = b.get_base_position()
		var a_to_b = (b_center - a_center).normalized()
		var b_to_a = -a_to_b
		if a_to_b == Vector2.ZERO:
			continue
		var start = a.get_surface_anchor(a_to_b.angle(), 0.0) if a.has_method("get_surface_anchor") else a_center + a_to_b * a.radius
		var end = b.get_surface_anchor(b_to_a.angle(), 0.0) if b.has_method("get_surface_anchor") else b_center + b_to_a * b.radius
		var band = ELECTRIC_ISOLATION_BAND_SCENE.instantiate()
		var start_texture = _electric_endpoint_textures.pick_random() if not _electric_endpoint_textures.is_empty() else null
		var end_texture = _electric_endpoint_textures.pick_random() if not _electric_endpoint_textures.is_empty() else null
		band.setup(start, end, a_to_b.angle(), b_to_a.angle(), start_texture, end_texture)
		band.follow_targets(a, start - a.global_position, b, end - b.global_position)
		electric_isolation_bands.add_child(band)
		connected.append(key)


func _spawn_defense_turrets(large_rocks: Array[Node2D]) -> void:
	if large_rocks.is_empty():
		return
	var count = randi_range(TURRET_MIN_COUNT, TURRET_MAX_COUNT)
	var placed_turrets: Array[Vector2] = []
	for _i in range(count):
		for _attempt in range(TURRET_MAX_ATTEMPTS):
			var rock = large_rocks.pick_random()
			if not is_instance_valid(rock):
				continue
			var angle = randf_range(0.0, TAU)
			var pos: Vector2 = rock.get_surface_anchor(angle, TURRET_SURFACE_INSET) if rock.has_method("get_surface_anchor") else rock.get_base_position() + Vector2(cos(angle), sin(angle)) * maxf(0.0, rock.radius - TURRET_SURFACE_INSET)
			var outward = (pos - rock.get_base_position()).normalized()
			if outward == Vector2.ZERO:
				outward = Vector2(cos(angle), sin(angle))
			pos += outward * 48.0
			var too_close = false
			for placed_pos in placed_turrets:
				if pos.distance_to(placed_pos) < TURRET_MIN_DISTANCE:
					too_close = true
					break
			if too_close:
				continue
			if _is_position_near_isolation_band(pos, REWARD_BAND_CLEARANCE):
				continue
			var turret = DEFENSE_TURRET_SCENE.instantiate()
			turret.global_position = pos
			turrets.add_child(turret)
			if turret.has_method("setup_anchor"):
				turret.setup_anchor(rock, pos - rock.global_position, outward.angle())
			placed_turrets.append(pos)
			break


func _spawn_rewards(large_rocks: Array[Node2D]) -> void:
	var placed: Array[Vector2] = []
	_spawn_chests(placed)
	_spawn_ore_veins(large_rocks, placed)


func _spawn_chests(placed: Array[Vector2]) -> void:
	var count = randi_range(CHEST_MIN_COUNT, CHEST_MAX_COUNT)
	var margin = ROOM_SIZE * CHEST_EDGE_EXCLUSION_RATIO
	for _i in range(count):
		for _attempt in range(REWARD_MAX_ATTEMPTS):
			var pos = Vector2(
				randf_range(margin.x, ROOM_SIZE.x - margin.x),
				randf_range(margin.y, ROOM_SIZE.y - margin.y)
			)
			if not _is_reward_position_valid(pos, placed):
				continue
			_create_reward(pos, 0, randf_range(0.0, TAU), null, _chest_textures.pick_random() if not _chest_textures.is_empty() else null)
			placed.append(pos)
			break


func _spawn_ore_veins(large_rocks: Array[Node2D], placed: Array[Vector2]) -> void:
	if large_rocks.is_empty():
		return
	var count = randi_range(ORE_VEIN_MIN_COUNT, ORE_VEIN_MAX_COUNT)
	for _i in range(count):
		for _attempt in range(REWARD_MAX_ATTEMPTS):
			var rock = large_rocks.pick_random()
			if not is_instance_valid(rock):
				continue
			var angle = randf_range(0.0, TAU)
			var pos: Vector2 = rock.get_surface_anchor(angle, ORE_VEIN_SURFACE_INSET) if rock.has_method("get_surface_anchor") else rock.get_base_position() + Vector2(cos(angle), sin(angle)) * maxf(0.0, rock.radius - ORE_VEIN_SURFACE_INSET)
			var outward = (pos - rock.get_base_position()).normalized()
			if outward == Vector2.ZERO:
				outward = Vector2(cos(angle), sin(angle))
			pos += outward * 20.0
			if not _is_reward_position_valid(pos, placed):
				continue
			_create_reward(pos, 1, angle + PI / 2.0, rock, _ore_vein_textures.pick_random() if not _ore_vein_textures.is_empty() else null)
			placed.append(pos)
			break


func _create_reward(pos: Vector2, reward_type: int, rotation_angle: float = 0.0, follow_target: Node2D = null, p_texture: Texture2D = null) -> void:
	var reward = EXPLORE_REWARD_SCENE.instantiate()
	reward.position = pos
	reward.rotation = rotation_angle
	reward.setup(reward_type)
	if p_texture:
		reward.set_reward_texture(p_texture)
	rewards.add_child(reward)
	if is_instance_valid(follow_target) and reward.has_method("follow_target"):
		reward.follow_target(follow_target, pos - follow_target.global_position)


func _is_reward_position_valid(pos: Vector2, placed: Array[Vector2]) -> bool:
	if pos.x < 0.0 or pos.y < 0.0 or pos.x > ROOM_SIZE.x or pos.y > ROOM_SIZE.y:
		return false
	for other in placed:
		if pos.distance_to(other) < REWARD_MIN_DISTANCE:
			return false
	if _is_position_near_isolation_band(pos, REWARD_BAND_CLEARANCE):
		return false
	return true


func _is_position_near_isolation_band(pos: Vector2, clearance: float) -> bool:
	for band in isolation_bands.get_children():
		if not is_instance_valid(band):
			continue
		var start: Vector2 = band.get("start_point") if band.get("start_point") != null else Vector2.ZERO
		var end: Vector2 = band.get("end_point") if band.get("end_point") != null else Vector2.ZERO
		if start == end:
			continue
		var band_width: float = band.get_collision_width() if band.has_method("get_collision_width") else ISOLATION_BAND_WIDTH
		var closest = Geometry2D.get_closest_point_to_segment(pos, start, end)
		if pos.distance_to(closest) < band_width * 0.5 + clearance:
			return true
	return false


func _spawn_isolation_bands(large_rocks: Array[Node2D]) -> void:
	var target_count = randi_range(ISOLATION_BAND_MIN_COUNT, ISOLATION_BAND_MAX_COUNT)
	print("[隔离带] 目标生成数量: %d (范围 %d-%d)" % [target_count, ISOLATION_BAND_MIN_COUNT, ISOLATION_BAND_MAX_COUNT])
	var connected: Array[String] = []
	var bands_by_key: Dictionary = {}
	var removed_by_pathfinding: int = 0
	for _i in range(target_count):
		if large_rocks.size() < 2:
			return
		var a_index = randi_range(0, large_rocks.size() - 1)
		var a = large_rocks[a_index]
		var candidates: Array[int] = []
		for b_index in range(large_rocks.size()):
			if b_index == a_index:
				continue
			var b = large_rocks[b_index]
			if a.get_base_position().distance_to(b.get_base_position()) <= ISOLATION_BAND_MAX_DISTANCE:
				candidates.append(b_index)
		if candidates.is_empty():
			continue
		var b_index = candidates.pick_random()
		var key = _band_key(a_index, b_index)
		if connected.has(key):
			continue
		var b = large_rocks[b_index]
		if _is_band_blocked(a, b, large_rocks):
			continue
		var start = a.get_base_position()
		var end = b.get_base_position()
		_destroy_small_space_rocks_on_band_path(start, end)
		var band = _create_isolation_band(start, end)
		var band_w: float = band.get_collision_width() if band.has_method("get_collision_width") else ISOLATION_BAND_WIDTH
		if not _can_traverse_between_band_sides(start, end, band_w):
			band.queue_free()
			removed_by_pathfinding += 1
			continue
		connected.append(key)
		bands_by_key[key] = band
		_sync_connected_sway_component(a_index, large_rocks, connected, bands_by_key)
	print("[隔离带] 实际生成数量: %d, 因寻路验证删除: %d" % [connected.size(), removed_by_pathfinding])


func _band_key(a: int, b: int) -> String:
	return "%d_%d" % [mini(a, b), maxi(a, b)]


func _can_traverse_between_band_sides(band_start: Vector2, band_end: Vector2, band_width: float) -> bool:
	const CELL_SIZE: float = 200.0
	var grid_w: int = int(ceil(ROOM_SIZE.x / CELL_SIZE))
	var grid_h: int = int(ceil(ROOM_SIZE.y / CELL_SIZE))

	var blocked: Array[Array] = []
	for x in range(grid_w):
		var col: Array[bool] = []
		col.resize(grid_h)
		col.fill(false)
		blocked.append(col)

	for rock in space_rocks.get_children():
		if not is_instance_valid(rock):
			continue
		var radius: float = rock.get("radius") if rock.get("radius") != null else SPACE_ROCK_BASE_RADIUS
		var pos: Vector2 = rock.get_base_position() if rock.has_method("get_base_position") else rock.global_position
		var rx0 = int(maxf(0, (pos.x - radius) / CELL_SIZE))
		var rx1 = int(minf(grid_w - 1, (pos.x + radius) / CELL_SIZE))
		var ry0 = int(maxf(0, (pos.y - radius) / CELL_SIZE))
		var ry1 = int(minf(grid_h - 1, (pos.y + radius) / CELL_SIZE))
		for gx in range(rx0, rx1 + 1):
			for gy in range(ry0, ry1 + 1):
				var cell_center = Vector2(gx * CELL_SIZE + CELL_SIZE * 0.5, gy * CELL_SIZE + CELL_SIZE * 0.5)
				if cell_center.distance_to(pos) < radius:
					blocked[gx][gy] = true

	for band in isolation_bands.get_children():
		if not is_instance_valid(band):
			continue
		var s: Vector2 = band.get("start_point") if band.get("start_point") != null else Vector2.ZERO
		var e: Vector2 = band.get("end_point") if band.get("end_point") != null else Vector2.ZERO
		if s == e:
			continue
		var w: float = band.get_collision_width() if band.has_method("get_collision_width") else ISOLATION_BAND_WIDTH
		var bx0 = int(maxf(0, (minf(s.x, e.x) - w) / CELL_SIZE))
		var bx1 = int(minf(grid_w - 1, (maxf(s.x, e.x) + w) / CELL_SIZE))
		var by0 = int(maxf(0, (minf(s.y, e.y) - w) / CELL_SIZE))
		var by1 = int(minf(grid_h - 1, (maxf(s.y, e.y) + w) / CELL_SIZE))
		for gx in range(bx0, bx1 + 1):
			for gy in range(by0, by1 + 1):
				var cell_center = Vector2(gx * CELL_SIZE + CELL_SIZE * 0.5, gy * CELL_SIZE + CELL_SIZE * 0.5)
				var closest = Geometry2D.get_closest_point_to_segment(cell_center, s, e)
				if cell_center.distance_to(closest) < w * 0.5:
					blocked[gx][gy] = true

	var direction = (band_end - band_start).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	var offset = band_width * 0.5 + CELL_SIZE * 2
	var midpoint = (band_start + band_end) * 0.5
	var side_a = midpoint + perpendicular * offset
	var side_b = midpoint - perpendicular * offset

	var start_cell = _world_to_cell(side_a, grid_w, grid_h, CELL_SIZE)
	var end_cell = _world_to_cell(side_b, grid_w, grid_h, CELL_SIZE)

	if blocked[start_cell.x][start_cell.y] or blocked[end_cell.x][end_cell.y]:
		return false

	var queue: Array[Vector2i] = [start_cell]
	var visited: Dictionary = {}
	visited["%d_%d" % [start_cell.x, start_cell.y]] = true

	while not queue.is_empty():
		var cur = queue.pop_front()
		if cur == end_cell:
			return true
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var nx = cur.x + dx
				var ny = cur.y + dy
				if nx < 0 or ny < 0 or nx >= grid_w or ny >= grid_h:
					continue
				var key = "%d_%d" % [nx, ny]
				if visited.has(key):
					continue
				if blocked[nx][ny]:
					continue
				visited[key] = true
				queue.append(Vector2i(nx, ny))

	return false


func _world_to_cell(world_pos: Vector2, grid_w: int, grid_h: int, cell_size: float) -> Vector2i:
	return Vector2i(
		clamp(int(world_pos.x / cell_size), 0, grid_w - 1),
		clamp(int(world_pos.y / cell_size), 0, grid_h - 1)
	)


func _is_band_blocked(a: Node2D, b: Node2D, large_rocks: Array[Node2D]) -> bool:
	var start = a.get_base_position()
	var end = b.get_base_position()
	for rock in large_rocks:
		if rock == a or rock == b:
			continue
		var center = rock.get_base_position()
		var closest = Geometry2D.get_closest_point_to_segment(center, start, end)
		if center.distance_to(closest) < rock.radius + ISOLATION_BAND_WIDTH * 0.5:
			return true
	return false


func _create_isolation_band(start: Vector2, end: Vector2) -> Node2D:
	var band = ISOLATION_BAND_SCENE.instantiate()
	if _isolation_band_tile_sets.is_empty():
		band.setup(start, end, ISOLATION_BAND_WIDTH)
	else:
		band.setup_tiles(start, end, ISOLATION_BAND_WIDTH, _isolation_band_tile_sets.pick_random())
	isolation_bands.add_child(band)
	return band


func _sync_connected_sway_component(start_index: int, large_rocks: Array[Node2D], connected: Array[String], bands_by_key: Dictionary) -> void:
	var rock_indices: Array[int] = []
	var band_keys: Array[String] = []
	var queue: Array[int] = [start_index]
	var visited: Dictionary = {}
	visited[start_index] = true

	while not queue.is_empty():
		var current = queue.pop_front()
		rock_indices.append(current)
		for key in connected:
			var pair = _parse_band_key(key)
			if pair.x != current and pair.y != current:
				continue
			if not band_keys.has(key):
				band_keys.append(key)
			var next_index = pair.y if pair.x == current else pair.x
			if visited.has(next_index):
				continue
			visited[next_index] = true
			queue.append(next_index)

	if rock_indices.is_empty():
		return
	var source = large_rocks[rock_indices[0]]
	if not source.has_method("get_sway_profile"):
		return
	var profile: Dictionary = source.get_sway_profile()
	for index in rock_indices:
		var rock = large_rocks[index]
		if rock.has_method("set_sway_profile"):
			rock.set_sway_profile(profile)
	for key in band_keys:
		var band = bands_by_key.get(key)
		if is_instance_valid(band) and band.has_method("set_sway_profile"):
			band.set_sway_profile(profile)


func _parse_band_key(key: String) -> Vector2i:
	var parts = key.split("_")
	return Vector2i(int(parts[0]), int(parts[1]))


func _destroy_small_space_rocks_on_band_path(start: Vector2, end: Vector2) -> void:
	for rock in space_rocks.get_children():
		if not is_instance_valid(rock) or _large_rocks.has(rock):
			continue
		var center = rock.get_base_position() if rock.has_method("get_base_position") else rock.global_position
		var closest = Geometry2D.get_closest_point_to_segment(center, start, end)
		var radius: float = rock.get("radius") if rock.get("radius") != null else 0.0
		if center.distance_to(closest) <= radius + ISOLATION_BAND_WIDTH * 0.5:
			rock.queue_free()


func _place_player_randomly() -> void:
	for _i in range(1000):
		var pos = Vector2(
			randf_range(PLAYER_SPAWN_MARGIN, ROOM_SIZE.x - PLAYER_SPAWN_MARGIN),
			randf_range(PLAYER_SPAWN_MARGIN, ROOM_SIZE.y - PLAYER_SPAWN_MARGIN)
		)
		if _is_player_spawn_position_valid(pos):
			player.global_position = pos
			return
	player.global_position = ROOM_SIZE * 0.5


func _is_player_spawn_position_valid(pos: Vector2) -> bool:
	for rock in space_rocks.get_children():
		if not is_instance_valid(rock):
			continue
		var radius: float = rock.get("radius") if rock.get("radius") != null else SPACE_ROCK_BASE_RADIUS
		if pos.distance_to(rock.global_position) < radius + PLAYER_SPAWN_CLEARANCE:
			return false
	for band in isolation_bands.get_children():
		if not is_instance_valid(band):
			continue
		var start: Vector2 = band.get("start_point") if band.get("start_point") != null else Vector2.ZERO
		var end: Vector2 = band.get("end_point") if band.get("end_point") != null else Vector2.ZERO
		if start == end:
			continue
		var closest = Geometry2D.get_closest_point_to_segment(pos, start, end)
		var band_width: float = band.get_collision_width() if band.has_method("get_collision_width") else ISOLATION_BAND_WIDTH
		if pos.distance_to(closest) < band_width * 0.5 + PLAYER_SPAWN_CLEARANCE:
			return false
	return true


func _is_space_rock_position_valid(pos: Vector2, placed: Array[Vector2]) -> bool:
	for other in placed:
		if pos.distance_to(other) < SPACE_ROCK_MIN_DISTANCE:
			return false
	return true


func _is_small_space_rock_position_valid(pos: Vector2, placed: Array[Vector2]) -> bool:
	for other in placed:
		if pos.distance_to(other) < SMALL_SPACE_ROCK_MIN_DISTANCE:
			return false
	return true
