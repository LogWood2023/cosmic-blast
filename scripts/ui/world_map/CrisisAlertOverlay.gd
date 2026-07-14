extends Control
## One-shot full-screen crisis alert shown when the player returns to the world map.

const BOSS_ICON_BY_FAMILY: Dictionary = {
	"colossus": preload("res://assets/ui/icons/boss_alert_colossus.svg"),
	"paradise": preload("res://assets/ui/icons/boss_alert_paradise.svg"),
	"warped": preload("res://assets/ui/icons/boss_alert_warped.svg"),
	"hell_eye": preload("res://assets/ui/icons/boss_alert_hell_eye.svg"),
	"divine": preload("res://assets/ui/icons/boss_alert_divine.svg"),
}
const BOSS_NAME_BY_FAMILY: Dictionary = {
	"colossus": "STAR COLOSSUS",
	"paradise": "PARADISE ENGINE",
	"warped": "WARPED CORE",
	"hell_eye": "INFERNAL SENTINEL",
	"divine": "DIVINE MESSENGER",
}
const ALERT_TOTAL_DURATION: float = 3.0
const ALERT_FADE_OUT_DURATION: float = 0.34
const ALERT_FADE_START_DELAY: float = ALERT_TOTAL_DURATION - ALERT_FADE_OUT_DURATION
const ALARM_DURATION: float = ALERT_TOTAL_DURATION
const DOUBLE_TAP_WINDOW_MSEC: int = 420

var _animation: Tween
var _flash_animation: Tween
var _alarm_player: AudioStreamPlayer
var _alarm_generator: AudioStreamGenerator
var _alarm_playback: AudioStreamGeneratorPlayback
var _alarm_time: float = 0.0
var _last_dismiss_tap_msec: int = -DOUBLE_TAP_WINDOW_MSEC
var _finish_timer: Timer

@onready var backdrop: ColorRect = $Backdrop
@onready var flash: ColorRect = $Flash
@onready var top_warning_tape: Control = $TopWarningTape
@onready var bottom_warning_tape: Control = $BottomWarningTape
@onready var center_content: Control = $CenterContent
@onready var boss_icon: TextureRect = $CenterContent/BossIcon
@onready var boss_label: Label = $CenterContent/BossLabel


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	_finish_timer = Timer.new()
	_finish_timer.one_shot = true
	_finish_timer.timeout.connect(_begin_fade_out)
	add_child(_finish_timer)
	_ensure_alarm_player()


func play_alert(family: String) -> void:
	var icon: Texture2D = BOSS_ICON_BY_FAMILY.get(family) as Texture2D
	if icon == null:
		return
	_kill_animations()
	boss_icon.texture = icon
	boss_label.text = "EXECUTOR SIGNAL  //  %s" % String(BOSS_NAME_BY_FAMILY.get(family, "UNKNOWN"))
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	top_warning_tape.call("set_active", true)
	bottom_warning_tape.call("set_active", true)
	modulate.a = 1.0
	backdrop.color.a = 0.0
	flash.color.a = 0.0
	center_content.modulate.a = 0.0
	center_content.scale = Vector2(0.16, 0.16)
	_alarm_time = 0.0
	_last_dismiss_tap_msec = -DOUBLE_TAP_WINDOW_MSEC
	_finish_timer.start(ALERT_FADE_START_DELAY)
	set_process(true)
	_start_alarm()
	_animation = create_tween()
	_animation.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_animation.set_parallel(true)
	_animation.tween_property(backdrop, "color:a", 0.84, 0.12)
	_animation.tween_property(center_content, "modulate:a", 1.0, 0.12)
	_animation.tween_property(center_content, "scale", Vector2.ONE, 0.46).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_flash_animation = create_tween()
	_flash_animation.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_flash_animation.tween_property(flash, "color:a", 0.42, 0.05)
	_flash_animation.tween_property(flash, "color:a", 0.0, 0.26)
	_flash_animation.set_loops(0)


func _process(_delta: float) -> void:
	_fill_alarm_buffer()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click or _register_dismiss_tap():
			_skip_alert()
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		if _register_dismiss_tap():
			_skip_alert()
		accept_event()


func _register_dismiss_tap() -> bool:
	var now_msec: int = Time.get_ticks_msec()
	var is_double_tap: bool = now_msec - _last_dismiss_tap_msec <= DOUBLE_TAP_WINDOW_MSEC
	_last_dismiss_tap_msec = now_msec
	return is_double_tap


func _skip_alert() -> void:
	_kill_animations()
	_finish_alert()


func _begin_fade_out() -> void:
	if not visible:
		return
	if is_instance_valid(_animation):
		_animation.kill()
	_animation = create_tween()
	_animation.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_animation.tween_property(self, "modulate:a", 0.0, ALERT_FADE_OUT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_animation.tween_callback(_finish_alert)


func _finish_alert() -> void:
	if is_instance_valid(_finish_timer):
		_finish_timer.stop()
	top_warning_tape.call("set_active", false)
	bottom_warning_tape.call("set_active", false)
	_stop_alarm()
	set_process(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	modulate.a = 1.0


func _kill_animations() -> void:
	if is_instance_valid(_animation):
		_animation.kill()
	if is_instance_valid(_flash_animation):
		_flash_animation.kill()


func _ensure_alarm_player() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_alarm_generator = AudioStreamGenerator.new()
	_alarm_generator.mix_rate = 22050.0
	_alarm_generator.buffer_length = 0.35
	_alarm_player = AudioStreamPlayer.new()
	_alarm_player.bus = &"SFX"
	_alarm_player.volume_db = -10.0
	_alarm_player.stream = _alarm_generator
	add_child(_alarm_player)


func _start_alarm() -> void:
	if not is_instance_valid(_alarm_player):
		return
	_alarm_player.play()
	_alarm_playback = _alarm_player.get_stream_playback() as AudioStreamGeneratorPlayback
	_fill_alarm_buffer()


func _stop_alarm() -> void:
	_alarm_playback = null
	if is_instance_valid(_alarm_player):
		_alarm_player.stop()


func _fill_alarm_buffer() -> void:
	if _alarm_playback == null or _alarm_generator == null:
		return
	var frames_available: int = _alarm_playback.get_frames_available()
	for _frame in frames_available:
		var sample: float = _get_alarm_sample(_alarm_time)
		_alarm_playback.push_frame(Vector2(sample, sample))
		_alarm_time += 1.0 / _alarm_generator.mix_rate


func _get_alarm_sample(time: float) -> float:
	if time >= ALARM_DURATION:
		return 0.0
	var pulse_time: float = fposmod(time, 0.34)
	if pulse_time >= 0.14:
		return 0.0
	var envelope: float = sin(PI * pulse_time / 0.14)
	var high_note: bool = fposmod(time, 0.68) >= 0.34
	var frequency: float = 1120.0 if high_note else 760.0
	return sin(TAU * frequency * time) * envelope * 0.32
