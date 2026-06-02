extends Node
## Manages one formal roguelite run: world map, economy, equipment, and crisis bosses.

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")

const WORLD_MAP_SCENE: String = "res://scenes/app/WorldMap.tscn"
const EXPLORE_ROOM_SCENE: String = "res://scenes/gameplay/explore/ExploreRoom.tscn"
const GAME_OVER_SCENE: String = "res://scenes/app/gameover.tscn"

const NODE_BASE: String = "base"
const NODE_BATTLE: String = "battle"
const NODE_EVENT: String = "event"
const NODE_REWARD: String = "reward"

const CRISIS_THRESHOLDS: Array[int] = [5, 12, 21]
const CENTER_ID: int = 0
const MAP_CENTER: Vector2 = Vector2(700.0, 590.0)

var run_active: bool = false
var run_finished: bool = false
var run_victory: bool = false
var map_nodes: Array[Dictionary] = []
var crisis_level: int = 0
var compute_capacity: int = 5
var minerals: int = 0
var completed_node_count: int = 0
var current_node_id: int = -1
var pending_room_loot: Dictionary = {}
var equipment_inventory: Array[String] = []
var equipped_weapon: String = "pulse_cannon"
var equipped_auxiliaries: Array[String] = []
var cleared_crisis_thresholds: Array[int] = []
var pending_boss_threshold: int = 0
var pending_boss_scene: String = ""
var last_result_summary: Dictionary = {}


func start_new_run() -> void:
	randomize()
	run_active = true
	run_finished = false
	run_victory = false
	crisis_level = 0
	compute_capacity = 5
	minerals = 0
	completed_node_count = 0
	current_node_id = -1
	pending_room_loot = _empty_loot()
	equipment_inventory = ["pulse_cannon"]
	equipped_weapon = "pulse_cannon"
	equipped_auxiliaries.clear()
	cleared_crisis_thresholds.clear()
	pending_boss_threshold = 0
	pending_boss_scene = ""
	last_result_summary.clear()
	_generate_world_map()


func cancel_run() -> void:
	run_active = false
	run_finished = false
	run_victory = false
	last_result_summary.clear()
	current_node_id = -1
	pending_boss_threshold = 0
	pending_boss_scene = ""
	pending_room_loot = _empty_loot()


func is_formal_run_active() -> bool:
	return run_active and not run_finished


func is_alert_active() -> bool:
	return CRISIS_THRESHOLDS.has(crisis_level) and not cleared_crisis_thresholds.has(crisis_level)


func get_alert_stage() -> int:
	if not is_alert_active():
		return 0
	return CRISIS_THRESHOLDS.find(crisis_level) + 1


func is_node_completed(node_id: int) -> bool:
	var node := get_map_node(node_id)
	return bool(node.get("completed", false))


func is_node_accessible(node_id: int) -> bool:
	if node_id == CENTER_ID:
		return true
	var node := get_map_node(node_id)
	if node.is_empty() or bool(node.get("completed", false)):
		return false
	if is_alert_active():
		return false
	for linked_id in node.get("links", []):
		if int(linked_id) == CENTER_ID or is_node_completed(int(linked_id)):
			return true
	return false


func get_map_node(node_id: int) -> Dictionary:
	if node_id < 0 or node_id >= map_nodes.size():
		return {}
	return map_nodes[node_id]


func get_node_state_text(node_id: int) -> String:
	if node_id == CENTER_ID:
		return "方舟核心"
	if is_node_completed(node_id):
		return "已探索"
	if is_node_accessible(node_id):
		return "可进入"
	if is_alert_active():
		return "警报锁定"
	return "未探索"


func get_node_type_name(node_type: String) -> String:
	match node_type:
		NODE_BASE:
			return "方舟核心"
		NODE_BATTLE:
			return "战斗残片"
		NODE_EVENT:
			return "事件信号"
		NODE_REWARD:
			return "奖励缓存"
	return "未知节点"


