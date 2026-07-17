# Run content contract (WG-01)

`RunManager` is the authority for current-run state. Content services receive only a `RunContentContext` snapshot and return a `RunMutationSet`; they never hold, save, or modify `RunManager`.

## Stable APIs

```gdscript
prepare_choices(node_id, context, seed) -> Array[Dictionary]
resolve_choice(node_id, choice_id, context, seed) -> RunMutationSet
validate_mutation(context, mutation) -> PackedStringArray
commit_mutation(mutation) -> Dictionary
get_active_rule_snapshot() -> Dictionary
```

Each choice includes `choice_id`, `title`, `description`, `preview`, `risk`, `disabled_reason`, and `tags`, plus legacy display fields where needed.

## Context fields

`state_version`, `map_nodes`, `crisis_level`, `compute_capacity`, `minerals`, `player_hp`, inventory/equipment, and `active_rules`. All returned Dictionaries are deep copies.

## Mutation fields and errors

Required fields: `mutation_id`, `source_id`, `node_id`, and `expected_state_version`. Optional costs are `mineral_cost` and `hp_cost`; ordered actions are the only requested changes.

Stable errors: `invalid_mutation`, `stale_state_version`, `duplicate_commit`, `insufficient_minerals`, `insufficient_hp`, `unknown_action`.

Allowed declarative actions are `grant_minerals`, `heal`, `damage`, `grant_compute`, `grant_equipment`, `add_event_contract`, `activate_special_bonus`, and `add_crisis`. Existing event/reward entry points remain compatibility methods during the migration.
