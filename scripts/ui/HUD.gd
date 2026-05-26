extends CanvasLayer
## HUD —— 左上分数 + 左下 HP 血条

@onready var score_label: Label = $ScoreLabel
@onready var score_panel: TextureRect = $ScorePanel
@onready var life_bar: Node2D = $LifeBar


func _process(_delta: float) -> void:
	score_label.text = "分数: %d" % GameManager.score
