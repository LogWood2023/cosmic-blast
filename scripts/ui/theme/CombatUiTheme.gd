extends RefCounted

const STATE_NORMAL := "normal"
const STATE_HOVER := "hover"
const STATE_PRESSED := "pressed"
const STATE_DANGER := "danger"
const STATE_SUCCESS := "success"
const STATE_ANOMALY := "anomaly"

const DANGER_RED := Color("#ff4f6a")
const FURNACE_AMBER := Color("#ffb84d")
const COMMAND_CYAN := Color("#52e8ff")
const VOID_VIOLET := Color("#b78cff")
const ANOMALY_GREEN := Color("#65f0a3")
const DEEP_PANEL := Color("#071018")
const NEAR_BLACK := Color("#03070c")
const TEXT_MAIN := Color("#f8fbff")
const TEXT_MUTED := Color("#b7c4cf")

const MIN_BUTTON_SIZE := Vector2(190, 48)
const PRIMARY_BUTTON_SIZE := Vector2(260, 56)


static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)


static func make_panel_style(accent: Color = FURNACE_AMBER, fill_alpha: float = 0.88) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = with_alpha(DEEP_PANEL, fill_alpha)
	style.border_color = with_alpha(accent, 0.55)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 2
	style.content_margin_left = 18
	style.content_margin_top = 14
	style.content_margin_right = 18
	style.content_margin_bottom = 14
	return style


static func make_button_style(state: String = STATE_NORMAL) -> StyleBoxFlat:
	var accent := FURNACE_AMBER
	var fill := Color(0.18, 0.08, 0.06, 0.82)
	if state == STATE_HOVER:
		accent = COMMAND_CYAN
		fill = Color(0.05, 0.18, 0.22, 0.88)
	elif state == STATE_PRESSED:
		accent = DANGER_RED
		fill = Color(0.24, 0.05, 0.08, 0.94)
	elif state == STATE_ANOMALY:
		accent = VOID_VIOLET
		fill = Color(0.1, 0.07, 0.18, 0.88)
	var style := make_panel_style(accent, fill.a)
	style.bg_color = fill
	style.content_margin_left = 16
	style.content_margin_right = 16
	return style


static func make_bar_background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.025, 0.035, 0.9)
	style.border_color = Color(1, 1, 1, 0.18)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	return style


static func make_bar_fill(color: Color = FURNACE_AMBER) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	return style


static func apply_label(label: Label, size: int = 22, color: Color = TEXT_MAIN, shadow: Color = Color(0, 0, 0, 0.8)) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", shadow)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)


static func style_button(button: Button, primary: bool = false) -> void:
	button.custom_minimum_size = PRIMARY_BUTTON_SIZE if primary else MIN_BUTTON_SIZE
	button.add_theme_stylebox_override("normal", make_button_style(STATE_NORMAL))
	button.add_theme_stylebox_override("hover", make_button_style(STATE_HOVER))
	button.add_theme_stylebox_override("pressed", make_button_style(STATE_PRESSED))
	button.add_theme_stylebox_override("focus", make_button_style(STATE_HOVER))
	button.add_theme_color_override("font_color", TEXT_MAIN)
	button.add_theme_color_override("font_hover_color", TEXT_MAIN)
	button.add_theme_color_override("font_pressed_color", TEXT_MAIN)
	button.add_theme_font_size_override("font_size", 22)
