extends Node
## 全局游戏管理器（Autoload 单例）

var score: int = 0
var player_hp: int = 100
const PLAYER_MAX_HP: int = 100
var elapsed: float = 0.0

var bgm_player: AudioStreamPlayer
const BGM = preload("res://assets/audio/bgm.mp3")

# 吸力（技能4）
var suction_active: bool = false
var suction_center: Vector2 = Vector2.ZERO
var controls_inverted: bool = false

# 测试功能：游戏场景缩放（正式版移除）
var test_scale_enabled: bool = false
var test_scale_factor: float = 1.0 / 3.0


func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	bgm_player.stream = BGM
	bgm_player.play()
	bgm_player.finished.connect(bgm_player.play)


func _process(delta: float) -> void:
	elapsed += delta


func add_score(amount: int) -> void:
	score += amount


func difficulty() -> float:
	return clampf(elapsed / 180.0, 0.0, 1.0)
