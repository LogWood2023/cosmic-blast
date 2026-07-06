extends Node


var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_seed_inventory()
	_check_loadout_api()
	if _failed:
		return
	_check_save_and_apply_loadout()
	if _failed:
		return
	_check_compute_limit_and_missing_equipment()
	if _failed:
		return
	_check_build_summary()
	if _failed:
		return
	_check_archetype_sync_summary()
	if _failed:
		return
	print("Hangar loadout check passed.")
	get_tree().quit(0)


func _seed_inventory() -> void:
	RunManager.compute_capacity = 5
	RunManager.equipment_inventory = [
		"pulse_cannon",
		"twin_lance",
		"overclock_core",
		"vector_thruster",
		"salvage_ai",
		"reinforced_plating",
	]
	RunManager.equipped_weapon = "twin_lance"
	RunManager.equipped_auxiliaries = ["overclock_core", "vector_thruster"]


func _check_loadout_api() -> void:
	for method in ["save_loadout_preset", "apply_loadout_preset", "get_loadout_preset", "get_loadout_summary"]:
		if not RunManager.has_method(method):
			_fail("RunManager should expose %s()." % method)
			return


func _check_save_and_apply_loadout() -> void:
	var saved: Dictionary = RunManager.save_loadout_preset(0, "冲刺试装")
	if not bool(saved.get("ok", false)):
		_fail("Saving current loadout should succeed: %s" % str(saved))
		return
	RunManager.equipped_weapon = "pulse_cannon"
	RunManager.equipped_auxiliaries = ["salvage_ai"]
	var applied: Dictionary = RunManager.apply_loadout_preset(0)
	if not bool(applied.get("ok", false)):
		_fail("Applying saved loadout should succeed: %s" % str(applied))
		return
	if RunManager.equipped_weapon != "twin_lance":
		_fail("Applied loadout should restore the saved weapon.")
		return
	if RunManager.equipped_auxiliaries != ["overclock_core", "vector_thruster"]:
		_fail("Applied loadout should restore saved auxiliaries.")
		return
	var preset: Dictionary = RunManager.get_loadout_preset(0)
	if String(preset.get("name", "")) != "冲刺试装":
		_fail("Saved loadout should preserve its display name.")
		return


func _check_compute_limit_and_missing_equipment() -> void:
	RunManager.equipped_weapon = "twin_lance"
	RunManager.equipped_auxiliaries = ["overclock_core", "salvage_ai", "reinforced_plating"]
	RunManager.save_loadout_preset(1, "超载试装")
	RunManager.compute_capacity = 3
	RunManager.equipment_inventory.erase("reinforced_plating")
	RunManager.equipped_weapon = "pulse_cannon"
	RunManager.equipped_auxiliaries.clear()
	var applied: Dictionary = RunManager.apply_loadout_preset(1)
	if not bool(applied.get("ok", false)):
		_fail("Applying a trimmed loadout should still succeed.")
		return
	if RunManager.equipped_auxiliaries.has("reinforced_plating"):
		_fail("Missing equipment should be skipped when applying a preset.")
		return
	if RunManager.get_used_compute() > RunManager.compute_capacity:
		_fail("Applied preset should not exceed current compute capacity.")
		return
	if int(applied.get("skipped_count", 0)) <= 0:
		_fail("Applying a trimmed preset should report skipped equipment.")
		return


func _check_build_summary() -> void:
	var summary: Dictionary = RunManager.get_loadout_summary()
	if String(summary.get("weapon_id", "")) != RunManager.equipped_weapon:
		_fail("Loadout summary should include equipped weapon id.")
		return
	if int(summary.get("used_compute", -1)) != RunManager.get_used_compute():
		_fail("Loadout summary should include used compute.")
		return
	if int(summary.get("capacity", -1)) != RunManager.compute_capacity:
		_fail("Loadout summary should include compute capacity.")
		return
	if int(summary.get("aux_count", -1)) != RunManager.equipped_auxiliaries.size():
		_fail("Loadout summary should include auxiliary count.")
		return
	if not summary.has("families"):
		_fail("Loadout summary should include family distribution.")
		return


func _check_archetype_sync_summary() -> void:
	RunManager.compute_capacity = 7
	RunManager.equipment_inventory = [
		"pulse_cannon",
		"colossus_impact_coil",
		"colossus_ramming_keel",
		"general_stability_chip",
	]
	RunManager.equipped_auxiliaries = [
		"colossus_impact_coil",
		"colossus_ramming_keel",
		"general_stability_chip",
	]
	var summary: Dictionary = RunManager.get_loadout_summary()
	if not summary.has("archetype_sync"):
		_fail("Loadout summary should include archetype_sync for route diagnosis.")
		return
	var sync := Dictionary(summary.get("archetype_sync", {}))
	for key in ["dominant_family", "dominant_family_name", "sync_level", "sync_text", "score_text", "effect_text", "scores"]:
		if not sync.has(key):
			_fail("Archetype sync summary should include %s: %s" % [key, str(sync)])
			return
	if String(sync.get("dominant_family", "")) != "colossus":
		_fail("Colossus loadout should be recognized as dominant, got: %s" % str(sync))
		return
	var combined := "%s\n%s\n%s\n%s" % [
		String(sync.get("dominant_family_name", "")),
		String(sync.get("sync_text", "")),
		String(sync.get("score_text", "")),
		String(sync.get("effect_text", "")),
	]
	for expected in ["星间巨构", "同调", "巨构", "通用", "冲锋"]:
		if not combined.contains(expected):
			_fail("Archetype sync copy should include %s, got: %s" % [expected, combined])
			return
	if _contains_ascii_letter(combined):
		_fail("Archetype sync summary should use Chinese-facing copy, got: %s" % combined)
		return


func _contains_ascii_letter(text: String) -> bool:
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
			return true
	return false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
