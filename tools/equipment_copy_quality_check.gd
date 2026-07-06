extends Node


const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const FORBIDDEN_COPY_TERMS: Array[String] = [
	"适合",
	"预留",
	"测试",
	"构筑",
	"需求",
	"玩家",
	"boss-family",
	"build",
	"early",
	"late",
	"run",
	"drone",
	"dash",
	"fire",
]

var _failed: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var checked := 0
	var all_ids := {}
	for id in EquipmentCatalogScript.get_shop_item_ids():
		all_ids[String(id)] = true
	for id in EquipmentCatalogScript.get_loot_item_ids():
		all_ids[String(id)] = true
	for id in EquipmentCatalogScript.get_boss_drop_item_ids():
		all_ids[String(id)] = true
	for id in all_ids.keys():
		_check_item_copy(String(id))
		if _failed:
			return
		checked += 1
	if checked < 110:
		_fail("Equipment copy check should cover the full progression catalog, got %d items." % checked)
		return
	print("Equipment copy quality check passed.")
	get_tree().quit(0)


func _check_item_copy(item_id: String) -> void:
	var item := EquipmentCatalogScript.get_item(item_id)
	var display_name := String(item.get("name", ""))
	var description := String(item.get("description", ""))
	if display_name.is_empty() or description.is_empty():
		_fail("Item %s should have name and description copy." % item_id)
		return
	if not _contains_cjk(display_name):
		_fail("Item %s display name should be Chinese copy: %s." % [item_id, display_name])
		return
	if _contains_ascii_letter(display_name):
		_fail("Item %s display name should not contain English letters: %s." % [item_id, display_name])
		return
	if not _contains_cjk(description):
		_fail("Item %s description should be Chinese copy: %s." % [item_id, description])
		return
	if _contains_ascii_letter(description):
		_fail("Item %s description should not contain English prose: %s." % [item_id, description])
		return
	for term in FORBIDDEN_COPY_TERMS:
		if description.to_lower().contains(term.to_lower()):
			_fail("Item %s description contains design-note term '%s': %s." % [item_id, term, description])
			return


func _contains_cjk(text: String) -> bool:
	for i in range(text.length()):
		var code := text.unicode_at(i)
		if code >= 0x4e00 and code <= 0x9fff:
			return true
	return false


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
