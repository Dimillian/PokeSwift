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
  `New Game -> Red's House -> Pallet Town -> Oak intro -> Oak's Lab starter choice -> first rival battle -> Route 1 -> Viridian City -> Viridian Pokecenter -> Viridian Mart parcel -> Oak parcel handoff + Pokedex -> Route 2 -> Viridian Forest corridor`, plus the first `ROUTE_22` rival trigger and the Pewter Gym Brock reward loop validated through focused runtime coverage.
- The currently extracted map set is:
  `REDS_HOUSE_2F`, `REDS_HOUSE_1F`, `PALLET_TOWN`, `ROUTE_1`, `VIRIDIAN_CITY`, `ROUTE_22`, `ROUTE_2`, `VIRIDIAN_SCHOOL_HOUSE`, `VIRIDIAN_NICKNAME_HOUSE`, `VIRIDIAN_POKECENTER`, `VIRIDIAN_MART`, `VIRIDIAN_FOREST_SOUTH_GATE`, `VIRIDIAN_FOREST`, `VIRIDIAN_FOREST_NORTH_GATE`, `PEWTER_CITY`, `PEWTER_GYM`, `OAKS_LAB`.
- The current save schema is `8`.
- The repo already has real native implementations for starter/capture naming, Pokedex browsing with persisted encounter counts, trainer/party/bag/save/options sidebars, marts, Pokecenter healing, capture, boxed overflow, blackout recovery, Brock's Boulder Badge plus `TM34` reward persistence, and telemetry-backed save/load.

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
| Maps, tilesets, and field assets | `bounded` | The early-game corridor plus `ROUTE_22`, `PEWTER_CITY`, and `PEWTER_GYM` are source-driven with real tilesets, blocksets, collision grids, warps, map connections, objects, and rendered field assets. | Expand beyond the current 17-map slice and keep map special cases out of runtime switches. |
| Field traversal and world logic | `bounded` | The runtime already supports connections, warps, doors, stairs, collisions, ledges, idle NPC walking, scripted movement, trainer LOS, object visibility, and visible pickups. | Add Red-wide traversal rules and blockers for `Cut`, `Surf`, `Strength`, `Flash`, bike gates, water travel, and late-game map mechanics. |
| Script engine and progression flags | `bounded` | Script execution already handles map triggers, dialogues, battles, movement, flags, inventory mutations, music cues, object mutations, parcel return, Pokedex handoff, Pokecenter healing, Brock's badge/TM reward branching, and the first `ROUTE_22` rival special-case scripts. | Generalize to broader story arcs, gifts, trades, fossils, Safari flows, legendary events, and late-game gates. |
| Encounters and capture | `bounded` | Grass encounters work for `ROUTE_1`, `ROUTE_2`, `ROUTE_22`, and `VIRIDIAN_FOREST`; capture uses source-style shake buckets, routes new Pokemon to party or current box, and feeds persisted encounter counts into the Pokedex lane. | Add water encounters, fishing, Safari encounters, static/story encounters, and broader trainer battle coverage. |
| Battle engine and progression | `bounded` | Trainer and wild battles already cover core damage, type effectiveness, stat stages, trainer AI shaping, EXP, StatExp, level-up learn prompts, payout, blackout, post-battle continuation, major/volatile status handling, the current GB-backed multi-turn/copy move families including Counter, Haze, Pay Day, Conversion, Bide, Thrash/Petal Dance, Teleport/forced escape, trapping, charge/Fly, Transform, Substitute, Rage, Mimic, Mirror Move, and Metronome, plus source-driven post-battle follow-up handling for Oak's Lab rival, the first `ROUTE_22` rival, and Brock. | Add battle items, broader gym/rival special battles, Red-wide trainer special cases, and deeper edge-case/manual-session parity coverage for the newly landed move families. |
| Inventory, marts, storage, persistence | `bounded` | Viridian Mart buy/sell/quit works, visible items persist, capture can overflow to boxes, and schema `8` save/load persists party, boxes, flags, blackout checkpoints, inventory, owned/seen species, species encounter counts, and normalized earned badges surfaced in the native shell; legacy saves that predate persisted play-time fields now default those values during decode so `Continue` still opens. | Add whole-game item extraction, general item use, PC deposit/withdraw/release/change-box flows, hidden items, and broader quest-item handling. |
| Native UI and shell | `bounded` | The app has real title flow, a Game Boy field/battle shell, native sidebars for trainer/Pokedex/party/bag/save/options, naming overlays, shop/healing overlays, save summary UI, Pokedex detail cards with encounter-count fields, and normalized badge shelves driven by persisted reward state. | Replace current sidebar stopgaps with fuller GB-equivalent gameplay menus where needed, add PC UI, and broaden accessibility/input settings. |
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
- General HM/TM reward plumbing beyond Brock's `TM34` plus field-move gates for `Cut`, `Surf`, `Strength`, `Flash`, and later travel mechanics.
- Red-wide badge-award flows and badge-gated map progression beyond the current Boulder Badge loop.
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
- `2026-03-14`: Closed the DIM-19 review rework on top of `origin/main@58bee867` by restoring source-driven direct interaction dialogue for the `ROUTE_22` rivals, matching the first-rival coordinate-trigger facings to `scripts/Route22.asm`, and covering both fixes with regenerated content plus focused extractor/runtime validation rerun before and after the final behavior-preserving simplification pass.
- `2026-03-14`: Landed the DIM-19 prerequisite slice for `M5` on top of the validated `M4` baseline: extractor/content/runtime/UI now cover `ROUTE_22`, `PEWTER_CITY`, and `PEWTER_GYM`; Brock's source-driven special battle awards the Boulder Badge plus `TM34`, retries the TM reward when the bag is full, and persists normalized badge reward state through save/load into the native shell; and the first post-Pokedex `ROUTE_22` rival trigger now uses extracted map scripts, trainer manifests, dialogue, and movement instead of runtime hardcoding. Revalidated with `./scripts/extract_red.sh`, focused `GameplayExtractionTests`, focused `PokeCoreTests` for Brock/Route 22/save flows, focused `PokeUITests` for badge rendering, and `./scripts/build_app.sh`, with a behavior-preserving `simplify-dirty-tree` pass rerun against the same command set.
- `2026-03-14`: Landed GB-style trainer and player send-out presentation in the native battle viewport by threading a source-driven send-out poof asset through the content pipeline, replacing the old handcrafted burst with runtime atlas composition from extracted battle tiles, and reworking the `.enemySendOut` renderer path to use slower toss timing plus staged `3/7 -> 5/7 -> full-size` reveal beats for trainer intros and replacement send-outs without changing runtime presentation stages. Revalidated with `./scripts/extract_red.sh`, `./scripts/build_app.sh`, focused `PokeUITests`, `PokeExtractCLITests`, `PokeContentTests`, and the relevant `PokeCoreTests` trainer send-out flow coverage.
- `2026-03-13`: Latest DIM-5 review rework on top of `8b68968a` fixed the last two battle-parity regressions on the move-family branch: `THRASH_PETAL_DANCE_EFFECT` now seeds the GB 2-3 continuation counter so Thrash/Petal Dance lasts 3-4 total hits before confusion, and `SWITCH_AND_TELEPORT_EFFECT` now uses the raw `enemyLevel / 4` wild-escape threshold with no artificial floor so level 1-3 opponents preserve the original zero-threshold behavior. Revalidated with focused `PokeCoreTests`, `./scripts/build_app.sh`, the full `PokeSwift-Workspace` test action, `./scripts/launch_app.sh`, and native `/health` plus `/quit` telemetry probes against the built `PokeMac.app`.
- `2026-03-13`: Latest DIM-5 rework on top of `7670f0ce` fixed the two new review regressions in the battle move-family slice: incoming damage now accumulates into `bideAccumulatedDamage` while Bide is storing energy, and multi-hit attacks now share the normal Substitute damage-routing path so doll hits do not bleed through to HP or status follow-up. Revalidated with focused `PokeCoreTests`, `./scripts/build_app.sh`, the full `PokeSwift-Workspace` test action, and a native `PokeMac` launch plus `/health` and `/quit` telemetry probes.
- `2026-03-13`: Final DIM-5 rework on top of `origin/main@ec558066` closed the newest review regressions in the battle move-family slice: battle presentation now burns enemy move-selection RNG while still reusing the peeked move for stable Counter ordering, copied `MIRROR_MOVE` and `METRONOME` executions now record their actual move metadata so `COUNTER` reacts to the real attack, and Transform snapshots now preserve the original Mimic slot so post-battle cleanup restores the correct move list. Revalidated with focused `PokeCoreTests`, `./scripts/build_app.sh`, the full `PokeSwift-Workspace` test action, and a native `PokeMac` launch plus `/health` and `/quit` telemetry probes.
- `2026-03-13`: Closed the remaining DIM-5 battle move-family parity gap on top of the merged ledger baseline by landing GB-backed `COUNTER` behavior and adding it to the existing Pay Day, Conversion, Bide, Thrash/Petal Dance, Teleport/forced escape, trapping, charge/Fly, Transform, Substitute, Rage, Mimic, Mirror Move, and Metronome handling with battle-local cleanup on switch/end. Validated with focused `PokeCoreTests`, `./scripts/build_app.sh`, the full `PokeSwift-Workspace` test action after merging `origin/main`, and a native trace-backed `PokeMac` launch.
- `2026-03-13`: Follow-up DIM-5 rework fixed the remaining review-level parity regressions in the landed move-family slice: `HAZE_EFFECT` now suppresses a cured sleep/freeze target's later move that turn, `SWITCH_AND_TELEPORT_EFFECT` now resolves success from a single RNG roll shared by text and outcome, Pay Day payouts now persist through battle input advancement, transformed Pokemon that level up in battle now keep their original-species stat/move growth after battle teardown, `COUNTER` now keys off the opponent's selected move metadata instead of copied `METRONOME`/`MIRROR_MOVE` results, and transformed learn-move prompts now surface the original move list for selection/telemetry. Revalidated with focused `PokeCoreTests`, `./scripts/build_app.sh`, the full `PokeSwift-Workspace` test action, and a native `PokeMac` launch plus `/health` and `/quit` telemetry probes.
- `2026-03-13`: Latest DIM-5 review rework on top of `origin/main@ec558066` fixed three more battle-parity regressions in the landed move-family slice: charge/Fly second turns now reuse the original PP spend, zero-power fixed-damage moves now route through damage resolution and let Substitute absorb them, and battle presentation now reuses the enemy move chosen for turn ordering so GB-style Counter sequencing stays stable across RNG-consuming player actions. Revalidated with focused `PokeCoreTests`, `./scripts/build_app.sh`, the full `PokeSwift-Workspace` test action, and a native `PokeMac` launch plus `/health` and `/quit` telemetry probes.
