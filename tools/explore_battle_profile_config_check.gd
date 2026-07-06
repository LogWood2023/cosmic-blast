extends Node


const ExploreRoomScript := preload("res://scripts/gameplay/explore/ExploreRoom.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_battle_profile_config_application()
	if _failed:
		return
	print("Explore battle profile config check passed.")
	get_tree().quit(0)


func _check_battle_profile_config_application() -> void:
	var room = ExploreRoomScript.new()
	room.setup_room_config({
		"large_space_rock_count": 9,
		"trap_count": 4,
		"chest_crystal_count": 12,
		"clutter_count": 30,
		"enemy_spawn_interval": 44.0,
		"max_patrol_enemy_count": 7,
		"battle_profile_id": "hunter_chain",
		"battle_trap_pressure": 12,
		"battle_enemy_spawn_interval": 18.0,
		"battle_max_patrol_enemy_count": 14,
	})
	var config: Dictionary = room.get_room_config()
	if int(config.get("large_space_rock_count", -1)) != 9:
		room.free()
		_fail("Battle profile should not overwrite intel large rock count.")
		return
	if int(config.get("chest_crystal_count", -1)) != 12:
		room.free()
		_fail("Battle profile should not overwrite intel reward count.")
		return
	if int(config.get("clutter_count", -1)) != 30:
		room.free()
		_fail("Battle profile should not overwrite intel clutter count.")
		return
	if int(config.get("trap_count", -1)) != 12:
		room.free()
		_fail("Battle trap pressure should raise trap_count, got %s." % str(config))
		return
	if float(config.get("enemy_spawn_interval", 0.0)) != 18.0:
		room.free()
		_fail("Battle profile should lower enemy spawn interval, got %s." % str(config))
		return
	if int(config.get("max_patrol_enemy_count", 0)) != 14:
		room.free()
		_fail("Battle profile should raise patrol enemy cap, got %s." % str(config))
		return
	room.free()


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
