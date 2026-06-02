class_name EquipmentCatalog
extends RefCounted

const TYPE_WEAPON: String = "weapon"
const TYPE_AUX: String = "aux"

const WEAPONS: Dictionary = {
	"pulse_cannon": {
		"name": "脉冲机炮",
		"type": TYPE_WEAPON,
		"price": 0,
		"atk_bonus": 0,
		"fire_rate_mult": 1.0,
		"bullet_count": 1,
		"spread_degrees": 0.0,
		"description": "方舟核心保留下来的标准武器。",
	},
	"twin_lance": {
		"name": "双联光矛",
		"type": TYPE_WEAPON,
		"price": 35,
		"atk_bonus": 1,
		"fire_rate_mult": 1.05,
		"bullet_count": 2,
		"spread_degrees": 9.0,
		"description": "两道轻型光矛并行射击，覆盖更宽。",
	},
	"rail_spike": {
		"name": "星轨钉刺炮",
		"type": TYPE_WEAPON,
		"price": 45,
		"atk_bonus": 6,
		"fire_rate_mult": 1.35,
		"bullet_count": 1,
		"spread_degrees": 0.0,
		"description": "射速较慢，但单发伤害更高。",
	},
	"storm_array": {
		"name": "风暴阵列",
		"type": TYPE_WEAPON,
		"price": 65,
		"atk_bonus": 0,
		"fire_rate_mult": 1.15,
		"bullet_count": 3,
		"spread_degrees": 18.0,
		"description": "三联散射阵列，适合清理巡逻敌群。",
	},
}

const AUXILIARIES: Dictionary = {
	"overclock_core": {
		"name": "超频核心",
		"type": TYPE_AUX,
		"price": 30,
		"compute_cost": 2,
		"atk_bonus": 1,
		"fire_rate_mult": 0.88,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"description": "降低开火间隔，并略微提升攻击。",
	},
	"vector_thruster": {
		"name": "矢量推进副机",
		"type": TYPE_AUX,
		"price": 25,
		"compute_cost": 1,
		"atk_bonus": 0,
		"fire_rate_mult": 1.0,
		"speed_mult": 1.18,
		"mineral_bonus": 0.0,
		"description": "提升机体机动速度。",
	},
	"salvage_ai": {
		"name": "回收演算副机",
		"type": TYPE_AUX,
		"price": 40,
		"compute_cost": 2,
		"atk_bonus": 0,
		"fire_rate_mult": 1.0,
		"speed_mult": 1.0,
		"mineral_bonus": 0.25,
		"description": "成功撤离时提高矿物回收量。",
	},
	"targeting_ghost": {
		"name": "幽灵瞄准副机",
		"type": TYPE_AUX,
		"price": 55,
		"compute_cost": 3,
		"atk_bonus": 3,
		"fire_rate_mult": 0.96,
		"speed_mult": 1.0,
		"mineral_bonus": 0.0,
		"description": "提升攻击，并小幅优化射击循环。",
	},
	"choir_shard": {
		"name": "圣歌碎片副机",
		"type": TYPE_AUX,
		"price": 75,
		"compute_cost": 5,
		"atk_bonus": 2,
		"fire_rate_mult": 0.84,
		"speed_mult": 1.08,
		"mineral_bonus": 0.1,
		"description": "高算力消耗的综合强化模块。",
	},
}


static func get_item(id: String) -> Dictionary:
	if WEAPONS.has(id):
		return WEAPONS[id].duplicate(true)
	if AUXILIARIES.has(id):
		return AUXILIARIES[id].duplicate(true)
	return {}


static func has_item(id: String) -> bool:
	return WEAPONS.has(id) or AUXILIARIES.has(id)


static func get_type(id: String) -> String:
	return String(get_item(id).get("type", ""))


static func get_display_name(id: String) -> String:
	return String(get_item(id).get("name", id))


static func get_price(id: String) -> int:
	return int(get_item(id).get("price", 0))


static func get_compute_cost(id: String) -> int:
	return int(get_item(id).get("compute_cost", 0))


static func get_shop_item_ids() -> Array[String]:
	return [
		"twin_lance",
		"rail_spike",
		"storm_array",
		"overclock_core",
		"vector_thruster",
		"salvage_ai",
		"targeting_ghost",
		"choir_shard",
	]


static func get_loot_item_ids() -> Array[String]:
	return [
		"twin_lance",
		"rail_spike",
		"storm_array",
		"overclock_core",
		"vector_thruster",
		"salvage_ai",
		"targeting_ghost",
	]


static func get_random_loot_item_id(owned_ids: Array) -> String:
	var candidates := get_loot_item_ids()
	candidates.shuffle()
	for id in candidates:
		if not owned_ids.has(id):
			return id
	return candidates.pick_random() if not candidates.is_empty() else "pulse_cannon"


static func make_player_stats(weapon_id: String, aux_ids: Array[String]) -> Dictionary:
	var weapon := get_item(weapon_id)
	if weapon.is_empty():
		weapon = get_item("pulse_cannon")
	var stats := {
		"atk_bonus": int(weapon.get("atk_bonus", 0)),
		"fire_rate_mult": float(weapon.get("fire_rate_mult", 1.0)),
		"speed_mult": 1.0,
		"bullet_count": int(weapon.get("bullet_count", 1)),
		"spread_degrees": float(weapon.get("spread_degrees", 0.0)),
		"mineral_bonus": 0.0,
	}
	for aux_id in aux_ids:
		var aux := get_item(aux_id)
		if aux.is_empty():
			continue
		stats["atk_bonus"] = int(stats["atk_bonus"]) + int(aux.get("atk_bonus", 0))
		stats["fire_rate_mult"] = float(stats["fire_rate_mult"]) * float(aux.get("fire_rate_mult", 1.0))
		stats["speed_mult"] = float(stats["speed_mult"]) * float(aux.get("speed_mult", 1.0))
		stats["mineral_bonus"] = float(stats["mineral_bonus"]) + float(aux.get("mineral_bonus", 0.0))
	return stats
