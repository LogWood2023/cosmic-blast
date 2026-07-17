extends Node

const FAMILIES: PackedStringArray = ["星间巨构", "天堂号", "扭曲星核", "地狱之眼", "神明使者"]
const DesignedEnemyCatalog := preload("res://scripts/entities/designed_enemies/DesignedEnemyCatalog.gd")


func _ready() -> void:
	for stage in range(1, 4):
		for behavior in range(DesignedEnemyCatalog.ENEMIES.size()):
			var enemy: Dictionary = DesignedEnemyCatalog.get_budgeted_enemy(behavior, stage)
			if String(enemy.get("tier", "")) == "normal" and (int(enemy.get("ehp", 0)) < 192 or int(enemy.get("ehp", 0)) > 1754):
				_fail("Normal enemy EHP is outside the stage budget.")
				return
			if String(enemy.get("tier", "")) == "elite" and int(enemy.get("ehp", 0)) != DesignedEnemyCatalog.ELITE_EHP[stage - 1]:
				_fail("Elite EHP must match the stage budget.")
				return
			if int(enemy.get("damage", 0)) > 40:
				_fail("Enemy hits must not exceed the heavy-hit cap.")
				return
		for family in FAMILIES:
			var boss: Dictionary = DesignedEnemyCatalog.get_boss_budget(family, stage)
			var expected: int = DesignedEnemyCatalog.BOSS_EHP[stage - 1]
			if absf(float(boss.get("ehp", 0)) / float(expected) - 1.0) > 0.15:
				_fail("Boss family EHP variation exceeds 15%.")
				return
			if int(boss.get("heavy_damage", 0)) > 40 or int(boss.get("phase_count", 0)) < 2:
				_fail("Boss budget must expose phase windows and capped heavy damage.")
				return
	print("Combat budget check passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