func start_explore_node(node_id: int) -> bool:
	if not is_node_accessible(node_id):
		return false
	var node := get_map_node(node_id)
	if node.is_empty() or String(node.get("type", "")) == NODE_BASE:
		return false
	current_node_id = node_id
	pending_room_loot = _empty_loot()
	var node_type := String(node.get("type", NODE_BATTLE))
	if node_type == NODE_REWARD:
		GameManager.set_next_explore_room_config({
			"large_space_rock_count": 12,
			"trap_count": 4,
			"chest_crystal_count": 14,
			"clutter_count": 35,
			"enemy_spawn_interval": 60.0,
			"max_patrol_enemy_count": 6,
		})
	else:
		GameManager.set_next_explore_room_config({})
	return true


func resolve_event_node(node_id: int) -> Dictionary:
	if not is_node_accessible(node_id):
		return {"ok": false, "message": "节点尚不可访问。"}
	var node := get_map_node(node_id)
	if String(node.get("type", "")) != NODE_EVENT:
		return {"ok": false, "message": "这不是事件节点。"}
	current_node_id = node_id
	pending_room_loot = _empty_loot()
	var roll := randi_range(0, 2)
	var message := ""
	if roll == 0:
		var amount := randi_range(14, 26)
		pending_room_loot["minerals"] = amount
		message = "你回收了一段旧时代补给链路，获得 %d 星髓矿。" % amount
	elif roll == 1:
		var heal := randi_range(20, 35)
		GameManager.player_hp = mini(GameManager.PLAYER_MAX_HP, GameManager.player_hp + heal)
		message = "方舟核心重校准了机体结构，恢复 %d 生命。" % heal
	else:
		var item_id := EquipmentCatalogScript.get_random_loot_item_id(equipment_inventory)
		pending_room_loot["equipment"] = [item_id]
		message = "异常信号中保存着一件装备：%s。" % EquipmentCatalogScript.get_display_name(item_id)
	_complete_current_node(true)
	return {"ok": true, "message": message}


func record_reward_broken(reward_type: int) -> void:
	if not is_formal_run_active() or current_node_id < 0:
		return
	if pending_room_loot.is_empty():
		pending_room_loot = _empty_loot()
	if reward_type == 1:
		pending_room_loot["minerals"] = int(pending_room_loot.get("minerals", 0)) + randi_range(5, 12)
		return
	if randf() < 0.32:
		var item_id := EquipmentCatalogScript.get_random_loot_item_id(equipment_inventory + pending_room_loot.get("equipment", []))
		var equipment: Array = pending_room_loot.get("equipment", [])
		equipment.append(item_id)
		pending_room_loot["equipment"] = equipment
	else:
		pending_room_loot["minerals"] = int(pending_room_loot.get("minerals", 0)) + randi_range(8, 18)


func complete_explore_room_success() -> Dictionary:
	return _complete_current_node(true)


func abandon_current_room() -> void:
	current_node_id = -1
	pending_room_loot = _empty_loot()


func begin_crisis_boss() -> bool:
	if not is_alert_active():
		return false
	pending_boss_threshold = crisis_level
	pending_boss_scene = _pick_crisis_boss_scene(get_alert_stage())
	if pending_boss_scene.is_empty():
		return false
	return true


func handle_boss_victory() -> bool:
	if not is_formal_run_active() or pending_boss_threshold <= 0:
		return false
	var threshold := pending_boss_threshold
	pending_boss_threshold = 0
	pending_boss_scene = ""
	if not cleared_crisis_thresholds.has(threshold):
		cleared_crisis_thresholds.append(threshold)
	if threshold >= 21:
		finish_run(true)
		get_tree().change_scene_to_file(GAME_OVER_SCENE)
	else:
		get_tree().change_scene_to_file(WORLD_MAP_SCENE)
	return true


