extends SceneTree

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	RunManager.equipment_inventory = ["pulse_cannon", "twin_lance", "overclock_core", "vector_thruster"]
	RunManager.equipped_weapon = "pulse_cannon"
	RunManager.equipped_auxiliaries.clear()
	_check_presets_removed()
	_check_direct_equipment_flow()
	quit(1 if _failed else 0)


func _check_presets_removed() -> void:
	for method in ["save_loadout_preset", "apply_loadout_preset", "get_loadout_preset"]:
		if RunManager.has_method(method):
			_fail("Loadout preset API should be removed: %s" % method)
			return


func _check_direct_equipment_flow() -> void:
	if _failed:
		return
	var weapon_result: Dictionary = RunManager.equip_or_toggle("twin_lance")
	if not bool(weapon_result.get("ok", false)) or RunManager.equipped_weapon != "twin_lance":
		_fail("Direct weapon equipment should remain available.")
		return
	var auxiliary_result: Dictionary = RunManager.equip_or_toggle("overclock_core")
	if not bool(auxiliary_result.get("ok", false)) or not RunManager.equipped_auxiliaries.has("overclock_core"):
		_fail("Direct auxiliary equipment should remain available.")


func _fail(message: String) -> void:
	_failed = true
	push_error(message)
