# SWIFT_PORT

## Goal
- Build a fully playable, native macOS reinterpretation of Pokemon Red in Swift.
- Treat `pret/pokered` as the gameplay and content source of truth.
- Keep runtime code consuming extracted `Content/Red/**` artifacts, never source `.asm` files directly.
- Treat this file as the current ledger for shipped scope, remaining parity gaps, and milestone order.

## Non-Negotiables
- `PokeExtractCLI` is the only module that parses source assets or disassembly.
- `PokeCore` stays headless and testable.
- `PokeUI` and `PokeMac` present native SwiftUI/AppKit shells instead of emulator UI shortcuts.
- A milestone is only `done` when the intended slice is implemented and validated.

## Ownership
- `PokeExtractCLI`: extraction, normalization, deterministic runtime artifacts.
- `PokeContent`: loading and validation of extracted content.
- `PokeDataModel`: shared manifest, save, and telemetry schemas.
- `PokeCore`: gameplay simulation, progression, battle, scripts, persistence.
- `PokeRender` + `PokeUI`: field/battle rendering and native presentation.
- `PokeMac` + `PokeTelemetry`: host shell, audio/save wiring, debug/control surfaces.

## Status Model
- `done`: implemented and validated for the intended scope.
- `bounded`: real implementation exists, but it is still current-slice-only or missing Red-wide generalization.
- `missing`: no meaningful implementation yet.

## Current Baseline
- Milestones `M1`, `M2`, `M3`, and `M4` are done.
- The current validated playable slice is:
  `New Game -> Red's House -> Pallet Town -> Oak intro -> Oak's Lab starter choice -> first rival battle -> Route 1 -> Viridian City -> Viridian Pokecenter -> Viridian Mart parcel -> Oak parcel handoff + Pokedex -> Route 2 -> Viridian Forest corridor`.
- The currently extracted map set is:
  `REDS_HOUSE_2F`, `REDS_HOUSE_1F`, `PALLET_TOWN`, `ROUTE_1`, `VIRIDIAN_CITY`, `ROUTE_2`, `VIRIDIAN_SCHOOL_HOUSE`, `VIRIDIAN_NICKNAME_HOUSE`, `VIRIDIAN_POKECENTER`, `VIRIDIAN_MART`, `VIRIDIAN_FOREST_SOUTH_GATE`, `VIRIDIAN_FOREST`, `VIRIDIAN_FOREST_NORTH_GATE`, `OAKS_LAB`.
- The current save schema is `8`.
- The repo already has real native implementations for starter/capture naming, Pokedex browsing with persisted encounter counts, trainer/party/bag/save/options sidebars, marts, Pokecenter healing, capture, boxed overflow, blackout recovery, and telemetry-backed save/load.

## Validation Sources
- Extraction and contract coverage:
  `PokeExtractCLITests/GameplayExtractionTests`
  `PokeExtractCLITests/AudioExtractionTests`
  `PokeContentTests/RepoContentContractTests`
- Runtime slice coverage:
  `PokeCoreTests/OverworldAndScriptRuntimeTests`
  `PokeCoreTests/BattleRuntimeTests`
  `PokeCoreTests/AudioRuntimeTests`
  `PokeCoreTests/TitleAndSaveRuntimeTests`
  `PokeCoreTests/PokemonProgressionRuntimeTests`
- UI and render coverage:
  `PokeUITests/ShellAndSidebarTests`
  `PokeUITests/FieldViewMotionTests`
  `PokeRenderTests/FieldRenderingTests`

