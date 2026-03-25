# Radar

A Warhammer 40,000: Darktide mod that displays teammates, selected enemies, pickups, objective items, materials, and event items on a configurable 2D radar.

This README replaces the current one-line project stub, which only states that the mod displays items and special enemy targets on a configurable radar.
## Feature overview

### Core radar
- Draws a live radar overlay on the HUD during gameplay.
- Supports **square** and **circle** radar styles.
- Supports configurable **radar size**, **range**, and **maximum marker count**.
- Can optionally **scale marker icon size with radar size**.
- Uses the local player as the radar center and projects nearby targets into a top-down 2D view.
- Sorts targets by distance and only keeps the nearest configured number of markers.

### Marker types
- **Teammates** with class-specific icons and player-slot colors.
- **High-priority enemies**:
    - Daemonhost
    - Monstrosities
    - Captains
    - Karnak Twins
- **Common pickups**:
    - Ammo tin
    - Ammo stash
    - Grenades
    - Crates
    - Pocketable ammo crates
    - Pocketable medical crates
    - Standard stimms
- **Collectable materials**:
    - Plasteel
    - Diamantine
    - Expedition salvage
    - Expedition tech-remnants
    - Dropped expedition loot
- **Primary objective items** such as power cells, cryonic rods, vacuum capsules, special issue ammo, prismata cases, mortis relics, and coordinates.
- **Secondary objective items** such as grimoires and scriptures.
- **Expeditions items** such as data reliquaries, mines, void shield, airstrike/artillery/hover markers, large ammunition crates, anti-rad stimm, and promethium barrels.
- **Event items** such as tainted skulls, saints relics, stolen rations, and corrupted auspex scanners.
- **Unknown pickups**, useful while expanding coverage and debugging missing mappings.

### Presentation features
- Separate display styles for **enemies** and **players**:
    - `Icon only`
    - `Marked icon`
- Colored center dot based on the local player slot HUD color.
- Per-kind icon materials and colors for most tracked radar targets.
- Safe fallback to an unknown icon when no specific presentation is available.

### Runtime behavior
- Only runs in supported gameplay states.
- Intentionally avoids hub, menu, loading, and most non-mission states.
- Prunes stale or dead tracked units automatically.
- Includes optional debug logging for classification and draw issues.

## Installation

This README assumes you already have a working Darktide mod setup.

1. Copy the `Radar` folder into your Darktide `mods` directory.
2. Add or enable the mod in your usual Darktide mod load order.
3. Start the game.
4. Open the mod options menu and configure `Radar`.

## Configuration

### General
- **Enable radar**: Master on/off switch.
- **Radar size**: Controls the overall widget size.
- **Radar range / filter distance**: Maximum horizontal distance for visible targets.
- **Highlight distance**: Reserved for close-range emphasis logic and future polish.
- **Max radar markers**: Caps the number of visible markers.
- **Scale icons with radar size**: Scales marker icons when radar size changes.
- **Radar style**: Square or circle frame.
- **Enemy marker style**: Icon only or marked icon.
- **Player marker style**: Icon only or marked icon.

### Item filters
The mod exposes per-category toggles for the major tracked item families:
- Common pickups
- Collectable materials
- Primary objective items
- Secondary objective items
- Expeditions-specific items
- Martyr's Skull items
- Deployables
- Event-related items
- Unknown pickups

### Entity filters
- **Monstrosities**
- **Captains**
- **Karnak Twins**
- **Teammates**

## Known limitations

- World-marker classification is currently broader than interactee classification. Some items seen only through `HudElementWorldMarkers` may still be grouped into generic ammo, grenade, medkit, or stimm buckets rather than the most specific toggle.
- Some setting names and runtime kind mappings are still in transition. The documentation below reflects the intended feature set, but the current code still contains older generic mappings such as `pickup_ammo`, `pickup_medkit`, and `pickup_stimm`.
- Radar position is currently hardcoded in code rather than exposed in the options menu.
- The radar is 2D and horizontal only. Height differences are ignored.
- Only selected enemy categories are tracked. Regular elites, specials, and hordes are intentionally not shown.
- Icon availability depends on the referenced game UI materials being loaded successfully.
- Unknown world-marker templates are not yet fully covered by a clean data-driven fallback in the current attached build.

