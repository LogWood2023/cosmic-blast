extends Node

const MetaProgression := preload("res://scripts/core/MetaProgression.gd")
const META_PREFLIGHT_POPUP_SCENE := preload("res://scenes/ui/main_menu/MetaPreflightPopup.tscn")


func _ready() -> void:
	var meta := MetaProgression.new()
	meta.unlock_calibration("salvage_probe")
	meta.unlock_crisis(2)
	var popup := META_PREFLIGHT_POPUP_SCENE.instantiate()
	popup.configure_for_progression(meta)
	add_child(popup)
	await get_tree().process_frame
	if not popup.apply_selection("salvage_probe", 2):
		_fail("Preflight popup rejected a valid unlocked selection.")
		return
	if meta.selected_calibration_id != "salvage_probe" or meta.selected_crisis_level != 2:
		_fail("Preflight popup did not apply the selected progression state.")
		return
	if popup.apply_selection("overclock_lease", 3):
		_fail("Preflight popup accepted an unavailable selection.")
		return
	for calibration_id in MetaProgression.CALIBRATION_IDS:
		meta.unlock_calibration(calibration_id)
	meta.unlock_crisis(10)
	meta.select_calibration("resonance_compass")
	if not popup.apply_selection("resonance_compass", 2, "warped") or meta.selected_calibration_family != "warped":
		_fail("Preflight popup did not persist the required resonance family selection.")
		return
	popup._select_calibration("resonance_compass")
	await get_tree().process_frame
	var crisis_grid := popup.find_child("CrisisGrid", true, false) as GridContainer
	var family_grid := popup.find_child("FamilyGrid", true, false) as GridContainer
	if crisis_grid == null or crisis_grid.get_child_count() != 11 or family_grid == null or family_grid.get_child_count() != MetaProgression.FAMILY_IDS.size():
		_fail("Preflight popup did not contain every wrapped calibration option.")
		return
	popup._select_calibration("salvage_probe")
	await get_tree().process_frame
	var details := popup.find_child("DetailsContent", true, false) as VBoxContainer
	var selected_name := popup.find_child("SelectedName", true, false) as Label
	var effect_list := popup.find_child("EffectList", true, false) as VBoxContainer
	var selection_scroll := popup.find_child("SelectionScroll", true, false) as ScrollContainer
	var details_scroll := popup.find_child("DetailsScroll", true, false) as ScrollContainer
	var selection_margin := popup.find_child("SelectionScrollMargin", true, false) as MarginContainer
	var calibration_grid := popup.find_child("CalibrationGrid", true, false) as GridContainer
	if details == null or selected_name == null or effect_list == null or selection_scroll == null or details_scroll == null or selection_margin == null or calibration_grid == null:
		_fail("Preflight popup is missing its selectable details layout.")
		return
	var salvage_data := meta.get_calibration_data("salvage_probe")
	if salvage_data == null or selected_name.text != salvage_data.display_name:
		_fail("Preflight popup did not refresh the selected calibration details.")
		return
	if effect_list.get_child_count() < 3:
		_fail("Preflight popup did not list every selected calibration effect.")
		return
	if selection_scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED or details_scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		_fail("Preflight popup allows horizontal content overflow.")
		return
	if selection_margin.get_theme_constant("margin_right") < 18:
		_fail("Preflight popup does not reserve space between cards and its scrollbar.")
		return
	for card in calibration_grid.get_children():
		if card is Button and bool(card.get_meta(&"combat_ui_motion_scale_enabled", true)):
			_fail("Preflight popup lets a selectable card scale outside its scroll viewport.")
			return
	var first_card := calibration_grid.get_child(0) as Button
	first_card.grab_focus()
	await get_tree().create_timer(0.2).timeout
	if first_card.scale.distance_to(Vector2.ONE) > 0.001:
		_fail("Preflight popup scales a focused selectable card outside its scroll viewport.")
		return
	if popup.panel.size.x > popup.get_viewport().get_visible_rect().size.x or popup.panel.size.y > popup.get_viewport().get_visible_rect().size.y:
		_fail("Preflight popup panel extends beyond the viewport.")
		return
	print("Meta preflight check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
