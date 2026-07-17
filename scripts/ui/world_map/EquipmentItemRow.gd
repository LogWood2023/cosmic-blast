extends HBoxContainer

signal action_pressed(item_id: String)

const EquipmentCatalogScript := preload("res://scripts/core/EquipmentCatalog.gd")
const CombatUiMotion := preload("res://scripts/ui/theme/CombatUiMotion.gd")
const CARD_HOVER_SCALE := Vector2(0.992, 0.992)
const CARD_PRESS_SCALE := Vector2(0.975, 0.975)

var _item_id: String = ""
var _card_tween: Tween
var _feedback_tween: Tween
var _feedback_flash_tween: Tween
var _card_hovered := false

@onready var icon_texture: TextureRect = $InfoPanel/Margin/Inner/CrestSlot/IconTexture
@onready var info_panel: PanelContainer = $InfoPanel
@onready var feedback_flash: ColorRect = $InfoPanel/FeedbackFlash
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
	card_button.mouse_entered.connect(_on_card_hovered)
	card_button.mouse_exited.connect(_on_card_unhovered)
	card_button.button_down.connect(_on_card_button_down)
	card_button.button_up.connect(_on_card_button_up)
	action_button.pressed.connect(_on_action_pressed)
	call_deferred("_refresh_card_pivot")


func setup(item_id: String, item_name: String, meta_text: String, description: String, action_text: String, disabled: bool, status_text: String = "") -> void:
	_item_id = item_id
	name_label.text = item_name
	var item := EquipmentCatalogScript.get_item(item_id)
	if item.is_empty():
		category_label.text = _fallback_category(meta_text)
		effect_label.text = meta_text if not meta_text.strip_edges().is_empty() else "实际效果待补充"
		flavor_label.text = description if not description.strip_edges().is_empty() else "风味文本待补充"
	else:
		category_label.text = "武器" if EquipmentCatalogScript.get_type(item_id) == EquipmentCatalogScript.TYPE_WEAPON else "辅助装备"
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
	card_button.focus_mode = Control.FOCUS_ALL if enabled and not card_button.disabled else Control.FOCUS_NONE
	set_context_text(context_text)


func set_context_text(text: String) -> void:
	context_label.text = text
	context_label.visible = not text.strip_edges().is_empty()


func set_context_font_size(font_size: int) -> void:
	context_label.add_theme_font_size_override("font_size", font_size)


func _on_action_pressed() -> void:
	action_pressed.emit(_item_id)


func _refresh_card_pivot() -> void:
	info_panel.pivot_offset = info_panel.size * 0.5


func _on_card_hovered() -> void:
	if card_button.disabled:
		return
	_card_hovered = true
	_animate_card(CARD_HOVER_SCALE, Color(1.08, 1.08, 1.08, 1.0), 0.13, Tween.TRANS_CUBIC, Tween.EASE_OUT)


func _on_card_unhovered() -> void:
	_card_hovered = false
	_animate_card(Vector2.ONE, Color.WHITE, 0.13, Tween.TRANS_CUBIC, Tween.EASE_OUT)


func _on_card_button_down() -> void:
	if card_button.disabled:
		return
	_animate_card(CARD_PRESS_SCALE, Color(1.16, 1.02, 1.02, 1.0), 0.07, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _on_card_button_up() -> void:
	if card_button.disabled:
		return
	var target_scale := CARD_HOVER_SCALE if _card_hovered else Vector2.ONE
	var target_modulate := Color(1.08, 1.08, 1.08, 1.0) if _card_hovered else Color.WHITE
	_animate_card(target_scale, target_modulate, 0.12, Tween.TRANS_BACK, Tween.EASE_OUT)


func _animate_card(target_scale: Vector2, target_modulate: Color, duration: float, transition: Tween.TransitionType, ease: Tween.EaseType) -> void:
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	if _feedback_flash_tween != null and _feedback_flash_tween.is_valid():
		_feedback_flash_tween.kill()
	feedback_flash.visible = false
	if _card_tween != null and _card_tween.is_valid():
		_card_tween.kill()
	# GridContainer 会在节点 ready 后再次调整卡片尺寸；动画开始时重设 pivot，确保始终从卡片中心缩放。
	info_panel.pivot_offset = info_panel.size * 0.5
	_card_tween = create_tween().set_parallel(true)
	_card_tween.set_trans(transition).set_ease(ease)
	_card_tween.tween_property(info_panel, "scale", target_scale, duration)
	_card_tween.tween_property(info_panel, "modulate", target_modulate, duration)


func play_rejection_feedback() -> void:
	if card_button.disabled:
		return
	if _card_tween != null and _card_tween.is_valid():
		_card_tween.kill()
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	if _feedback_flash_tween != null and _feedback_flash_tween.is_valid():
		_feedback_flash_tween.kill()
	info_panel.pivot_offset = info_panel.size * 0.5
	var base_position := info_panel.position
	var rest_scale := CARD_HOVER_SCALE if _card_hovered else Vector2.ONE
	var rest_modulate := Color(1.08, 1.08, 1.08, 1.0) if _card_hovered else Color.WHITE
	info_panel.scale = Vector2.ONE
	feedback_flash.color = Color(1.0, 0.04, 0.08, 0.62)
	feedback_flash.visible = true
	_feedback_flash_tween = create_tween()
	_feedback_flash_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_feedback_flash_tween.tween_property(feedback_flash, "color:a", 0.0, 0.24)
	_feedback_flash_tween.tween_callback(func() -> void:
		feedback_flash.visible = false
	)
	_feedback_tween = create_tween()
	_feedback_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_property(info_panel, "position:x", base_position.x + 9.0, 0.035)
	_feedback_tween.parallel().tween_property(info_panel, "modulate", Color(1.35, 0.24, 0.3, 1.0), 0.035)
	_feedback_tween.tween_property(info_panel, "position:x", base_position.x - 9.0, 0.05)
	_feedback_tween.tween_property(info_panel, "position:x", base_position.x + 5.0, 0.045)
	_feedback_tween.tween_property(info_panel, "position:x", base_position.x, 0.04)
	_feedback_tween.parallel().tween_property(info_panel, "modulate", rest_modulate, 0.1)
	_feedback_tween.parallel().tween_property(info_panel, "scale", rest_scale, 0.1)


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
	return "辅助装备" if meta_text.contains("辅助装备") or meta_text.contains("辅助机") else "武器"
