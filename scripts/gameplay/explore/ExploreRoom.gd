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
const ELECTRIC_ISOLATION_BAND_MIN_COUNT: int = 2
const ELECTRIC_ISOLATION_BAND_MAX_COUNT: int = 5
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
const TRAP_REWARD_CLEARANCE: float = 500.0
const CLUTTER_MIN_COUNT: int = 20
const CLUTTER_MAX_COUNT: int = 100
const CLUTTER_MIN_DISTANCE: float = 200.0
const CLUTTER_MAX_ATTEMPTS: int = 16000
const CLUTTER_BIG_ROCK_CLEARANCE: float = 120.0
const CLUTTER_TEXTURE_DIR: String = "res://assets/images/explore/clutter/generated/props"
const EVACUATION_MIN_DISTANCE_FROM_SPAWN: float = 5000.0
const EVACUATION_MAX_ATTEMPTS: int = 3000
const EVACUATION_ROCK_CLEARANCE: float = 160.0
const ORE_VEIN_SURFACE_INSET: float = 48.0
const CHEST_EDGE_EXCLUSION_RATIO: float = 0.125
const PLAYER_SPAWN_MARGIN: float = 120.0
const PLAYER_SPAWN_CLEARANCE: float = 120.0
const PATROL_PATH_MIN_COUNT: int = 2
const PATROL_PATH_MAX_COUNT: int = 4
const PATROL_PATH_GRID_SIZE: float = 340.0
const PATROL_PATH_CLEARANCE: float = 180.0
const PATROL_PATH_POINT_OFFSET: float = 100.0
const PATROL_PATH_EDGE_MARGIN: float = 80.0
const PATROL_PATH_OUTSIDE_MARGIN: float = 400.0
const PATROL_ENEMY_OUTSIDE_MARGIN: float = 140.0
const PATROL_PATH_MAX_ATTEMPTS: int = 6
const PATROL_PATH_SIMPLIFY_EPSILON: float = 120.0
const PATROL_PATH_MAX_POINTS: int = 96
const PATROL_PATH_LINE_WIDTH: float = 18.0
const PATROL_PATH_LINE_COLOR: Color = Color(1.0, 0.05, 0.02, 0.9)
const PATROL_PATH_GRID_ROWS_PER_FRAME: int = 4
const SHOW_PATROL_PATH_DEBUG_LINES: bool = false
const PATROL_ENEMY_MIN_GROUP_COUNT: int = 2
const PATROL_ENEMY_MAX_GROUP_COUNT: int = 5
const PATROL_ENEMY_SPAWN_SPACING: float = 96.0
const PATROL_ENEMY_PATH_OFFSET: float = 90.0
const PATROL_ENEMY_DESPAWN_MARGIN: float = 900.0
const PATROL_ENEMY_DEFAULT_SPAWN_INTERVAL: float = 30.0
const PATROL_ENEMY_SPAWNS_PER_FRAME: int = 1
const PATROL_ENEMY_DEFAULT_MAX_COUNT: int = 20
const PATROL_ENEMY_MAX_QUEUED_SPAWNS: int = 12
const PATROL_ENEMY_POOL_PREWARM_PER_BEHAVIOR: int = 3
const PATROL_ENEMY_POOL_MAX_PER_BEHAVIOR: int = 8
const DEBUG_ENEMY_MAX_COUNT: int = 30
const ELITE_CHEST_REPLACEMENT_MIN_COUNT: int = 1
const ELITE_CHEST_REPLACEMENT_MAX_COUNT: int = 3
const RENDER_ACTIVE_MARGIN: float = 1000.0
const RENDER_CULL_UPDATE_INTERVAL: float = 0.25
const RENDER_CULL_NODES_PER_FRAME: int = 24
const LOAD_STAGE_TEXTURES: float = 0.05
const LOAD_STAGE_LARGE_ROCKS: float = 0.35
const LOAD_STAGE_SMALL_ROCKS: float = 0.85
const LOAD_STAGE_ISOLATION_BANDS: float = 0.91
const LOAD_STAGE_ELECTRIC_ISOLATION_BANDS: float = 0.93
const LOAD_STAGE_TURRETS: float = 0.95
const LOAD_STAGE_REWARDS: float = 0.975
const LOAD_STAGE_CLUTTER: float = 0.985
const LOAD_STAGE_SPAWN_POINTS: float = 0.99
const LOAD_STAGE_PATROL_PATHS: float = 0.993
const LOAD_STAGE_PATROL_POOL: float = 0.997
const LOAD_STAGE_ELITE_CHESTS: float = 0.999
const LOAD_STAGE_DONE: float = 1.0
const LARGE_ROCKS_PER_FRAME: int = 4
const SMALL_ROCK_PARENTS_PER_FRAME: int = 1
const SMALL_ROCKS_PER_FRAME: int = 4
const TEXTURE_LOADS_PER_FRAME: int = 3

const SPACE_ROCK_SCENE := preload("res://scenes/gameplay/explore/SpaceRock.tscn")
const ISOLATION_BAND_SCENE := preload("res://scenes/gameplay/explore/IsolationBand.tscn")
const ELECTRIC_ISOLATION_BAND_SCENE := preload("res://scenes/gameplay/explore/ElectricIsolationBand.tscn")
const DEFENSE_TURRET_SCENE := preload("res://scenes/gameplay/explore/DefenseTurret.tscn")
const EXPLORE_REWARD_SCENE := preload("res://scenes/gameplay/explore/ExploreReward.tscn")
const SPACE_CLUTTER_SCENE := preload("res://scenes/gameplay/explore/SpaceClutter.tscn")
const EVACUATION_POINT_SCENE := preload("res://scenes/gameplay/explore/EvacuationPoint.tscn")
const EVACUATION_SUCCESS_HUD_SCENE := preload("res://scenes/ui/EvacuationSuccessHUD.tscn")
const COMMAND_CONSOLE_POPUP_SCENE := preload("res://scenes/ui/explore/CommandConsolePopup.tscn")
const DESIGNED_ENEMY_SCENE := preload("res://scenes/entities/designed_enemies/DesignedEnemy.tscn")
const DesignedEnemyScript = preload("res://scripts/entities/designed_enemies/DesignedEnemy.gd")
const DesignedEnemyCatalog = preload("res://scripts/entities/designed_enemies/DesignedEnemyCatalog.gd")
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
const ORE_SOURCE_WEIGHTS: Dictionary = {
	"star_marrow": 52.0,
	"gleam_crystal": 24.0,
	"rift_cluster": 16.0,
	"deep_core": 8.0,
}
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
const COMMAND_HELP_ENTRIES: Array[Dictionary] = [
	{"command": "/展示陷阱", "description": "切换小地图中的炮台与电击隔离带端点显示"},
	{"command": "/展示刷怪", "description": "切换小地图中的巡逻路线显示"},
	{"command": "/清除迷雾", "description": "隐藏小地图上的所有战争迷雾"},
]

@export var large_space_rock_count: int = -1
@export var trap_count: int = -1
@export var chest_crystal_count: int = -1
@export var clutter_count: int = -1
@export var colossus_family_weight: float = 1.0
@export var paradise_family_weight: float = 1.0
@export var warped_family_weight: float = 1.0
@export var hell_eye_family_weight: float = 1.0
@export var divine_family_weight: float = 1.0
@export var enemy_spawn_interval: float = PATROL_ENEMY_DEFAULT_SPAWN_INTERVAL
@export var max_patrol_enemy_count: int = PATROL_ENEMY_DEFAULT_MAX_COUNT
@export var patrol_path_min_count: int = PATROL_PATH_MIN_COUNT
@export var patrol_path_max_count: int = PATROL_PATH_MAX_COUNT
@export var elite_replacement_min_count: int = ELITE_CHEST_REPLACEMENT_MIN_COUNT
@export var elite_replacement_max_count: int = ELITE_CHEST_REPLACEMENT_MAX_COUNT

@onready var player: Area2D = $player
@onready var camera: Camera2D = $Camera2D
@onready var background_tiles: Node2D = $BackgroundTiles
@onready var isolation_bands: Node2D = $IsolationBands
@onready var electric_isolation_bands: Node2D = $ElectricIsolationBands
@onready var space_rocks: Node2D = $SpaceRocks
@onready var turrets: Node2D = $Turrets
@onready var rewards: Node2D = $Rewards
@onready var clutter: Node2D = $Clutter
@onready var evacuation_points: Node2D = $EvacuationPoints
@onready var enemy_effects: Node2D = $EnemyEffects if has_node("EnemyEffects") else null
@onready var map_ui: Control = $UILayer/ExploreMapUI
@onready var loading_screen: Control = $UILayer/LoadingScreen
@onready var loading_bar: ProgressBar = loading_screen.find_child("ProgressBar", true, false) as ProgressBar
@onready var loading_label: Label = loading_screen.find_child("Label", true, false) as Label
@onready var loading_tip_label: Label = loading_screen.find_child("TipLabel", true, false) as Label
@onready var ui_layer: CanvasLayer = $UILayer

var _space_rock_textures: Array[Texture2D] = []
var _isolation_band_tile_sets: Array[Array] = []
var _chest_textures: Array[Texture2D] = []
var _ore_vein_textures: Array[Texture2D] = []
var _clutter_textures: Array[Texture2D] = []
var _electric_endpoint_textures: Array[Texture2D] = []
var _large_rocks: Array[Node2D] = []
var _large_rock_positions: Array[Vector2] = []
var _large_attempts: int = 0
var _large_rock_target_count: int = 0
var _small_parent_index: int = 0
var _small_rock_spawn_queue: Array[Node2D] = []
var _command_layer: Control
var _command_dialog_panel: Control
var _command_dialog_label: RichTextLabel
var _command_input_panel: Control
var _command_input_edit: LineEdit
var _command_dialog_tween: Tween
var _command_history: Array[String] = []
var _patrol_paths: Node2D
var _enemies: Node2D
var _patrol_path_points: Array[PackedVector2Array] = []
var _patrol_path_families: Array[String] = []
var _static_enemy_map_icons: Array[Dictionary] = []
var _enemy_spawn_timer: float = 0.0
var _pending_patrol_enemy_spawns: Array[Dictionary] = []
var _patrol_enemy_pool: Dictionary = {}
var _patrol_enemy_pool_container: Node2D
var _patrol_enemy_pool_prewarm_queue: Array[int] = []
var _static_enemy_icon_texture_poll_timer: float = 0.0
var _render_cull_timer: float = 0.0
var _render_cull_in_progress: bool = false
var _render_cull_container_index: int = 0
var _render_cull_child_index: int = 0
var _ore_source_weights: Dictionary = ORE_SOURCE_WEIGHTS.duplicate(true)
var _render_cull_active_rect: Rect2 = Rect2()
var _debug_enemy_cycle_active: bool = false
var _debug_enemy_cycle_index: int = 0
var _debug_enemy_cycle_timer: float = 0.0
var _debug_enemy_cycle_interval: float = 5.0
var _engineering_console_unlocked: bool = false
var _room_setup_cancelled: bool = false
var _loading_context_tip_text: String = ""


func _ready() -> void:
	_ensure_enemy_effects_root()
	_apply_pending_room_config()
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


func _exit_tree() -> void:
	_room_setup_cancelled = true
	if _command_dialog_tween and _command_dialog_tween.is_running():
		_command_dialog_tween.kill()
	_clear_patrol_runtime()
	_clear_enemy_effects_root()
	DesignedEnemyScript.release_static_runtime_resources()


func _ensure_enemy_effects_root() -> void:
	if is_instance_valid(enemy_effects):
		return
	enemy_effects = Node2D.new()
	enemy_effects.name = "EnemyEffects"
	add_child(enemy_effects)


func _clear_enemy_effects_root() -> void:
	if not is_instance_valid(enemy_effects):
		return
	for child in enemy_effects.get_children():
		if is_instance_valid(child):
			child.queue_free()
	enemy_effects.queue_free()
	enemy_effects = null


func setup_room_counts(p_large_space_rock_count: int = -1, p_trap_count: int = -1, p_chest_crystal_count: int = -1, p_clutter_count: int = -1) -> void:
	large_space_rock_count = maxi(-1, p_large_space_rock_count)
	trap_count = maxi(-1, p_trap_count)
	chest_crystal_count = maxi(-1, p_chest_crystal_count)
	clutter_count = maxi(-1, p_clutter_count)