## System Ledger
| System | State | Shipped Now | Remaining For Full Red Parity |
| --- | --- | --- | --- |
| Extraction pipeline | `bounded` | `RedContentExtractor` already writes `game_manifest.json`, `constants.json`, `charmap.json`, `title_manifest.json`, `gameplay_manifest.json`, `audio_manifest.json`, plus copied title/field/battle assets. | Remove slice hard-coding for maps, items, marts, wild tables, trainer battles, and audio map routes. |
| Gameplay content schema | `bounded` | `GameplayManifest` already covers maps, tilesets, sprites, dialogues, field interactions, scripts, items, marts, species, moves, type chart, wild encounters, trainer AI mods, trainer battles, battle text, and player start. | Add manifest families for evolution, gifts, trades, hidden items, fishing, fossils, legendaries, and other one-off progression systems. |
| Species, moves, and Pokedex data | `done` | Full-catalog species and move extraction is already in place, including catch rates, growth rates, learnsets, cries, battle sprites, dex number, category, size, entry text, and persisted per-species encounter counts surfaced in the native Pokedex. | Keep schemas stable as more systems consume the data. |
| Maps, tilesets, and field assets | `bounded` | The early-game corridor is source-driven with real tilesets, blocksets, collision grids, warps, map connections, objects, and rendered field assets. | Expand beyond the current 14-map slice and keep map special cases out of runtime switches. |
| Field traversal and world logic | `bounded` | The runtime already supports connections, warps, doors, stairs, collisions, ledges, idle NPC walking, scripted movement, trainer LOS, object visibility, and visible pickups. | Add Red-wide traversal rules and blockers for `Cut`, `Surf`, `Strength`, `Flash`, bike gates, water travel, and late-game map mechanics. |
| Script engine and progression flags | `bounded` | Script execution already handles map triggers, dialogues, battles, movement, flags, inventory mutations, music cues, object mutations, parcel return, Pokedex handoff, and Pokecenter healing. | Generalize to broader story arcs, gifts, trades, fossils, Safari flows, legendary events, and late-game gates. |
| Encounters and capture | `bounded` | Grass encounters work for `ROUTE_1`, `ROUTE_2`, and `VIRIDIAN_FOREST`; capture uses source-style shake buckets, routes new Pokemon to party or current box, and feeds persisted encounter counts into the Pokedex lane. | Add water encounters, fishing, Safari encounters, static/story encounters, and broader trainer battle coverage. |
| Battle engine and progression | `bounded` | Trainer and wild battles already cover core damage, type effectiveness, stat stages, trainer AI shaping, EXP, StatExp, level-up learn prompts, payout, blackout, post-battle continuation, major/volatile status handling, and the current GB-backed multi-turn/copy move families including Counter, Pay Day, Conversion, Bide, Thrash/Petal Dance, Teleport/forced escape, trapping, charge/Fly, Transform, Substitute, Rage, Mimic, Mirror Move, and Metronome. | Add battle items, badge/TM reward consequences, broader special battles, Red-wide trainer special cases, and deeper edge-case/manual-session parity coverage for the newly landed move families. |
| Inventory, marts, storage, persistence | `bounded` | Viridian Mart buy/sell/quit works, visible items persist, capture can overflow to boxes, and schema `8` save/load persists party, boxes, flags, blackout checkpoints, inventory, owned/seen species, and species encounter counts. | Add whole-game item extraction, general item use, PC deposit/withdraw/release/change-box flows, hidden items, and broader quest-item handling. |
| Inventory, marts, storage, persistence | `bounded` | Viridian Mart buy/sell/quit works, visible items persist, capture can overflow to boxes, and schema `8` save/load persists party, boxes, flags, blackout checkpoints, inventory, owned/seen species, and species encounter counts; legacy saves that predate persisted play-time fields now default those values during decode so `Continue` still opens. | Add whole-game item extraction, general item use, PC deposit/withdraw/release/change-box flows, hidden items, and broader quest-item handling. |
| Native UI and shell | `bounded` | The app has real title flow, a Game Boy field/battle shell, native sidebars for trainer/Pokedex/party/bag/save/options, naming overlays, shop/healing overlays, save summary UI, and Pokedex detail cards with encounter-count fields. | Replace current sidebar stopgaps with fuller GB-equivalent gameplay menus where needed, add PC UI, and broaden accessibility/input settings. |
| Audio and telemetry | `bounded` | Extracted music and SFX, cue arbitration, cries, save/audio/healing/shop/battle telemetry, HTTP control routes, and session-event traces already exist. | Expand route coverage, late-game cue hooks, richer debug surfaces, and deeper control-server test coverage. |

## Missing Or Still-Slice-Bounded Systems
- Whole-game extractor generalization for items, marts, wild encounters, trainer battles, scripts, and audio routes.
- Evolution data + runtime + presentation.
- Player and rival naming flows beyond the current fixed default names.
- General item-use plumbing outside marts and Pokeballs.
- PC storage management UI and actions.
- Hidden items and related discovery tooling.
- Gift Pokemon, in-game trades, fossils, and legendary encounter flows.
- Fishing, water encounters, Safari rules, and other non-grass encounter families.
- HM/TM reward plumbing and field-move gates for `Cut`, `Surf`, `Strength`, `Flash`, and later travel mechanics.
- Badge-award flows and badge-gated map progression.
- Special map mechanics such as elevators, warp panels, switches, dark caves, boulder puzzles, and other dungeon-specific rules.
- Endgame flows: late gyms, Victory Road, Elite Four, Hall of Fame, and credits.

