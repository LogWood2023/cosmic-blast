extends SceneTree


const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")

const OUTPUT_DIR := "res://assets/images/equipment"
const ICON_SIZE := 96

const FAMILY_COLORS := {
	EquipmentCatalogScript.FAMILY_GENERAL: Color("#8d8f9c"),
	EquipmentCatalogScript.FAMILY_COLOSSUS: Color("#ff8c4f"),
	EquipmentCatalogScript.FAMILY_PARADISE: Color("#68d3ff"),
	EquipmentCatalogScript.FAMILY_WARPED: Color("#a87bff"),
	EquipmentCatalogScript.FAMILY_HELL_EYE: Color("#ff5f86"),
	EquipmentCatalogScript.FAMILY_DIVINE: Color("#6dffb4"),
}


func _initialize() -> void:
	_generate_icons()
	quit(0)


func _generate_icons() -> void:
	var dir := DirAccess.open(OUTPUT_DIR)
	if dir == null:
		var err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
		if err != OK:
			push_error("Failed to create output dir %s, error %d" % [OUTPUT_DIR, err])
			quit(1)
			return
		dir = DirAccess.open(OUTPUT_DIR)
	if dir == null:
		push_error("Failed to open output dir %s." % OUTPUT_DIR)
		quit(1)
		return

	var ids: Array[String] = []
	for item_id in EquipmentCatalogScript.get_weapon_item_ids():
		ids.append(item_id)
	for item_id in EquipmentCatalogScript.get_auxiliary_item_ids(true):
		ids.append(item_id)

	for item_id in ids:
		var icon_path := "%s/%s.png" % [OUTPUT_DIR, item_id]
		_write_icon(icon_path, item_id, EquipmentCatalogScript.get_item(item_id))


func _write_icon(path: String, item_id: String, item: Dictionary) -> void:
	var image := Image.create(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.04, 0.05, 0.08, 1.0))

	var family := String(item.get("family", EquipmentCatalogScript.FAMILY_GENERAL))
	var family_color: Color = FAMILY_COLORS.get(family, Color("#9ba1b3"))
	var type_color := Color("#ffbf5a") if String(item.get("type", "")) == EquipmentCatalogScript.TYPE_WEAPON else Color("#69d9ff")
	var accent := Color(
		lerpf(family_color.r, type_color.r, 0.35),
		lerpf(family_color.g, type_color.g, 0.35),
		lerpf(family_color.b, type_color.b, 0.35),
		1.0
	)

	_draw_background(image, family_color)
	_draw_frame(image, accent)
	_draw_symbol(image, item_id, family, String(item.get("type", "")), accent, type_color)

	var err := image.save_png(path)
	if err != OK:
		push_error("Failed to save %s: %d" % [path, err])


func _draw_background(image: Image, family_color: Color) -> void:
	for y in range(ICON_SIZE):
		var t := float(y) / float(maxi(1, ICON_SIZE - 1))
		var row_color := Color(
			lerp(0.03, family_color.r * 0.18 + 0.03, t),
			lerp(0.04, family_color.g * 0.18 + 0.03, t),
			lerp(0.06, family_color.b * 0.18 + 0.03, t),
			1.0
		)
		for x in range(ICON_SIZE):
			if absf(x - ICON_SIZE * 0.5) < 2.0 or absf(y - ICON_SIZE * 0.5) < 2.0:
				image.set_pixel(x, y, row_color.lightened(0.06))
			else:
				image.set_pixel(x, y, row_color)


func _draw_frame(image: Image, accent: Color) -> void:
	for x in range(ICON_SIZE):
		for y in range(ICON_SIZE):
			var border := x < 4 or y < 4 or x >= ICON_SIZE - 4 or y >= ICON_SIZE - 4
			if border:
				image.set_pixel(x, y, accent.darkened(0.2))


