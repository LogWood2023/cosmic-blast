extends Node2D
## 玩家 HP 血条 —— ColorRect 节点

const FLASH_DURATION: float = 0.4

var full_width: float
var flash_hp: int = 100
var flash_timer: float = 0.0
var last_hp: int = 100

@onready var red_bar: ColorRect = $RedBar
@onready var yellow_bar: ColorRect = $YellowBar


func _ready() -> void:
	full_width = red_bar.size.x
	_update_red_bar()


func _process(delta: float) -> void:
	var hp = GameManager.player_hp
	if hp != last_hp:
		take_hit(hp)
		last_hp = hp

	if flash_timer < FLASH_DURATION:
		flash_timer += delta
		_update_yellow_bar()


func take_hit(_new_hp: int) -> void:
	flash_hp = last_hp
	flash_timer = 0.0
	_update_red_bar()
	_update_yellow_bar()


func _update_red_bar() -> void:
	red_bar.size.x = full_width * float(GameManager.player_hp) / float(GameManager.PLAYER_MAX_HP)


func _update_yellow_bar() -> void:
	var loss = flash_hp - GameManager.player_hp
	if loss <= 0 or flash_timer >= FLASH_DURATION:
		yellow_bar.size.x = 0
		return
	var original_w = full_width * float(loss) / float(GameManager.PLAYER_MAX_HP)
	var progress = clampf(flash_timer / FLASH_DURATION, 0.0, 1.0)
	yellow_bar.size.x = original_w * (1.0 - progress)
	yellow_bar.position.x = red_bar.position.x + red_bar.size.x
