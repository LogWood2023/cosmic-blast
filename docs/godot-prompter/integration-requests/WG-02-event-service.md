# WG-02 integration request

WG-02 delivers `EventService.prepare_choices(node_id, context, seed)` and `resolve_choice(node_id, choice_id, context)` without holding a `RunManager` reference.

WG-01 integration needs to:

1. Instantiate `EventService` in `RunContentFacade` and route event nodes to it after legacy compatibility checks migrate.
2. Include `current_node_id`, `completed_node_count`, `family_tags`, `seen_event_ids`, and `recent_event_families` in the read-only run-content snapshot and persist those IDs safely.
3. On a committed event mutation, append its `event_id` and family tag to the run history, then expire `add_event_contract` payloads at node completion.
4. Map `effect_type` contract payloads to future mechanic, shop, and route adapters; no Event Resource carries a Callable or script path.

The existing `procurement_discount`, `procurement_reroll_voucher`, `ore_vault`, and `sealed_armory` IDs map to the WG-02 catalog through `EventService.LEGACY_ID_MIGRATIONS`.
