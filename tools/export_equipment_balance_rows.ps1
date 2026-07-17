param(
    [string]$CatalogPath = "scripts/core/EquipmentCatalog.gd",
    [string]$OutputPath = (Join-Path $env:TEMP "cosmic_blast_equipment_balance_rows.csv")
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$invariant = [Globalization.CultureInfo]::InvariantCulture

function Map-Family([string]$raw) {
    switch ($raw) {
        "FAMILY_COLOSSUS" { return "colossus" }
        "FAMILY_PARADISE" { return "paradise" }
        "FAMILY_WARPED" { return "warped" }
        "FAMILY_HELL_EYE" { return "hell_eye" }
        "FAMILY_DIVINE" { return "divine" }
        "FAMILY_GENERAL" { return "general" }
        default { return $raw.Trim('"') }
    }
}

function Parse-Scalar([string]$raw) {
    $value = $raw.Trim().TrimEnd(',').Trim()
    if ($value -match '^\x22(.*)\x22$') { return $Matches[1] }
    return $value
}

function Clamp-Int([int]$value, [int]$minimum, [int]$maximum) {
    return [Math]::Max($minimum, [Math]::Min($maximum, $value))
}

function Format-Number([double]$value) {
    return $value.ToString("0.###", $invariant)
}

function Try-Number([object]$value, [ref]$number) {
    $parsed = 0.0
    $ok = [double]::TryParse([string]$value, [Globalization.NumberStyles]::Float, $invariant, [ref]$parsed)
    $number.Value = $parsed
    return $ok
}

function Normalize-Stats([hashtable]$stats, [string]$rarity) {
    $limits = switch ($rarity) {
        "common" { @{ atk = 1; fire = 0.92; speed = 1.08; mineral = 0.10; frenzy_gain = 1.18; frenzy_fire = 0.92; frenzy_taken = 0.92; frenzy_damage = 1.10 } }
        "rare" { @{ atk = 2; fire = 0.86; speed = 1.12; mineral = 0.14; frenzy_gain = 1.30; frenzy_fire = 0.86; frenzy_taken = 0.86; frenzy_damage = 1.20 } }
        "epic" { @{ atk = 3; fire = 0.80; speed = 1.18; mineral = 0.18; frenzy_gain = 1.45; frenzy_fire = 0.80; frenzy_taken = 0.80; frenzy_damage = 1.35 } }
        "boss" { @{ atk = 4; fire = 0.75; speed = 1.20; mineral = 0.20; frenzy_gain = 1.75; frenzy_fire = 0.68; frenzy_taken = 0.68; frenzy_damage = 1.52 } }
        default { @{ atk = 1; fire = 0.92; speed = 1.08; mineral = 0.10; frenzy_gain = 1.18; frenzy_fire = 0.92; frenzy_taken = 0.92; frenzy_damage = 1.10 } }
    }
    foreach ($key in @($stats.Keys)) {
        $number = 0.0
        if (-not (Try-Number $stats[$key] ([ref]$number))) { continue }
        switch ($key) {
            "atk_bonus" { $stats[$key] = [string][Math]::Min([int]$number, [int]$limits.atk) }
            "fire_rate_mult" { $stats[$key] = Format-Number ([Math]::Max($number, [double]$limits.fire)) }
            "speed_mult" { $stats[$key] = Format-Number ([Math]::Min($number, [double]$limits.speed)) }
            "mineral_bonus" { $stats[$key] = Format-Number ([Math]::Min($number, [double]$limits.mineral)) }
            "frenzy_gain_mult" { $stats[$key] = Format-Number ([Math]::Min($number, [double]$limits.frenzy_gain)) }
            "frenzy_fire_rate_mult" { $stats[$key] = Format-Number ([Math]::Max($number, [double]$limits.frenzy_fire)) }
            "frenzy_damage_taken_mult" { $stats[$key] = Format-Number ([Math]::Max($number, [double]$limits.frenzy_taken)) }
            "frenzy_damage_mult" { $stats[$key] = Format-Number ([Math]::Min($number, [double]$limits.frenzy_damage)) }
        }
    }
}

function Infer-Role([string]$id, [string]$family, [string]$rarity, [hashtable]$stats) {
    if ($rarity -eq "boss") { return "converter" }
    $keys = ($stats.Keys | Sort-Object) -join "|"
    $dash = $keys -match "dash_"
    $projectile = $keys -match "bullet_|homing_|gravity_"
    $drone = $keys -match "drone_"
    $frenzy = $keys -match "frenzy_"
    if (($dash -and $projectile) -or ($drone -and $frenzy) -or ($projectile -and $frenzy)) { return "bridge" }
    if ($family -eq "general") {
        if ($keys -match "mineral|heal|shield|speed|reveal|evac|risk|lifesteal|armor|coolant") { return "stabilizer" }
        return "amplifier"
    }
    if ($family -eq "colossus" -and $keys -match "dash_rebound|dash_aftershock|dash_chain|dash_mining") { return "starter" }
    if ($family -eq "paradise" -and $keys -match "bullet_split|bullet_ring|bullet_chain|bullet_pierce|bullet_charge|bullet_dot") { return "starter" }
    if ($family -eq "warped" -and $keys -match "homing_|blackhole|bullet_phase|gravity_pull") { return "starter" }
    if ($family -eq "hell_eye" -and $id -match "iris|pupil|redline|metronome|clock|last_stand") { return "starter" }
    if ($family -eq "divine" -and $keys -match "drone_behavior|drone_slots") { return "starter" }
    return "amplifier"
}

function Normalize-Price([int]$price, [string]$rarity) {
    switch ($rarity) {
        "common" { return Clamp-Int $price 50 90 }
        "rare" { return Clamp-Int $price 100 155 }
        "epic" { return Clamp-Int $price 170 220 }
        "boss" { return 0 }
        default { return Clamp-Int $price 50 90 }
    }
}

function Normalize-Compute([int]$compute, [string]$rarity) {
    switch ($rarity) {
        "common" { return Clamp-Int $compute 2 3 }
        "rare" { return Clamp-Int $compute 3 5 }
        "epic" { return Clamp-Int $compute 5 7 }
        "boss" { return Clamp-Int $compute 4 6 }
        default { return Clamp-Int $compute 2 3 }
    }
}

$weaponTargetDps = @{
    pulse_cannon = 40; twin_lance = 48; rail_spike = 52; storm_array = 50; comet_shredder = 54
    prism_volley = 55; nova_borer = 62; aurora_needler = 54; void_saw = 60; pulse_hail = 50
    ion_carbine = 50; meteor_hammer = 64; starfall_shotgun = 62; graviton_piercer = 60; solar_bloom = 66
    dusk_repeater = 55; oracle_beam = 64; ember_scythe = 58; frostline_rail = 65; drone_command_staff = 52
}
$weaponPrice = @{
    pulse_cannon = 0; twin_lance = 60; rail_spike = 70; storm_array = 75; comet_shredder = 85
    prism_volley = 100; nova_borer = 130; aurora_needler = 100; void_saw = 125; pulse_hail = 90
    ion_carbine = 65; meteor_hammer = 145; starfall_shotgun = 130; graviton_piercer = 135; solar_bloom = 155
    dusk_repeater = 90; oracle_beam = 150; ember_scythe = 115; frostline_rail = 145; drone_command_staff = 140
}
$weaponFamily = @{
    pulse_cannon = "general"; twin_lance = "general"; rail_spike = "colossus"; storm_array = "paradise"; comet_shredder = "paradise"
    prism_volley = "paradise"; nova_borer = "colossus"; aurora_needler = "hell_eye"; void_saw = "warped"; pulse_hail = "hell_eye"
    ion_carbine = "general"; meteor_hammer = "colossus"; starfall_shotgun = "paradise"; graviton_piercer = "warped"; solar_bloom = "paradise"
    dusk_repeater = "general"; oracle_beam = "divine"; ember_scythe = "hell_eye"; frostline_rail = "general"; drone_command_staff = "divine"
}
$bridgeRules = @{
    colossus_kinetic_battery = "aftershock_mass_mark"
    colossus_crash_recorder = "dash_fan_shot"
    paradise_tracer_fan = "split_inherit_homing"
    paradise_starfall_clock = "split_secondary_trigger"
    warped_tide_hook = "pulled_target_split"
    warped_event_harpoon = "gravity_well_projectile_recast"
    hell_eye_frenzy_relay = "frenzy_reset_oldest_mechanic"
    hell_eye_wound_chorus = "damage_event_to_heat"
    divine_choir_protocol = "drone_player_onhit"
    divine_companion_kernel = "drone_hit_heat"
}
$roleOverrides = @{
    divine_swarm_router = "amplifier"
    divine_remote_gunner = "amplifier"
}

$lines = Get-Content -LiteralPath $CatalogPath -Encoding UTF8
$items = New-Object System.Collections.Generic.List[object]
$section = ""
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match '^const WEAPONS') { $section = "weapon"; continue }
    if ($line -match '^const AUXILIARIES:') { $section = "aux"; continue }
    if ($line -match '^const AUXILIARY_EXPANSION_ROWS') { $section = "expansion"; continue }
    if ($section -in @("weapon", "aux") -and $line -match '^\t\x22([^\x22]+)\x22: \{$') {
        $id = $Matches[1]
        $fields = @{}
        for ($j = $i + 1; $j -lt $lines.Count; $j++) {
            if ($lines[$j] -match '^\t\},?$') { $i = $j; break }
            if ($lines[$j] -match '^\s*\x22([^\x22]+)\x22:\s*(.+),\s*$') {
                $fields[$Matches[1]] = Parse-Scalar $Matches[2]
            }
        }
        $items.Add([pscustomobject]@{ id = $id; source_type = $section; fields = $fields })
        continue
    }
    if ($section -eq "expansion" -and $line -match '^\t\{\x22id\x22:') {
        $fields = @{}
        foreach ($field in @("id", "name", "rarity", "price", "compute_cost", "description")) {
            $match = [regex]::Match($line, ('\x22' + $field + '\x22:\s*(\x22[^\x22]*\x22|[^,}]+)'))
            if ($match.Success) { $fields[$field] = Parse-Scalar $match.Groups[1].Value }
        }
        $familyMatch = [regex]::Match($line, '\x22family\x22:\s*([^,}]+)')
        if ($familyMatch.Success) { $fields.family = $familyMatch.Groups[1].Value.Trim() }
        $stats = @{}
        $statsMatch = [regex]::Match($line, '\x22stats\x22:\s*\{([^}]*)\}')
        if ($statsMatch.Success) {
            foreach ($pair in [regex]::Matches($statsMatch.Groups[1].Value, '\x22([^\x22]+)\x22:\s*(\x22[^\x22]*\x22|[^,}]+)')) {
                $stats[$pair.Groups[1].Value] = Parse-Scalar $pair.Groups[2].Value
            }
        }
        $fields.stats = $stats
        $items.Add([pscustomobject]@{ id = [string]$fields.id; source_type = "aux"; fields = $fields })
    }
}