## Technical overview

The mod has two main parts.

### 1. Runtime collection and classification, `Radar.lua`
`Radar.lua` is responsible for discovering trackable targets and turning them into radar kinds.

It currently gathers targets from several sources:
- **Interactee system** for standard pickups and objective items.
- **Chest system** for unopened crates.
- **Unit data system** for selected enemy breeds.
- **Player manager** for teammates.
- **World marker hook** for some additional generic marker types.

Tracked targets are stored in an internal unit table with:
- kind
- source
- last seen time
- current position
- optional metadata

The update loop runs on a scan interval, refreshes tracked units, removes stale entries, filters by range, sorts by distance, applies the configured marker cap, and builds a snapshot for rendering.

### 2. HUD rendering, `ui/hud_element_radar_debug.lua`
The HUD element reads the latest radar snapshot and draws the overlay.

Important details:
- The radar frame is drawn procedurally, not from custom texture files.
- Marker icons are rendered through UI widgets using material paths.
- Player markers use class icons plus player-slot colors.
- Enemy and player markers can optionally draw bracket corners for the `marked icon` style.
- If a marker kind has no dedicated presentation, the HUD falls back to either the source interaction icon or the generic unknown icon.

### Projection logic
The mod projects each target from world space into a local 2D radar coordinate system:
- target position is compared against player position
- only horizontal X/Y distance is used
- the target vector is rotated into the player's facing basis
- the result is scaled into the radar radius based on configured radar range

## Visual asset checklist

This checklist mixes **currently referenced in-game materials** and **recommended custom assets** for future polish. Status values are meant to make planning easier:
- **existing** = already referenced by the current build
- **missing** = recommended but not yet present as a dedicated asset
- **needs update** = exists, but may deserve a better custom replacement or clearer naming

### Radar UI images

| Asset purpose | Suggested file name | Expected path | Current reference / note | Status |
|---|---|---|---|---|
| Square radar background | `radar_bg_square` | `Radar/content/ui/materials/radar/radar_bg_square` | Current build draws background procedurally | missing |
| Circle radar background | `radar_bg_circle` | `Radar/content/ui/materials/radar/radar_bg_circle` | Current build draws background procedurally | missing |
| Square radar frame | `radar_frame_square` | `Radar/content/ui/materials/radar/radar_frame_square` | Current build draws border procedurally | missing |
| Circle radar frame | `radar_frame_circle` | `Radar/content/ui/materials/radar/radar_frame_circle` | Current build draws border procedurally | missing |
| Center dot | `radar_center_dot` | `Radar/content/ui/materials/radar/radar_center_dot` | Current build draws a small colored rect | missing |
| Marker brackets / corners | `radar_marker_brackets` | `Radar/content/ui/materials/radar/radar_marker_brackets` | Current build draws brackets procedurally | missing |

### Enemy icons

| Asset purpose | Suggested file name | Expected path | Current reference / note | Status |
|---|---|---|---|---|
| Daemonhost | `enemy_daemonhost` | `content/ui/materials/icons/circumstances/havoc/havoc_mutator_heinous_rituals` | Current material in use | existing |
| Monstrosity | `enemy_monstrosity` | `content/ui/materials/icons/presets/preset_05` | Generic preset icon, could be replaced with a clearer dedicated one | needs update |
| Captain | `enemy_captain` | `content/ui/materials/icons/circumstances/havoc/havoc_mutator_fading_light_1` | Current material in use | existing |
| Karnak Twin | `enemy_karnak_twin` | `content/ui/materials/icons/circumstances/havoc/havoc_mutator_fading_light_2` | Current material in use | existing |
| Generic enemy fallback | `enemy_unknown` | `Radar/content/ui/materials/radar/enemy_unknown` | No dedicated generic enemy fallback asset yet | missing |

### Pocketables and deployables

