extends HBoxContainer

signal action_pressed(item_id: String)

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")

var _item_id: String = ""

@onready var crest_slot: Panel = $InfoPanel/CrestSlot
@onready var crest_glow: ColorRect = $InfoPanel/CrestSlot/CrestGlow
@onready var icon_texture: TextureRect = $InfoPanel/CrestSlot/IconTexture
@onready var family_stripe: ColorRect = $InfoPanel/CrestSlot/FamilyStripe
@onready var family_label: Label = $InfoPanel/CrestSlot/FamilyLabel
@onready var rarity_badge: Label = $InfoPanel/CrestSlot/RarityBadge
@onready var crest_mark: Label = $InfoPanel/CrestSlot/CrestMark
@onready var notch_row: HBoxContainer = $InfoPanel/CrestSlot/NotchRow
@onready var name_label: Label = $InfoPanel/InfoBox/NameLabel
@onready var meta_label: Label = $InfoPanel/InfoBox/MetaLabel
@onready var description_label: Label = $InfoPanel/InfoBox/DescriptionLabel
@onready var action_button: Button = $ActionButton


func _ready() -> void:
	CombatUiMotion.bind_button(action_button)
	action_button.pressed.connect(_on_action_pressed)


func setup(item_id: String, item_name: String, meta_text: String, description: String, action_text: String, disabled: bool, status_text: String = "") -> void:
	_item_id = item_id
	name_label.text = item_name if status_text.is_empty() else "%s  %s" % [item_name, status_text]
	meta_label.text = meta_text
	description_label.text = description
	action_button.text = action_text
	action_button.disabled = disabled
	_apply_crest_state(meta_text, disabled, status_text, action_text)
	_apply_icon()


func _on_action_pressed() -> void:
	action_pressed.emit(_item_id)


func _apply_crest_state(meta_text: String, disabled: bool, status_text: String, action_text: String) -> void:
	var item_type := EquipmentCatalogScript.get_type(_item_id)
	var is_known_item := not item_type.is_empty()
	var is_aux: bool = item_type == EquipmentCatalogScript.TYPE_AUX if is_known_item else _meta_describes_auxiliary(meta_text)
	var compute_cost: int = EquipmentCatalogScript.get_compute_cost(_item_id) if is_aux and is_known_item else _compute_cost_from_meta(meta_text)
	var is_equipped: bool = status_text.contains("已装配") or status_text.contains("已装填") or action_text.contains("卸下")

	crest_slot.visible = true
	crest_mark.text = _crest_mark_for_item(is_aux)
	crest_glow.color = Color(0.72, 0.55, 1.0, 0.18 if is_aux else 0.08)
	modulate = Color.WHITE if not disabled else Color(0.78, 0.78, 0.78, 0.82)
	_apply_family_visuals()

	if is_equipped:
		crest_glow.color = Color(0.32, 0.91, 1.0, 0.30)
		crest_mark.add_theme_color_override("font_color", Color("#65f0a3"))
	elif is_aux:
		crest_mark.add_theme_color_override("font_color", Color("#b78cff"))
	else:
		crest_mark.add_theme_color_override("font_color", Color("#ffb84d"))

	_update_notches(compute_cost, is_aux, is_equipped)


func _apply_family_visuals() -> void:
	var family := EquipmentCatalogScript.get_family(_item_id)
	var rarity := EquipmentCatalogScript.get_rarity(_item_id)
	family_label.text = _short_family_name(family)
	rarity_badge.text = EquipmentCatalogScript.get_rarity_display_name(rarity)
	var family_color := _family_color(family)
	var rarity_color := _rarity_color(rarity)
	family_stripe.color = family_color
	family_label.add_theme_color_override("font_color", Color(
		minf(1.0, family_color.r + 0.32),
		minf(1.0, family_color.g + 0.32),
		minf(1.0, family_color.b + 0.32),
		1.0
	))
	rarity_badge.add_theme_color_override("font_color", rarity_color)
	crest_slot.self_modulate = Color(
		minf(1.0, family_color.r + 0.18),
		minf(1.0, family_color.g + 0.18),
		minf(1.0, family_color.b + 0.18),
		1.0
	)


func _apply_icon() -> void:
	var item := EquipmentCatalogScript.get_item(_item_id)
	var icon_path := String(item.get("icon", ""))
	var texture := _load_icon_texture(icon_path)
	icon_texture.texture = texture
	icon_texture.visible = texture != null
	crest_mark.visible = texture == null


func _load_icon_texture(icon_path: String) -> Texture2D:
	if icon_path.is_empty():
		return null
	if ResourceLoader.exists(icon_path):
		return load(icon_path) as Texture2D
	if not FileAccess.file_exists(icon_path):
		return null
	var image := Image.new()
	var err := image.load(icon_path)
	if err != OK:
		return null
	return ImageTexture.create_from_image(image)


func _crest_mark_for_item(is_aux: bool) -> String:
	if not is_aux:
		return "武"
	var hash_value: int = absi(_item_id.hash())
	var marks: Array[String] = ["◇", "◆", "○", "△"]
	return marks[hash_value % marks.size()]


func _short_family_name(family: String) -> String:
	match family:
		EquipmentCatalogScript.FAMILY_COLOSSUS:
			return "巨构"
		EquipmentCatalogScript.FAMILY_PARADISE:
			return "天堂"
		EquipmentCatalogScript.FAMILY_WARPED:
			return "星核"
		EquipmentCatalogScript.FAMILY_HELL_EYE:
			return "赤眼"
		EquipmentCatalogScript.FAMILY_DIVINE:
			return "神使"
	return "通用"


func _family_color(family: String) -> Color:
	match family:
		EquipmentCatalogScript.FAMILY_COLOSSUS:
			return Color(0.95, 0.55, 0.26, 0.95)
		EquipmentCatalogScript.FAMILY_PARADISE:
			return Color(1.0, 0.86, 0.32, 0.95)
		EquipmentCatalogScript.FAMILY_WARPED:
			return Color(0.52, 0.47, 1.0, 0.95)
		EquipmentCatalogScript.FAMILY_HELL_EYE:
			return Color(1.0, 0.28, 0.34, 0.95)
		EquipmentCatalogScript.FAMILY_DIVINE:
			return Color(0.42, 0.92, 1.0, 0.95)
	return Color(0.62, 0.74, 0.82, 0.95)


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"boss":
			return Color(1.0, 0.32, 0.42, 1.0)
		"epic":
			return Color(0.86, 0.56, 1.0, 1.0)
		"rare":
			return Color(0.38, 0.9, 1.0, 1.0)
	return Color(1.0, 0.72, 0.3, 1.0)


func _compute_cost_from_meta(meta_text: String) -> int:
	var digits := ""
	for i in meta_text.length():
		var code := meta_text.unicode_at(i)
		if code >= 48 and code <= 57:
			digits += char(code)
	if digits.is_empty():
		return 0
	return clampi(int(digits), 0, 7)


func _meta_describes_auxiliary(meta_text: String) -> bool:
	return meta_text.contains("辅助机") or meta_text.to_lower().contains("aux")


func _update_notches(cost: int, is_aux: bool, is_equipped: bool) -> void:
	var notches: Array[Node] = notch_row.get_children()
	for i in range(notches.size()):
		var notch := notches[i] as Panel
		var active: bool = is_aux and i < maxi(1, cost)
		if active:
			notch.modulate = Color(0.38, 1.0, 0.68, 1.0) if is_equipped else Color(1.0, 0.72, 0.3, 1.0)
		else:
			notch.modulate = Color(0.28, 0.38, 0.45, 0.68)
