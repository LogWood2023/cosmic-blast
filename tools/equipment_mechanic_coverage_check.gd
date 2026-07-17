extends Node

const FAMILIES: PackedStringArray = ["colossus", "paradise", "warped", "hell_eye", "divine"]
const REQUIRED_ROLES: PackedStringArray = ["starter", "amplifier", "bridge"]


func _ready() -> void:
	var item_ids := EquipmentCatalog.get_all_item_ids()
	if item_ids.size() < 142:
		_fail("Catalog coverage is incomplete: expected at least 142 equipment entries.")
		return
	var bridge_count := 0
	for item_id in item_ids:
		var item := EquipmentCatalog.get_item(item_id)
		if String(item.get("role", "")) == "" or not item.has("mechanic_tags") or not item.has("effect_ids") or not item.has("bridge_tags"):
			_fail("Equipment metadata is incomplete for %s." % item_id)
			return
		if not bool(item.get("legacy_compatible", false)) and EquipmentCatalog.get_mechanic_effects([item_id]).is_empty():
			_fail("Migrated equipment must resolve to a mechanic resource: %s." % item_id)
			return
		if not EquipmentCatalog.get_bridge_tags(item_id).is_empty():
			bridge_count += 1
	for family in FAMILIES:
		for role in REQUIRED_ROLES:
			if EquipmentCatalog.get_role_candidates(family, role).size() < 2:
				_fail("%s needs at least two %s candidates." % [family, role])
				return
	if bridge_count < 10:
		_fail("At least ten equipment entries must expose a cross-family bridge tag.")
		return
	print("Equipment mechanic coverage check passed for %d entries." % item_ids.size())
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
