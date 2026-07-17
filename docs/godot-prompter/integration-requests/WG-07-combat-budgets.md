# WG-07 combat budget integration request

When spawning a designed enemy, WG-01 should replace direct `DesignedEnemyCatalog.ENEMIES[behavior]` access with `DesignedEnemyCatalog.get_budgeted_enemy(behavior, current_stage)`. Boss launchers should obtain their EHP/damage categories/phase count from `get_boss_budget(family, current_stage)` and apply the injected crisis modifier once.

The current catalog remains source-compatible for existing test scenes; this request avoids modifying central RunManager from WG-07.
