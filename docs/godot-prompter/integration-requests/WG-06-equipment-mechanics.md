# WG-06 equipment mechanic integration request

`EquipmentCatalog.get_mechanic_effects(owned_ids)` returns immutable mechanic effect Resources for the currently owned equipment. At formal-run initialization, WG-01 should pass that result plus active beacon rule keys to `Player.configure_mechanic_effects(effects, active_rule_keys)`.

Persist only equipment IDs in run saves. Role, mechanic tags, effect IDs and bridge tags are derived from the catalog on load, preserving backward compatibility for legacy item IDs.