## Milestone Roadmap
| Milestone | Status | Zone Scope | Depends On |
| --- | --- | --- | --- |
| `M1` Extraction Foundation | `done` | Deterministic Red extraction, loader contracts, title-scope assets. | None. |
| `M2` Native Boot + Title | `done` | Native launch, splash, title attract, title menu, telemetry. | `M1`. |
| `M3` First Playable Slice | `done` | `REDS_HOUSE_2F -> PALLET_TOWN -> OAKS_LAB`, starter choice, first rival battle. | `M1-M2`, script runner, bounded battle loop, real field assets for the starter slice. |
| `M4` Early-Game Progression | `done` | `ROUTE_1`, `VIRIDIAN_CITY`, Pokecenter, Mart parcel loop, `ROUTE_2`, Viridian Forest corridor, generic early trainers, capture, save/load, blackout. | `M3`, bounded encounter/trainer generalization, marts, healing, capture, and persistence. |
| `M5` Pewter Badge Loop | `planned` | `ROUTE_2` north exit, `PEWTER_CITY`, Pewter interiors, `PEWTER_GYM`, `ROUTE_3`. | Generalize map/item/mart/trainer extraction beyond the current slice. Add badge + TM reward plumbing and gym-leader special battle scripting. |
| `M6` Mt. Moon To Cerulean | `planned` | `MT_MOON_*`, `ROUTE_4`, `CERULEAN_CITY`, `ROUTE_24`, `ROUTE_25`, `BILLS_HOUSE`. | Cave expansion, ladder-heavy dungeon coverage, gift/choice-item systems, broader trainer corpus, rival special cases, and Bill ticket reward flow. |
| `M7` Vermilion + Cut | `planned` | `ROUTE_5`, `ROUTE_6`, `UNDERGROUND_PATH_*`, `VERMILION_CITY`, `S.S._ANNE_*`, `ROUTE_11`, Diglett access paths. | Multi-map ship scripting, ticket/gate logic, HM reward plumbing, `Cut` field obstacles, and more town-service generalization. |
| `M8` Midgame Rocket Arc | `planned` | `ROUTE_7`, `ROUTE_8`, `ROUTE_9`, `ROUTE_10`, `ROCK_TUNNEL_*`, `LAVENDER_TOWN`, `CELADON_CITY`, `ROCKET_HIDEOUT_*`, `POKEMON_TOWER_*`. | `Flash` or dark-cave support, elevator/warp-panel/switch puzzles, coin/game-corner economy, Silph Scope and Pokeflute style story items, and wider move/status coverage. |
| `M9` Saffron + Silph Co | `planned` | `SAFFRON_CITY`, `FIGHTING_DOJO`, `SILPH_CO_*`, surrounding trainer routes and gates. | Guard/drink gate scripts, multi-floor office dungeon support, gift Pokemon, boss-trainer special cases, and Team Rocket mid/late-game story generalization. |
| `M10` Fuchsia To Cinnabar | `planned` | `ROUTE_12` to `ROUTE_21`, `FUCHSIA_CITY`, `SAFARI_ZONE_*`, `SEAFOAM_ISLANDS_*`, `CINNABAR_ISLAND`, `POKEMON_MANSION_*`. | Bike progression, fishing + Surf/water encounters, Safari rules, `Strength`, mansion key/door puzzles, and fossil revival. |
| `M11` Endgame + Credits | `planned` | `VIRIDIAN_GYM`, `ROUTE_22`, `ROUTE_23`, `VICTORY_ROAD_*`, `INDIGO_PLATEAU`, Hall of Fame, credits. | Full badge-gate enforcement, late-gym and Elite Four trainer coverage, final dungeon mechanics, Hall of Fame persistence, and ending flow. |

