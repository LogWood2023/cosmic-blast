extends Node2D
## Short lived particle burst used when projectiles disappear.

@export var particle_color: Color = Color(0.35, 0.75, 1.0, 1.0)
@export var particle_count: int = 16
@export var lifetime: float = 0.32
@export var min_speed: float = 80.0
@export var max_speed: float = 240.0
@export var min_radius: float = 1.5
@export var max_radius: float = 3.4

var _age: float = 0.0
var _particles: Array[Dictionary] = []


func setup(color: Color, count: int = 24) -> void:
	particle_color = color
	particle_count = count


func _ready() -> void:
	z_index = 1000
	z_as_relative = false
	for _i in particle_count:
		var angle := randf_range(0.0, TAU)
		var speed := randf_range(min_speed, max_speed)
		_particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"radius": randf_range(min_radius, max_radius),
			"drag": randf_range(4.0, 8.0),
		})
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	for p in _particles:
		p.pos += p.vel * delta
		p.vel = p.vel.move_toward(Vector2.ZERO, p.vel.length() * p.drag * delta)
	queue_redraw()


func _draw() -> void:
	var t := clampf(_age / maxf(lifetime, 0.001), 0.0, 1.0)
	var fade := 1.0 - t
	var glow := particle_color
	glow.a = 0.10 * fade
	draw_circle(Vector2.ZERO, 12.0 * fade, glow)

	var core := particle_color
	core.a = 0.55 * fade
	draw_circle(Vector2.ZERO, 6.0 * fade, core)

	for p in _particles:
		var col := particle_color
		col.a = 1.0 * fade
		var pos: Vector2 = p.pos
		var vel: Vector2 = p.vel
		var dir := vel.normalized()
		if dir != Vector2.ZERO:
			draw_line(pos - dir * (6.0 + 8.0 * fade), pos, col, maxf(1.0, p.radius * 0.6), true)
		draw_circle(pos, maxf(0.5, p.radius * fade), col)
