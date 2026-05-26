extends Node2D

const SPACE_ROCK_SCENE = preload("res://scenes/gameplay/explore/SpaceRock.tscn")
const ISOLATION_BAND_SCENE = preload("res://scenes/gameplay/explore/IsolationBand.tscn")
const SPACE_CLUTTER_SCENE = preload("res://scenes/gameplay/explore/SpaceClutter.tscn")
const EXPLORE_REWARD_SCENE = preload("res://scenes/gameplay/explore/ExploreReward.tscn")


func _ready() -> void:
	_spawn_space_rocks()
	_spawn_isolation_band()
	_spawn_clutter()
	_spawn_rewards()


func _spawn_space_rocks() -> void:
	var large := SPACE_ROCK_SCENE.instantiate()
	large.name = "TestLargeSpaceRock"
	large.position = Vector2(960, 430)
	large.radius = 145.0
	large.use_simple_collision = true
	add_child(large)
	var small := SPACE_ROCK_SCENE.instantiate()
	small.name = "TestSmallSpaceRock"
	small.position = Vector2(1220, 610)
	small.radius = 48.0
	small.use_simple_collision = true
	add_child(small)


func _spawn_isolation_band() -> void:
	var band = ISOLATION_BAND_SCENE.instantiate()
	band.name = "TestIsolationBand"
	band.setup(Vector2(560, 600), Vector2(840, 600), 80.0)
	add_child(band)


func _spawn_clutter() -> void:
	for i in range(3):
		var clutter = SPACE_CLUTTER_SCENE.instantiate()
		clutter.name = "TestClutter%d" % i
		clutter.position = Vector2(1080 + i * 90, 310 + i * 70)
		add_child(clutter)
		clutter.setup(null)


func _spawn_rewards() -> void:
	var chest = EXPLORE_REWARD_SCENE.instantiate()
	chest.name = "TestChest"
	chest.position = Vector2(760, 360)
	add_child(chest)
	chest.setup(0)
	var ore = EXPLORE_REWARD_SCENE.instantiate()
	ore.name = "TestOreVein"
	ore.position = Vector2(1340, 470)
	add_child(ore)
	ore.setup(1)