## Zone Expansion Order
| Wave | Zones To Add Together | Why They Belong Together | New Systems That Must Exist First |
| --- | --- | --- | --- |
| `Z1` | `ROUTE_22`, `PEWTER_CITY`, `PEWTER_GYM`, `ROUTE_3` | This is the first post-Viridian badge loop and the smallest meaningful step beyond the current slice. | Full trainer extraction beyond the current slice, gym-leader special battle scripting, badge awards, TM rewards, expanded marts/items/maps, and the first non-current-slice rival special case. |
| `Z2` | `MT_MOON_*`, `ROUTE_4`, `CERULEAN_CITY`, `ROUTE_24`, `ROUTE_25`, `BILLS_HOUSE` | Mt. Moon and Cerulean are one progression arc with dense trainer coverage and early story rewards. | Cave/dungeon generalization, ladder-heavy map support, wider trainer-party extraction, gift and choice-item flows, and Bill ticket/story reward scripting. |
| `Z3` | `ROUTE_5`, `ROUTE_6`, `UNDERGROUND_PATH_*`, `VERMILION_CITY`, `S.S._ANNE_*`, `ROUTE_11`, `DIGLETTS_CAVE` access routes | This is the first HM-driven city cluster and the first large multi-map vehicle/ship story sequence. | Ticket/gate scripting, multi-floor ship progression, broader quest-item handling, HM reward plumbing, `Cut` field blockers, and more generalized town-service scripts. |
| `Z4` | `VERMILION_GYM`, `ROUTE_9`, `ROUTE_10`, `ROCK_TUNNEL_*`, `LAVENDER_TOWN` | This wave adds the next badge plus the first dark-cave traversal corridor. | Badge-gate progression, the first switch-puzzle implementation for Vermilion Gym, dark-cave or `Flash` handling, longer dungeon traversal rules, and more complete move/status coverage for the growing trainer roster. |
| `Z5` | `CELADON_CITY`, `GAME_CORNER`, `ROCKET_HIDEOUT_*` | Celadon and Rocket Hideout are tightly linked through coin economy, hideout puzzles, and Silph Scope progression. | Coin/game-corner economy, elevator/spinner/puzzle support, hideout key progression, and stronger story-item scripting. |
| `Z6` | `POKEMON_TOWER_*`, `SAFFRON_CITY`, `FIGHTING_DOJO`, `SILPH_CO_*` | The midgame Rocket arc spans Lavender and Saffron and needs the same story-item and multi-floor-office support. | Pokeflute/Silph Scope gating, gift Pokemon flows, guard/drink gate logic, multi-floor office/dungeon support, and more special-case boss trainer scripting. |
| `Z7` | `ROUTES_12_15`, `FUCHSIA_CITY`, `SAFARI_ZONE_*`, `ROUTES_16_18` | Fuchsia is the point where bike, Safari, fishing, and several new encounter systems all become mandatory. | Bike gates, fishing, water encounter tables, Safari rules, hidden items, wider item-use support, and `Strength` reward/setup work. |
| `Z8` | `SEAFOAM_ISLANDS_*`, `CINNABAR_ISLAND`, `POKEMON_MANSION_*` | This wave combines Surf-heavy travel, boulder puzzles, mansion keys, and fossil revival. | `Surf`, `Strength`, water-route traversal, dungeon puzzle mechanics, key/door puzzle state, and fossil/lab revival systems. |
| `Z9` | `VIRIDIAN_GYM`, late `ROUTE_22`, `ROUTE_23`, `VICTORY_ROAD_*`, `INDIGO_PLATEAU` | The endgame is one badge-gated corridor with late-gym, final rival, Elite Four, and ending persistence. | Full badge enforcement, late-gym scripting, Victory Road dungeon mechanics, Elite Four sequencing, Hall of Fame persistence, and credits/end-state flow. |

## Ordering Notes
- Expand the world in the order above so every new zone wave is blocked by a small, explicit set of systems instead of a vague "full parity later" bucket.
- `M7` intentionally stops short of `VERMILION_GYM`: the ship/Cut unlock can land before the first switch-puzzle implementation, so the city/harbor content and the badge fight are split on purpose.
- Do not add late-game zones before the dependency system for that zone exists in extracted content, runtime, and UI.
- When a milestone changes status, or a new dependency appears, update this file in the same change set.

## Latest Update
- `2026-03-13`: Closed the remaining DIM-5 battle move-family parity gap on top of the merged ledger baseline by landing GB-backed `COUNTER` behavior and adding it to the existing Pay Day, Conversion, Bide, Thrash/Petal Dance, Teleport/forced escape, trapping, charge/Fly, Transform, Substitute, Rage, Mimic, Mirror Move, and Metronome handling with battle-local cleanup on switch/end. Validated with focused `PokeCoreTests`, `./scripts/build_app.sh`, the full `PokeSwift-Workspace` test action after merging `origin/main`, and a native trace-backed `PokeMac` launch.
