extends Node


const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := EquipmentCatalogScript.new()
	var weapon_ids := EquipmentCatalogScript.get_weapon_item_ids()
	var aux_ids := EquipmentCatalogScript.get_auxiliary_item_ids()
	if weapon_ids.size() < 20:
		_fail("Equipment catalog should contain at least 20 weapons, got %d." % weapon_ids.size())
		return
	if aux_ids.size() < 100:
		_fail("Equipment catalog should contain at least 100 auxiliaries for commercial-scale build variety, got %d." % aux_ids.size())
		return

	for family in [
		EquipmentCatalogScript.FAMILY_COLOSSUS,
		EquipmentCatalogScript.FAMILY_PARADISE,
		EquipmentCatalogScript.FAMILY_WARPED,
		EquipmentCatalogScript.FAMILY_HELL_EYE,
		EquipmentCatalogScript.FAMILY_DIVINE,
	]:
		var family_count := 0
		for id in aux_ids:
			if EquipmentCatalogScript.get_family(id) == family:
				family_count += 1
		if family_count < 15:
			_fail("Family %s should have at least 15 auxiliaries including boss drops, got %d." % [family, family_count])
			return

	var general_count := 0
	for id in aux_ids:
		if EquipmentCatalogScript.get_family(id) == EquipmentCatalogScript.FAMILY_GENERAL:
			general_count += 1
	if general_count < 15:
		_fail("General auxiliary pool should have at least 15 flexible auxiliaries, got %d." % general_count)
		return

	var all_progression_ids := EquipmentCatalogScript.get_shop_item_ids() + EquipmentCatalogScript.get_loot_item_ids()
	if all_progression_ids.size() < 110:
		_fail("Shop and loot pools should expose at least 110 progression items, got %d." % all_progression_ids.size())
		return
	for id in all_progression_ids:
		if not EquipmentCatalogScript.has_item(id):
			_fail("Progression pool references unknown item %s." % id)
			return
		var item := EquipmentCatalogScript.get_item(id)
		for field in ["name", "type", "price", "description", "icon"]:
			if not item.has(field):
				_fail("Item %s should define %s." % [id, field])
				return
		if EquipmentCatalogScript.get_type(id) == EquipmentCatalogScript.TYPE_AUX:
			var compute_cost := EquipmentCatalogScript.get_compute_cost(id)
			if compute_cost < 1 or compute_cost > 7:
				_fail("Auxiliary %s compute cost should stay in 1-7, got %d." % [id, compute_cost])
				return
		var icon := String(item.get("icon", ""))
		if not icon.begins_with("res://assets/images/equipment/"):
			_fail("Item %s should use equipment icon path, got %s." % [id, icon])
			return
		if not catalog.has_method("get_build_tags") or not catalog.has_method("get_build_summary_text"):
			_fail("Equipment catalog should expose build tag and build summary helpers.")
			return
		var build_tags: Array = catalog.call("get_build_tags", id)
		if build_tags.is_empty() or build_tags.size() > 3:
			_fail("Item %s should expose 1-3 readable build tags, got %s." % [id, str(build_tags)])
			return
		var build_summary := String(catalog.call("get_build_summary_text", id))
		if build_summary.is_empty():
			_fail("Item %s should expose build summary text." % id)
			return
		if _contains_ascii_letter(build_summary):
			_fail("Build summary should be Chinese UI copy for %s, got: %s" % [id, build_summary])
			return

	var archetype_keywords := {
		EquipmentCatalogScript.FAMILY_COLOSSUS: "冲锋",
		EquipmentCatalogScript.FAMILY_PARADISE: "火力",
		EquipmentCatalogScript.FAMILY_WARPED: "引力",
		EquipmentCatalogScript.FAMILY_HELL_EYE: "狂热",
		EquipmentCatalogScript.FAMILY_DIVINE: "僚机",
	}
	for family in archetype_keywords.keys():
		var found_keyword := false
		for id in all_progression_ids:
			if EquipmentCatalogScript.get_family(id) != String(family):
				continue
			if String(catalog.call("get_build_summary_text", id)).contains(String(archetype_keywords[family])):
				found_keyword = true
				break
		if not found_keyword:
			_fail("Family %s should expose archetype keyword %s in build summaries." % [String(family), String(archetype_keywords[family])])
			return

	var stats := EquipmentCatalogScript.make_player_stats("comet_shredder", ["impact_servos", "gravity_threader", "frenzy_injector", "drone_hangar"])
	if int(stats.get("bullet_count", 0)) < 2:
		_fail("Expanded weapon and aux stats should compose bullet count.")
		return
	if float(stats.get("dash_damage_mult", 1.0)) <= 1.0:
		_fail("Expanded colossus auxiliary should affect dash damage.")
		return
	if float(stats.get("gravity_pull_strength", 0.0)) <= 0.0:
		_fail("Expanded warped auxiliary should affect gravity pull.")
		return
	if int(stats.get("drone_slots", 0)) < 1:
		_fail("Expanded divine auxiliary should add drone slots.")
		return

	print("Equipment catalog scale check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)


func _contains_ascii_letter(text: String) -> bool:
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
			return true
	return false
