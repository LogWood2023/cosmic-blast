extends CanvasLayer

@onready var player_status_hud: Control = $PlayerStatusHUD
@onready var score_label: Label = $PlayerStatusHUD/ScoreLabel
@onready var score_panel: TextureRect = $PlayerStatusHUD/ScorePanel
@onready var life_bar: Node2D = $PlayerStatusHUD/LifeBar


func _process(_delta: float) -> void:
	score_label.text = "分数: %d" % GameManager.score