func finish_run(victory: bool) -> void:
	if not run_active:
		return
	run_finished = true
	run_victory = victory
	last_result_summary = {
		"victory": victory,
		"score": GameManager.score,
		"crisis_level": crisis_level,
		"compute_capacity": compute_capacity,
		"minerals": minerals,
		"completed_node_count": completed_node_count,
		"equipment_count": equipment_inventory.size(),
		"cleared_boss_count": cleared_crisis_thresholds.size(),
	}
	abandon_current_room()


func buy_equipment(item_id: String) -> Dictionary:
	if not EquipmentCatalogScript.has_item(item_id):
		return {"ok": false, "message": "未知装备。"}
	if equipment_inventory.has(item_id):
		return {"ok": false, "message": "已经拥有该装备。"}
	var price := EquipmentCatalogScript.get_price(item_id)
	if minerals < price:
		return {"ok": false, "message": "星髓矿不足，需要 %d。" % price}
	minerals -= price
	equipment_inventory.append(item_id)
	return {"ok": true, "message": "购买了 %s。" % EquipmentCatalogScript.get_display_name(item_id)}


func equip_or_toggle(item_id: String) -> Dictionary:
	if not equipment_inventory.has(item_id):
		return {"ok": false, "message": "尚未拥有该装备。"}
	var item_type := EquipmentCatalogScript.get_type(item_id)
	if item_type == EquipmentCatalogScript.TYPE_WEAPON:
		equipped_weapon = item_id
		return {"ok": true, "message": "已切换武器：%s。" % EquipmentCatalogScript.get_display_name(item_id)}
	if item_type == EquipmentCatalogScript.TYPE_AUX:
		if equipped_auxiliaries.has(item_id):
			equipped_auxiliaries.erase(item_id)
			return {"ok": true, "message": "已卸下辅助机：%s。" % EquipmentCatalogScript.get_display_name(item_id)}
		var cost := EquipmentCatalogScript.get_compute_cost(item_id)
		if get_used_compute() + cost > compute_capacity:
			return {"ok": false, "message": "算力不足，当前 %d/%d。" % [get_used_compute(), compute_capacity]}
		equipped_auxiliaries.append(item_id)
		return {"ok": true, "message": "已装配辅助机：%s。" % EquipmentCatalogScript.get_display_name(item_id)}
	return {"ok": false, "message": "该物品不能装配。"}


func get_used_compute() -> int:
	var used := 0
	for item_id in equipped_auxiliaries:
		used += EquipmentCatalogScript.get_compute_cost(item_id)
	return used


func get_player_stats() -> Dictionary:
	return EquipmentCatalogScript.make_player_stats(equipped_weapon, equipped_auxiliaries)


func get_mineral_bonus() -> float:
	return float(get_player_stats().get("mineral_bonus", 0.0))


func _complete_current_node(success: bool) -> Dictionary:
	if not success or current_node_id <= 0:
		abandon_current_room()
		return {"ok": false, "message": "节点未完成。"}
	var node := get_map_node(current_node_id)
	if node.is_empty() or bool(node.get("completed", false)):
		abandon_current_room()
		return {"ok": false, "message": "节点已结算。"}
	_commit_pending_room_loot()
	node["completed"] = true
	map_nodes[current_node_id] = node
	completed_node_count += 1
	crisis_level += 1
	compute_capacity += 1
	var summary := {
		"ok": true,
		"node_id": current_node_id,
		"crisis_level": crisis_level,
		"compute_capacity": compute_capacity,
		"alert_active": is_alert_active(),
	}
	abandon_current_room()
	return summary


func _commit_pending_room_loot() -> void:
	var base_minerals := int(pending_room_loot.get("minerals", 0))
	var bonus := int(floor(float(base_minerals) * get_mineral_bonus()))
	minerals += base_minerals + bonus
	for item_id in pending_room_loot.get("equipment", []):
		if EquipmentCatalogScript.has_item(item_id) and not equipment_inventory.has(item_id):
			equipment_inventory.append(item_id)


func _empty_loot() -> Dictionary:
	return {
		"minerals": 0,
		"equipment": [],
	}


