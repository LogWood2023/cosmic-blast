extends Node

## Central access point for player-facing copy. Keep runtime IDs out of the UI
## and make missing localization visible during development without leaking keys.

const FALLBACK_LOCALE := "zh_CN"
const MISSING_COPY := "文本暂不可用"


func _ready() -> void:
	TranslationServer.set_locale(FALLBACK_LOCALE)


func text(key: StringName, values: Array = []) -> String:
	var resolved := tr(String(key))
	if resolved == String(key):
		push_error("Missing player-facing copy key: %s" % key)
		return MISSING_COPY
	return resolved % values if not values.is_empty() else resolved