func setup_room_config(config: Dictionary) -> void:
	if config.has("large_space_rock_count"):
		large_space_rock_count = maxi(-1, int(config["large_space_rock_count"]))
	if config.has("trap_count"):
		trap_count = maxi(-1, int(config["trap_count"]))
	if config.has("chest_crystal_count"):
		chest_crystal_count = maxi(-1, int(config["chest_crystal_count"]))
	if config.has("clutter_count"):
		clutter_count = maxi(-1, int(config["clutter_count"]))
	if config.has("colossus_family_weight"):
		colossus_family_weight = maxf(0.0, float(config["colossus_family_weight"]))
	if config.has("paradise_family_weight"):
		paradise_family_weight = maxf(0.0, float(config["paradise_family_weight"]))
	if config.has("warped_family_weight"):
		warped_family_weight = maxf(0.0, float(config["warped_family_weight"]))
	if config.has("hell_eye_family_weight"):
		hell_eye_family_weight = maxf(0.0, float(config["hell_eye_family_weight"]))
	if config.has("divine_family_weight"):
		divine_family_weight = maxf(0.0, float(config["divine_family_weight"]))
	if config.has("enemy_spawn_interval"):
		enemy_spawn_interval = maxf(0.1, float(config["enemy_spawn_interval"]))
	if config.has("max_patrol_enemy_count"):
		max_patrol_enemy_count = maxi(0, int(config["max_patrol_enemy_count"]))
	if config.has("modifier_tip_text"):
		_loading_context_tip_text = String(config["modifier_tip_text"]).strip_edges()
	if config.has("ore_source_weights"):
		_apply_ore_source_weights(config["ore_source_weights"])
	_apply_battle_profile_config(config)


func get_room_config() -> Dictionary:
	return {
		"large_space_rock_count": large_space_rock_count,
		"trap_count": trap_count,
		"chest_crystal_count": chest_crystal_count,
		"clutter_count": clutter_count,
		"colossus_family_weight": colossus_family_weight,
		"paradise_family_weight": paradise_family_weight,
		"warped_family_weight": warped_family_weight,
		"hell_eye_family_weight": hell_eye_family_weight,
		"divine_family_weight": divine_family_weight,
		"enemy_spawn_interval": enemy_spawn_interval,
		"max_patrol_enemy_count": max_patrol_enemy_count,
		"patrol_path_min_count": patrol_path_min_count,
		"patrol_path_max_count": patrol_path_max_count,
		"elite_replacement_min_count": elite_replacement_min_count,
		"elite_replacement_max_count": elite_replacement_max_count,
	}


func _apply_battle_profile_config(config: Dictionary) -> void:
	if config.has("battle_trap_pressure"):
		trap_count = maxi(trap_count, int(config["battle_trap_pressure"]))
	if config.has("battle_enemy_spawn_interval"):
		enemy_spawn_interval = minf(enemy_spawn_interval, maxf(0.1, float(config["battle_enemy_spawn_interval"])))
	if config.has("battle_max_patrol_enemy_count"):
		max_patrol_enemy_count = maxi(max_patrol_enemy_count, int(config["battle_max_patrol_enemy_count"]))
	if config.has("battle_family_bias"):
		_apply_battle_family_bias(
			String(config["battle_family_bias"]),
			maxf(1.0, float(config.get("battle_family_weight_boost", 1.0)))
		)
	if config.has("battle_patrol_path_min_count"):
		patrol_path_min_count = maxi(0, int(config["battle_patrol_path_min_count"]))
	if config.has("battle_patrol_path_max_count"):
		patrol_path_max_count = maxi(patrol_path_min_count, int(config["battle_patrol_path_max_count"]))
	if config.has("battle_elite_replacement_min"):
		elite_replacement_min_count = maxi(0, int(config["battle_elite_replacement_min"]))
	if config.has("battle_elite_replacement_max"):
		elite_replacement_max_count = maxi(elite_replacement_min_count, int(config["battle_elite_replacement_max"]))


func _apply_battle_family_bias(family: String, weight_boost: float) -> void:
	match family:
		"colossus":
			colossus_family_weight = maxf(colossus_family_weight, weight_boost)
		"paradise":
			paradise_family_weight = maxf(paradise_family_weight, weight_boost)
		"warped":
			warped_family_weight = maxf(warped_family_weight, weight_boost)
		"hell_eye":
			hell_eye_family_weight = maxf(hell_eye_family_weight, weight_boost)
		"divine":
			divine_family_weight = maxf(divine_family_weight, weight_boost)


func _apply_pending_room_config() -> void:
	if GameManager.has_method("consume_next_explore_room_config"):
		setup_room_config(GameManager.consume_next_explore_room_config())


func _configured_or_random_count(configured_count: int, default_min: int, default_max: int) -> int:
	return configured_count if configured_count >= 0 else randi_range(default_min, default_max)


func _get_reward_target_counts(large_rocks: Array[Node2D]) -> Vector2i:
	if chest_crystal_count < 0:
		return Vector2i(
			randi_range(CHEST_MIN_COUNT, CHEST_MAX_COUNT),
			randi_range(ORE_VEIN_MIN_COUNT, ORE_VEIN_MAX_COUNT)
		)
	if large_rocks.is_empty():
		return Vector2i(chest_crystal_count, 0)
	var chest_count = mini(chest_crystal_count, maxi(1, int(ceil(float(chest_crystal_count) * 0.25))))
	var ore_vein_count = chest_crystal_count - chest_count
	return Vector2i(chest_count, ore_vein_count)


func _process(_delta: float) -> void:
	if not _is_player_camera_effect_active():
		camera.global_position = player.global_position
	_update_background_position()
	if GameManager.should_defer_work("ExploreRoom.after_background"):
		return
	_update_render_culling(_delta)
	if GameManager.should_defer_work("ExploreRoom.after_render_culling"):
		return
	_process_pending_patrol_enemy_spawns()
	if GameManager.should_defer_work("ExploreRoom.after_pending_spawns"):
		return
	_process_patrol_enemy_pool_prewarm()
	if GameManager.should_defer_work("ExploreRoom.after_pool_prewarm"):
		return
	_update_static_enemy_icon_textures(_delta)
	if GameManager.should_defer_work("ExploreRoom.after_static_enemy_icons"):
		return
	_update_patrol_enemy_spawning(_delta)
	if GameManager.should_defer_work("ExploreRoom.after_patrol_spawn_timer"):
		return
	_update_debug_enemy_cycle(_delta)


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


func _update_render_culling(delta: float) -> void:
	if not _render_cull_in_progress:
		_render_cull_timer -= delta
		if _render_cull_timer > 0.0:
			return
		_begin_render_culling_pass()
	_process_render_culling_batch()


func _get_render_active_rect() -> Rect2:
	var viewport_size = get_viewport_rect().size
	var safe_zoom = Vector2(maxf(absf(camera.zoom.x), 0.001), maxf(absf(camera.zoom.y), 0.001))
	var visible_world_size = Vector2(viewport_size.x / safe_zoom.x, viewport_size.y / safe_zoom.y)
	var top_left = camera.global_position - visible_world_size * 0.5
	return Rect2(top_left, visible_world_size).grow(RENDER_ACTIVE_MARGIN)


func _is_player_camera_effect_active() -> bool:
	return is_instance_valid(player) and player.has_method("has_active_camera_effect") and player.has_active_camera_effect()


func _begin_render_culling_pass() -> void:
	_render_cull_in_progress = true
	_render_cull_container_index = 0
	_render_cull_child_index = 0
	_render_cull_active_rect = _get_render_active_rect()


func _process_render_culling_batch() -> void:
	var containers := _get_render_cull_containers()
	var processed := 0
	while _render_cull_container_index < containers.size():
		var container := containers[_render_cull_container_index]
		if not is_instance_valid(container):
			_render_cull_container_index += 1
			_render_cull_child_index = 0
			continue
		var children := container.get_children()
		while _render_cull_child_index < children.size():
			if processed >= RENDER_CULL_NODES_PER_FRAME or GameManager.should_defer_work("ExploreRoom.render_cull_batch"):
				return
			var child := children[_render_cull_child_index]
			_render_cull_child_index += 1
			if not is_instance_valid(child) or not child is Node2D:
				continue
			_apply_render_culling_to_node(child as Node2D, _render_cull_active_rect)
			processed += 1
		_render_cull_container_index += 1
		_render_cull_child_index = 0
	_render_cull_in_progress = false
	_render_cull_timer = RENDER_CULL_UPDATE_INTERVAL


func _get_render_cull_containers() -> Array[Node]:
	var containers: Array[Node] = [
		space_rocks,
		isolation_bands,
		rewards,
		clutter,
		turrets,
		electric_isolation_bands,
	]
	if is_instance_valid(_enemies):
		containers.append(_enemies)
	return containers


func _apply_render_culling_to_node(node: Node2D, active_rect: Rect2) -> void:
	var active = _is_node_near_render_rect(node, active_rect)
	if node.has_method("set_explore_render_active"):
		node.set_explore_render_active(active)
	else:
		node.visible = active
		node.set_process(active)


func _is_node_near_render_rect(node: Node2D, active_rect: Rect2) -> bool:
	if node.has_method("get_map_position"):
		return active_rect.has_point(node.get_map_position())
	if node.has_method("get_base_position"):
		return active_rect.has_point(node.get_base_position())
	if node.has_method("get_map_start") and node.has_method("get_map_end"):
		var start: Vector2 = node.get_map_start()
		var end: Vector2 = node.get_map_end()
		return active_rect.has_point(start) or active_rect.has_point(end) or _segment_intersects_rect(start, end, active_rect)
	if node.has_method("get_map_endpoints"):
		for endpoint in node.get_map_endpoints():
			if active_rect.has_point(endpoint.get("position", Vector2.ZERO)):
				return true
		return false
	return active_rect.has_point(node.global_position)


func _segment_intersects_rect(start: Vector2, end: Vector2, rect: Rect2) -> bool:
	if rect.has_point(start) or rect.has_point(end):
		return true
	var corners = [
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y),
	]
	for i in range(corners.size()):
		if Geometry2D.segment_intersects_segment(start, end, corners[i], corners[(i + 1) % corners.size()]) != null:
			return true
	return false


func _setup_command_ui() -> void:
	if _command_layer:
		return
	_command_layer = COMMAND_CONSOLE_POPUP_SCENE.instantiate() as Control
	ui_layer.add_child(_command_layer)

	_command_dialog_panel = _command_layer.call("get_dialog_panel")
	_command_dialog_label = _command_layer.call("get_dialog_label")
	_command_input_panel = _command_layer.call("get_input_panel")
	_command_input_edit = _command_layer.call("get_input_edit")
	_command_input_edit.text_submitted.connect(_on_command_text_submitted)

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
		_close_command_console(true)
		return
	var response = _execute_command(command)
	_close_command_console()
	_append_command_dialog(command, response)


func _execute_command(command: String) -> String:
	if not command.begins_with("/"):
		return "指令必须以 / 开头。输入 /help 查看可用指令。"
	if command == "/help":
		return _get_command_help_text()
	if command == "/工程席位":
		_engineering_console_unlocked = true
		return "工程席位已接管航图指令。"
	if command == "/展示陷阱":
		var enabled = map_ui.toggle_turret_trap_mode()
		return "已开启陷阱显示。" if enabled else "已关闭陷阱显示。"
	if command == "/展示刷怪":
		var enabled = map_ui.toggle_patrol_spawn_mode()
		return "已开启刷怪巡逻路线显示。" if enabled else "已关闭刷怪巡逻路线显示。"
	if command == "/清除迷雾":
		map_ui.clear_fog()
		return "已清除迷雾。"
	if _is_engineering_command(command) and not _engineering_console_unlocked:
		return "工程席位尚未接管，当前只开放航图辅助指令。"
	if command == "/刷校准者":
		return _spawn_debug_enemy_command(["/刷敌", "8", "1"])
	if command == "/刷全精英":
		return _spawn_debug_elite_command(["/刷精英", "all", "1"])
	if command == "/刷全敌":
		return _spawn_all_debug_enemies()
	if command == "/停轮测":
		_debug_enemy_cycle_active = false
		return "已停止敌人轮测。"
	if command == "/清测试敌":
		return _clear_debug_spawned_enemies()
	if command.begins_with("/轮测敌"):
		return _start_debug_enemy_cycle(command.split(" ", false))
	if command.begins_with("/刷小怪家族"):
		return _spawn_debug_family_minion_command(command.split(" ", false))
	if command.begins_with("/刷精英"):
		return _spawn_debug_elite_command(command.split(" ", false))
	if command.begins_with("/刷敌"):
		return _spawn_debug_enemy_command(command.split(" ", false))
	return "未知指令：%s\n输入 /help 查看可用指令。" % command


