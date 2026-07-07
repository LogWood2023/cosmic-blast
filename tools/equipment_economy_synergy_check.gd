extends Node


const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")

const REQUIRED_ITEMS: Dictionary = {
	"colossus_quarry_mandrel": {
		"family": EquipmentCatalogScript.FAMILY_COLOSSUS,
		"stat_keys": ["mineral_bonus", "dash_mining"],
	},
	"colossus_orebreaker_keel": {
		"family": EquipmentCatalogScript.FAMILY_COLOSSUS,
		"stat_keys": ["mineral_bonus", "dash_mining"],
	},
	"paradise_mining_barrage": {
		"family": EquipmentCatalogScript.FAMILY_PARADISE,
		"stat_keys": ["mineral_bonus", "bullet_dot_damage_mult"],
	},
	"paradise_lumen_belt": {
		"family": EquipmentCatalogScript.FAMILY_PARADISE,
		"stat_keys": ["mineral_bonus", "bullet_dot_damage_mult"],
	},
	"warped_quarry_lens": {
		"family": EquipmentCatalogScript.FAMILY_WARPED,
		"stat_keys": ["mineral_bonus", "gravity_pull_strength"],
	},
	"warped_treasure_orbit": {
		"family": EquipmentCatalogScript.FAMILY_WARPED,
		"stat_keys": ["mineral_bonus", "bullet_mark_bonus"],
	},
	"hell_eye_molten_ledger": {
		"family": EquipmentCatalogScript.FAMILY_HELL_EYE,
		"stat_keys": ["mineral_bonus", "frenzy_gain_mult"],
	},
	"hell_eye_redline_collector": {
		"family": EquipmentCatalogScript.FAMILY_HELL_EYE,
		"stat_keys": ["mineral_bonus", "frenzy_damage_mult"],
	},
	"divine_salvage_squadron": {
		"family": EquipmentCatalogScript.FAMILY_DIVINE,
		"stat_keys": ["mineral_bonus", "drone_slots"],
	},
	"divine_foundry_companion": {
		"family": EquipmentCatalogScript.FAMILY_DIVINE,
		"stat_keys": ["mineral_bonus", "drone_slots"],
	},
	"general_ore_beacon_array": {
		"family": EquipmentCatalogScript.FAMILY_GENERAL,
		"stat_keys": ["mineral_bonus", "speed_mult"],
	},
	"general_extraction_cradle": {
		"family": EquipmentCatalogScript.FAMILY_GENERAL,
		"stat_keys": ["mineral_bonus", "atk_bonus"],
	},
}

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var shop_ids := EquipmentCatalogScript.get_shop_item_ids()
	var loot_ids := EquipmentCatalogScript.get_loot_item_ids()
	var synergy_ids: Array[String] = []
	for raw_id in REQUIRED_ITEMS.keys():
		var item_id := String(raw_id)
		_check_synergy_item(item_id, Dictionary(REQUIRED_ITEMS[item_id]), shop_ids, loot_ids)
		if _failed:
			return
		synergy_ids.append(item_id)

	var stats := EquipmentCatalogScript.make_player_stats("pulse_cannon", synergy_ids)
	if float(stats.get("mineral_bonus", 0.0)) < 1.0:
		_fail("Economy synergy auxiliaries should materially improve mineral income.")
		return
	if float(stats.get("dash_mining", 0.0)) <= 0.0:
		_fail("Colossus economy auxiliaries should keep dash mining growth.")
		return
	if float(stats.get("bullet_dot_damage_mult", 0.0)) <= 0.0:
		_fail("Paradise economy auxiliaries should keep bullet DoT growth.")
		return
	if float(stats.get("gravity_pull_strength", 0.0)) <= 0.0:
		_fail("Warped economy auxiliaries should keep gravity control growth.")
		return
	if float(stats.get("frenzy_gain_mult", 1.0)) <= 1.0:
		_fail("Hell-eye economy auxiliaries should keep frenzy growth.")
		return
	if int(stats.get("drone_slots", 0)) <= 0:
		_fail("Divine economy auxiliaries should keep support drone growth.")
		return

	print("Equipment economy synergy check passed.")
	get_tree().quit(0)


func _check_synergy_item(item_id: String, spec: Dictionary, shop_ids: Array[String], loot_ids: Array[String]) -> void:
	if not EquipmentCatalogScript.has_item(item_id):
		_fail("Missing economy synergy auxiliary %s." % item_id)
		return
	if EquipmentCatalogScript.get_type(item_id) != EquipmentCatalogScript.TYPE_AUX:
		_fail("%s should be an auxiliary." % item_id)
		return
	if EquipmentCatalogScript.is_boss_drop(item_id):
		_fail("%s should belong to shop and loot progression, not boss-only drops." % item_id)
		return
	if EquipmentCatalogScript.get_family(item_id) != String(spec.get("family", "")):
		_fail("%s should belong to family %s." % [item_id, String(spec.get("family", ""))])
		return
	if not shop_ids.has(item_id) or not loot_ids.has(item_id):
		_fail("%s should be reachable through normal shop and loot pools." % item_id)
		return
	var item := EquipmentCatalogScript.get_item(item_id)
	_assert_chinese_copy(String(item.get("name", "")), "%s name" % item_id)
	_assert_chinese_copy(String(item.get("description", "")), "%s description" % item_id)
	if _failed:
		return
	var icon_path := String(item.get("icon", ""))
	if icon_path.is_empty() or not icon_path.begins_with("res://assets/images/equipment/"):
		_fail("%s should expose an equipment icon path." % item_id)
		return
	for raw_key in Array(spec.get("stat_keys", [])):
		var stat_key := String(raw_key)
		if not item.has(stat_key):
			_fail("%s should expose stat %s." % [item_id, stat_key])
			return
		if _stat_has_no_growth(item, stat_key):
			_fail("%s stat %s should change the build." % [item_id, stat_key])
			return


func _stat_has_no_growth(item: Dictionary, stat_key: String) -> bool:
	var value: Variant = item.get(stat_key)
	match stat_key:
		"fire_rate_mult", "drone_fire_interval_mult", "frenzy_damage_taken_mult":
			return float(value) >= 1.0
		"dash_damage_mult", "dash_distance_mult", "bullet_speed_mult", "homing_strength", "gravity_pull_strength", "frenzy_gain_mult", "frenzy_damage_mult", "speed_mult", "mineral_bonus":
			return float(value) <= 0.0 if stat_key in ["homing_strength", "gravity_pull_strength", "mineral_bonus"] else float(value) <= 1.0
		"bullet_count_bonus", "drone_slots", "atk_bonus":
			return int(value) <= 0
	return false


func _assert_chinese_copy(text: String, label: String) -> void:
	if text.strip_edges().is_empty():
		_fail("%s should not be empty." % label)
		return
	var has_cjk := false
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if code >= 0x4e00 and code <= 0x9fff:
			has_cjk = true
		if (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
			_fail("%s should be polished Chinese copy, got: %s" % [label, text])
			return
	if not has_cjk:
		_fail("%s should contain Chinese copy, got: %s" % [label, text])


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
