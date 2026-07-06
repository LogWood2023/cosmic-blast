extends Node


const DesignedEnemyCatalog := preload("res://scripts/entities/designed_enemies/DesignedEnemyCatalog.gd")

const FORBIDDEN_COPY_TERMS: Array[String] = [
	"AI",
	"HP",
	"px",
	"玩家",
	"小怪",
	"单位",
	"流程",
	"同款",
	"警戒距离",
	"精灵",
	"0.",
	"+",
	"/",
	"%",
]

var _failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	if DesignedEnemyCatalog.ENEMIES.size() < 25:
		_fail("Designed enemy catalog should keep the 25-family enemy archive.")
		return
	for enemy in DesignedEnemyCatalog.ENEMIES:
		var data := Dictionary(enemy)
		var enemy_id := String(data.get("id", "unknown"))
		_check_copy("%s/name" % enemy_id, String(data.get("name", "")), true)
		if _failed:
			return
		_check_copy("%s/family" % enemy_id, String(data.get("family", "")), true)
		if _failed:
			return
		_check_copy("%s/mechanic" % enemy_id, String(data.get("mechanic", "")), true)
		if _failed:
			return
	print("Designed enemy copy quality check passed.")
	get_tree().quit(0)


func _check_copy(label: String, text: String, required: bool) -> void:
	var stripped := text.strip_edges()
	if stripped.is_empty():
		if required:
			_fail("%s should not be empty." % label)
		return
	if not _contains_cjk(stripped):
		_fail("%s should be Chinese copy: %s" % [label, stripped])
		return
	if _contains_ascii_letter(stripped):
		_fail("%s should not contain English letters: %s" % [label, stripped])
		return
	for term in FORBIDDEN_COPY_TERMS:
		if stripped.contains(term):
			_fail("%s contains design-note term '%s': %s" % [label, term, stripped])
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