func _get_command_help_text() -> String:
	var lines: Array[String] = ["航图指令："]
	for entry in COMMAND_HELP_ENTRIES:
		lines.append("%s：%s" % [entry.get("command", ""), entry.get("description", "")])
	return "\n".join(lines)


func _is_engineering_command(command: String) -> bool:
	return (
		command == "/刷校准者"
		or command == "/刷全精英"
		or command == "/刷全敌"
		or command == "/停轮测"
		or command == "/清测试敌"
		or command.begins_with("/轮测敌")
		or command.begins_with("/刷小怪家族")
		or command.begins_with("/刷精英")
		or command.begins_with("/刷敌")
	)


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


func _close_command_console(hide_dialog: bool = false) -> void:
	GameManager.command_console_open = false
	if is_instance_valid(_command_input_panel):
		_command_input_panel.visible = false
	if is_instance_valid(_command_input_edit):
		_command_input_edit.release_focus()
		_command_input_edit.text = ""
	if hide_dialog and is_instance_valid(_command_dialog_panel):
		if _command_dialog_tween and _command_dialog_tween.is_running():
			_command_dialog_tween.kill()
		_command_dialog_panel.visible = false
		_command_dialog_panel.modulate.a = 0.0


func _spawn_debug_enemy_command(parts: PackedStringArray) -> String:
	if parts.size() < 2:
		return "用法：/刷敌 编号 [数量]，编号范围 0-24。"
	var behavior := _parse_debug_enemy_behavior(parts[1])
	if behavior < 0:
		return "未知敌人：%s。可使用编号0-24，或输入 /刷校准者。" % parts[1]
	var count := 1
	if parts.size() >= 3 and parts[2].is_valid_int():
		count = clampi(int(parts[2]), 1, 12)
	var spawned := 0
	for i in range(count):
		var angle := TAU * float(i) / float(maxi(count, 1))
		var offset := Vector2.RIGHT.rotated(angle) * (460.0 + 70.0 * float(i % 3))
		var pos := _find_debug_enemy_spawn_position(player.global_position + offset)
		var enemy := _spawn_debug_enemy(behavior, pos)
		if is_instance_valid(enemy):
			spawned += 1
	return "已生成测试敌人 %s x%d。" % [_get_debug_enemy_name(behavior), spawned]


func _spawn_debug_family_minion_command(parts: PackedStringArray) -> String:
	if parts.size() < 2:
		return "用法：/刷小怪家族 家族 [数量]。家族可用：colossus/paradise/warped/hell_eye/divine。"
	var family := _normalize_debug_family(parts[1])
	if family.is_empty():
		return "未知家族：%s。家族可用：colossus/paradise/warped/hell_eye/divine。" % parts[1]
	var count := 6
	if parts.size() >= 3 and parts[2].is_valid_int():
		count = clampi(int(parts[2]), 1, 15)
	var behaviors := _get_patrol_enemy_behaviors_for_family(family)
	var spawned := _spawn_debug_behavior_group(behaviors, count, 520.0, false)
	return "已生成%s小怪测试敌人：%d只。" % [_get_debug_family_display_name(family), spawned]


func _spawn_debug_elite_command(parts: PackedStringArray) -> String:
	var family := ""
	var count := 1
	if parts.size() >= 2:
		if parts[1].is_valid_int():
			count = clampi(int(parts[1]), 1, 5)
		else:
			family = _normalize_debug_family(parts[1])
			if family.is_empty() and parts[1].to_lower() != "all":
				return "未知家族：%s。可用家族或all。" % parts[1]
	if parts.size() >= 3 and parts[2].is_valid_int():
		count = clampi(int(parts[2]), 1, 5)
	if parts.size() >= 2 and parts[1].to_lower() == "all":
		var all_behaviors: Array[int] = []
		for elite_family in ["colossus", "paradise", "warped", "hell_eye", "divine"]:
			all_behaviors.append_array(_get_elite_behaviors_for_family(elite_family))
		var all_spawned := _spawn_debug_behavior_group(all_behaviors, count, 760.0, true)
		return "已生成全部精英测试敌人：%d只。" % all_spawned
	if family.is_empty():
		family = _pick_patrol_enemy_family()
	var behaviors := _get_elite_behaviors_for_family(family)
	var spawned := _spawn_debug_behavior_group(behaviors, count, 680.0, true)
	return "已生成%s精英测试敌人：%d只。" % [_get_debug_family_display_name(family), spawned]


func _spawn_all_debug_enemies() -> String:
	_debug_enemy_cycle_active = false
	_clear_debug_spawned_enemies(false)
	var center := player.global_position
	var spawned := 0
	for behavior in range(DesignedEnemyCatalog.ENEMIES.size()):
		var ring := float(behavior / 8)
		var index := behavior % 8
		var angle := TAU * float(index) / 8.0 + ring * 0.22
		var pos := _find_debug_enemy_spawn_position(center + Vector2.RIGHT.rotated(angle) * (560.0 + ring * 300.0))
		var enemy := _spawn_debug_enemy(behavior, pos)
		if is_instance_valid(enemy):
			spawned += 1
	return "已生成全部测试敌人：%d 种。建议逐个靠近观察帧率。" % spawned


func _spawn_debug_behavior_group(behaviors: Array[int], count_per_behavior: int, radius: float, clear_existing: bool) -> int:
	if behaviors.is_empty():
		return 0
	if clear_existing:
		_debug_enemy_cycle_active = false
		_clear_debug_spawned_enemies(false)
	var spawned := 0
	var total := mini(behaviors.size() * count_per_behavior, DEBUG_ENEMY_MAX_COUNT)
	for i in range(total):
		if GameManager.should_defer_work("ExploreRoom.debug_spawn_group"):
			break
		var behavior := behaviors[i % behaviors.size()]
		var ring := float(i / 8)
		var index := i % 8
		var angle := TAU * float(index) / 8.0 + ring * 0.25
		var pos := _find_debug_enemy_spawn_position(player.global_position + Vector2.RIGHT.rotated(angle) * (radius + ring * 220.0))
		var enemy := _spawn_debug_enemy(behavior, pos)
		if is_instance_valid(enemy):
			spawned += 1
	return spawned


func _start_debug_enemy_cycle(parts: PackedStringArray) -> String:
	_debug_enemy_cycle_interval = 5.0
	if parts.size() >= 2 and parts[1].is_valid_float():
		_debug_enemy_cycle_interval = clampf(float(parts[1]), 1.0, 30.0)
	_debug_enemy_cycle_active = true
	_debug_enemy_cycle_index = 0
	_debug_enemy_cycle_timer = 0.0
	_clear_debug_spawned_enemies(false)
	_spawn_debug_cycle_enemy()
	return "已开始敌人轮测，每 %.1f 秒切换一次。输入 /停轮测 停止。" % _debug_enemy_cycle_interval


func _update_debug_enemy_cycle(delta: float) -> void:
	if not _debug_enemy_cycle_active:
		return
	_debug_enemy_cycle_timer -= delta
	if _debug_enemy_cycle_timer > 0.0:
		return
	_debug_enemy_cycle_index += 1
	if _debug_enemy_cycle_index >= DesignedEnemyCatalog.ENEMIES.size():
		_debug_enemy_cycle_active = false
		_clear_debug_spawned_enemies(false)
		_append_command_dialog("/轮测敌", "敌人轮测已完成。")
		return
	_spawn_debug_cycle_enemy()


func _spawn_debug_cycle_enemy() -> void:
	_clear_debug_spawned_enemies(false)
	var behavior := _debug_enemy_cycle_index
	var pos := _find_debug_enemy_spawn_position(player.global_position + Vector2.RIGHT.rotated(player.rotation) * 620.0)
	var enemy := _spawn_debug_enemy(behavior, pos)
	if is_instance_valid(enemy):
		_append_command_dialog("/轮测敌", "当前测试：%s" % _get_debug_enemy_name(behavior))
	_debug_enemy_cycle_timer = _debug_enemy_cycle_interval


func _clear_debug_spawned_enemies(show_message: bool = true) -> String:
	if show_message:
		_debug_enemy_cycle_active = false
	var cleared := 0
	if is_instance_valid(_enemies):
		for enemy in _enemies.get_children():
			if GameManager.should_defer_work("ExploreRoom.clear_debug_enemies"):
				break
			if not is_instance_valid(enemy) or enemy == _patrol_enemy_pool_container:
				continue
			if enemy.get_meta(&"debug_spawned_enemy", false):
				enemy.remove_meta(&"debug_spawned_enemy")
				if enemy.has_method("release_explore_pool_item"):
					enemy.release_explore_pool_item()
				else:
					enemy.queue_free()
				cleared += 1
	return "已清除测试敌人：%d。" % cleared if show_message else ""


func _spawn_debug_enemy(behavior: int, pos: Vector2) -> Node2D:
	_ensure_enemy_container()
	var enemy := _acquire_pooled_patrol_enemy(behavior)
	enemy.global_position = pos
	enemy.set_meta(&"debug_spawned_enemy", true)
	if enemy.get_parent() != _enemies:
		if enemy.get_parent():
			enemy.get_parent().remove_child(enemy)
		_enemies.add_child(enemy)
	if enemy.has_method("reset_explore_pooled_idle_enemy"):
		enemy.reset_explore_pooled_idle_enemy(behavior, Rect2(Vector2.ZERO, ROOM_SIZE), pos)
	elif enemy.has_method("setup_explore_room_idle"):
		enemy.set(&"behavior", behavior)
		enemy.setup_explore_room_idle(Rect2(Vector2.ZERO, ROOM_SIZE))
	return enemy


func _parse_debug_enemy_behavior(token: String) -> int:
	if token.is_valid_int():
		var value := int(token)
		return value if value >= 0 and value < DesignedEnemyCatalog.ENEMIES.size() else -1
	var normalized := token.strip_edges().to_lower()
	for data in DesignedEnemyCatalog.ENEMIES:
		var behavior := int(data.get("behavior", -1))
		var id := String(data.get("id", "")).to_lower()
		var name := String(data.get("name", "")).to_lower()
		if normalized == id or normalized == name:
			return behavior
	return -1


func _get_debug_enemy_name(behavior: int) -> String:
	for data in DesignedEnemyCatalog.ENEMIES:
		if int(data.get("behavior", -1)) == behavior:
			return "%s(%d)" % [String(data.get("name", "敌人")), behavior]
	return "敌人(%d)" % behavior


func _normalize_debug_family(raw: String) -> String:
	var token := raw.strip_edges().to_lower()
	match token:
		"colossus", "巨构", "星间巨构":
			return "colossus"
		"paradise", "天堂", "天堂号":
			return "paradise"
		"warped", "扭曲", "扭曲星核":
			return "warped"
		"hell_eye", "helleye", "地狱", "地狱之眼":
			return "hell_eye"
		"divine", "神明", "神明使者":
			return "divine"
	return ""


func _get_debug_family_display_name(family: String) -> String:
	match family:
		"colossus":
			return "星间巨构"
		"paradise":
			return "天堂号"
		"warped":
			return "扭曲星核"
		"hell_eye":
			return "地狱之眼"
		"divine":
			return "神明使者"
	return family


func _find_debug_enemy_spawn_position(preferred: Vector2) -> Vector2:
	var candidates: Array[Vector2] = [preferred]
	for i in range(16):
		candidates.append(player.global_position + Vector2.RIGHT.rotated(TAU * float(i) / 16.0) * randf_range(420.0, 980.0))
	for candidate in candidates:
		var pos := candidate.clamp(Vector2(160.0, 160.0), ROOM_SIZE - Vector2(160.0, 160.0))
		if not _is_patrol_path_point_blocked(pos):
			return pos
	return preferred.clamp(Vector2(160.0, 160.0), ROOM_SIZE - Vector2(160.0, 160.0))


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
	await _setup_room_async()


func _setup_room_async() -> void:
	_load_space_rock_textures()
	var large_rocks = _spawn_large_space_rocks()
	_spawn_small_space_rocks(large_rocks)
	_spawn_isolation_bands(large_rocks)
	_spawn_defense_turrets(large_rocks)
	_spawn_rewards(large_rocks)
	_spawn_clutter(large_rocks)
	_place_player_randomly()
	_spawn_evacuation_point()
	await _generate_patrol_paths_async()


func _start_room_setup() -> void:
	loading_screen.visible = true
	_set_loading_progress(0.0, "正在加载太空石材质...")
	_load_room_async()


