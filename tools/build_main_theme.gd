extends SceneTree
## 生成全局 UI 主题 res://assets/theme/main_theme.tres。
##
## 字体：default_font = 思源黑体 Regular（消除中文系统 fallback 发布风险，不设默认字号以免撑破布局）。
## 两个 type variation（仅换字体、不设字号，应用点各自控制大小）：
##   DisplayTitle → 思源黑体 Bold（中文大标题加粗）
##   HudReadout   → Orbitron（数字/拉丁 HUD 读数，科技感）
##
## 样式：把 scripts/ui/theme/CombatUiTheme.gd 的九色板 + 斜切圆角 StyleBox 沉淀为
## Button / Panel / PanelContainer / ProgressBar 的默认样式，全项目未 override 的控件自动统一为
## 全息指挥舱风。已有 theme_override_styles 的控件优先级更高、不受影响。

const DANGER_RED := Color("#ff4f6a")
const FURNACE_AMBER := Color("#ffb84d")
const COMMAND_CYAN := Color("#52e8ff")
const VOID_VIOLET := Color("#b78cff")
const DEEP_PANEL := Color("#071018")
const TEXT_MAIN := Color("#f8fbff")
const TEXT_MUTED := Color("#b7c4cf")


func _with_alpha(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)


## 斜切圆角面板（左上/右下小、右上/左下大），沿用 CombatUiTheme.make_panel_style
func _panel_style(accent: Color, fill: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = _with_alpha(accent, 0.55)
	s.border_width_left = 2
	s.border_width_top = 2
	s.border_width_right = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left = 2
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 2
	s.content_margin_left = 18
	s.content_margin_top = 14
	s.content_margin_right = 18
	s.content_margin_bottom = 14
	return s


func _button_style(fill: Color, accent: Color) -> StyleBoxFlat:
	var s := _panel_style(accent, fill)
	s.content_margin_left = 16
	s.content_margin_right = 16
	return s


func _bar_bg() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.02, 0.025, 0.035, 0.9)
	s.border_color = Color(1, 1, 1, 0.18)
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = 2
	s.corner_radius_top_right = 2
	s.corner_radius_bottom_left = 2
	s.corner_radius_bottom_right = 2
	return s


func _bar_fill(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 2
	s.corner_radius_top_right = 2
	s.corner_radius_bottom_left = 2
	s.corner_radius_bottom_right = 2
	return s


func _init() -> void:
	var dir := DirAccess.open("res://assets")
	if dir == null:
		printerr("无法打开 res://assets")
		quit(1)
		return
	if not dir.dir_exists("theme"):
		dir.make_dir("theme")

	var regular := load("res://assets/fonts/SourceHanSansSC-Regular.otf")
	var bold := load("res://assets/fonts/SourceHanSansSC-Bold.otf")
	var orbitron := load("res://assets/fonts/Orbitron-Variable.ttf")
	if regular == null or bold == null or orbitron == null:
		printerr("字体加载失败 regular=%s bold=%s orbitron=%s" % [regular, bold, orbitron])
		quit(1)
		return

	var theme := Theme.new()

	# ── 字体 ──
	theme.default_font = regular
	theme.set_type_variation(&"DisplayTitle", &"Label")
	theme.set_font(&"font", &"DisplayTitle", bold)
	theme.set_type_variation(&"HudReadout", &"Label")
	theme.set_font(&"font", &"HudReadout", orbitron)

	# ── Button 各态样式（九色板：常态琥珀 / 悬停青 / 按下红 / 禁用暗）──
	theme.set_stylebox(&"normal", &"Button", _button_style(Color(0.18, 0.08, 0.06, 0.82), FURNACE_AMBER))
	theme.set_stylebox(&"hover", &"Button", _button_style(Color(0.05, 0.18, 0.22, 0.88), COMMAND_CYAN))
	theme.set_stylebox(&"pressed", &"Button", _button_style(Color(0.24, 0.05, 0.08, 0.94), DANGER_RED))
	theme.set_stylebox(&"focus", &"Button", _button_style(Color(0.05, 0.18, 0.22, 0.5), COMMAND_CYAN))
	theme.set_stylebox(&"disabled", &"Button", _button_style(Color(0.08, 0.09, 0.11, 0.7), TEXT_MUTED))
	theme.set_color(&"font_color", &"Button", TEXT_MAIN)
	theme.set_color(&"font_hover_color", &"Button", TEXT_MAIN)
	theme.set_color(&"font_pressed_color", &"Button", TEXT_MAIN)
	theme.set_color(&"font_focus_color", &"Button", TEXT_MAIN)
	theme.set_color(&"font_disabled_color", &"Button", TEXT_MUTED)

	# ── Panel / PanelContainer ──
	theme.set_stylebox(&"panel", &"Panel", _panel_style(FURNACE_AMBER, _with_alpha(DEEP_PANEL, 0.88)))
	theme.set_stylebox(&"panel", &"PanelContainer", _panel_style(FURNACE_AMBER, _with_alpha(DEEP_PANEL, 0.88)))

	# ── ProgressBar ──
	theme.set_stylebox(&"background", &"ProgressBar", _bar_bg())
	theme.set_stylebox(&"fill", &"ProgressBar", _bar_fill(FURNACE_AMBER))

	var err := ResourceSaver.save(theme, "res://assets/theme/main_theme.tres")
	print("save main_theme.tres err=", err)
	quit(0 if err == OK else 1)
