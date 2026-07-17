extends Node

const ExploreRoom := preload("res://scripts/gameplay/explore/ExploreRoom.gd")


func _ready() -> void:
	var room := ExploreRoom.new()
	room.setup_room_config({
		"trap_count": 4,
		"enemy_spawn_interval": 30.0,
		"max_patrol_enemy_count": 8,
		"advanced_patrol_interval_mult": 0.9,
		"advanced_patrol_enemy_cap_bonus": 1,
		"advanced_trap_count_mult": 1.2,
		"advanced_crisis_enemy": {"mixed_family_wave_chance": 0.3},
	})
	var config: Dictionary = room.get_room_config()
	room.free()
	if float(config.get("enemy_spawn_interval", 0.0)) != 27.0:
		_fail("Crisis patrol interval modifier was not applied to ExploreRoom.")
		return
	if int(config.get("max_patrol_enemy_count", 0)) != 9:
		_fail("Crisis patrol cap modifier was not applied to ExploreRoom.")
		return
	if float(config.get("advanced_trap_count_mult", 0.0)) != 1.2:
		_fail("Crisis trap multiplier was not retained for room spawning.")
		return
	if float(config.get("advanced_mixed_family_wave_chance", 0.0)) != 0.3:
		_fail("Crisis mixed-family wave chance was not retained for patrol spawning.")
		return
	print("Advanced crisis explore config check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