func _load_room_async() -> void:
	await _load_space_rock_textures_async()
	if _is_room_setup_cancelled():
		return
	_large_rocks.clear()
	_large_rock_positions.clear()
	_large_attempts = 0
	_small_parent_index = 0
	_small_rock_spawn_queue.clear()
	_large_rock_target_count = _configured_or_random_count(large_space_rock_count, SPACE_ROCK_MIN_COUNT, SPACE_ROCK_MAX_COUNT)
	_set_loading_progress(LOAD_STAGE_TEXTURES, "正在生成大块太空石...")
	await get_tree().process_frame
	if _is_room_setup_cancelled():
		return
	while _large_rocks.size() < _large_rock_target_count and _large_attempts < _large_rock_target_count * 200:
		for _i in range(LARGE_ROCKS_PER_FRAME):
			if _large_rocks.size() >= _large_rock_target_count or _large_attempts >= _large_rock_target_count * 200:
				break
			_try_spawn_large_space_rock()
		var max_attempts = maxi(1, _large_rock_target_count * 200)
		var count_progress = float(_large_rocks.size()) / maxf(1.0, float(_large_rock_target_count))
		var attempt_progress = float(_large_attempts) / float(max_attempts)
		var p = maxf(count_progress, attempt_progress)
		_set_loading_progress(lerpf(LOAD_STAGE_TEXTURES, LOAD_STAGE_LARGE_ROCKS, p), "正在生成大块太空石...")
		await get_tree().process_frame
		if _is_room_setup_cancelled():
			return
	_set_loading_progress(LOAD_STAGE_LARGE_ROCKS, "正在生成小块太空石...")
	await get_tree().process_frame
	if _is_room_setup_cancelled():
		return
	while _small_parent_index < _large_rocks.size() or not _small_rock_spawn_queue.is_empty():
		var spawned_small := 0
		while spawned_small < SMALL_ROCKS_PER_FRAME:
			if _small_rock_spawn_queue.is_empty():
				if _small_parent_index >= _large_rocks.size():
					break
				for _i in range(SMALL_ROCK_PARENTS_PER_FRAME):
					if _small_parent_index >= _large_rocks.size():
						break
					_queue_small_space_rocks_for_parent(_large_rocks[_small_parent_index])
					_small_parent_index += 1
			if _small_rock_spawn_queue.is_empty():
				break
			var queued_rock := _small_rock_spawn_queue.pop_front() as Node2D
			if is_instance_valid(queued_rock):
				space_rocks.add_child(queued_rock)
				spawned_small += 1
		var p = float(_small_parent_index) / maxf(1.0, float(_large_rocks.size()))
		_set_loading_progress(lerpf(LOAD_STAGE_LARGE_ROCKS, LOAD_STAGE_SMALL_ROCKS, p), "正在生成小块太空石...")
		await get_tree().process_frame
		if _is_room_setup_cancelled():
			return
	_set_loading_progress(LOAD_STAGE_SMALL_ROCKS, "正在生成隔离带...")
	await get_tree().process_frame
	if _is_room_setup_cancelled():
		return
	await _spawn_isolation_bands_async(_large_rocks)
	if _is_room_setup_cancelled():
		return
	_set_loading_progress(LOAD_STAGE_ISOLATION_BANDS, "正在生成电击隔离带...")
	await get_tree().process_frame
	if _is_room_setup_cancelled():
		return
	_spawn_electric_isolation_bands(_large_rocks)
	_set_loading_progress(LOAD_STAGE_ELECTRIC_ISOLATION_BANDS, "正在生成自动防卫炮台...")
	await get_tree().process_frame
	if _is_room_setup_cancelled():
		return
	_spawn_defense_turrets(_large_rocks)
	_set_loading_progress(LOAD_STAGE_TURRETS, "正在生成奖励...")
	await get_tree().process_frame
	if _is_room_setup_cancelled():
		return
	_spawn_rewards(_large_rocks)
	_set_loading_progress(LOAD_STAGE_REWARDS, "正在生成漂浮杂物...")
	await get_tree().process_frame
	if _is_room_setup_cancelled():
		return
	_spawn_clutter(_large_rocks)
	_set_loading_progress(LOAD_STAGE_CLUTTER, "正在决定玩家出生点...")
	await get_tree().process_frame
	if _is_room_setup_cancelled():
		return
	_place_player_randomly()
	_spawn_evacuation_point()
	_set_loading_progress(LOAD_STAGE_SPAWN_POINTS, "正在生成巡逻路径...")
	await get_tree().process_frame
	if _is_room_setup_cancelled():
		return
	await _generate_patrol_paths_async()
	if _is_room_setup_cancelled():
		return
	_set_loading_progress(LOAD_STAGE_PATROL_PATHS, "正在排队巡逻敌人池...")
	await _prewarm_patrol_enemy_pool_for_loading()
	if _is_room_setup_cancelled():
		return
	await get_tree().process_frame
	if _is_room_setup_cancelled():
		return
	_set_loading_progress(LOAD_STAGE_PATROL_POOL, "正在替换宝箱敌人...")
	await get_tree().process_frame
	if _is_room_setup_cancelled():
		return
	_spawn_elite_chest_replacement_enemies()
	_enemy_spawn_timer = enemy_spawn_interval
	_set_loading_progress(LOAD_STAGE_ELITE_CHESTS, "正在完成探索房间...")
	await get_tree().process_frame
	if _is_room_setup_cancelled():
		return
	camera.position = player.position
	camera.global_position = player.global_position
	_update_background_position()
	player.visible = true
	_set_loading_progress(LOAD_STAGE_DONE, "加载完成")
	await get_tree().process_frame
	if _is_room_setup_cancelled():
		return
	loading_screen.visible = false
	GameManager.stutter_context = "ExploreRoom.ready"


func _is_room_setup_cancelled() -> bool:
	return _room_setup_cancelled or not is_inside_tree()


func _set_loading_progress(value: float, text: String) -> void:
	if _is_room_setup_cancelled():
		return
	GameManager.stutter_context = "ExploreRoom.loading:%s:%d%%" % [text, int(clampf(value * 100.0, 0.0, 100.0))]
	if not loading_bar or not loading_label:
		return
	loading_bar.value = clampf(value * 100.0, 0.0, 100.0)
	loading_label.text = "%d%%" % int(loading_bar.value)
	if loading_tip_label:
		loading_tip_label.text = _loading_context_tip_text if not _loading_context_tip_text.is_empty() else text


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
	_electric_endpoint_textures = _load_texture_list(ELECTRIC_ISOLATION_ENDPOINT_PATHS)
	_clutter_textures = _load_textures_from_dir(CLUTTER_TEXTURE_DIR)
	print("[电击隔离带] 端点贴图数量: %d" % _electric_endpoint_textures.size())
	print("[杂物] 贴图数量: %d" % _clutter_textures.size())


func _load_space_rock_textures_async() -> void:
	_space_rock_textures.clear()
	await _load_texture_paths_async(SPACE_ROCK_TEXTURE_PATHS, _space_rock_textures, 0.0, 0.012, "正在加载太空石材质...")
	_isolation_band_tile_sets.clear()
	var tile_index := 0
	for paths in ISOLATION_BAND_TILE_PATHS:
		var textures: Array[Texture2D] = []
		await _load_texture_paths_async(paths, textures, 0.012 + float(tile_index) * 0.006, 0.02 + float(tile_index) * 0.006, "正在加载隔离带材质...")
		if not textures.is_empty():
			_isolation_band_tile_sets.append(textures)
		tile_index += 1
	_chest_textures.clear()
	await _load_texture_paths_async(CHEST_TEXTURE_PATHS, _chest_textures, 0.022, 0.03, "正在加载宝箱材质...")
	_ore_vein_textures.clear()
	await _load_texture_paths_async(ORE_VEIN_TEXTURE_PATHS, _ore_vein_textures, 0.03, 0.038, "正在加载矿脉材质...")
	_electric_endpoint_textures.clear()
	await _load_texture_paths_async(ELECTRIC_ISOLATION_ENDPOINT_PATHS, _electric_endpoint_textures, 0.038, 0.044, "正在加载电击隔离带材质...")
	_clutter_textures.clear()
	var clutter_paths := _collect_texture_paths_from_dir(CLUTTER_TEXTURE_DIR)
	await _load_texture_paths_async(clutter_paths, _clutter_textures, 0.044, LOAD_STAGE_TEXTURES, "正在加载杂物材质...")
	print("[电击隔离带] 端点贴图数量: %d" % _electric_endpoint_textures.size())
	print("[杂物] 贴图数量: %d" % _clutter_textures.size())


func _load_texture_paths_async(paths: Array, target: Array[Texture2D], progress_from: float, progress_to: float, text: String) -> void:
	var total := maxi(1, paths.size())
	for i in range(paths.size()):
		if _is_room_setup_cancelled():
			return
		var tex = load(String(paths[i]))
		if tex is Texture2D:
			target.append(tex)
		if (i + 1) % TEXTURE_LOADS_PER_FRAME == 0:
			var progress := float(i + 1) / float(total)
			_set_loading_progress(lerpf(progress_from, progress_to, progress), text)
			await get_tree().process_frame
			if _is_room_setup_cancelled():
				return
	_set_loading_progress(progress_to, text)
	await get_tree().process_frame


func _collect_texture_paths_from_dir(dir_path: String) -> Array[String]:
	var paths: Array[String] = []
	_collect_texture_paths_from_dir_recursive(dir_path, paths)
	return paths