func _draw_symbol(image: Image, item_id: String, family: String, item_type: String, accent: Color, type_color: Color) -> void:
	var hash_value := absi(item_id.hash())
	var center := Vector2i(ICON_SIZE / 2, ICON_SIZE / 2)
	var points: Array[Vector2i] = []

	match item_type:
		EquipmentCatalogScript.TYPE_WEAPON:
			points = _weapon_points(hash_value, center)
		_:
			points = _aux_points(hash_value, center, family)

	for p in points:
		_draw_dot(image, p, 5, type_color)

	for i in range(points.size()):
		var from := points[i]
		var to := points[(i + 1) % points.size()]
		_draw_line(image, from, to, accent.lightened(0.22))

	_draw_center_core(image, center, accent)


func _weapon_points(hash_value: int, center: Vector2i) -> Array[Vector2i]:
	var spread := 16 + (hash_value % 6) * 2
	return [
		center + Vector2i(0, -spread),
		center + Vector2i(spread, 0),
		center + Vector2i(0, spread),
		center + Vector2i(-spread, 0),
	]


func _aux_points(hash_value: int, center: Vector2i, family: String) -> Array[Vector2i]:
	var size := 14 + (hash_value % 7)
	match family:
		EquipmentCatalogScript.FAMILY_COLOSSUS:
			return [
				center + Vector2i(-size, -size),
				center + Vector2i(size, -size + 4),
				center + Vector2i(size - 4, size),
				center + Vector2i(-size, size - 4),
			]
		EquipmentCatalogScript.FAMILY_PARADISE:
			return [
				center + Vector2i(0, -size - 2),
				center + Vector2i(size + 4, 0),
				center + Vector2i(0, size + 2),
				center + Vector2i(-size - 4, 0),
			]
		EquipmentCatalogScript.FAMILY_WARPED:
			return [
				center + Vector2i(-size, -size / 2),
				center + Vector2i(size / 2, -size),
				center + Vector2i(size, size / 2),
				center + Vector2i(-size / 2, size),
			]
		EquipmentCatalogScript.FAMILY_HELL_EYE:
			return [
				center + Vector2i(0, -size),
				center + Vector2i(size, 0),
				center + Vector2i(0, size),
				center + Vector2i(-size, 0),
			]
		EquipmentCatalogScript.FAMILY_DIVINE:
			return [
				center + Vector2i(0, -size - 2),
				center + Vector2i(size - 2, size - 2),
				center + Vector2i(0, size + 4),
				center + Vector2i(-size + 2, size - 2),
			]
		_:
			return [
				center + Vector2i(-size, -size / 2),
				center + Vector2i(size, -size / 2),
				center + Vector2i(size / 2, size),
				center + Vector2i(-size / 2, size),
			]


func _draw_center_core(image: Image, center: Vector2i, accent: Color) -> void:
	_draw_dot(image, center, 10, accent.lightened(0.12))
	_draw_dot(image, center + Vector2i(1, 1), 4, Color(1, 1, 1, 1))


func _draw_dot(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if x < 0 or y < 0 or x >= ICON_SIZE or y >= ICON_SIZE:
				continue
			if center.distance_to(Vector2(x, y)) <= float(radius):
				image.set_pixel(x, y, color)


func _draw_line(image: Image, from: Vector2i, to: Vector2i, color: Color) -> void:
	var dx: int = abs(to.x - from.x)
	var dy: int = -abs(to.y - from.y)
	var sx: int = 1 if from.x < to.x else -1
	var sy: int = 1 if from.y < to.y else -1
	var err: int = dx + dy
	var x: int = from.x
	var y: int = from.y
	while true:
		if x >= 0 and y >= 0 and x < ICON_SIZE and y < ICON_SIZE:
			image.set_pixel(x, y, color)
			if x + 1 < ICON_SIZE:
				image.set_pixel(x + 1, y, color.lightened(0.06))
		if x == to.x and y == to.y:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy
