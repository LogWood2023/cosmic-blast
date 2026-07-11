extends CanvasLayer

@onready var score_label: Label = $PlayerStatusHUD/Cluster/Margin/Stack/ScoreRow/ScoreLabel
@onready var hp_value: Label = $PlayerStatusHUD/Cluster/Margin/Stack/StructRow/HpValue
@onready var frenzy_value: Label = $PlayerStatusHUD/Cluster/Margin/Stack/FrenzyRow/FrenzyValue


func _process(_delta: float) -> void:
	score_label.text = "%d" % GameManager.score
	hp_value.text = "%d / %d" % [maxi(0, GameManager.player_hp), GameManager.PLAYER_MAX_HP]
	if GameManager.frenzy_active:
		frenzy_value.text = "%.1fs" % GameManager.frenzy_timer
	else:
		var pct: int = int(round(GameManager.get_frenzy_ratio() * 100.0))
		frenzy_value.text = "就绪" if pct >= 100 else "%d%%" % pct
