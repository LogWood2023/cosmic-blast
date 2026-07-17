# WG-03 integration request

WG-03 exposes `RewardService.prepare_choices`, `prepare_boss_choices`, and `resolve_choice`. It reads only `RunContentContext` plus the legacy catalog's read-only query methods.

WG-01 must wire normal reward nodes and Boss completions to the service, persist `active_rules.reward_protection`, and apply `mutation.metadata.reward_protection` only after a successful commit. The snapshot needs current equipment IDs, compute capacity, active family tags, distance to Boss, and the three dry-streak counters.

WG-06 should replace `RewardService._role_for_item` with its frozen equipment role query. The temporary mapping is explicit: weapons/common items are starters; remaining non-Boss items are amplifiers.

The four Boss choices include a maintenance card whose mutation adds a two-node `boss_maintenance_equipment_weight` contract. WG-01 must consume that contract in the next two reward drafts.
