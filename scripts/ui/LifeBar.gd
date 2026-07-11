extends Panel
## 玩家机体结构（HP）血条 —— 面板轨道 + ColorRect 填充（含受击残影）

const FLASH_DURATION: float = 0.4
const INSET: float = 3.0

@onready var red_bar: ColorRect = $RedBar
@onready var yellow_bar: ColorRect = $YellowBar

var _flash_hp: int = 0
var _flash_timer: float = FLASH_DURATION
var _last_hp: int = -1


func _process(delta: float) -> void:
	var hp: int = GameManager.player_hp
	var max_hp: int = maxi(1, GameManager.PLAYER_MAX_HP)
	if _last_hp < 0:
		_last_hp = hp
	if hp != _last_hp:
		if hp < _last_hp:
			_flash_hp = _last_hp
			_flash_timer = 0.0
		_last_hp = hp

	var track_w: float = maxf(0.0, size.x - INSET * 2.0)
	var ratio: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	red_bar.position.x = INSET
	red_bar.size.x = track_w * ratio

	if _flash_timer < FLASH_DURATION:
		_flash_timer += delta
		var loss: int = maxi(0, _flash_hp - hp)
		var loss_w: float = track_w * float(loss) / float(max_hp)
		var progress: float = clampf(_flash_timer / FLASH_DURATION, 0.0, 1.0)
		yellow_bar.size.x = maxf(0.0, loss_w * (1.0 - progress))
		yellow_bar.position.x = INSET + red_bar.size.x
	else:
		yellow_bar.size.x = 0.0
