extends Node2D

const BAR_WIDTH: float = 40.0
const BAR_HEIGHT: float = 5.0
const FLASH_DURATION: float = 0.4
const DANGER_RED := Color("#ff4f6a")
const FURNACE_AMBER := Color("#ffb84d")
const COMMAND_CYAN := Color("#52e8ff")
const DEEP_PANEL := Color("#071018")

var max_hp: int
var current_hp: int
var flash_hp: int = 0
var flash_timer: float = 0.0


func setup(p_max_hp: int) -> void:
	max_hp = p_max_hp
	current_hp = p_max_hp
	visible = false
	top_level = true


func take_hit(new_hp: int) -> void:
	flash_hp = current_hp
	current_hp = new_hp
	flash_timer = 0.0
	visible = true
	queue_redraw()


func _process(delta: float) -> void:
	global_position = get_parent().global_position + Vector2(0, -40)
	if flash_timer < FLASH_DURATION:
		flash_timer += delta
		queue_redraw()
	global_rotation = 0


func _draw() -> void:
	if max_hp <= 0:
		return

	var left := -BAR_WIDTH / 2.0
	var frame_rect := Rect2(left - 1.0, -1.0, BAR_WIDTH + 2.0, BAR_HEIGHT + 2.0)
	var bar_rect := Rect2(left, 0.0, BAR_WIDTH, BAR_HEIGHT)

	draw_rect(frame_rect, Color(COMMAND_CYAN.r, COMMAND_CYAN.g, COMMAND_CYAN.b, 0.26), false, 1.0)
	draw_rect(bar_rect, Color(DEEP_PANEL.r, DEEP_PANEL.g, DEEP_PANEL.b, 0.82))

	var red_width := BAR_WIDTH * (float(current_hp) / float(max_hp))
	if red_width > 0.0:
		draw_rect(Rect2(left, 0.0, red_width, BAR_HEIGHT), DANGER_RED)

	if flash_timer < FLASH_DURATION:
		var loss := flash_hp - current_hp
		var original_flash_w := BAR_WIDTH * (float(loss) / float(max_hp))
		var progress := clampf(flash_timer / FLASH_DURATION, 0.0, 1.0)
		var current_flash_w := original_flash_w * (1.0 - progress)
		if current_flash_w > 0.0:
			draw_rect(Rect2(left + red_width, 0.0, current_flash_w, BAR_HEIGHT), Color(FURNACE_AMBER.r, FURNACE_AMBER.g, FURNACE_AMBER.b, 0.92))
