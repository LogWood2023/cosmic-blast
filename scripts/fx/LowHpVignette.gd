extends CanvasLayer
## 低血暗角控制：按 GameManager.player_hp / PLAYER_MAX_HP 平滑驱动暗角强度。
## 恒定开销（一个全屏 ColorRect + fragment shader），不参与任何高频逐实体路径。

const APPEAR_BELOW := 0.4    # 血量降到此比例以下才开始出现
const MAX_INTENSITY := 0.85  # 濒死时的暗角上限（留余量保 HUD 可读）
const SMOOTH_SPEED := 6.0    # 强度追随速度，防血量跳变时闪烁

@onready var _rect: ColorRect = $Vignette

var _mat: ShaderMaterial
var _current: float = 0.0


func _ready() -> void:
	_mat = _rect.material as ShaderMaterial
	if _mat != null:
		_mat.set_shader_parameter(&"intensity", 0.0)


func _process(delta: float) -> void:
	if _mat == null:
		return
	var maxhp: int = GameManager.PLAYER_MAX_HP
	var ratio := clampf(float(GameManager.player_hp) / float(maxi(maxhp, 1)), 0.0, 1.0)
	var target := 0.0
	if ratio < APPEAR_BELOW:
		target = (APPEAR_BELOW - ratio) / APPEAR_BELOW * MAX_INTENSITY
	_current = lerpf(_current, target, clampf(delta * SMOOTH_SPEED, 0.0, 1.0))
	_mat.set_shader_parameter(&"intensity", _current)
