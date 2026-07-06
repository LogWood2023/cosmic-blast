extends Node


const HANGAR_POPUP_SCENE := preload("res://scenes/ui/world_map/HangarPopup.tscn")
const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_resonance_summary()
	if _failed:
		return
	_check_resonance_stats()
	if _failed:
		return
	await _check_hangar_resonance_copy()
	if _failed:
		return
	print("Equipment family resonance check passed.")
	get_tree().quit(0)


func _check_resonance_summary() -> void:
	RunManager.equipped_weapon = "pulse_cannon"
	RunManager.equipped_auxiliaries = [
		"colossus_impact_coil",
		"colossus_ramming_keel",
	]
	var sync := Dictionary(RunManager.get_loadout_summary().get("archetype_sync", {}))
	if int(sync.get("family_count", 0)) != 2:
		_fail("Two colossus auxiliaries should expose family_count 2, got: %s" % str(sync))
		return
	if int(sync.get("resonance_level", 0)) != 1:
		_fail("Two matching family auxiliaries should activate resonance level 1, got: %s" % str(sync))
		return
	var summary_copy := "%s\n%s\n%s" % [
		String(sync.get("resonance_text", "")),
		String(sync.get("resonance_effect_text", "")),
		String(sync.get("next_resonance_text", "")),
	]
	for expected in ["星间巨构", "二件共鸣", "冲锋", "四件共鸣"]:
		if not summary_copy.contains(expected):
			_fail("Family resonance copy should include %s, got: %s" % [expected, summary_copy])
			return
	if _contains_ascii_identifier(summary_copy):
		_fail("Family resonance copy should be polished Chinese copy, got: %s" % summary_copy)
		return

	RunManager.equipped_auxiliaries = [
		"colossus_impact_coil",
		"colossus_ramming_keel",
		"colossus_vector_plow",
		"colossus_rebound_gyros",
	]
	var full_sync := Dictionary(RunManager.get_loadout_summary().get("archetype_sync", {}))
	if int(full_sync.get("family_count", 0)) != 4:
		_fail("Four colossus auxiliaries should expose family_count 4, got: %s" % str(full_sync))
		return
	if int(full_sync.get("resonance_level", 0)) != 2:
		_fail("Four matching family auxiliaries should activate resonance level 2, got: %s" % str(full_sync))
		return
	var full_copy := "%s\n%s" % [
		String(full_sync.get("resonance_text", "")),
		String(full_sync.get("resonance_effect_text", "")),
	]
	for expected in ["四件共鸣", "余震", "冲锋"]:
		if not full_copy.contains(expected):
			_fail("Four-piece family resonance copy should include %s, got: %s" % [expected, full_copy])
			return


func _check_resonance_stats() -> void:
	RunManager.equipped_weapon = "pulse_cannon"
	RunManager.equipped_auxiliaries = [
		"colossus_impact_coil",
		"colossus_ramming_keel",
		"colossus_vector_plow",
		"colossus_rebound_gyros",
	]
	var raw_stats := EquipmentCatalogScript.make_player_stats(RunManager.equipped_weapon, RunManager.equipped_auxiliaries)
	var run_stats := RunManager.get_player_stats()
	if int(run_stats.get("family_resonance_level", 0)) != 2:
		_fail("Player stats should expose family_resonance_level 2, got: %s" % str(run_stats))
		return
	if String(run_stats.get("family_resonance_family", "")) != EquipmentCatalogScript.FAMILY_COLOSSUS:
		_fail("Player stats should record colossus resonance family, got: %s" % str(run_stats))
		return
	if float(run_stats.get("dash_distance_mult", 1.0)) <= float(raw_stats.get("dash_distance_mult", 1.0)):
		_fail("Colossus resonance should add dash distance beyond raw equipment stats.")
		return
	if float(run_stats.get("dash_aftershock_radius", 0.0)) <= 0.0:
		_fail("Four-piece colossus resonance should unlock dash aftershock radius.")
		return

	RunManager.equipped_auxiliaries = [
		"paradise_splitter_board",
		"paradise_rapid_breech",
		"paradise_halo_lattice",
		"paradise_orbital_rake",
	]
	var paradise_stats := RunManager.get_player_stats()
	if int(paradise_stats.get("family_resonance_level", 0)) != 2:
		_fail("Paradise four-piece loadout should expose resonance level 2.")
		return
	if int(paradise_stats.get("bullet_count", 1)) <= int(EquipmentCatalogScript.make_player_stats("pulse_cannon", RunManager.equipped_auxiliaries).get("bullet_count", 1)):
		_fail("Four-piece paradise resonance should add one extra projectile line.")
		return


func _check_hangar_resonance_copy() -> void:
	RunManager.equipment_inventory = [
		"pulse_cannon",
		"colossus_impact_coil",
		"colossus_ramming_keel",
	]
	RunManager.equipped_weapon = "pulse_cannon"
	RunManager.equipped_auxiliaries = [
		"colossus_impact_coil",
		"colossus_ramming_keel",
	]
	var popup := HANGAR_POPUP_SCENE.instantiate()
	add_child(popup)
	popup.call("setup")
	await get_tree().process_frame
	var sync_label := popup.get_node_or_null("Panel/LoadoutBar/ArchetypeSyncLabel") as Label
	if sync_label == null:
		_fail("Hangar popup should expose ArchetypeSyncLabel.")
		popup.queue_free()
		return
	for expected in ["星间巨构", "二件共鸣", "冲锋"]:
		if not sync_label.text.contains(expected):
			_fail("Hangar archetype sync should show %s, got: %s" % [expected, sync_label.text])
			popup.queue_free()
			return
	if _contains_ascii_identifier(sync_label.text):
		_fail("Hangar resonance copy should be Chinese-facing text, got: %s" % sync_label.text)
		popup.queue_free()
		return
	popup.queue_free()


func _contains_ascii_identifier(text: String) -> bool:
	for token in ["colossus", "paradise", "warped", "hell_eye", "divine", "resonance", "family", "_"]:
		if text.contains(token):
			return true
	return false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
