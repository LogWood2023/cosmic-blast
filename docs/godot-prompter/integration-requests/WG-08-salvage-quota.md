# WG-08 salvage quota integration request

`ExploreRoom` should own one `SalvageQuotaController`. Register stable value when creating chests, mineral veins, elite caches and special objectives; call `collect_value` only when the corresponding reward is collected/destroyed, never from patrol enemy deaths. Bind its signals to the existing objectives HUD and disable evacuation completion until `evacuation_is_unlocked`.

The controller intentionally has no dependency on `ExploreRoom`, HUD, or `RunManager`, so it can be tested and reused without changing existing generation logic.
