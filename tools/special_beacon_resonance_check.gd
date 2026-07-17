extends Node


const WORLD_MAP_SCENE := preload("res://scenes/app/WorldMap.tscn")

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	_check_special_beacon_resonance_api_and_stats()
	if _failed:
		return
	await _check_world_map_lists_beacon_resonance()
	if _failed:
		return
	print("Special beacon resonance check passed.")
	get_tree().quit(0)


func _check_special_beacon_resonance_api_and_stats() -> void:
	if not RunManager.has_method("get_active_special_beacon_resonance_summaries"):
		_fail("RunManager should expose active special beacon resonance summaries.")
		return
	var before := RunManager.get_player_stats()
	RunManager.active_special_bonus_ids = [
		"colossus_charge_beacon",
		"colossus_mirror_ram_beacon",
	]
	var after := RunManager.get_player_stats()
	if float(after.get("dash_aftershock_radius", 0.0)) <= float(before.get("dash_aftershock_radius", 0.0)):
		_fail("Colossus beacon resonance should expand dash aftershock radius.")
		return
	if float(after.get("dash_damage_mult", 1.0)) <= 1.3:
		_fail("Colossus beacon resonance should make dash impact visibly stronger, stats=%s." % str(after))
		return
	var summaries: Array = RunManager.call("get_active_special_beacon_resonance_summaries")
	if summaries.size() != 1:
		_fail("Two colossus beacons should form one resonance summary, got: %s" % str(summaries))
		return
	var summary := Dictionary(summaries[0])
	var joined := "%s\n%s\n%s" % [
		String(summary.get("name", "")),
		String(summary.get("family_name", "")),
		String(summary.get("effects_text", "")),
	]
	for expected in ["星间巨构", "信标共鸣", "冲锋", "余震"]:
		if not joined.contains(expected):
			_fail("Beacon resonance summary should mention %s, got: %s" % [expected, joined])
			return
	if _contains_ascii_identifier(joined):
		_fail("Beacon resonance summary should hide internal ids: %s" % joined)


func _check_world_map_lists_beacon_resonance() -> void:
	RunManager.start_new_run()
	RunManager.active_special_bonus_ids = [
		"colossus_charge_beacon",
		"colossus_mirror_ram_beacon",
	]
	var world_map := WORLD_MAP_SCENE.instantiate()
	add_child(world_map)
	await get_tree().process_frame
	var details_body := world_map.get_node("WorldMap/DetailsPanel/DetailsBody") as RichTextLabel
	var text := details_body.text
	for expected in ["信标共鸣", "星间巨构", "余震"]:
		if not text.contains(expected):
			_fail("World map should list beacon resonance %s. Text: %s" % [expected, text])
			world_map.queue_free()
			return
	if _contains_ascii_identifier(text):
		_fail("World map beacon resonance copy should hide internal ids: %s" % text)
	world_map.queue_free()


func _contains_ascii_identifier(text: String) -> bool:
	# RichTextLabel BBCode contains harmless attribute names such as font_size;
	# assert actual gameplay identifiers instead of rejecting every underscore.
	for token in ["colossus", "beacon", "bonus_id", "family_bias"]:
		if text.contains(token):
			return true
	return false


func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
