extends Node


const DEFAULT_QUIT_AFTER_SECONDS: float = 3.0
const CLEANUP_FRAMES: int = 8

var _target_scene_path: String = ""
var _quit_after_seconds: float = DEFAULT_QUIT_AFTER_SECONDS
var _elapsed: float = 0.0
var _target_scene: Node
var _cleanup_started: bool = false
var _cleanup_frames_left: int = CLEANUP_FRAMES


func _ready() -> void:
	_parse_args()
	if _target_scene_path.is_empty():
		push_error("HeadlessSceneRunner requires headless_runner/scene.")
		get_tree().quit(1)
		return
	var packed := load(_target_scene_path) as PackedScene
	if not packed:
		push_error("HeadlessSceneRunner could not load scene: %s" % _target_scene_path)
		get_tree().quit(1)
		return
	_target_scene = packed.instantiate()
	add_child(_target_scene)
	var target_quit_after = _target_scene.get(&"headless_runner_quit_after_seconds")
	if target_quit_after != null:
		_quit_after_seconds = maxf(_quit_after_seconds, float(target_quit_after))


func _process(delta: float) -> void:
	if _cleanup_started:
		_cleanup_frames_left -= 1
		if _cleanup_frames_left <= 0:
			get_tree().quit(0)
		return
	_elapsed += delta
	if _elapsed < _quit_after_seconds:
		return
	_cleanup_started = true
	if is_instance_valid(_target_scene):
		remove_child(_target_scene)
		_target_scene.queue_free()


func _parse_args() -> void:
	var args := OS.get_cmdline_user_args()
	args.append_array(OS.get_cmdline_args())
	for i in range(args.size()):
		match args[i]:
			"--headless-runner-scene":
				if i + 1 < args.size():
					_target_scene_path = args[i + 1]
			"--headless-runner-quit-after":
				if i + 1 < args.size():
					_quit_after_seconds = maxf(0.0, float(args[i + 1]))
