extends CanvasLayer

const BOSS_SCENES = {
	"Boss1Button": "res://scenes/gameplay/boss/BossBattle.tscn",
	"Boss2Button": "res://scenes/gameplay/boss/BossBattle_Frontier.tscn",
	"Boss3Button": "res://scenes/gameplay/boss/BossBattle_Heavy.tscn",
	"Boss4Button": "res://scenes/gameplay/boss/BossBattle_Nebula.tscn",
	"Boss5Button": "res://scenes/gameplay/boss/BossBattle_Paradise.tscn",
	"Boss6Button": "res://scenes/gameplay/boss/BossBattle_PeachBlossom.tscn",
	"Boss7Button": "res://scenes/gameplay/boss/BossBattle_Utopia.tscn",
	"Boss8Button": "res://scenes/gameplay/boss/BossBattle_Eden.tscn",
	"Boss9Button": "res://scenes/gameplay/boss/BossBattle_WarpedCore.tscn",
	"Boss10Button": "res://scenes/gameplay/boss/BossBattle_Source.tscn",
	"Boss11Button": "res://scenes/gameplay/boss/BossBattle_Spore.tscn",
	"Boss12Button": "res://scenes/gameplay/boss/BossBattle_Anti.tscn",
	"Boss13Button": "res://scenes/gameplay/boss/BossBattle_HellEye.tscn",
	"Boss14Button": "res://scenes/gameplay/boss/BossBattle_Sentry.tscn",
	"Boss15Button": "res://scenes/gameplay/boss/BossBattle_Admin.tscn",
	"Boss16Button": "res://scenes/gameplay/boss/BossBattle_Gate.tscn",
	"Boss17Button": "res://scenes/gameplay/boss/BossBattle_DivineMessenger.tscn",
	"Boss18Button": "res://scenes/gameplay/boss/BossBattle_ImitationAngel.tscn",
	"Boss19Button": "res://scenes/gameplay/boss/BossBattle_HolyBloodBrokenSword.tscn",
	"Boss20Button": "res://scenes/gameplay/boss/BossBattle_CrystalMother.tscn",
}


func _ready() -> void:
	for btn_name in BOSS_SCENES:
		get_node(btn_name).pressed.connect(_on_boss_selected.bind(BOSS_SCENES[btn_name]))
	$BackButton.pressed.connect(_on_back_pressed)


func _on_boss_selected(scene_path: String) -> void:
	GameManager.reset_run_state()
	get_tree().change_scene_to_file(scene_path)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/app/MainMenu.tscn")