$rows = foreach ($item in $items) {
    $id = [string]$item.id
    $fields = [hashtable]$item.fields
    $name = [string]$fields.name
    $stats = @{}
    if ($fields.ContainsKey("stats")) {
        foreach ($key in $fields.stats.Keys) { $stats[$key] = [string]$fields.stats[$key] }
    } else {
        foreach ($key in $fields.Keys) {
            if ($key -notin @("name", "type", "price", "compute_cost", "family", "rarity", "description", "icon")) {
                $stats[$key] = [string]$fields[$key]
            }
        }
    }
    if ($item.source_type -eq "weapon") {
        $price = [int]$weaponPrice[$id]
        $family = [string]$weaponFamily[$id]
        $rarity = "rare"
        if ($price -eq 0) { $rarity = "starter" }
        elseif ($price -le 90) { $rarity = "common" }
        $attack = 10 + [int]$stats.atk_bonus
        $intervalMult = [double]::Parse([string]$stats.fire_rate_mult, $invariant)
        $bulletCount = [int]$stats.bullet_count
        $targetDps = [double]$weaponTargetDps[$id]
        $projectileMult = $targetDps * 0.25 * $intervalMult / ($attack * $bulletCount)
        $stats.projectile_damage_mult = Format-Number $projectileMult
        $stats.target_single_target_dps = Format-Number $targetDps
        $statText = ($stats.Keys | Sort-Object | ForEach-Object { $_ + ":" + $stats[$_] }) -join "|"
        $attributes = "family=$family;role=main_weapon;rarity=$rarity;price=$price;stats=$statText"
        [pscustomobject][ordered]@{
            schema_version = "1.0"; domain = "equipment"; kind = "weapon"; id = $id; name = $name
            value = ""; stage_1 = ""; stage_2 = ""; stage_3 = ""; unit = "record"; data_type = "record"
            attributes = $attributes; formula = "projectile_mult=target_dps*0.25*interval_mult/((10+atk_bonus)*bullet_count)"
            notes = "Weapon single-target DPS normalized to 40-66; coverage is budgeted separately."
        }
    } else {
    $family = "general"
    if ($fields.ContainsKey("family")) { $family = Map-Family ([string]$fields.family) }
    $rarity = "common"
    if ($fields.ContainsKey("rarity")) { $rarity = [string]$fields.rarity }
    $oldPrice = 50
    if ($fields.ContainsKey("price")) { $oldPrice = [int]$fields.price }
    $oldCompute = 2
    if ($fields.ContainsKey("compute_cost")) { $oldCompute = [int]$fields.compute_cost }
    $price = Normalize-Price $oldPrice $rarity
    $compute = Normalize-Compute $oldCompute $rarity
    Normalize-Stats $stats $rarity
    $role = Infer-Role $id $family $rarity $stats
    if ($roleOverrides.ContainsKey($id)) { $role = [string]$roleOverrides[$id] }
    if ($bridgeRules.ContainsKey($id)) {
        $role = "bridge"
        $bridgeRule = [string]$bridgeRules[$id]
        $stats.bridge_rule = $bridgeRule
        $stats.proc_coefficient = if ($bridgeRule -match "fan_shot|secondary_trigger|player_onhit") { "0.35" } else { "0.5" }
    }
    $statText = ($stats.Keys | Sort-Object | ForEach-Object { $_ + ":" + $stats[$_] }) -join "|"
    $attributes = "family=$family;role=$role;rarity=$rarity;price=$price;compute=$compute;stats=$statText"
    [pscustomobject][ordered]@{
        schema_version = "1.0"; domain = "equipment"; kind = "auxiliary"; id = $id; name = $name
        value = ""; stage_1 = ""; stage_2 = ""; stage_3 = ""; unit = "record"; data_type = "record"
        attributes = $attributes; formula = "rarity_budget_clamp"
        notes = "Legacy price $oldPrice and compute $oldCompute; normalized by rarity and pure-stat caps."
    }
    }
}

$duplicates = $rows | Group-Object id | Where-Object Count -gt 1
if ($rows.Count -ne 142) { throw "Expected 142 equipment rows, got $($rows.Count)." }
if (@($duplicates).Count -ne 0) { throw "Duplicate equipment ids found." }
$rows | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8
Write-Output "equipment_rows=$($rows.Count)"