func _generate_world_map() -> void:
	map_nodes.clear()
	map_nodes.append({
		"id": CENTER_ID,
		"name": "方舟核心",
		"type": NODE_BASE,
		"position": MAP_CENTER,
		"links": [],
		"completed": true,
	})
	var ring_counts: Array[int] = [5, 8, 11]
	var ring_radii: Array[float] = [200.0, 330.0, 455.0]
	var rings: Array[Array] = []
	for ring_index in range(ring_counts.size()):
		var ring_ids: Array[int] = []
		var count := ring_counts[ring_index]
		var radius := ring_radii[ring_index]
		var angle_offset := -PI * 0.5 + float(ring_index) * 0.11
		for i in range(count):
			var angle := angle_offset + TAU * (float(i) + 0.5) / float(count)
			var node_id := map_nodes.size()
			ring_ids.append(node_id)
			map_nodes.append({
				"id": node_id,
				"name": "空间残片 %02d" % node_id,
				"type": _roll_node_type(),
				"position": MAP_CENTER + Vector2(cos(angle), sin(angle)) * radius,
				"links": [],
				"completed": false,
			})
		rings.append(ring_ids)
	for id in rings[0]:
		_add_link(CENTER_ID, id)
	_connect_ordered_rings(rings[0], rings[1])
	_connect_ordered_rings(rings[1], rings[2])


func _roll_node_type() -> String:
	var roll := randf()
	if roll < 0.70:
		return NODE_BATTLE
	if roll < 0.85:
		return NODE_EVENT
	return NODE_REWARD


func _connect_ordered_rings(parent_ids: Array, child_ids: Array) -> void:
	for child_index in range(child_ids.size()):
		var parent_index := int(floor(float(child_index) * float(parent_ids.size()) / float(child_ids.size())))
		parent_index = clampi(parent_index, 0, parent_ids.size() - 1)
		_add_link(int(parent_ids[parent_index]), int(child_ids[child_index]))


func _add_link(a: int, b: int) -> void:
	var node_a := map_nodes[a]
	var node_b := map_nodes[b]
	var links_a: Array = node_a.get("links", [])
	var links_b: Array = node_b.get("links", [])
	if not links_a.has(b):
		links_a.append(b)
	if not links_b.has(a):
		links_b.append(a)
	node_a["links"] = links_a
	node_b["links"] = links_b
	map_nodes[a] = node_a
	map_nodes[b] = node_b


func _pick_crisis_boss_scene(stage: int) -> String:
	var pools := {
		1: [
			"res://scenes/gameplay/boss/BossBattle_Frontier.tscn",
			"res://scenes/gameplay/boss/BossBattle_PeachBlossom.tscn",
			"res://scenes/gameplay/boss/BossBattle_Source.tscn",
			"res://scenes/gameplay/boss/BossBattle_Sentry.tscn",
			"res://scenes/gameplay/boss/BossBattle_ImitationAngel.tscn",
		],
		2: [
			"res://scenes/gameplay/boss/BossBattle_Heavy.tscn",
			"res://scenes/gameplay/boss/BossBattle_Utopia.tscn",
			"res://scenes/gameplay/boss/BossBattle_Spore.tscn",
			"res://scenes/gameplay/boss/BossBattle_Admin.tscn",
			"res://scenes/gameplay/boss/BossBattle_HolyBloodBrokenSword.tscn",
		],
		3: [
			"res://scenes/gameplay/boss/BossBattle_Nebula.tscn",
			"res://scenes/gameplay/boss/BossBattle_Eden.tscn",
			"res://scenes/gameplay/boss/BossBattle_Anti.tscn",
			"res://scenes/gameplay/boss/BossBattle_Gate.tscn",
			"res://scenes/gameplay/boss/BossBattle_CrystalMother.tscn",
		],
	}
	var candidates: Array = pools.get(stage, [])
	candidates.shuffle()
	for path in candidates:
		if ResourceLoader.exists(path):
			return path
	return ""
