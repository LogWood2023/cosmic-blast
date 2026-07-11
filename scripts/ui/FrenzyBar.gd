extends Panel
## 狂热槽 —— 面板轨道 + ColorRect 填充

const INSET: float = 3.0

@onready var fill_bar: ColorRect = $FillBar


func _process(_delta: float) -> void:
	var ratio: float = clampf(GameManager.get_frenzy_ratio(), 0.0, 1.0)
	var track_w: float = maxf(0.0, size.x - INSET * 2.0)
	fill_bar.position.x = INSET
	fill_bar.size.x = track_w * ratio
	fill_bar.color = Color(1.0, 0.35, 0.12, 1.0) if GameManager.frenzy_active else Color(0.9, 0.35, 1.0, 1.0)
