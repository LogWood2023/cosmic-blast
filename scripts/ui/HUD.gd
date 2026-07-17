extends CanvasLayer

@onready var mineral_badge: Panel = $PlayerStatusHUD/Cluster/MineralBadge
@onready var mineral_value: Label = $PlayerStatusHUD/Cluster/MineralBadge/MineralValue
@onready var hp_value: Label = $PlayerStatusHUD/Cluster/Bars/HealthRow/HpValue
@onready var frenzy_value: Label = $PlayerStatusHUD/Cluster/Bars/FrenzyRow/FrenzyValue


func _process(_delta: float) -> void:
	_update_mineral_display()
	hp_value.text = "%d" % maxi(0, GameManager.player_hp)
	if GameManager.frenzy_active:
		frenzy_value.text = GameCopy.text(&"ui.hud.overload_active", [GameManager.frenzy_timer])
	else:
		var pct: int = int(round(GameManager.get_frenzy_ratio() * 100.0))
		frenzy_value.text = GameCopy.text(&"ui.hud.overload_ready") if pct >= 100 else GameCopy.text(&"ui.hud.overload_charge", [pct])
	_align_hp_value_with_frenzy()


func _align_hp_value_with_frenzy() -> void:
	var font := frenzy_value.get_theme_font("font")
	var font_size := frenzy_value.get_theme_font_size("font_size")
	var frenzy_width := ceilf(font.get_string_size(frenzy_value.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	hp_value.custom_minimum_size.x = maxf(1.0, frenzy_width)


func _update_mineral_display() -> void:
	var pending_minerals := int(RunManager.pending_room_loot.get("minerals", 0))
	var minerals := maxi(0, RunManager.minerals + pending_minerals)
	var value_text := str(minerals)
	if mineral_value.text == value_text:
		return
	mineral_value.text = value_text
	var font := mineral_value.get_theme_font("font")
	var font_size := mineral_value.get_theme_font_size("font_size")
	var text_width := font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	mineral_badge.custom_minimum_size.x = maxf(82.0, ceilf(text_width) + 30.0)
