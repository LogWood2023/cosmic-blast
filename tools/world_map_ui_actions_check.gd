extends Node

const WORLD_MAP_SCENE := preload("res://scenes/ui/world_map/WorldMapUI.tscn")


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	RunManager.start_new_run()
	var world_map := WORLD_MAP_SCENE.instantiate()
	add_child(world_map)
	await get_tree().process_frame
	var selected_node_id := -1
	for node_data in RunManager.map_nodes:
		var node_id := int(node_data.get("id", RunManager.CENTER_ID))
		if node_id != RunManager.CENTER_ID and RunManager.is_node_accessible(node_id):
			selected_node_id = node_id
			break
	if selected_node_id < 0:
		_fail("World map should provide an accessible non-core node.")
		return
	world_map.call("_on_map_node_selected", selected_node_id)
	await get_tree().process_frame
	for path in ["DetailsPanel/ActionButton", "ShopButton", "HangarButton", "SettingsButton"]:
		var button := world_map.get_node(path) as Button
		if not button.visible:
			_fail("World map action and navigation button should be visible: %s" % path)
			return
	var action_button := world_map.get_node("DetailsPanel/ActionButton") as Button
	if action_button.disabled or not action_button.modulate.is_equal_approx(Color.WHITE):
		_fail("Accessible world map node action should be enabled and use its normal color.")
		return
	var map_viewport := world_map.get_node("MapViewport") as Control
	if not _check_map_link_routes(map_viewport):
		return
	print("World map UI actions check passed.")
	get_tree().quit(0)


func _check_map_link_routes(map_viewport: Control) -> bool:
	for zoom_level in [0.55, 0.82, 1.80]:
		map_viewport.set("_zoom", zoom_level)
		if not _check_map_link_routes_at_current_zoom(map_viewport, zoom_level):
			return false
	return true


func _check_map_link_routes_at_current_zoom(map_viewport: Control, zoom_level: float) -> bool:
	var checked_links := {}
	for from_node in RunManager.map_nodes:
		var from_id := int(from_node.get("id", -1))
		for linked_id in from_node.get("links", []):
			var to_id := int(linked_id)
			var link_key := "%d_%d" % [mini(from_id, to_id), maxi(from_id, to_id)]
			if checked_links.has(link_key):
				continue
			checked_links[link_key] = true
			var to_node := RunManager.get_map_node(to_id)
			var route: PackedVector2Array = map_viewport.call("_build_link_route", from_node, to_node)
			if route.size() < 2:
				_fail("World map link %s should produce a visible route at zoom %.2f." % [link_key, zoom_level])
				return false
			for obstacle in RunManager.map_nodes:
				var obstacle_id := int(obstacle.get("id", -1))
				if obstacle_id == from_id or obstacle_id == to_id:
					continue
				for point_index in range(route.size() - 1):
					var intersects_ui := bool(map_viewport.call(
						"_route_segment_intersects_node_ui",
						route[point_index],
						route[point_index + 1],
						obstacle
					))
					if intersects_ui:
						_fail(
							"World map link %s crosses unrelated node %d at zoom %.2f: route=%s."
							% [link_key, obstacle_id, zoom_level, str(route)]
						)
						return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