| Asset purpose | Suggested file name | Expected path | Current reference / note | Status |
|---|---|---|---|---|
| Ammo crate, pocketable | `party_ammo_crate` | `content/ui/materials/icons/pocketables/hud/small/party_ammo_crate` | Current material in use | existing |
| Medical crate, pocketable | `party_medic_crate` | `content/ui/materials/icons/pocketables/hud/small/party_medic_crate` | Current material in use | existing |
| Concentration stimm | `party_syringe_ability` | `content/ui/materials/icons/pocketables/hud/small/party_syringe_ability` | Current material in use | existing |
| Med stimm | `party_syringe_corruption` | `content/ui/materials/icons/pocketables/hud/small/party_syringe_corruption` | Current material in use | existing |
| Combat stimm | `party_syringe_power` | `content/ui/materials/icons/pocketables/hud/small/party_syringe_power` | Current material in use | existing |
| Celerity stimm | `party_syringe_speed` | `content/ui/materials/icons/pocketables/hud/small/party_syringe_speed` | Current material in use | existing |
| Anti-rad stimm | `time_syringe` | `content/ui/materials/hud/interactions/icons/time_syringe` | Current material in use | existing |
| Void shield | `void_shield` | `content/ui/materials/icons/pocketables/hud/void_shield` | Current material in use | existing |
| Airstrike marker | `valkyrie_payload` | `content/ui/materials/hud/interactions/icons/valkyrie_payload` | Current material in use | existing |
| Artillery strike marker | `artillery_strike` | `content/ui/materials/hud/interactions/icons/artillery_strike` | Current material in use | existing |
| Big grenade | `big_fn_grenade` | `content/ui/materials/hud/interactions/icons/big_fn_grenade` | Current material in use | existing |
| Valkyrie hover marker | `valkyrie_hover` | `content/ui/materials/hud/interactions/icons/valkyrie_hover` | Current material in use | existing |
| Explosive mine | `landmine_explosive` | `content/ui/materials/hud/interactions/icons/landmine_explosive` | Current material in use | existing |
| Fire mine | `landmine_fire` | `content/ui/materials/hud/interactions/icons/landmine_fire` | Current material in use | existing |
| Shock mine | `landmine_shock` | `content/ui/materials/hud/interactions/icons/landmine_shock` | Current material in use | existing |
| Large ammunition crate | `pocketable_ammo_large` | `content/ui/materials/hud/interactions/icons/pocketable_ammo` | Current material in use | existing |
| Deployable ammo crate | `deployable_ammo_crate` | `content/ui/materials/hud/interactions/icons/pocketable_ammo` | Shares ammo icon today | needs update |
| Deployable medical crate | `deployable_medical_crate` | `content/ui/materials/hud/interactions/icons/pocketable_medkit` | Shares medkit icon today | needs update |
| Corrupted auspex scanner | `auspex_scanner` | `content/ui/materials/icons/pocketables/hud/auspex_scanner` | Current material in use | existing |

### Collectables, materials, objective items, and event items

