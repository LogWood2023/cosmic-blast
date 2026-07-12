extends HBoxContainer

signal action_pressed(item_id: String)

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")

var _item_id: String = ""

@onready var icon_texture: TextureRect = $InfoPanel/Margin/Inner/CrestSlot/IconTexture
@onready var name_label: Label = $InfoPanel/Margin/Inner/InfoBox/NameLabel
@onready var category_label: Label = $InfoPanel/Margin/Inner/InfoBox/CategoryLabel
@onready var effect_label: Label = $InfoPanel/Margin/Inner/InfoBox/EffectLabel
@onready var flavor_label: Label = $InfoPanel/Margin/Inner/InfoBox/FlavorLabel
@onready var context_label: Label = $InfoPanel/Margin/Inner/InfoBox/ContextLabel
@onready var card_button: Button = $InfoPanel/CardButton
@onready var action_button: Button = $ActionButton


func _ready() -> void:
	CombatUiMotion.bind_button(action_button)
	card_button.pressed.connect(_on_action_pressed)
	action_button.pressed.connect(_on_action_pressed)


func setup(item_id: String, item_name: String, meta_text: String, description: String, action_text: String, disabled: bool, status_text: String = "") -> void:
	_item_id = item_id
	name_label.text = item_name
	var item := EquipmentCatalogScript.get_item(item_id)
	if item.is_empty():
		category_label.text = _fallback_category(meta_text)
		effect_label.text = meta_text if not meta_text.strip_edges().is_empty() else "实际效果待补充"
		flavor_label.text = description if not description.strip_edges().is_empty() else "风味文本待补充"
	else:
		category_label.text = "武器" if EquipmentCatalogScript.get_type(item_id) == EquipmentCatalogScript.TYPE_WEAPON else "辅助机"
		effect_label.text = EquipmentCatalogScript.get_effect_summary_text(item_id)
		flavor_label.text = String(item.get("description", ""))
	action_button.text = action_text
	action_button.disabled = disabled
	card_button.disabled = disabled
	set_context_text(status_text)
	_apply_icon()
	modulate = Color.WHITE if not disabled else Color(0.78, 0.8, 0.84, 0.82)


func set_card_action_only(enabled: bool, context_text: String = "") -> void:
	action_button.visible = not enabled
	set_context_text(context_text)


func set_context_text(text: String) -> void:
	context_label.text = text
	context_label.visible = not text.strip_edges().is_empty()


func set_context_font_size(font_size: int) -> void:
	context_label.add_theme_font_size_override("font_size", font_size)


func _on_action_pressed() -> void:
	action_pressed.emit(_item_id)


func _apply_icon() -> void:
	var item := EquipmentCatalogScript.get_item(_item_id)
	var icon_path := String(item.get("icon", ""))
	icon_texture.texture = _load_icon_texture(icon_path)


func _load_icon_texture(icon_path: String) -> Texture2D:
	if icon_path.is_empty():
		return null
	if ResourceLoader.exists(icon_path):
		return load(icon_path) as Texture2D
	if not FileAccess.file_exists(icon_path):
		return null
	var image := Image.new()
	if image.load(icon_path) != OK:
		return null
	return ImageTexture.create_from_image(image)


func _fallback_category(meta_text: String) -> String:
	return "辅助机" if meta_text.contains("辅助机") else "武器"
