extends Node


const BULLET_SCENE := preload("res://scenes/entities/projectiles/bullet.tscn")
const PLAYER_SCENE := preload("res://scenes/entities/player/player.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_equip_all_boss_drops()

	var stats := RunManager.get_player_stats()
	_expect_int_gte(stats, "dash_chain", 1)
	_expect_float_gt(stats, "dash_shield_duration", 0.0)
	_expect_float_gt(stats, "dash_damage_mult", 1.0)
	_expect_float_gt(stats, "dash_aftershock_radius", 0.0)
	_expect_float_gt(stats, "dash_aftershock_damage_mult", 0.0)
	_expect_int_gte(stats, "bullet_chain", 1)
	_expect_float_gt(stats, "bullet_charge", 0.0)
	_expect_int_gte(stats, "bullet_split_count", 1)
	_expect_float_gt(stats, "bullet_split_spread_degrees", 0.0)
	_expect_float_gt(stats, "bullet_split_damage_mult", 0.0)
	_expect_float_gt(stats, "gravity_pull_strength", 0.0)
	_expect_float_gt(stats, "bullet_blackhole", 0.0)
	_expect_float_gt(stats, "bullet_mark_bonus", 0.0)
	_expect_float_gt(stats, "frenzy_gain_mult", 1.0)
	_expect_float_lt(stats, "frenzy_fire_rate_mult", 1.0)
	_expect_float_gt(stats, "frenzy_damage_mult", 1.0)
	_expect_float_lt(stats, "frenzy_damage_taken_mult", 1.0)
	_expect_int_gte(stats, "drone_slots", 1)
	if _failed:
		return
	_check_archetype_sync_stat_bonus()
	if _failed:
		return
	_equip_all_boss_drops()

	var player = PLAYER_SCENE.instantiate()
	player.bullet_scene = BULLET_SCENE
	player.movement_bounds = Rect2(Vector2.ZERO, Vector2(1920, 1080))
	player.global_position = Vector2(500, 500)
	add_child(player)

	if int(player.get("_run_dash_chain")) < 1:
		_fail("Player should apply colossus dash chain from boss drop.")
		return
	if float(player.get("_run_dash_damage_mult")) <= 1.0:
		_fail("Player should apply boss-drop dash damage multiplier.")
		return
	if float(player.get("_run_dash_aftershock_radius")) <= 0.0:
		_fail("Player should apply colossus dash aftershock radius.")
		return
	if int(player.get("_run_drone_slots")) < 1:
		_fail("Player should apply drone slots from divine boss drop.")
		return

	player._spawn_player_bullet(Vector2.RIGHT)
	await get_tree().process_frame
	var bullet := _find_player_bullet()
	if bullet == null:
		_fail("Player should spawn a test bullet.")
		return
	if int(bullet.get("chain_left")) <= 0:
		_fail("Paradise boss drop should give spawned bullets chain-bounce.")
		return
	if int(bullet.get("split_count")) <= 0:
		_fail("Paradise boss drop should give spawned bullets split coverage.")
		return
	if float(bullet.get("gravity_pull_strength")) <= 0.0:
		_fail("Warped boss drop should give spawned bullets gravity repulsion.")
		return
	if float(bullet.get("blackhole_strength")) <= 0.0:
		_fail("Warped boss drop should give spawned bullets blackhole pull.")
		return
	var normal_atk := int(bullet.get("atk"))
	bullet.queue_free()
	GameManager.frenzy_active = true
	GameManager.frenzy_timer = GameManager.FRENZY_DURATION
	GameManager.frenzy_value = GameManager.FRENZY_MAX
	player._spawn_player_bullet(Vector2.RIGHT)
	await get_tree().process_frame
	var frenzy_bullet := _find_player_bullet()
	if frenzy_bullet == null:
		_fail("Player should spawn a frenzy bullet.")
		return
	if int(frenzy_bullet.get("atk")) <= normal_atk:
		_fail("Hell-eye boss drop should increase spawned bullet damage during frenzy.")
		return

	var drone_count := get_tree().get_nodes_in_group(&"player_support_drones").size()
	if drone_count < 1:
		_fail("Divine boss drop should create at least one support drone.")
		return

	GameManager.reset_run_state()
	GameManager.add_frenzy(40.0)
	if GameManager.frenzy_value <= 40.0:
		_fail("Hell-eye boss drop should increase frenzy gain.")
		return

	print("Archetype effects check passed.")
	get_tree().quit(0)


func _equip_all_boss_drops() -> void:
	RunManager.start_new_run()
	RunManager.compute_capacity = 99
	RunManager.equipment_inventory = [
		"pulse_cannon",
		"colossus_impact_mirror",
		"colossus_aftershock_keel",
		"colossus_singularity_ram",
		"paradise_cover_matrix",
		"paradise_heavenfall_array",
		"paradise_sunburst_rack",
		"warped_gravity_lens",
		"warped_event_horizon_spool",
		"warped_gravity_well_core",
		"hell_eye_frenzy_iris",
		"divine_drone_seed",
	]
	RunManager.equipped_weapon = "pulse_cannon"
	RunManager.equipped_auxiliaries = [
		"colossus_impact_mirror",
		"colossus_aftershock_keel",
		"colossus_singularity_ram",
		"paradise_cover_matrix",
		"paradise_heavenfall_array",
		"paradise_sunburst_rack",
		"warped_gravity_lens",
		"warped_event_horizon_spool",
		"warped_gravity_well_core",
		"hell_eye_frenzy_iris",
		"divine_drone_seed",
	]


func _check_archetype_sync_stat_bonus() -> void:
	_check_colossus_sync_bonus()
	if _failed:
		return
	_check_paradise_sync_bonus()
	if _failed:
		return
	_check_warped_sync_bonus()
	if _failed:
		return
	_check_hell_eye_sync_bonus()
	if _failed:
		return
	_check_divine_sync_bonus()


func _check_colossus_sync_bonus() -> void:
	var mixed := _stats_for_aux(["colossus_impact_coil", "general_stability_chip"])
	var synced := _stats_for_aux(["colossus_impact_coil", "colossus_ramming_keel"])
	if float(synced.get("dash_distance_mult", 1.0)) <= float(mixed.get("dash_distance_mult", 1.0)):
		_fail("Colossus sync should further increase dash distance. mixed=%s synced=%s" % [str(mixed), str(synced)])
	if float(synced.get("dash_damage_mult", 1.0)) <= float(mixed.get("dash_damage_mult", 1.0)):
		_fail("Colossus sync should further increase dash damage. mixed=%s synced=%s" % [str(mixed), str(synced)])


func _check_paradise_sync_bonus() -> void:
	var mixed := _stats_for_aux(["paradise_splitter_board", "general_stability_chip"])
	var synced := _stats_for_aux(["paradise_splitter_board", "paradise_rapid_breech"])
	if float(synced.get("bullet_speed_mult", 1.0)) <= float(mixed.get("bullet_speed_mult", 1.0)):
		_fail("Paradise sync should increase bullet speed. mixed=%s synced=%s" % [str(mixed), str(synced)])
	if float(synced.get("fire_rate_mult", 1.0)) >= float(mixed.get("fire_rate_mult", 1.0)):
		_fail("Paradise sync should shorten fire interval. mixed=%s synced=%s" % [str(mixed), str(synced)])


func _check_warped_sync_bonus() -> void:
	var mixed := _stats_for_aux(["warped_seek_processor", "general_stability_chip"])
	var synced := _stats_for_aux(["warped_seek_processor", "warped_orbit_compass"])
	if float(synced.get("homing_strength", 0.0)) <= float(mixed.get("homing_strength", 0.0)):
		_fail("Warped sync should increase homing strength. mixed=%s synced=%s" % [str(mixed), str(synced)])
	if float(synced.get("gravity_pull_strength", 0.0)) <= float(mixed.get("gravity_pull_strength", 0.0)):
		_fail("Warped sync should add gravity pull. mixed=%s synced=%s" % [str(mixed), str(synced)])


func _check_hell_eye_sync_bonus() -> void:
	var mixed := _stats_for_aux(["hell_eye_heat_credit", "general_stability_chip"])
	var synced := _stats_for_aux(["hell_eye_heat_credit", "hell_eye_adrenal_pump"])
	if float(synced.get("frenzy_gain_mult", 1.0)) <= float(mixed.get("frenzy_gain_mult", 1.0)):
		_fail("Hell-eye sync should increase frenzy gain. mixed=%s synced=%s" % [str(mixed), str(synced)])
	if float(synced.get("frenzy_damage_mult", 1.0)) <= float(mixed.get("frenzy_damage_mult", 1.0)):
		_fail("Hell-eye sync should add frenzy damage. mixed=%s synced=%s" % [str(mixed), str(synced)])


func _check_divine_sync_bonus() -> void:
	var mixed := _stats_for_aux(["divine_wingman_bus", "general_stability_chip"])
	var synced := _stats_for_aux(["divine_wingman_bus", "divine_swarm_router"])
	if float(synced.get("drone_damage_mult", 1.0)) <= float(mixed.get("drone_damage_mult", 1.0)):
		_fail("Divine sync should strengthen drone damage. mixed=%s synced=%s" % [str(mixed), str(synced)])
	if float(synced.get("drone_fire_interval_mult", 1.0)) >= float(mixed.get("drone_fire_interval_mult", 1.0)):
		_fail("Divine sync should quicken drone fire. mixed=%s synced=%s" % [str(mixed), str(synced)])


func _stats_for_aux(aux_ids: Array[String]) -> Dictionary:
	RunManager.start_new_run()
	RunManager.compute_capacity = 99
	var inventory: Array[String] = ["pulse_cannon"]
	for aux_id in aux_ids:
		inventory.append(aux_id)
	RunManager.equipment_inventory = inventory
	RunManager.equipped_weapon = "pulse_cannon"
	RunManager.equipped_auxiliaries = aux_ids.duplicate()
	return RunManager.get_player_stats()


func _expect_float_gt(stats: Dictionary, key: String, minimum: float) -> void:
	if float(stats.get(key, 0.0)) <= minimum:
		_fail("Expected %s > %.2f, got %s." % [key, minimum, str(stats.get(key, null))])


func _expect_float_lt(stats: Dictionary, key: String, maximum: float) -> void:
	if float(stats.get(key, 1.0)) >= maximum:
		_fail("Expected %s < %.2f, got %s." % [key, maximum, str(stats.get(key, null))])


func _expect_int_gte(stats: Dictionary, key: String, minimum: int) -> void:
	if int(stats.get(key, 0)) < minimum:
		_fail("Expected %s >= %d, got %s." % [key, minimum, str(stats.get(key, null))])


func _find_player_bullet() -> Node:
	for node in get_tree().get_nodes_in_group(&"force_field_projectiles"):
		if is_instance_valid(node) and node.has_method("is_player_bullet") and bool(node.call("is_player_bullet")):
			return node
	return null


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