| Asset purpose | Suggested file name | Expected path | Current reference / note | Status |
|---|---|---|---|---|
| Ammo tin | `ammunition` | `content/ui/materials/hud/interactions/icons/ammunition` | Current material in use | existing |
| Ammo stash | `ammo_stash` | `content/ui/materials/icons/presets/preset_16` | Generic preset icon | needs update |
| Grenade pickup | `grenade` | `content/ui/materials/hud/interactions/icons/grenade` | Current material in use | existing |
| Unknown crate | `crate_unknown` | `content/ui/materials/icons/generic/loot` | Current material in use | existing |
| Plasteel | `plasteel_big` | `content/ui/materials/icons/currencies/plasteel_big` | Current material in use | existing |
| Diamantine | `diamantine_big` | `content/ui/materials/icons/currencies/diamantine_big` | Current material in use | existing |
| Expedition currency / salvage | `salvage_big` | `content/ui/materials/icons/currencies/salvage_big` | Current material in use | existing |
| Expedition loot / tech-remnants | `tech_remnant_big` | `content/ui/materials/icons/currencies/tech_remnant_big` | Current material in use | existing |
| Expedition dropped loot | `tech_dropped` | `content/ui/materials/icons/notifications/tech_dropped` | Current material in use | existing |
| Coordinates paper | `coordinates_paper` | `content/ui/materials/icons/system/escape/credits` | Placeholder-like icon today | needs update |
| Data reliquary | `data_reliquary` | `content/ui/materials/icons/player_states/lugged` | Uses generic luggable icon today | needs update |
| Power cell, teal | `power_cell_teal` | `content/ui/materials/icons/player_states/lugged` | Uses generic luggable icon today | needs update |
| Power cell, orange | `power_cell_orange` | `content/ui/materials/icons/player_states/lugged` | Uses generic luggable icon today | needs update |
| Cryonic rod | `cryonic_rod` | `content/ui/materials/icons/player_states/lugged` | Uses generic luggable icon today | needs update |
| Moebian Pox Zetaphyte-13 Sample | `pox_sample` | `content/ui/materials/icons/player_states/lugged` | Uses generic luggable icon today | needs update |
| Vacuum capsule | `vacuum_capsule` | `content/ui/materials/icons/player_states/lugged` | Uses generic luggable icon today | needs update |
| Special issue ammo | `special_issue_ammo` | `content/ui/materials/icons/player_states/lugged` | Uses generic luggable icon today | needs update |
| Prismata Crystal Repository | `prismata_crystal_repository` | `content/ui/materials/icons/player_states/lugged` | Uses generic luggable icon today | needs update |
| Promethium barrel | `promethium_barrel` | `content/ui/materials/hud/interactions/icons/barrel_explosive` | Current material in use | existing |
| Mortis relic | `mortis_relic` | `content/ui/materials/icons/item_types/devices` | Generic device icon | needs update |
| Martyr's Skull | `martyr_skull` | `content/ui/materials/hud/interactions/icons/enemy` | Placeholder-like icon today | needs update |
| Tainted skull | `tainted_skull` | `content/ui/materials/hud/interactions/icons/enemy` | Placeholder-like icon today | needs update |
| Saints relic | `saints_relic` | `content/ui/materials/icons/circumstances/live_event_01` | Current material in use | existing |
| Stolen rations | `stolen_rations` | `content/ui/materials/icons/pickups/default` | Generic pickup icon | needs update |
| Grimoire | `party_grimoire` | `content/ui/materials/icons/pocketables/hud/small/party_grimoire` | Current material in use | existing |
| Scripture | `party_scripture` | `content/ui/materials/icons/pocketables/hud/small/party_scripture` | Current material in use | existing |

### Player class icons

| Asset purpose | Suggested file name | Expected path | Current reference / note | Status |
|---|---|---|---|---|
| Veteran | `veteran` | `content/ui/materials/icons/classes/veteran` | Current material in use | existing |
| Zealot | `zealot` | `content/ui/materials/icons/classes/zealot` | Current material in use | existing |
| Psyker | `psyker` | `content/ui/materials/icons/classes/psyker` | Current material in use | existing |
| Ogryn | `ogryn` | `content/ui/materials/icons/classes/ogryn` | Current material in use | existing |
| Adamant | `adamant` | `content/ui/materials/icons/classes/adamant` | Current material in use for non-standard archetype support | existing |
| Broker | `broker` | `content/ui/materials/icons/classes/broker` | Current material in use for non-standard archetype support | existing |
| Unknown class fallback | `player_unknown` | `content/ui/materials/icons/pickups/default` | Current fallback in use when no class icon resolves | existing |

### Fallback and debug visuals

| Asset purpose | Suggested file name | Expected path | Current reference / note | Status |
|---|---|---|---|---|
| Unknown pickup fallback | `pickup_unknown` | `content/ui/materials/icons/traits/empty` | Current fallback icon in use | existing |
| Generic pickup fallback | `pickup_default` | `content/ui/materials/icons/pickups/default` | Used in some fallback paths | existing |
| Debug placeholder box | `debug_placeholder` | `Radar/content/ui/materials/radar/debug_placeholder` | Current build falls back to drawing a colored box, not a texture | missing |

## Recommended next documentation updates

After the mapping cleanup is finished, this README should be updated in three places:
- replace the current world-marker limitation with the final data-driven classification behavior
- document the exact unknown-template fallback rules
- update the asset checklist statuses for any custom radar art you decide to add
