extends CanvasLayer
## Boss 血条 HUD —— 双条叠层
## 黄条在底层显示 display_hp（缓慢追赶），红条在上层显示实际 HP
## 红条盖住黄条 → 只露出右侧受伤部分，黄条自然缩短无跳动

const CATCH_SPEED: float = 200.0        # HP/s 追赶速度

var bar_full_w: float
var bar_left: float
var bar_top: float
var bar_bottom: float

var display_hp: float = -1.0            # 黄条显示的 HP，缓慢追赶当前 HP
var boss: Node

@onready var red_bar: ColorRect = $RedBar
@onready var yellow_bar: ColorRect = $FlashBar
@onready var name_label: Label = $NameLabel


func _ready() -> void:
	bar_left = red_bar.offset_left
	bar_top = red_bar.offset_top
	bar_bottom = red_bar.offset_bottom
	bar_full_w = red_bar.offset_right - bar_left
	visible = false


func _process(delta: float) -> void:
	if not is_instance_valid(boss):
		_find_boss()
		if not boss:
			visible = false
			return
		visible = true
		name_label.text = boss.boss_name
		display_hp = float(boss.boss_hp)
		_update_bars()
		return

	# 进场动画期间不显示（每帧检查）
	if not boss.active:
		visible = false
		return

	visible = true
	var current: float = float(boss.boss_hp)

	# 黄条追赶（只减不增 — Boss 不会回血）
	if display_hp > current:
		display_hp = maxf(display_hp - CATCH_SPEED * delta, current)
	else:
		display_hp = current                # 满血或回血时直接同步

	_update_bars()


func _find_boss() -> void:
	var tree := get_tree()
	if not tree:
		return
	var root_node := tree.current_scene
	if not root_node:
		return
	for child in root_node.get_children():
		if is_instance_valid(child) and child.has_method(&"apply_damage") and child.get(&"boss_hp") != null:
			boss = child
			return


func _update_bars() -> void:
	var current: float = float(boss.boss_hp)
	var max_hp: float = float(boss.max_hp)

	# 黄条（底层）：display_hp 宽度
	var yw := bar_full_w * display_hp / max_hp
	yellow_bar.offset_left = bar_left
	yellow_bar.offset_top = bar_top
	yellow_bar.offset_right = bar_left + yw
	yellow_bar.offset_bottom = bar_bottom

	# 红条（上层，盖在黄条上）：实际 HP 宽度
	var rw := bar_full_w * current / max_hp
	red_bar.offset_left = bar_left
	red_bar.offset_top = bar_top
	red_bar.offset_right = bar_left + rw
	red_bar.offset_bottom = bar_bottom
