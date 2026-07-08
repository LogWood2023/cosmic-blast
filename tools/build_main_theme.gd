extends SceneTree
## 生成全局 UI 主题 res://assets/theme/main_theme.tres。
## default_font = 思源黑体 Regular（消除中文系统 fallback 发布风险，不设默认字号以免撑破现有布局）。
## 两个 type variation（仅换字体、不设字号，应用点各自控制大小）：
##   DisplayTitle → 思源黑体 Bold（中文大标题加粗）
##   HudReadout   → Orbitron（数字/拉丁 HUD 读数，科技感）

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
	theme.default_font = regular

	theme.set_type_variation(&"DisplayTitle", &"Label")
	theme.set_font(&"font", &"DisplayTitle", bold)

	theme.set_type_variation(&"HudReadout", &"Label")
	theme.set_font(&"font", &"HudReadout", orbitron)

	var err := ResourceSaver.save(theme, "res://assets/theme/main_theme.tres")
	print("save main_theme.tres err=", err)
	quit(0 if err == OK else 1)
