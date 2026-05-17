extends CanvasLayer

const BOSS_SCENES = {
	"Boss1Button": "res://scenes/BossBattle.tscn",
	"Boss2Button": "res://scenes/BossBattle_Frontier.tscn",
	"Boss3Button": "res://scenes/BossBattle_Heavy.tscn",
	"Boss4Button": "res://scenes/BossBattle_Nebula.tscn",
	"Boss5Button": "res://scenes/BossBattle_Paradise.tscn",
	"Boss6Button": "res://scenes/BossBattle_PeachBlossom.tscn",
	"Boss7Button": "res://scenes/BossBattle_Utopia.tscn",
	"Boss8Button": "res://scenes/BossBattle_Eden.tscn",
	"Boss9Button": "res://scenes/BossBattle_WarpedCore.tscn",
	"Boss10Button": "res://scenes/BossBattle_Source.tscn",
	"Boss11Button": "res://scenes/BossBattle_Spore.tscn",
	"Boss12Button": "res://scenes/BossBattle_Anti.tscn",
	"Boss13Button": "res://scenes/BossBattle_HellEye.tscn",
	"Boss14Button": "res://scenes/BossBattle_Sentry.tscn",
	"Boss15Button": "res://scenes/BossBattle_Admin.tscn",
	"Boss16Button": "res://scenes/BossBattle_Gate.tscn",
	"Boss17Button": "res://scenes/BossBattle_DivineMessenger.tscn",
}


func _ready() -> void:
	for btn_name in BOSS_SCENES:
		get_node(btn_name).pressed.connect(_on_boss_selected.bind(BOSS_SCENES[btn_name]))
	$BackButton.pressed.connect(_on_back_pressed)


func _on_boss_selected(scene_path: String) -> void:
	GameManager.score = 0
	GameManager.player_hp = GameManager.PLAYER_MAX_HP
	GameManager.elapsed = 0.0
	get_tree().change_scene_to_file(scene_path)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