func _collect_texture_paths_from_dir_recursive(dir_path: String, paths: Array[String]) -> void:
	var dir = DirAccess.open(dir_path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name != "." and file_name != "..":
			var path = dir_path.path_join(file_name)
			if dir.current_is_dir():
				_collect_texture_paths_from_dir_recursive(path, paths)
			elif file_name.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp"]:
				paths.append(path)
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_textures_from_dir(dir_path: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	_load_textures_from_dir_recursive(dir_path, textures)
	return textures


func _load_textures_from_dir_recursive(dir_path: String, textures: Array[Texture2D]) -> void:
	var dir = DirAccess.open(dir_path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name != "." and file_name != "..":
			var path = dir_path.path_join(file_name)
			if dir.current_is_dir():
				_load_textures_from_dir_recursive(path, textures)
			elif file_name.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp"]:
				var tex = load(path)
				if tex is Texture2D:
					textures.append(tex)
		file_name = dir.get_next()
	dir.list_dir_end()


func _load_texture_list(paths: Array[String]) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for path in paths:
		var tex = load(path)
		if tex is Texture2D:
			textures.append(tex)
	return textures


func _spawn_large_space_rocks() -> Array[Node2D]:
	var large_rocks: Array[Node2D] = []
	var placed: Array[Vector2] = []
	var attempts: int = 0
	var target_count = _configured_or_random_count(large_space_rock_count, SPACE_ROCK_MIN_COUNT, SPACE_ROCK_MAX_COUNT)
	_large_rocks.clear()
	_large_rock_positions.clear()
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
		_large_rocks.append(rock)
		placed.append(pos)
		_large_rock_positions.append(pos)
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
	for rock in _build_small_space_rocks_for_parent(large_rock):
		space_rocks.add_child(rock)


func _queue_small_space_rocks_for_parent(large_rock: Node2D) -> void:
	_small_rock_spawn_queue.append_array(_build_small_space_rocks_for_parent(large_rock))


func _build_small_space_rocks_for_parent(large_rock: Node2D) -> Array[Node2D]:
	var result: Array[Node2D] = []
	if not is_instance_valid(large_rock):
		return result
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
		result.append(rock)
		placed.append(pos)
	return result


func _spawn_electric_isolation_bands(large_rocks: Array[Node2D]) -> void:
	if large_rocks.size() < 2:
		return
	var target_count = 0 if trap_count >= 0 else randi_range(ELECTRIC_ISOLATION_BAND_MIN_COUNT, ELECTRIC_ISOLATION_BAND_MAX_COUNT)
	print("[电击隔离带] 目标生成数量: %d" % target_count)
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
			print("[电击隔离带] 第 %d 次尝试未找到可连接的第二块太空石" % (_i + 1))
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
		var start_texture = _electric_endpoint_textures.pick_random() if not _electric_endpoint_textures.is_empty() else null
		var end_texture = _electric_endpoint_textures.pick_random() if not _electric_endpoint_textures.is_empty() else null
		if _is_electric_band_overlapping_isolation_band(start, end):
			print("[电击隔离带] 跳过与隔离带重合的连接 %d -> %d, start=%s end=%s" % [a_index, b_index, start, end])
			continue
		print("[电击隔离带] 连接 %d -> %d, start=%s end=%s, start_tex=%s end_tex=%s" % [a_index, b_index, start, end, start_texture.resource_path if start_texture else "null", end_texture.resource_path if end_texture else "null"])
		var band = ELECTRIC_ISOLATION_BAND_SCENE.instantiate()
		band.setup(start, end, a_to_b.angle(), b_to_a.angle(), start_texture, end_texture)
		band.follow_targets(a, start - a.global_position, b, end - b.global_position)
		electric_isolation_bands.add_child(band)
		connected.append(key)
		print("[电击隔离带] 当前节点数量: %d" % electric_isolation_bands.get_child_count())
	print("[电击隔离带] 实际生成数量: %d" % connected.size())


func _spawn_defense_turrets(large_rocks: Array[Node2D]) -> void:
	if large_rocks.is_empty():
		return
	var count = _configured_or_random_count(trap_count, TURRET_MIN_COUNT, TURRET_MAX_COUNT)
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
			if _is_position_near_electric_endpoint(pos, TRAP_REWARD_CLEARANCE):
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
	var reward_counts = _get_reward_target_counts(large_rocks)
	_spawn_chests(placed, reward_counts.x)
	_spawn_ore_veins(large_rocks, placed, reward_counts.y)


func _spawn_chests(placed: Array[Vector2], count: int) -> void:
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


func _spawn_ore_veins(large_rocks: Array[Node2D], placed: Array[Vector2], count: int) -> void:
	if large_rocks.is_empty():
		return
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
			_create_reward(
				pos,
				1,
				angle + PI / 2.0,
				rock,
				_ore_vein_textures.pick_random() if not _ore_vein_textures.is_empty() else null,
				_pick_ore_source_profile()
			)
			placed.append(pos)
			break


func _create_reward(pos: Vector2, reward_type: int, rotation_angle: float = 0.0, follow_target: Node2D = null, p_texture: Texture2D = null, ore_source_profile: Dictionary = {}) -> void:
	var reward = EXPLORE_REWARD_SCENE.instantiate()
	reward.position = pos
	reward.rotation = rotation_angle
	reward.setup(reward_type)
	if reward_type == 1 and reward.has_method("apply_ore_source_profile"):
		reward.apply_ore_source_profile(ore_source_profile)
	if p_texture:
		reward.set_reward_texture(p_texture)
	rewards.add_child(reward)
	if is_instance_valid(follow_target) and reward.has_method("follow_target"):
		reward.follow_target(follow_target, pos - follow_target.global_position)


func _pick_ore_source_profile() -> Dictionary:
	var profiles: Array = preload("res://scripts/gameplay/explore/ExploreReward.gd").get_ore_source_profiles_static()
	if profiles.is_empty():
		return {}
	var total_weight := 0.0
	for raw_profile in profiles:
		var profile := Dictionary(raw_profile)
		total_weight += maxf(0.0, float(_ore_source_weights.get(String(profile.get("id", "")), 1.0)))
	if total_weight <= 0.0:
		return Dictionary(profiles.pick_random()).duplicate(true)
	var roll := randf() * total_weight
	var cursor := 0.0
	for raw_profile in profiles:
		var profile := Dictionary(raw_profile)
		cursor += maxf(0.0, float(_ore_source_weights.get(String(profile.get("id", "")), 1.0)))
		if roll <= cursor:
			return profile.duplicate(true)
	return Dictionary(profiles.back()).duplicate(true)


func _apply_ore_source_weights(raw_weights) -> void:
	if raw_weights is Dictionary:
		_ore_source_weights = ORE_SOURCE_WEIGHTS.duplicate(true)
		for key in raw_weights.keys():
			_ore_source_weights[String(key)] = maxf(0.0, float(raw_weights[key]))


func _is_reward_position_valid(pos: Vector2, placed: Array[Vector2]) -> bool:
	if pos.x < 0.0 or pos.y < 0.0 or pos.x > ROOM_SIZE.x or pos.y > ROOM_SIZE.y:
		return false
	for other in placed:
		if pos.distance_to(other) < REWARD_MIN_DISTANCE:
			return false
	if _is_position_near_isolation_band(pos, REWARD_BAND_CLEARANCE):
		return false
	if _is_position_near_turret(pos, TRAP_REWARD_CLEARANCE):
		return false
	if _is_position_near_electric_endpoint(pos, TRAP_REWARD_CLEARANCE):
		return false
	return true


func _spawn_clutter(large_rocks: Array[Node2D]) -> void:
	if _clutter_textures.is_empty():
		return
	var target_count = _configured_or_random_count(clutter_count, CLUTTER_MIN_COUNT, CLUTTER_MAX_COUNT)
	var placed: Array[Vector2] = []
	var attempts = 0
	while placed.size() < target_count and attempts < CLUTTER_MAX_ATTEMPTS:
		attempts += 1
		var pos = Vector2(randf_range(0.0, ROOM_SIZE.x), randf_range(0.0, ROOM_SIZE.y))
		if not _is_clutter_position_valid(pos, placed, large_rocks):
			continue
		var node = SPACE_CLUTTER_SCENE.instantiate()
		node.global_position = pos
		node.rotation = randf_range(0.0, TAU)
		node.setup(_clutter_textures.pick_random())
		clutter.add_child(node)
		placed.append(pos)
	print("[杂物] 目标生成数量: %d, 实际生成数量: %d" % [target_count, placed.size()])


func _is_clutter_position_valid(pos: Vector2, placed: Array[Vector2], large_rocks: Array[Node2D]) -> bool:
	if pos.x < 0.0 or pos.y < 0.0 or pos.x > ROOM_SIZE.x or pos.y > ROOM_SIZE.y:
		return false
	for other in placed:
		if pos.distance_to(other) < CLUTTER_MIN_DISTANCE:
			return false
	if _is_position_near_reward(pos, CLUTTER_MIN_DISTANCE):
		return false
	if _is_position_near_turret(pos, CLUTTER_MIN_DISTANCE):
		return false
	if _is_position_near_small_space_rock(pos, CLUTTER_MIN_DISTANCE, large_rocks):
		return false
	if _is_position_near_electric_endpoint(pos, CLUTTER_MIN_DISTANCE):
		return false
	if _is_position_near_isolation_band(pos, CLUTTER_BIG_ROCK_CLEARANCE):
		return false
	if _is_position_inside_large_rock(pos, large_rocks):
		return false
	return true


func _is_position_near_reward(pos: Vector2, clearance: float) -> bool:
	for reward in rewards.get_children():
		if is_instance_valid(reward) and pos.distance_to(reward.global_position) < clearance:
			return true
	return false


func _is_position_near_small_space_rock(pos: Vector2, clearance: float, large_rocks: Array[Node2D]) -> bool:
	for rock in space_rocks.get_children():
		if not is_instance_valid(rock) or large_rocks.has(rock):
			continue
		if pos.distance_to(rock.global_position) < clearance:
			return true
	return false


func _is_position_inside_large_rock(pos: Vector2, large_rocks: Array[Node2D]) -> bool:
	for rock in large_rocks:
		if not is_instance_valid(rock):
			continue
		if rock.has_method("get_push_out_position"):
			var pushed = rock.get_push_out_position(pos, CLUTTER_BIG_ROCK_CLEARANCE)
			if pushed.distance_to(pos) > 0.1:
				return true
		else:
			var radius: float = rock.get("radius") if rock.get("radius") != null else SPACE_ROCK_BASE_RADIUS
			if pos.distance_to(rock.global_position) < radius + CLUTTER_BIG_ROCK_CLEARANCE:
				return true
	return false


func _is_position_near_turret(pos: Vector2, clearance: float) -> bool:
	for turret in turrets.get_children():
		if is_instance_valid(turret) and pos.distance_to(turret.global_position) < clearance:
			return true
	return false


func _is_position_near_electric_endpoint(pos: Vector2, clearance: float) -> bool:
	for band in electric_isolation_bands.get_children():
		if not is_instance_valid(band) or not band.has_method("get_map_endpoints"):
			continue
		for endpoint in band.get_map_endpoints():
			var endpoint_pos: Vector2 = endpoint.get("position", Vector2.ZERO)
			if pos.distance_to(endpoint_pos) < clearance:
				return true
	return false


func _is_position_near_isolation_band(pos: Vector2, clearance: float) -> bool:
	for band in isolation_bands.get_children():
		if not is_instance_valid(band):
			continue
		var start: Vector2 = band.get_map_start() if band.has_method("get_map_start") else band.get("start_point") if band.get("start_point") != null else Vector2.ZERO
		var end: Vector2 = band.get_map_end() if band.has_method("get_map_end") else band.get("end_point") if band.get("end_point") != null else Vector2.ZERO
		if start == end:
			continue
		var band_width: float = band.get_collision_width() if band.has_method("get_collision_width") else ISOLATION_BAND_WIDTH
		var closest = Geometry2D.get_closest_point_to_segment(pos, start, end)
		if pos.distance_to(closest) < band_width * 0.5 + clearance:
			return true
	return false


func _is_electric_band_overlapping_isolation_band(start: Vector2, end: Vector2) -> bool:
	for band in isolation_bands.get_children():
		if not is_instance_valid(band) or not band.has_method("get_map_start") or not band.has_method("get_map_end"):
			continue
		var band_start = band.get_map_start()
		var band_end = band.get_map_end()
		if Geometry2D.segment_intersects_segment(start, end, band_start, band_end) != null:
			return true
		if _segment_distance(start, end, band_start, band_end) < ISOLATION_BAND_WIDTH * 0.5:
			return true
	return false


func _segment_distance(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> float:
	var p1 = Geometry2D.get_closest_point_to_segment(a1, b1, b2)
	var p2 = Geometry2D.get_closest_point_to_segment(a2, b1, b2)
	var p3 = Geometry2D.get_closest_point_to_segment(b1, a1, a2)
	var p4 = Geometry2D.get_closest_point_to_segment(b2, a1, a2)
	return minf(minf(a1.distance_to(p1), a2.distance_to(p2)), minf(b1.distance_to(p3), b2.distance_to(p4)))


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


func _spawn_isolation_bands_async(large_rocks: Array[Node2D]) -> void:
	var target_count = randi_range(ISOLATION_BAND_MIN_COUNT, ISOLATION_BAND_MAX_COUNT)
	print("[隔离带] 目标生成数量: %d (范围 %d-%d)" % [target_count, ISOLATION_BAND_MIN_COUNT, ISOLATION_BAND_MAX_COUNT])
	var connected: Array[String] = []
	var bands_by_key: Dictionary = {}
	var removed_by_pathfinding: int = 0
	for i in range(target_count):
		if _is_room_setup_cancelled():
			return
		if large_rocks.size() < 2:
			return
		if _try_spawn_one_isolation_band(large_rocks, connected, bands_by_key):
			pass
		else:
			removed_by_pathfinding += 0
		var p := float(i + 1) / float(maxi(1, target_count))
		_set_loading_progress(lerpf(LOAD_STAGE_SMALL_ROCKS, LOAD_STAGE_ISOLATION_BANDS, p), "正在生成隔离带...")
		await get_tree().process_frame
	print("[隔离带] 实际生成数量: %d, 因寻路验证删除: %d" % [connected.size(), removed_by_pathfinding])


func _try_spawn_one_isolation_band(large_rocks: Array[Node2D], connected: Array[String], bands_by_key: Dictionary) -> bool:
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
		return false
	var b_index = candidates.pick_random()
	var key = _band_key(a_index, b_index)
	if connected.has(key):
		return false
	var b = large_rocks[b_index]
	if _is_band_blocked(a, b, large_rocks):
		return false
	var start = a.get_base_position()
	var end = b.get_base_position()
	_destroy_small_space_rocks_on_band_path(start, end)
	var band = _create_isolation_band(start, end)
	var band_w: float = band.get_collision_width() if band.has_method("get_collision_width") else ISOLATION_BAND_WIDTH
	if not _can_traverse_between_band_sides(start, end, band_w):
		band.queue_free()
		return false
	connected.append(key)
	bands_by_key[key] = band
	_sync_connected_sway_component(a_index, large_rocks, connected, bands_by_key)
	return true


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


func _spawn_evacuation_point() -> void:
	for child in evacuation_points.get_children():
		child.queue_free()
	for _i in range(EVACUATION_MAX_ATTEMPTS):
		var pos = Vector2(
			randf_range(PLAYER_SPAWN_MARGIN, ROOM_SIZE.x - PLAYER_SPAWN_MARGIN),
			randf_range(PLAYER_SPAWN_MARGIN, ROOM_SIZE.y - PLAYER_SPAWN_MARGIN)
		)
		if not _is_evacuation_position_valid(pos):
			continue
		var point = EVACUATION_POINT_SCENE.instantiate()
		point.global_position = pos
		point.evacuation_completed.connect(_on_evacuation_completed)
		evacuation_points.add_child(point)
		print("[撤离点] 生成于 %s，距离出生点 %.1f" % [pos, pos.distance_to(player.global_position)])
		return
	var fallback_dir = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	var fallback = (player.global_position + fallback_dir * EVACUATION_MIN_DISTANCE_FROM_SPAWN).clamp(Vector2(PLAYER_SPAWN_MARGIN, PLAYER_SPAWN_MARGIN), ROOM_SIZE - Vector2(PLAYER_SPAWN_MARGIN, PLAYER_SPAWN_MARGIN))
	var fallback_point = EVACUATION_POINT_SCENE.instantiate()
	fallback_point.global_position = fallback
	fallback_point.evacuation_completed.connect(_on_evacuation_completed)
	evacuation_points.add_child(fallback_point)
	print("[撤离点] 使用备用位置 %s" % fallback)


func _is_evacuation_position_valid(pos: Vector2) -> bool:
	if pos.distance_to(player.global_position) < EVACUATION_MIN_DISTANCE_FROM_SPAWN:
		return false
	if _is_position_near_isolation_band(pos, EVACUATION_ROCK_CLEARANCE):
		return false
	if _is_position_inside_large_rock(pos, _large_rocks):
		return false
	return true


func _on_evacuation_completed() -> void:
	_show_evacuation_success()


func _show_evacuation_success() -> void:
	get_tree().paused = true
	var hud = EVACUATION_SUCCESS_HUD_SCENE.instantiate()
	hud.evacuate_pressed.connect(_on_evacuation_button_pressed)
	ui_layer.add_child(hud)


func _generate_patrol_paths_async() -> void:
	_clear_patrol_paths()
	_patrol_path_points.clear()
	_patrol_path_families.clear()
	_static_enemy_map_icons.clear()
	if map_ui and map_ui.has_method("set_static_enemy_icons"):
		map_ui.set_static_enemy_icons(_static_enemy_map_icons)
	var reward_candidates = _get_patrol_reward_candidates()
	if reward_candidates.is_empty():
		print("[巡逻路径] 未找到宝箱或矿脉，跳过生成")
		if map_ui and map_ui.has_method("set_patrol_paths"):
			map_ui.set_patrol_paths(_patrol_path_points)
		return
	GameManager.stutter_context = "ExploreRoom.patrol_paths:grid"
	var grid = await _build_patrol_path_grid_async()
	if _is_room_setup_cancelled():
		return
	var target_count = randi_range(patrol_path_min_count, maxi(patrol_path_min_count, patrol_path_max_count))
	var generated_count = 0
	for path_index in range(target_count):
		if _is_room_setup_cancelled():
			return
		GameManager.stutter_context = "ExploreRoom.patrol_paths:path_%d" % path_index
		var points = PackedVector2Array()
		var shuffled_rewards = reward_candidates.duplicate()
		shuffled_rewards.shuffle()
		for reward in shuffled_rewards:
			points = _try_build_patrol_path(grid, reward)
			if points.size() >= 2:
				break
			if GameManager.should_defer_work("ExploreRoom.patrol_paths.reward_attempt"):
				await get_tree().process_frame
				if _is_room_setup_cancelled():
					return
		if points.size() < 2:
			print("[巡逻路径] 生成失败")
			_set_loading_progress(lerpf(LOAD_STAGE_SPAWN_POINTS, LOAD_STAGE_PATROL_PATHS, float(path_index + 1) / float(maxi(1, target_count))), "正在生成巡逻路径...")
			await get_tree().process_frame
			if _is_room_setup_cancelled():
				return
			continue
		var family = _pick_patrol_enemy_family()
		points = _adjust_patrol_path_for_enemy_spawn(points)
		if SHOW_PATROL_PATH_DEBUG_LINES:
			_draw_patrol_path(points)
		_patrol_path_points.append(points)
		_patrol_path_families.append(family)
		generated_count += 1
		_set_loading_progress(lerpf(LOAD_STAGE_SPAWN_POINTS, LOAD_STAGE_PATROL_PATHS, float(path_index + 1) / float(maxi(1, target_count))), "正在生成巡逻路径...")
		await get_tree().process_frame
		if _is_room_setup_cancelled():
			return
		print("[巡逻路径] 已生成，家族: %s, 路径点数量: %d" % [family, points.size()])
	print("[巡逻路径] 目标生成数量: %d, 实际生成数量: %d" % [target_count, generated_count])
	_queue_patrol_enemy_pool_prewarm()
	_enemy_spawn_timer = enemy_spawn_interval
	if map_ui and map_ui.has_method("set_patrol_paths"):
		map_ui.set_patrol_paths(_patrol_path_points)


func _generate_patrol_paths() -> void:
	_generate_patrol_paths_async()


func _clear_patrol_paths() -> void:
	_pending_patrol_enemy_spawns.clear()
	if not is_instance_valid(_patrol_paths):
		_patrol_paths = Node2D.new()
		_patrol_paths.name = "PatrolPaths"
		add_child(_patrol_paths)
	for child in _patrol_paths.get_children():
		child.queue_free()


func _clear_patrol_runtime() -> void:
	_pending_patrol_enemy_spawns.clear()
	_patrol_enemy_pool_prewarm_queue.clear()
	_patrol_path_points.clear()
	_patrol_path_families.clear()
	_static_enemy_map_icons.clear()
	for pool_key in _patrol_enemy_pool.keys():
		var pool: Array = _patrol_enemy_pool.get(pool_key, [])
		for enemy in pool:
			if is_instance_valid(enemy):
				enemy.queue_free()
	_patrol_enemy_pool.clear()
	if is_instance_valid(_enemies):
		for enemy in _enemies.get_children():
			if is_instance_valid(enemy):
				enemy.queue_free()
		_enemies.queue_free()
	_enemies = null
	_patrol_enemy_pool_container = null
	if is_instance_valid(_patrol_paths):
		for child in _patrol_paths.get_children():
			if is_instance_valid(child):
				child.queue_free()
		_patrol_paths.queue_free()
	_patrol_paths = null


func _ensure_enemy_container() -> void:
	if is_instance_valid(_enemies):
		if not is_instance_valid(_patrol_enemy_pool_container):
			_ensure_patrol_enemy_pool_container()
		return
	_enemies = Node2D.new()
	_enemies.name = "ExploreEnemies"
	add_child(_enemies)
	_ensure_patrol_enemy_pool_container()


func _ensure_patrol_enemy_pool_container() -> void:
	if is_instance_valid(_patrol_enemy_pool_container):
		return
	_patrol_enemy_pool_container = Node2D.new()
	_patrol_enemy_pool_container.name = "PatrolEnemyPool"
	_enemies.add_child(_patrol_enemy_pool_container)


func _pick_patrol_enemy_family() -> String:
	var entries = [
		{"family": "colossus", "weight": colossus_family_weight},
		{"family": "paradise", "weight": paradise_family_weight},
		{"family": "warped", "weight": warped_family_weight},
		{"family": "hell_eye", "weight": hell_eye_family_weight},
		{"family": "divine", "weight": divine_family_weight},
	]
	var total_weight = 0.0
	for entry in entries:
		total_weight += maxf(0.0, float(entry.weight))
	if total_weight <= 0.0:
		return "paradise"
	var roll = randf() * total_weight
	var accumulated = 0.0
	for entry in entries:
		accumulated += maxf(0.0, float(entry.weight))
		if roll <= accumulated:
			return String(entry.family)
	return "paradise"


func _get_elite_behaviors_for_family(family: String) -> Array[int]:
	if family == "colossus":
		return [3, 4]
	if family == "paradise":
		return [8, 9]
	if family == "warped":
		return [13, 14]
	if family == "hell_eye":
		return [18, 19]
	if family == "divine":
		return [23, 24]
	return [8, 9]


func _spawn_elite_chest_replacement_enemies() -> void:
	var chests: Array[Node2D] = []
	for reward in rewards.get_children():
		if not is_instance_valid(reward):
			continue
		var reward_type = reward.get_reward_type() if reward.has_method("get_reward_type") else 0
		if int(reward_type) == 0:
			chests.append(reward)
	if chests.is_empty():
		return
	chests.shuffle()
	_ensure_enemy_container()
	var target_count = mini(randi_range(elite_replacement_min_count, maxi(elite_replacement_min_count, elite_replacement_max_count)), chests.size())
	var spawned_count = 0
	for i in range(target_count):
		var chest = chests[i]
		if not is_instance_valid(chest):
			continue
		var spawn_pos = chest.get_base_position() if chest.has_method("get_base_position") else chest.global_position
		var family = _pick_patrol_enemy_family()
		var behaviors = _get_elite_behaviors_for_family(family)
		var behavior = behaviors.pick_random()
		var tex = DesignedEnemyScript.poll_behavior_texture(behavior)
		var enemy = DESIGNED_ENEMY_SCENE.instantiate()
		enemy.behavior = behavior
		enemy.global_position = spawn_pos
		if enemy.has_method("setup_explore_room_idle"):
			enemy.setup_explore_room_idle(Rect2(Vector2.ZERO, ROOM_SIZE))
		_enemies.add_child(enemy)
		_static_enemy_map_icons.append({
			"position": spawn_pos,
			"texture": tex,
			"family": family,
			"behavior": behavior,
		})
		chest.queue_free()
		spawned_count += 1
	if map_ui and map_ui.has_method("set_static_enemy_icons"):
		map_ui.set_static_enemy_icons(_static_enemy_map_icons)
	print("[宝箱替换敌人] 已生成数量: %d" % spawned_count)


func _update_static_enemy_icon_textures(delta: float) -> void:
	if _static_enemy_map_icons.is_empty():
		return
	_static_enemy_icon_texture_poll_timer -= delta
	if _static_enemy_icon_texture_poll_timer > 0.0:
		return
	_static_enemy_icon_texture_poll_timer = 0.25
	var changed := false
	for icon in _static_enemy_map_icons:
		if icon.get("texture") != null:
			continue
		var behavior := int(icon.get("behavior", -1))
		var tex := DesignedEnemyScript.poll_behavior_texture(behavior)
		if tex:
			icon["texture"] = tex
			changed = true
	if changed and map_ui and map_ui.has_method("set_static_enemy_icons"):
		map_ui.set_static_enemy_icons(_static_enemy_map_icons)


func _adjust_patrol_path_for_enemy_spawn(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() < 2:
		return points
	points[0] = _move_point_near_room_edge(points[0])
	points[points.size() - 1] = _move_point_near_room_edge(points[points.size() - 1])
	return points


func _move_point_near_room_edge(pos: Vector2) -> Vector2:
	if pos.x < 0.0:
		pos.x = -PATROL_ENEMY_OUTSIDE_MARGIN
	elif pos.x > ROOM_SIZE.x:
		pos.x = ROOM_SIZE.x + PATROL_ENEMY_OUTSIDE_MARGIN
	elif pos.y < 0.0:
		pos.y = -PATROL_ENEMY_OUTSIDE_MARGIN
	elif pos.y > ROOM_SIZE.y:
		pos.y = ROOM_SIZE.y + PATROL_ENEMY_OUTSIDE_MARGIN
	return pos


func _get_patrol_reward_candidates() -> Array[Node2D]:
	var chests: Array[Node2D] = []
	var ores: Array[Node2D] = []
	for reward in rewards.get_children():
		if not is_instance_valid(reward):
			continue
		var reward_type = reward.get_reward_type() if reward.has_method("get_reward_type") else 0
		if reward_type == 0:
			chests.append(reward)
		else:
			ores.append(reward)
	if not chests.is_empty():
		return chests
	return ores


func _try_build_patrol_path(grid: AStarGrid2D, reward: Node2D) -> PackedVector2Array:
	var reward_pos = reward.get_base_position() if reward.has_method("get_base_position") else reward.global_position
	for _attempt in range(PATROL_PATH_MAX_ATTEMPTS):
		var start = _random_patrol_edge_point()
		var end = _random_patrol_edge_point()
		var via = _pick_patrol_via_point(reward_pos)
		if start == Vector2.INF or end == Vector2.INF or via == Vector2.INF:
			continue
		var start_entry = _nearest_patrol_walkable_position(grid, _clamp_patrol_point_to_room(start))
		var end_entry = _nearest_patrol_walkable_position(grid, _clamp_patrol_point_to_room(end))
		via = _nearest_patrol_walkable_position(grid, via)
		if start_entry == Vector2.INF or end_entry == Vector2.INF or via == Vector2.INF:
			continue
		var first_leg = _find_patrol_path_segment(grid, start_entry, via)
		if first_leg.is_empty():
			continue
		first_leg.insert(0, start)
		var second_leg = _find_patrol_path_segment(grid, via, end_entry)
		if second_leg.is_empty():
			continue
		second_leg.append(end)
		first_leg.append_array(second_leg.slice(1))
		var simplified = _simplify_patrol_path(first_leg, PATROL_PATH_SIMPLIFY_EPSILON)
		var smoothed = _cap_patrol_path_points(_smooth_patrol_path(simplified), PATROL_PATH_MAX_POINTS)
		if _is_patrol_path_clear(simplified):
			return smoothed
		if _is_patrol_path_clear(first_leg):
			return _cap_patrol_path_points(first_leg, PATROL_PATH_MAX_POINTS)
	return PackedVector2Array()


func _random_patrol_edge_point() -> Vector2:
	for _attempt in range(PATROL_PATH_MAX_ATTEMPTS):
		var edge = randi_range(0, 3)
		var pos = Vector2.ZERO
		if edge == 0:
			pos = Vector2(randf_range(PATROL_PATH_EDGE_MARGIN, ROOM_SIZE.x - PATROL_PATH_EDGE_MARGIN), -PATROL_PATH_OUTSIDE_MARGIN)
		elif edge == 1:
			pos = Vector2(ROOM_SIZE.x + PATROL_PATH_OUTSIDE_MARGIN, randf_range(PATROL_PATH_EDGE_MARGIN, ROOM_SIZE.y - PATROL_PATH_EDGE_MARGIN))
		elif edge == 2:
			pos = Vector2(randf_range(PATROL_PATH_EDGE_MARGIN, ROOM_SIZE.x - PATROL_PATH_EDGE_MARGIN), ROOM_SIZE.y + PATROL_PATH_OUTSIDE_MARGIN)
		else:
			pos = Vector2(-PATROL_PATH_OUTSIDE_MARGIN, randf_range(PATROL_PATH_EDGE_MARGIN, ROOM_SIZE.y - PATROL_PATH_EDGE_MARGIN))
		return pos
	return Vector2.INF


func _clamp_patrol_point_to_room(pos: Vector2) -> Vector2:
	return pos.clamp(
		Vector2(PATROL_PATH_EDGE_MARGIN, PATROL_PATH_EDGE_MARGIN),
		ROOM_SIZE - Vector2(PATROL_PATH_EDGE_MARGIN, PATROL_PATH_EDGE_MARGIN)
	)


func _pick_patrol_via_point(reward_pos: Vector2) -> Vector2:
	for _attempt in range(PATROL_PATH_MAX_ATTEMPTS):
		var offset = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(PATROL_PATH_POINT_OFFSET, PATROL_PATH_POINT_OFFSET * 2.2)
		var pos = (reward_pos + offset).clamp(Vector2(PATROL_PATH_EDGE_MARGIN, PATROL_PATH_EDGE_MARGIN), ROOM_SIZE - Vector2(PATROL_PATH_EDGE_MARGIN, PATROL_PATH_EDGE_MARGIN))
		if pos.distance_to(reward_pos) < PATROL_PATH_POINT_OFFSET:
			continue
		if not _is_patrol_path_point_blocked(pos):
			return pos
	return Vector2.INF


func _build_patrol_path_grid() -> AStarGrid2D:
	var grid = AStarGrid2D.new()
	var grid_size = Vector2i(int(ceil(ROOM_SIZE.x / PATROL_PATH_GRID_SIZE)), int(ceil(ROOM_SIZE.y / PATROL_PATH_GRID_SIZE)))
	grid.region = Rect2i(Vector2i.ZERO, grid_size)
	grid.cell_size = Vector2(PATROL_PATH_GRID_SIZE, PATROL_PATH_GRID_SIZE)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var id = Vector2i(x, y)
			grid.set_point_solid(id, _is_patrol_path_point_blocked(_patrol_grid_to_world(id)))
	return grid


func _build_patrol_path_grid_async() -> AStarGrid2D:
	var grid = AStarGrid2D.new()
	var grid_size = Vector2i(int(ceil(ROOM_SIZE.x / PATROL_PATH_GRID_SIZE)), int(ceil(ROOM_SIZE.y / PATROL_PATH_GRID_SIZE)))
	grid.region = Rect2i(Vector2i.ZERO, grid_size)
	grid.cell_size = Vector2(PATROL_PATH_GRID_SIZE, PATROL_PATH_GRID_SIZE)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for x in range(grid_size.x):
		if _is_room_setup_cancelled():
			return grid
		GameManager.stutter_context = "ExploreRoom.patrol_paths:grid_col_%d" % x
		for y in range(grid_size.y):
			var id = Vector2i(x, y)
			grid.set_point_solid(id, _is_patrol_path_point_blocked(_patrol_grid_to_world(id)))
		if x % PATROL_PATH_GRID_ROWS_PER_FRAME == PATROL_PATH_GRID_ROWS_PER_FRAME - 1:
			_set_loading_progress(lerpf(LOAD_STAGE_SPAWN_POINTS, LOAD_STAGE_PATROL_PATHS, float(x + 1) / float(maxi(1, grid_size.x))), "正在生成巡逻路径...")
			await get_tree().process_frame
			if _is_room_setup_cancelled():
				return grid
	return grid


func _find_patrol_path_segment(grid: AStarGrid2D, from_pos: Vector2, to_pos: Vector2) -> PackedVector2Array:
	var from_id = _patrol_world_to_grid(from_pos)
	var to_id = _patrol_world_to_grid(to_pos)
	if grid.is_point_solid(from_id) or grid.is_point_solid(to_id):
		return PackedVector2Array()
	var ids = grid.get_id_path(from_id, to_id)
	if ids.is_empty():
		return PackedVector2Array()
	var points = PackedVector2Array()
	points.append(from_pos)
	for i in range(1, ids.size() - 1):
		points.append(_patrol_grid_to_world(ids[i]))
	points.append(to_pos)
	return points


func _nearest_patrol_walkable_position(grid: AStarGrid2D, pos: Vector2) -> Vector2:
	var center_id = _patrol_world_to_grid(pos)
	if not grid.is_point_solid(center_id):
		return pos
	for radius in range(1, 6):
		for x in range(center_id.x - radius, center_id.x + radius + 1):
			for y in range(center_id.y - radius, center_id.y + radius + 1):
				if abs(x - center_id.x) != radius and abs(y - center_id.y) != radius:
					continue
				var id = Vector2i(x, y)
				if not grid.region.has_point(id):
					continue
				if not grid.is_point_solid(id):
					return _patrol_grid_to_world(id)
	return Vector2.INF


func _patrol_world_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(
		clamp(int(pos.x / PATROL_PATH_GRID_SIZE), 0, int(ceil(ROOM_SIZE.x / PATROL_PATH_GRID_SIZE)) - 1),
		clamp(int(pos.y / PATROL_PATH_GRID_SIZE), 0, int(ceil(ROOM_SIZE.y / PATROL_PATH_GRID_SIZE)) - 1)
	)


func _patrol_grid_to_world(id: Vector2i) -> Vector2:
	return Vector2(
		clampf((float(id.x) + 0.5) * PATROL_PATH_GRID_SIZE, PATROL_PATH_EDGE_MARGIN, ROOM_SIZE.x - PATROL_PATH_EDGE_MARGIN),
		clampf((float(id.y) + 0.5) * PATROL_PATH_GRID_SIZE, PATROL_PATH_EDGE_MARGIN, ROOM_SIZE.y - PATROL_PATH_EDGE_MARGIN)
	)


func _is_patrol_path_point_blocked(pos: Vector2) -> bool:
	if pos.x < PATROL_PATH_EDGE_MARGIN or pos.y < PATROL_PATH_EDGE_MARGIN or pos.x > ROOM_SIZE.x - PATROL_PATH_EDGE_MARGIN or pos.y > ROOM_SIZE.y - PATROL_PATH_EDGE_MARGIN:
		return true
	if pos.distance_to(player.global_position) < PATROL_PATH_CLEARANCE * 1.5:
		return true
	for point in evacuation_points.get_children():
		if is_instance_valid(point) and pos.distance_to(point.global_position) < PATROL_PATH_CLEARANCE * 1.5:
			return true
	for rock in _large_rocks:
		if not is_instance_valid(rock):
			continue
		if rock.has_method("get_push_out_position"):
			var pushed = rock.get_push_out_position(pos, PATROL_PATH_CLEARANCE)
			if pushed.distance_to(pos) > 0.1:
				return true
		else:
			var radius: float = rock.get("radius") if rock.get("radius") != null else SPACE_ROCK_BASE_RADIUS
			if pos.distance_to(rock.global_position) < radius + PATROL_PATH_CLEARANCE:
				return true
	for debris in clutter.get_children():
		if is_instance_valid(debris) and debris.has_method("get_push_out_position"):
			var pushed_debris = debris.get_push_out_position(pos, PATROL_PATH_CLEARANCE)
			if pushed_debris.distance_to(pos) > 0.1:
				return true
	if _is_position_near_isolation_band(pos, PATROL_PATH_CLEARANCE):
		return true
	return false


func _is_patrol_path_clear(points: PackedVector2Array) -> bool:
	if points.size() < 2:
		return false
	for i in range(points.size() - 1):
		var start = points[i]
		var end = points[i + 1]
		var distance = start.distance_to(end)
		var steps = maxi(1, int(ceil(distance / (PATROL_PATH_GRID_SIZE * 0.35))))
		for step in range(steps + 1):
			var pos = start.lerp(end, float(step) / float(steps))
			if _is_patrol_path_clear_sample_blocked(pos):
				return false
	return true


func _is_patrol_path_clear_sample_blocked(pos: Vector2) -> bool:
	if pos.x < PATROL_PATH_EDGE_MARGIN or pos.y < PATROL_PATH_EDGE_MARGIN or pos.x > ROOM_SIZE.x - PATROL_PATH_EDGE_MARGIN or pos.y > ROOM_SIZE.y - PATROL_PATH_EDGE_MARGIN:
		return false
	return _is_patrol_path_point_blocked(pos)


func _smooth_patrol_path(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() <= 2:
		return points
	var smoothed = PackedVector2Array()
	smoothed.append(points[0])
	for i in range(1, points.size() - 1):
		var previous = points[i - 1]
		var current = points[i]
		var next = points[i + 1]
		var in_dir = (previous - current).normalized()
		var out_dir = (next - current).normalized()
		if in_dir == Vector2.ZERO or out_dir == Vector2.ZERO:
			smoothed.append(current)
			continue
		var corner_radius = minf(80.0, minf(current.distance_to(previous) * 0.35, current.distance_to(next) * 0.35))
		smoothed.append(current + in_dir * corner_radius)
		for step in range(1, 5):
			var t = float(step) / 5.0
			smoothed.append(_quadratic_bezier(current + in_dir * corner_radius, current, current + out_dir * corner_radius, t))
		smoothed.append(current + out_dir * corner_radius)
	smoothed.append(points[points.size() - 1])
	return smoothed


func _simplify_patrol_path(points: PackedVector2Array, epsilon: float) -> PackedVector2Array:
	if points.size() <= 2:
		return points
	var keep: Dictionary = {
		0: true,
		points.size() - 1: true,
	}
	_simplify_patrol_path_range(points, 0, points.size() - 1, epsilon, keep)
	var simplified = PackedVector2Array()
	for i in range(points.size()):
		if keep.has(i):
			simplified.append(points[i])
	return simplified


func _simplify_patrol_path_range(points: PackedVector2Array, start_index: int, end_index: int, epsilon: float, keep: Dictionary) -> void:
	if end_index - start_index <= 1:
		return
	var start = points[start_index]
	var end = points[end_index]
	var max_distance = 0.0
	var max_index = -1
	for i in range(start_index + 1, end_index):
		var closest = Geometry2D.get_closest_point_to_segment(points[i], start, end)
		var distance = points[i].distance_to(closest)
		if distance > max_distance:
			max_distance = distance
			max_index = i
	if max_index < 0 or max_distance <= epsilon:
		return
	keep[max_index] = true
	_simplify_patrol_path_range(points, start_index, max_index, epsilon, keep)
	_simplify_patrol_path_range(points, max_index, end_index, epsilon, keep)


func _cap_patrol_path_points(points: PackedVector2Array, max_points: int) -> PackedVector2Array:
	if points.size() <= max_points or max_points < 2:
		return points
	var capped := PackedVector2Array()
	for i in range(max_points):
		var source_index := int(round(float(i) * float(points.size() - 1) / float(max_points - 1)))
		capped.append(points[source_index])
	return capped


func _quadratic_bezier(start: Vector2, control: Vector2, end: Vector2, t: float) -> Vector2:
	return start.lerp(control, t).lerp(control.lerp(end, t), t)


func _draw_patrol_path(points: PackedVector2Array) -> void:
	var line = Line2D.new()
	line.name = "PatrolPathDebug"
	line.width = PATROL_PATH_LINE_WIDTH
	line.default_color = PATROL_PATH_LINE_COLOR
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	line.points = points
	_patrol_paths.add_child(line)


func _update_patrol_enemy_spawning(delta: float) -> void:
	if _patrol_path_points.is_empty() or enemy_spawn_interval <= 0.0:
		return
	if _get_explore_room_enemy_count() >= max_patrol_enemy_count:
		_pending_patrol_enemy_spawns.clear()
		_enemy_spawn_timer = maxf(_enemy_spawn_timer, enemy_spawn_interval)
		return
	_enemy_spawn_timer -= delta
	if _enemy_spawn_timer > 0.0:
		return
	_enemy_spawn_timer = enemy_spawn_interval
	for i in range(_patrol_path_points.size()):
		var family = _patrol_path_families[i] if i < _patrol_path_families.size() else _pick_patrol_enemy_family()
		_queue_patrol_enemy_wave(_patrol_path_points[i], family)


func _queue_patrol_enemy_wave(path_points: PackedVector2Array, family: String) -> void:
	if path_points.size() < 2:
		return
	_ensure_enemy_container()
	var count = randi_range(PATROL_ENEMY_MIN_GROUP_COUNT, PATROL_ENEMY_MAX_GROUP_COUNT)
	var available_slots = mini(
		max_patrol_enemy_count - _get_explore_room_enemy_count() - _pending_patrol_enemy_spawns.size(),
		PATROL_ENEMY_MAX_QUEUED_SPAWNS - _pending_patrol_enemy_spawns.size()
	)
	if available_slots <= 0:
		return
	count = mini(count, available_slots)
	var behaviors = _get_patrol_enemy_behaviors_for_family(family)
	var shared_path_points = path_points.duplicate()
	var start = path_points[0]
	var next = path_points[1]
	var direction = (next - start).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	var side = Vector2(-direction.y, direction.x)
	var placed: Array[Vector2] = []
	var queued_count = 0
	for i in range(count):
		var behavior = behaviors.pick_random()
		var offset = side * (float(i) - float(count - 1) * 0.5) * PATROL_ENEMY_SPAWN_SPACING
		offset += direction.rotated(randf_range(-0.35, 0.35)) * randf_range(-36.0, 36.0)
		var spawn_pos = start + offset
		for placed_pos in placed:
			if spawn_pos.distance_to(placed_pos) < PATROL_ENEMY_SPAWN_SPACING:
				spawn_pos += side * PATROL_ENEMY_SPAWN_SPACING
		_pending_patrol_enemy_spawns.append({
			"behavior": behavior,
			"spawn_pos": spawn_pos,
			"path_points": shared_path_points,
			"path_offset": Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(0.0, PATROL_ENEMY_PATH_OFFSET),
		})
		placed.append(spawn_pos)
		queued_count += 1
	print("[巡逻敌人] 家族: %s, 本波排队数量: %d" % [family, queued_count])


func _process_pending_patrol_enemy_spawns() -> void:
	if _pending_patrol_enemy_spawns.is_empty():
		return
	_ensure_enemy_container()
	var spawned_this_frame = 0
	while spawned_this_frame < PATROL_ENEMY_SPAWNS_PER_FRAME and not _pending_patrol_enemy_spawns.is_empty():
		if _get_explore_room_enemy_count() >= max_patrol_enemy_count:
			_pending_patrol_enemy_spawns.clear()
			return
		var next_behavior := int(_pending_patrol_enemy_spawns[0].get("behavior", 5))
		if _get_patrol_enemy_pool_for_behavior(next_behavior).is_empty():
			_request_patrol_enemy_pool_fill(next_behavior, 1)
			return
		var spawn_data: Dictionary = _pending_patrol_enemy_spawns.pop_front()
		_spawn_pooled_patrol_enemy(spawn_data)
		spawned_this_frame += 1


func _get_patrol_enemy_count() -> int:
	if not is_instance_valid(_enemies):
		return 0
	var count = 0
	for enemy in _enemies.get_children():
		if enemy == _patrol_enemy_pool_container:
			continue
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			count += 1
	return count


func _get_explore_room_enemy_count() -> int:
	return _get_patrol_enemy_count()


func _spawn_pooled_patrol_enemy(spawn_data: Dictionary) -> void:
	var behavior := int(spawn_data.get("behavior", 5))
	var spawn_pos := spawn_data.get("spawn_pos", Vector2.ZERO) as Vector2
	var enemy := _acquire_pooled_patrol_enemy(behavior)
	enemy.global_position = spawn_pos
	if enemy.get_parent() != _enemies:
		if enemy.get_parent():
			enemy.get_parent().remove_child(enemy)
		_enemies.add_child(enemy)
	if enemy.has_method("reset_explore_pooled_patrol_enemy"):
		enemy.reset_explore_pooled_patrol_enemy(
			behavior,
			spawn_data.get("path_points", PackedVector2Array()),
			spawn_data.get("path_offset", Vector2.ZERO),
			Rect2(Vector2.ZERO, ROOM_SIZE),
			PATROL_ENEMY_DESPAWN_MARGIN,
			spawn_pos
		)
	elif enemy.has_method("setup_explore_patrol"):
		enemy.behavior = behavior
		enemy.setup_explore_patrol(
			spawn_data.get("path_points", PackedVector2Array()),
			spawn_data.get("path_offset", Vector2.ZERO),
			Rect2(Vector2.ZERO, ROOM_SIZE),
			PATROL_ENEMY_DESPAWN_MARGIN,
			spawn_pos
		)


func _acquire_pooled_patrol_enemy(behavior: int) -> Node2D:
	_ensure_enemy_container()
	var pool := _get_patrol_enemy_pool_for_behavior(behavior)
	while not pool.is_empty():
		var enemy := pool.pop_back() as Node2D
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			_patrol_enemy_pool[behavior] = pool
			return enemy
	var enemy := DESIGNED_ENEMY_SCENE.instantiate() as Node2D
	enemy.set(&"behavior", behavior)
	if enemy.has_method("setup_explore_pool"):
		enemy.setup_explore_pool(self, behavior)
	return enemy


func release_pooled_patrol_enemy(enemy: Node2D, behavior: int) -> void:
	if not is_instance_valid(enemy):
		return
	_ensure_enemy_container()
	_ensure_patrol_enemy_pool_container()
	var pool := _get_patrol_enemy_pool_for_behavior(behavior)
	if pool.has(enemy):
		return
	if pool.size() >= PATROL_ENEMY_POOL_MAX_PER_BEHAVIOR:
		enemy.queue_free()
		return
	if enemy.get_parent() != _patrol_enemy_pool_container:
		if enemy.get_parent():
			enemy.get_parent().remove_child(enemy)
		_patrol_enemy_pool_container.add_child(enemy)
	pool.append(enemy)
	_patrol_enemy_pool[behavior] = pool


func _get_patrol_enemy_pool_for_behavior(behavior: int) -> Array:
	if not _patrol_enemy_pool.has(behavior):
		_patrol_enemy_pool[behavior] = []
	return _patrol_enemy_pool[behavior] as Array


func _queue_patrol_enemy_pool_prewarm() -> void:
	_ensure_enemy_container()
	_patrol_enemy_pool_prewarm_queue.clear()
	for family in _patrol_path_families:
		for behavior in _get_patrol_enemy_behaviors_for_family(family):
			_request_patrol_enemy_pool_fill(behavior, 1)


func _request_patrol_enemy_pool_fill(behavior: int, target_count: int) -> void:
	var pool := _get_patrol_enemy_pool_for_behavior(behavior)
	var queued := 0
	for queued_behavior in _patrol_enemy_pool_prewarm_queue:
		if queued_behavior == behavior:
			queued += 1
	var needed := maxi(0, target_count - pool.size() - queued)
	for _i in range(needed):
			_patrol_enemy_pool_prewarm_queue.append(behavior)


func _prewarm_patrol_enemy_pool_for_loading() -> void:
	var total := maxi(1, _patrol_enemy_pool_prewarm_queue.size())
	while not _patrol_enemy_pool_prewarm_queue.is_empty():
		if _is_room_setup_cancelled():
			return
		_process_patrol_enemy_pool_prewarm()
		var remaining := _patrol_enemy_pool_prewarm_queue.size()
		var progress := 1.0 - float(remaining) / float(total)
		_set_loading_progress(
			lerpf(LOAD_STAGE_PATROL_PATHS, LOAD_STAGE_PATROL_POOL, progress),
			"正在预热巡逻敌人池..."
		)
		await get_tree().process_frame
		if _is_room_setup_cancelled():
			return


func _process_patrol_enemy_pool_prewarm() -> void:
	if _patrol_enemy_pool_prewarm_queue.is_empty():
		return
	_ensure_enemy_container()
	var warmed := 0
	while warmed < 1 and not _patrol_enemy_pool_prewarm_queue.is_empty():
		if GameManager.should_defer_work("ExploreRoom.pool_prewarm"):
			return
		GameManager.stutter_context = "ExploreRoom.pool_prewarm:create"
		var behavior: int = int(_patrol_enemy_pool_prewarm_queue.pop_front())
		var pool := _get_patrol_enemy_pool_for_behavior(behavior)
		if pool.size() >= PATROL_ENEMY_POOL_PREWARM_PER_BEHAVIOR:
			continue
		_prewarm_one_patrol_enemy(behavior, pool)
		warmed += 1


func _prewarm_one_patrol_enemy(behavior: int, pool: Array) -> void:
	var enemy := DESIGNED_ENEMY_SCENE.instantiate() as Node2D
	enemy.set(&"behavior", behavior)
	if enemy.has_method("setup_explore_pool"):
		enemy.setup_explore_pool(self, behavior)
	_patrol_enemy_pool_container.add_child(enemy)
	enemy.remove_from_group(&"enemies")
	enemy.visible = false
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	enemy.set_process(false)
	enemy.set_physics_process(false)
	enemy.set(&"monitoring", false)
	enemy.set(&"monitorable", false)
	var shape_node := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node:
		shape_node.disabled = true
	pool.append(enemy)
	_patrol_enemy_pool[behavior] = pool


func _get_patrol_enemy_behaviors_for_family(family: String) -> Array[int]:
	if family == "colossus":
		return [0, 1, 2]
	if family == "paradise":
		return [5, 6, 7]
	if family == "warped":
		return [10, 11, 12]
	if family == "hell_eye":
		return [15, 16, 17]
	if family == "divine":
		return [20, 21, 22]
	return [5, 6, 7]


func _preload_patrol_enemy_textures() -> void:
	var behaviors: Array[int] = []
	for family in _patrol_path_families:
		for behavior in _get_patrol_enemy_behaviors_for_family(family):
			if not behaviors.has(behavior):
				behaviors.append(behavior)
	for family in ["colossus", "paradise", "warped", "hell_eye", "divine"]:
		for behavior in _get_elite_behaviors_for_family(family):
			if not behaviors.has(behavior):
				behaviors.append(behavior)
	DesignedEnemyScript.preload_behavior_textures(behaviors)


func _on_evacuation_button_pressed() -> void:
	get_tree().paused = false
	if RunManager.is_formal_run_active():
		RunManager.complete_explore_room_success()
		get_tree().change_scene_to_file("res://scenes/app/WorldMap.tscn")
		return
	GameManager.player_hp = GameManager.PLAYER_MAX_HP
	GameManager.elapsed = 0.0
	get_tree().change_scene_to_file("res://scenes/app/MainMenu.tscn")


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
	for debris in clutter.get_children():
		if is_instance_valid(debris) and debris.has_method("get_push_out_position"):
			var pushed = debris.get_push_out_position(pos, PLAYER_SPAWN_CLEARANCE)
			if pushed.distance_to(pos) > 0.1:
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
