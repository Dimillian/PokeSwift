# SWIFT_PORT

## Vision
Build a fully playable, native macOS reinterpretation of Pokemon Red in Swift, using the `pret/pokered` disassembly in this repository as the source of truth for game data, scripted behavior, rules, and content coverage.

The port target is not "run the ROM." The target is:

- a native macOS app with a Swift engine and native UI shell
- deterministic content extracted from the disassembly into tracked runtime artifacts
- a headless, testable simulation core that can be validated independently of rendering
- a telemetry and automation surface that supports stable smoke validation plus high-signal manual-session debugging

## Non-Goals

- No runtime parsing of `.asm` files from the app process
- No ROM-emulator dependency for normal app execution
- No Blue support in Milestones 1-2
- No public distribution assumptions; legal/distribution questions are separate from engineering scope
- No "UI first" implementation that outruns engine and content parity
- No milestone is considered done based only on code presence or compile success

## Governance

- This file is the master engineering ledger for the Swift port.
- Any milestone, PR, or agent task that changes scope, completes work, or uncovers a blocker must update this file in the same change.
- The disassembly remains the canonical gameplay/content source of truth.
- Runtime code must consume extracted artifacts, not ad hoc repo parsing.
- "Done" means implementation plus successful validation against the milestone acceptance criteria.

## Status Legend

- `not started`
- `in progress`
- `blocked`
- `done`

## Current Milestone

### Active Scope

- `M1`: Red extraction foundation
- `M2`: Native macOS boot, splash, title attract, title menu, telemetry, and validation harness
- `M3`: First playable slice from `New Game` to the first rival battle in Oak's Lab
- `M4A`: Real GB-style field rendering for the current M3 slice

### Current State Summary

Milestones `M1`, `M2`, `M3`, and `M4A` remain complete as of `2026-03-11`.

The repo now contains:

- Tuist manifests
- the planned Swift module layout
- a working Red extraction CLI and committed `Content/Red` artifacts
- a native macOS app that reaches `launch -> splash -> titleAttract -> titleMenu`
- telemetry and harness targets with working build, launch, input, latest-snapshot, quit, and validate flows
- the harness intentionally scoped to a stable intro/M3 smoke path, with broader early-M4 work validated through focused tests plus live telemetry/session traces
- bounded M3 gameplay extraction for `REDS_HOUSE_2F`, `REDS_HOUSE_1F`, `PALLET_TOWN`, and `OAKS_LAB`
- a playable field/dialogue/starter-choice/battle runtime slice from `New Game` through the first rival battle
- source-driven tileset collision metadata and per-map step collision grids for the four-map M3 slice
- source-driven Pallet Town and Oak's Lab map-script triggers and extracted script manifests, with no fallback Swift-only story paths for the slice
- source-driven M3 NPC movement manifests for Pallet Town and Oak's Lab, including actor-aware scripted movement kinds, starter-dependent rival pickup paths, Oak's Pallet escort, and structured idle-wander metadata extracted from map objects
- source-driven trainer battle manifests with extracted enemy parties and starter-dependent rival selection for Oak's Lab
- extracted starter typings, starter battle sprite paths, copied starter battle assets, and a source-driven type-effectiveness table for Oak Lab battle hardening
- a native overworld/dialogue/battle UI shell for the M3 slice
- real extracted field tilesets, blocksets, and overworld sprite sheets for the M3 slice
- corrected overworld sprite compositing for the accepted M3/M4A slice so sprite color-0 white is treated as transparent instead of multiply-blending against the field background
- Oak Lab rival battle hardening for the accepted M3 slice: battle sprites, queued battle text phases, accuracy/evasion, STAB, type effectiveness, critical hits, bounded move-effect handling, and deterministic trainer AI better than first-PP selection
- Oak Lab rival progression for the accepted M3 slice: starter species now carry extracted base-exp and growth-rate data, party Pokemon now persist hidden Gen 1 DVs and per-stat StatExp, the first rival battle grants source-driven trainer EXP plus hidden stat growth, the starter levels up when thresholds are crossed, that progression state persists through native saves, and the party sidebar hover card now shows live current stats with favored/lagging hidden-growth cues
- Oak Lab battle presentation polish for the accepted M3 slice: battles now render inside the shared Game Boy shell without the field LCD shader, while battle text stays in the viewport footer, battle controls/status move into the modern sidebar, move selection now forces the combat accordion open with `Run` rendered as a trailing action row beneath the move list for wild battles, battle sprites honor border-connected white-as-transparent compositing so internal highlights stay opaque, and the in-viewport HUD uses field-style LCD-tinted surfaces with HP and EXP bars instead of raw white panels
- a real GB-style field compositor for M3 maps and actors, with telemetry proving `renderMode == realAssets` and the native field view now presenting those scenes through a tinted Game Boy green treatment, a fixed `160x144` LCD viewport with camera scrolling, and a shader-based DMG LCD treatment with a restrained reflective screen sheen
- connected outdoor map crossings now stay map-scoped in runtime while animating as continuous one-tile steps in presentation, so transitions like `PALLET_TOWN <-> ROUTE_1` no longer visually snap when the active `mapID` changes
- bounded native M3 music playback driven from extracted ASM-backed audio manifests, including title, map-default, scripted override, battle, rival-exit, and Mom-heal routing
- hardened native M3 audio startup/transition behavior so title music is primed before first attract playback, trainer battle music no longer bleeds into the immediate post-battle result dialogue, and extracted pitch slides now carry frame-count timing metadata instead of gliding across the entire note
- a native-first single-slot save/load foundation using schema-versioned JSON save envelopes, title-menu `Continue` gating from readable save metadata, in-session sidebar save/load actions, XP-preserving party snapshots with hidden-growth persistence in save schema `4`, and save telemetry/control endpoints for the harness
- isolated validation save storage under `.runtime-traces/pokemac/validation-saves` so milestone harness resets never delete the user-facing Application Support save slot
- battle telemetry that now exposes phase, queued/current text, and move-slot state so the UI, focused tests, and manual sessions can consume turn sequencing directly
- field telemetry that now exposes visible object id, tile position, facing, and idle-vs-scripted movement mode so tests and manual sessions can assert NPC choreography and no-overlap behavior directly
- audio telemetry that now exposes current track, entry, playback reason, and revision so smoke validation and manual sessions can validate music transitions during the slice
- save telemetry that now exposes metadata, save/load availability, the last save operation result, and save-store error details so title flow, the gameplay shell, and manual sessions can verify restore behavior explicitly
- session event traces under `.runtime-traces/pokemac/session_events.jsonl` that log script starts/finishes, dialogue starts, warp completions, encounter triggers, battle starts/ends, inventory changes, heals, and save/load outcomes for live debugging
- a unified tile-by-tile movement runner for player and NPC actors, with blocking occupancy checks, scripted movement serialization, bounded idle walking for the current `WALK` NPCs, and animated Oak/Blue movement instead of teleport shortcuts
- a passing validation sweep across the current movement-sensitive module test targets plus the M3 milestone harness
- a macOS `26.0+` baseline for the Swift port so native Liquid Glass UI can be used without legacy fallback surfaces

The current accepted baseline was revalidated on `2026-03-11` with:

- `./scripts/extract_red.sh`
- `./scripts/validate_milestone.sh`
- `xcodebuild -workspace PokeSwift.xcworkspace -scheme PokeSwift-Workspace -derivedDataPath .build/DerivedData test -only-testing:PokeExtractCLITests -only-testing:PokeCoreTests -only-testing:PokeUITests`

### M1 Acceptance Criteria

- `PokeExtractCLI` supports `extract --game red` and `verify --game red`
- deterministic output is generated under `Content/Red/`
- extracted manifests exist for `game_manifest.json`, `constants.json`, `charmap.json`, `title_manifest.json`
- title-relevant assets are copied or normalized into runtime-friendly paths
- runtime code can load extracted Red content without reading source `.asm`
- milestone checks document and verify deterministic extraction behavior

### M2 Acceptance Criteria

- a fresh clone can generate the Tuist workspace and build the app locally
- the app launches as a native macOS process from this repo
- the app progresses through `launch -> splash -> titleAttract -> titleMenu`
- the title menu exposes `New Game`, `Continue`, and `Options`
- `Continue` is disabled in M2
- `New Game` and `Options` route to explicit placeholder screens
- telemetry exposes scene state, menu focus, input events, asset failures, and render/window state
- the harness can build, launch, poll telemetry, send synthetic input, and stop the app
- the validation loop can be rerun until all acceptance checks pass

### M3 Acceptance Criteria

- `New Game` starts a fresh in-memory run in `REDS_HOUSE_2F`
- the player can traverse `REDS_HOUSE_2F -> REDS_HOUSE_1F -> PALLET_TOWN -> OAKS_LAB`
- Oak stops the north-exit attempt in Pallet Town and the lab sequence proceeds correctly
- the player can choose a real starter and receive a party Pokemon in-memory
- the rival receives the correct counter-starter
- the first rival battle is playable, grants source-driven EXP to the starter, and resolves into the correct post-battle lab state
- telemetry exposes field, dialogue, starter-choice, battle, party, and event-flag state for the slice
- the harness validator can drive the full path from the title menu through the post-battle lab state

## Repo Architecture

### Planned Module Ownership Boundaries

| Module | Ownership Boundary | Responsibilities | Must Not Own |
| --- | --- | --- | --- |
| `PokeDataModel` | Shared contracts only | Codable manifests, enums, telemetry snapshot models, stable cross-target types | File IO policy, rendering, app lifecycle |
| `PokeExtractCLI` | Source-of-truth extraction | Read disassembly/assets, normalize Red content, write deterministic artifacts, verify extraction outputs | App runtime, UI, scene management |
| `PokeContent` | Runtime loading and validation | Locate content roots, decode manifests, validate content integrity, expose loaded content to runtime | Source repo parsing, game simulation |
| `PokeCore` | Headless simulation | Scene state machine, input handling, timing, menu navigation, future gameplay simulation systems | Platform windowing, AppKit/SwiftUI concerns |
| `PokeUI` | Reusable presentation primitives | Pixel surfaces, title/splash/menu presentation components, debug overlays, future reusable UI widgets | Business logic, content extraction |
| `PokeMac` | Native host shell | App lifecycle, windows, commands, menus, keyboard routing, environment/config plumbing | Game rules, extraction logic |
| `PokeTelemetry` | Observability and control | Snapshot publishing, trace output, latest-state access, control endpoints for harness/agents | Scene logic, rendering decisions |
| `PokeHarness` | Agentic automation | Build/launch wrappers, telemetry polling, synthetic input, intro smoke validation, clean shutdown orchestration | Game state ownership, content decoding |

### Architectural Rules

- `PokeExtractCLI` is the only module allowed to parse source disassembly files.
- `PokeCore` must remain usable without a macOS UI process.
- `PokeTelemetry` must be stable enough for automated milestone validation.
- `PokeHarness` must operate against the real app process, not mocks, for milestone acceptance.
- Shared schemas must live in `PokeDataModel` before they are consumed across multiple modules.

## Full Game Delivery Ledger

The following table is the top-level full-port checklist. Each row represents a durable subsystem that must reach playable parity for an end-to-end Pokemon Red port.

| Subsystem | Status | Parity Target | Source of Truth | Target Module(s) | Telemetry / Observability | Known Gaps / Next Step |
| --- | --- | --- | --- | --- | --- | --- |
| Content extraction pipeline | `in progress` | Deterministic Red extraction covering all runtime content categories | `constants/*.asm`, `data/**`, `engine/**`, `maps/**`, `gfx/**`, `audio/**`, `scripts/**`, `text/**` | `PokeExtractCLI`, `PokeDataModel` | extractor summaries, deterministic diff checks, verify command output | Title plus bounded M3 gameplay extraction is accepted; expand beyond the first playable slice |
| Runtime content loading | `in progress` | Decode all extracted manifests and fail fast on missing/invalid content | `Content/Red/**` | `PokeContent`, `PokeDataModel` | content load failures, manifest versions, asset lookup failures | Loader now covers gameplay manifests for M3; broaden validation as more content lands |
| Text / charmap / font pipeline | `in progress` | Native text rendering with original charmap semantics and full dialogue support | `constants/charmap.asm`, text sources, font assets | `PokeExtractCLI`, `PokeContent`, `PokeUI` | charmap coverage checks, missing glyph traces, rendered text snapshots | Title text and bounded M3 dialogue are wired; naming/text edge cases remain |
| Intro / splash / title flow | `done` | Native reproduction of title flow with required transitions and menu logic | `engine/movie/intro.asm`, `engine/movie/title.asm`, `engine/movie/title2.asm`, `gfx/title/**`, `gfx/splash/**` | `PokeExtractCLI`, `PokeCore`, `PokeUI`, `PokeMac` | scene state snapshots, menu focus traces, asset load failures | Extend from accepted title flow into gameplay scenes in M3 |
| Save / load / persistence | `in progress` | Usable native-first save system for progression restart, with future adapters for ROM-compatible formats | save format references, WRAM/SRAM behaviors, menu flows | `PokeCore`, `PokeDataModel`, `PokeMac`, `PokeTelemetry` | save slot inventory, metadata, load failures, save/load timing traces | v1 ships as a versioned single-slot native save in Application Support, and schema `4` now persists exact party EXP totals, inventory, and early-M4 encounter state; defer raw `.sav` compatibility until broader runtime parity exists |
| Overworld map loading | `in progress` | All maps load with correct tilesets, warps, objects, metadata | `maps/**`, `data/maps/**`, tileset data | `PokeExtractCLI`, `PokeContent`, `PokeCore`, `PokeUI` | current map id/name, tileset id, warp traces, missing map asset reports | M3 covers four maps only, but bounded warps now resolve from source destination-warp tiles instead of runtime offset tables; expand map coverage and edge rules next |
| Overworld rendering | `in progress` | Native tile and sprite rendering with deterministic visual composition | map assets, sprite assets, tilesets | `PokeUI`, `PokeCore`, `PokeContent` | render surface dimensions, visible map region, sprite layer traces, render mode | Real extracted tile and sprite rendering is accepted for the M3 slice, and the player now uses extracted walking frames plus field-local indoor/outdoor black fades; camera polish and full asset parity remain |
| Player movement and collisions | `in progress` | Correct grid movement, collision, ledges, doors, warps, cut/surf/bike gating | movement/collision logic in disassembly | `PokeExtractCLI`, `PokeContent`, `PokeCore`, `PokeTelemetry` | player position, heading, blocked movement reasons, warp transitions | M3 movement now uses extracted tileset collision metadata, source-resolved warp destinations, black fade transitions for field warps, door-only step-out behavior, blocking occupancy checks against moving actors, and serialized tile-by-tile scripted movement for the four-map slice; broader movement rules and more map coverage remain |
| NPC objects and trainer objects | `in progress` | Correct object spawning, movement, facing, trainer line-of-sight, interactions | object event data, scripts, map data | `PokeExtractCLI`, `PokeCore`, `PokeTelemetry` | object states, interaction target ids, trainer trigger traces | M3 lab/Pallet objects are now extracted with structured idle movement behavior, bounded wandering is live for the current `WALK` NPCs, and Oak/Blue use animated source-driven movement sequences; trainer sight, broader NPC schedules, and full-map coverage still remain |
| Script engine and event flags | `in progress` | Full script execution and event flag parity | `scripts/**`, event tables, map scripts, flag constants | `PokeExtractCLI`, `PokeCore`, `PokeTelemetry` | current script id, active flags, script transitions, blocking reasons | Pallet Town and Oak's Lab now run extracted map-script triggers plus actor-aware movement manifests end to end in M3, including Oak escort, lab entry, forced walkback, starter-dependent rival pickup, rival approach, and rival exit; broaden the extracted script subset only as new map coverage demands it |
| Inventory, items, shops, PC | `not started` | Functional bag, PC storage, marts, item use, hidden items | item data, shop tables, menu scripts | `PokeExtractCLI`, `PokeCore`, `PokeUI`, `PokeTelemetry` | bag contents, item actions, mart transactions, storage traces | Extract item catalogs and menu layouts |
| Party, stats, moves, evolution | `in progress` | Correct party state, stat growth, level up, learnsets, evolution rules | species/move data, evolution tables | `PokeExtractCLI`, `PokeCore`, `PokeTelemetry` | party summary, move learn events, evolution triggers, stat deltas | Starter acquisition now seeds hidden Gen 1 DVs and zero StatExp, trainer battles grant hidden stat growth, visible stats recalculate through the Gen 1 formula on creation and level-up, and battle-driven party progression is implemented for M3; the gameplay sidebar party hover card now surfaces live current stats plus favored/lagging growth coloring derived from hidden DVs and StatExp; learnsets and evolution still remain |
| Battle engine | `in progress` | Wild, trainer, scripted, and special battle parity | battle engine code, move data, trainer data, effects tables | `PokeExtractCLI`, `PokeCore`, `PokeUI`, `PokeTelemetry` | battle state snapshots, turn/action logs, HP/status/EXP deltas | Oak Lab rival battle now applies source-driven type data, accuracy/evasion, STAB, type effectiveness, critical hits, bounded debuff effects, trainer EXP gain, Gen 1-style hidden StatExp rewards with fixed trainer DVs, bounded level-up handling, queued turn text, and deterministic `RIVAL1`-style move choice; broader battle parity still excludes wild battles, capture, items, switching, statuses, animations, and general trainer systems |
| Battle UI | `in progress` | Native battle presentation, menus, animations, text, outcomes | battle assets, menu text, move/item strings | `PokeUI`, `PokeMac`, `PokeCore` | active combatants, current menu, damage/result events | Oak Lab now renders battles inside the shared Game Boy shell without the field LCD shader, keeps battle text in the viewport footer, surfaces move selection and battle status in the modern sidebar, forces the combat accordion open whenever move choice is required, renders wild-battle `Run` as a trailing action row beneath the move list instead of a detached hint, uses border-connected white-as-transparent compositing for battle and party Pokemon sprites so internal sprite highlights stay visible, and swaps the in-viewport battle HUD to field-style LCD-tinted cards with native HP/EXP bars and phase-aware battle telemetry; full command menus, switch/item/run flows, animations, and broad presentation parity remain |
| Encounters, fishing, gifts, trades, fossils, legendaries | `not started` | Full world content progression parity | encounter tables, map scripts, NPC scripts, gift/trade data | `PokeExtractCLI`, `PokeCore`, `PokeTelemetry` | encounter source, gift/trade state, one-off content completion flags | Expand extraction beyond core loop data |
| Menus, naming, Pokedex, party UI | `not started` | Full native menu/navigation stack with gameplay parity | menu scripts, text resources, species data | `PokeCore`, `PokeUI`, `PokeMac`, `PokeTelemetry` | current menu stack, selection state, naming input events | Build generic menu framework after title menu is stable |
| Audio / music / SFX | `in progress` | Native playback matching timing and event hooks closely enough for parity | `audio/**`, music/sfx data, track references | `PokeExtractCLI`, `PokeCore`, `PokeMac`, `PokeTelemetry` | current track ids, entry ids, playback reasons, audio load failures, playback state | Bounded M3 music extraction, routing, telemetry, and native playback are live for title, map-default, scripted, battle, rival-exit, and heal cues, with title-track cache priming, explicit post-battle music stop, and frame-counted pitch-slide metadata now wired through the extractor/runtime; fidelity and broader SFX/music parity still remain |
| Native macOS shell and UX | `in progress` | Native menus, settings, scaling, input mapping, window behavior, accessibility basics | app-level design decisions and extracted content constraints | `PokeMac`, `PokeUI`, `PokeTelemetry` | window scale, focused scene, input bindings, command usage | Title-shell scope is accepted; expand settings and accessibility with later gameplay milestones |
| Telemetry, debug tooling, parity harnesses | `in progress` | Stable state snapshots, control hooks, regression harnesses, parity/debug surfaces | runtime state plus extracted content metadata | `PokeTelemetry`, `PokeHarness`, `PokeCore` | JSONL traces, session event traces, latest snapshot endpoint, smoke validators, debug overlay | The harness is intentionally kept at the stable intro/M3 smoke boundary, while early-M4 validation now relies on focused extractor/runtime tests plus live `telemetry.jsonl` and `session_events.jsonl` traces during manual sessions |

## End-to-End Delivery Checklist

### Foundations

- [x] Tuist workspace is stable and reproducible
- [x] module boundaries are enforced by imports and target graph
- [x] deterministic content root for Red is committed and documented
- [x] build, launch, and validate commands are documented and reliable
- [x] SWIFT_PORT remains current during every milestone

### Extraction and Content

- [x] charmap extraction
- [x] text extraction and normalization
- [x] constants extraction
- [x] title and intro manifests
- [x] map manifests
- [x] tileset and sprite manifests
- [ ] item, move, species, trainer, and encounter catalogs
- [x] event/script extraction
- [x] audio identifier extraction
- [x] extraction verification and determinism tests

### Core Runtime

- [x] launch/title scene state machine
- [x] overworld simulation
- [x] event flag system
- [x] script runner
- [~] save/load state management
- [x] party and trainer state
- [x] battle simulation
- [ ] menu stack and naming input
- [ ] economy/progression systems

### Presentation

- [x] title/intro visuals
- [x] overworld tile renderer
- [x] sprite renderer
- [x] text box system
- [x] battle UI
- [ ] menu UI
- [ ] Pokedex / PC / shop UI
- [ ] accessibility and scaling pass

### Validation

- [x] unit tests for extractors and content decoders
- [x] scene/state tests for runtime transitions
- [x] automation harness for build/launch/input/quit
- [x] telemetry schema tests
- [ ] golden fixture validation for extracted content
- [x] milestone smoke tests
- [ ] future parity comparison harness against original behavior

## Milestone Board

| Milestone | Status | Scope | Exit Criteria | Notes |
| --- | --- | --- | --- | --- |
| `M1` Extraction Foundation | `done` | Red-only title-scope extraction, loader schemas, deterministic content output | extraction and verify commands succeed; deterministic output is proven; runtime can load extracted content | Accepted on `2026-03-09` via extractor build, extract/verify, deterministic diff check, and loader-backed app boot |
| `M2` Native Boot + Title | `done` | launch, splash, title attract, title menu, telemetry, harness validation loop | native app builds and launches; title flow works; telemetry and harness acceptance checks pass | Accepted on `2026-03-09` via `./scripts/validate_milestone.sh` and passing workspace tests |
| `M3` First Playable Slice | `done` | intro to player room, Pallet Town, Oak trigger, lab, starter choice, first rival battle | one serious vertical slice is playable end to end | Accepted on `2026-03-09` via `./scripts/validate_milestone.sh`, deterministic extraction diff, and passing workspace tests |
| `M4A` Real Field Rendering for M3 | `done` | render the current M3 maps and actors from extracted GB assets instead of placeholder geometry | real extracted tilesets, blocksets, sprite sheets, and zero field asset failures in validation | Accepted on `2026-03-09` via `./scripts/validate_milestone.sh`, passing workspace tests, and `renderMode == realAssets` telemetry in field scenes; presentation baseline revalidated on `2026-03-10` after moving the field treatment to a shader-based DMG LCD pass with restrained reflective glass |
| `M4` Early-Game Progression | `in progress` | route and town progression through early-game loop | stable field loop, trainers, encounters, marts, healing, save/load | Validation strategy is now focused tests plus manual-session telemetry/traces, while the harness stays scoped to the accepted intro smoke gate |
| `M5` Full Content Parity | `not started` | complete Red content coverage from start to credits | end-to-end playable game | Requires all subsystem rows to reach done or approved residual-gap state |

## Data Extraction Coverage Matrix

| Content Area | M1 Target | Current State | Primary Inputs | Output Artifact(s) | Owner | Next Step |
| --- | --- | --- | --- | --- | --- | --- |
| Game manifest | yes | `done` | repo metadata, extractor metadata | `game_manifest.json` | `PokeExtractCLI` | Extend fields only with schema discipline |
| Title constants | yes | `done` | `constants/*.asm`, title/menu references | `constants.json` | `PokeExtractCLI` | Expand constants coverage beyond title scope in M3+ |
| Charmap | yes | `done` | `constants/charmap.asm` | `charmap.json` | `PokeExtractCLI` | Expand validation once full text pipeline lands |
| Title scene manifest | yes | `done` | `engine/movie/intro.asm`, `engine/movie/title.asm`, `engine/movie/title2.asm` | `title_manifest.json` | `PokeExtractCLI` | Extend manifests for gameplay scenes later |
| Splash assets | yes | `done` | `gfx/splash/**` | copied/normalized assets | `PokeExtractCLI` | Maintain stable runtime paths as extraction expands |
| Title assets | yes | `done` | `gfx/title/**` | copied/normalized assets | `PokeExtractCLI` | Maintain stable runtime paths as extraction expands |
| Font assets | yes | `done` | `gfx/font/**` | copied/normalized assets | `PokeExtractCLI` | Expand glyph/render validation with dialogue systems |
| Bounded M3 audio manifest | optional | `in progress` | `constants/music_constants.asm`, `audio/headers/musicheaders*.asm`, `data/maps/songs.asm`, selected `audio/music/*.asm`, `audio/wave_samples.asm` | `audio_manifest.json` | `PokeExtractCLI` | M3 now extracts tracks, cues, map music routes, channel event IR, and alternate rival entrypoints; expand coverage and fidelity beyond the bounded slice |
| Maps | no | `in progress` | `maps/**`, `data/maps/**` | `gameplay_manifest.json` map section | `PokeExtractCLI` | Expand beyond the four M3 maps |
| Tilesets / blocksets / overworld sprites | no | `in progress` | `gfx/tilesets/**`, `gfx/blocksets/**`, `gfx/sprites/**` | `gameplay_manifest.json` tileset/sprite sections, collision metadata, and copied field assets | `PokeExtractCLI` | M3 slice assets and collision metadata are extracted and consumed; expand coverage beyond the current slice |
| Species / moves / items | no | `in progress` | `data/pokemon/**`, `data/moves/**`, `data/items/**` | `gameplay_manifest.json` species/moves sections | `PokeExtractCLI` | M3 now extracts starter typings, starter battle sprite paths, and the bounded move catalog needed for Oak Lab hardening; add broader catalogs beyond the current slice |
| Scripts / events / flags | no | `in progress` | `scripts/**`, event constants | `gameplay_manifest.json` script/event sections | `PokeExtractCLI` | Grow the bounded IR only as the next slice requires |
| Battle data | no | `in progress` | battle engine data, trainer/move tables | `gameplay_manifest.json` trainer battle section | `PokeExtractCLI` | Trainer parties, starter battle assets, and the type-effectiveness table are source-driven for Oak Lab; add broader trainer and wild battle coverage after the first rival fight |

## Gameplay Parity Matrix

| Gameplay Area | Parity Goal | Status | Blocking Dependencies | Telemetry Needed | Notes |
| --- | --- | --- | --- | --- | --- |
| Boot and scene progression | Native app reaches title menu reliably | `done` | content loader, title assets, runtime state machine | current scene, scene timestamps, failures | Accepted in harness and validation script |
| Title menu input | Directional navigation and confirm/cancel/start | `done` | runtime input mapping, app key routing | recent input events, focused entry, disabled states | `Continue` is now runtime-resolved from save availability; the no-save disabled path was validated in M2 and is preserved |
| Placeholder routing | Explicit non-silent routing for unavailable paths | `done` | scene state machine, placeholder view | active placeholder id/reason | `New Game` and `Options` route to placeholders in M2 |
| Overworld movement | Full field control and collisions | `in progress` | maps, object data, collision rules, renderer | map id, position, heading, blocked reasons | Bounded four-map slice is live in M3 and now uses extracted collision metadata, exact destination-warp spawning, and door-only step-out semantics instead of manual blocked-tile and warp-offset logic |
| NPC interaction | Correct interaction and script triggering | `in progress` | objects, scripts, text engine | target object id, script id, dialogue state | Oak, Mom, starter balls, and rival flow are wired for M3, with Pallet/Oak/Lab progression now driven by extracted script contracts rather than fallback runtime branches |
| Story progression | Event flag and scripted sequence parity | `in progress` | event flags, script runner, map triggers | active flags, story milestones, last trigger | First playable story slice is accepted in M3 and its Pallet/Oak/Lab trigger flow is now source-driven within the fixed four-map boundary |
| Battles | Correct outcomes and flow | `in progress` | species/move/trainer data, battle engine, UI | battle snapshots, turn logs, HP/status, rewards | The first rival battle now has materially better correctness inside the accepted M3 slice, including source-driven typings/sprites, queued text sequencing, and bounded Gen 1 damage rules; overall combat still remains slice-bounded rather than full Red parity |
| Save/load | Persistent progression | `in progress` | save schema, runtime serialization, UI | slot metadata, save result, load result | Native-first single-slot save/load is live for the current slice; raw `.sav` compatibility and broader progression data remain future work |
| End-to-end full game | Start to credits fully playable | `not started` | every major subsystem | milestone dashboard plus parity checkpoints | Final target |

## Platform / Native UX Matrix

| UX Area | Target | Status | Owner | Validation |
| --- | --- | --- | --- | --- |
| Native macOS app target | App launches from repo without ROM dependency | `in progress` | `PokeMac` | build + launch harness |
| Native menu bar integration | basic app commands and dev/debug entry points | `in progress` | `PokeMac` | app command tests and manual validation |
| Integer scaling | nearest-neighbor pixel presentation | `in progress` | `PokeUI` | render smoke test and telemetry surface info |
| Keyboard mapping | directional, confirm, cancel, start | `in progress` | `PokeMac`, `PokeCore` | harness input drive tests |
| Debug overlay / panel | scene, manifest version, input events | `in progress` | `PokeUI`, `PokeTelemetry` | UI smoke checks and telemetry parity |
| Settings / Options shell | native host for future options | `not started` | `PokeMac`, `PokeUI` | route placeholder exists in M2 |
| Save slots UI | single-slot native save management with title `Continue` and in-session restore affordances | `in progress` | `PokeMac`, `PokeUI`, `PokeCore` | save/load acceptance and restore validation |
| Accessibility basics | readable text, focus order, scaling policy | `not started` | `PokeUI`, `PokeMac` | future accessibility checklist |

## Telemetry and Agentic Validation Matrix

The M1/M2 contract requires telemetry that is stable enough for repeated build-launch-drive-verify loops.

| Capability | Target | Status | Surface | Owner | Acceptance Use |
| --- | --- | --- | --- | --- | --- |
| Latest runtime snapshot | machine-readable current state | `done` | JSON endpoint and JSONL trace | `PokeTelemetry` | used by the harness, targeted tests, and manual debugging |
| Scene identity | `launch`, `splash`, `titleAttract`, `titleMenu`, placeholder substates | `done` | runtime snapshot | `PokeCore`, `PokeTelemetry` | validated through end-to-end loop |
| Menu telemetry | menu entries, focus index, disabled state | `done` | runtime snapshot | `PokeCore`, `PokeTelemetry` | validated through synthetic input flow |
| Input event telemetry | recent synthetic and real inputs | `done` | runtime snapshot / trace | `PokeCore`, `PokeTelemetry` | confirmed during smoke validation and manual debugging |
| Content / asset failures | load failures are visible, not silent | `done` | runtime snapshot / trace | `PokeContent`, `PokeTelemetry` | surfaced in snapshot contract |
| Session event log | high-signal story/runtime trace for live sessions | `done` | `session_events.jsonl` | `PokeCore`, `PokeTelemetry` | primary debugging surface for early-M4 manual playtesting |
| Render/window state | scale and render dimensions | `done` | runtime snapshot | `PokeMac`, `PokeTelemetry` | exposed in M2 telemetry contract |
| Field render mode | field scenes prove placeholder vs real extracted assets | `done` | runtime snapshot / trace | `PokeCore`, `PokeTelemetry`, `PokeUI` | `renderMode == realAssets` is validated through the M3/M4A loop, with transition telemetry now distinguishing indoor/outdoor door fades from immediate stair warps |
| Build command | one stable app build command | `done` | repo script / harness command | `PokeHarness` | used in milestone automation |
| Launch command | one stable app launch command | `done` | repo script / harness command | `PokeHarness` | used in milestone automation |
| Synthetic input injection | up/down/confirm/cancel/start | `done` | harness to telemetry control surface | `PokeHarness`, `PokeTelemetry` | validated end to end |
| Save/load control surface | native save, in-session load, and relaunch `Continue` behavior are externally observable and driveable | `done` | runtime snapshot plus `/save` and `/load` control endpoints | `PokeCore`, `PokeTelemetry`, `PokeHarness` | used by the intro smoke and by manual-session debugging |
| Clean shutdown | deterministic stop path | `done` | harness command | `PokeHarness` | quit handshake fixed and validated |
| Smoke validator | stable intro/M3 acceptance script | `done` | harness validate command | `PokeHarness` | `./scripts/validate_milestone.sh` is intentionally limited to the accepted intro smoke path |

### Telemetry Contract for M2

M2 must expose, at minimum:

- app version
- content manifest version
- active scene
- active substate or placeholder reason when applicable
- title menu entries
- focused menu index
- disabled entry states
- recent input events
- asset/content loading failures
- window scale
- render surface dimensions

### Agentic Validation Contract for M2

The project must support the following repeatable loop:

1. build the required targets
2. regenerate or verify extracted Red content
3. launch the native app
4. poll latest telemetry
5. drive synthetic input
6. verify state transitions and UI state through telemetry
7. stop the app cleanly
8. repeat until the milestone acceptance criteria pass

## Testing and Validation Matrix

| Validation Area | Required for M1 | Required for M2 | Status | Notes |
| --- | --- | --- | --- | --- |
| extractor unit tests | yes | no | `done` | `PokeExtractCLITests` passes |
| manifest fixture tests | yes | yes | `in progress` | explicit snapshot-style fixtures are still worth adding |
| extraction determinism check | yes | yes | `done` | two temp-root extraction runs produced no diff on `2026-03-09` |
| content loader tests | yes | yes | `done` | `PokeContentTests` passes |
| runtime scene tests | no | yes | `done` | `PokeCoreTests` covers title-flow transitions |
| input navigation tests | no | yes | `done` | `PokeCoreTests` covers disabled `Continue` behavior |
| save/load runtime tests | no | no | `done` | `PokeCoreTests` covers save + `Continue` restore and unreadable-save handling |
| telemetry schema tests | no | yes | `done` | `PokeTelemetryTests` plus smoke/manual-trace coverage |
| harness command tests | no | yes | `done` | build/launch/latest/input/save/load/quit/validate remain exercised through the stable intro smoke loop only |
| render smoke test | no | yes | `done` | app boots with extracted assets and zero asset-loading failures in validation |
| ROM build non-regression | yes | no | `not started` | keep existing pokered build path intact if applicable |
| parity harness | no | future | `not started` | compare original behavior vs Swift engine over time |

## Milestone 1 Detailed Scope

### Inputs

- `constants/charmap.asm`
- `engine/movie/intro.asm`
- `engine/movie/title.asm`
- `engine/movie/title2.asm`
- `gfx/title/**`
- `gfx/splash/**`
- `gfx/font/**`
- title-relevant constants from `constants/*.asm`

### Expected Outputs

- `Content/Red/game_manifest.json`
- `Content/Red/constants.json`
- `Content/Red/charmap.json`
- `Content/Red/title_manifest.json`
- `Content/Red/audio_manifest.json` if identifiers are stubbed early
- normalized runtime asset tree for title, splash, and font assets

### Public Contracts to Freeze

- `GameVariant`
- `GameManifest`
- `CharmapManifest`
- `TitleSceneManifest`
- `ContentLoader`
- `RuntimeTelemetrySnapshot`
- `TelemetryPublisher`

## Milestone 2 Detailed Scope

### Scene States

- `launch`
- `splash`
- `titleAttract`
- `titleMenu`
- explicit placeholder states for unavailable routes

### Required Behavior

- native macOS window and host shell
- integer-scaled pixel content
- native keyboard input routing
- title menu with `New Game`, `Continue`, `Options`
- `Continue` enabled only when a valid native save exists
- explicit placeholder destinations for unavailable actions
- lightweight debug surface
- telemetry stable enough for harness control

## Open Risks

- The exact extracted schema surface can drift if multiple agents add fields without freezing `PokeDataModel` first.
- Title flow implementation can appear complete while still lacking deterministic telemetry, which would block true milestone acceptance.
- Asset path conventions can drift between extractor output and runtime loading unless the runtime-facing layout is explicitly frozen.
- The native-first save format is now real, so any future ROM-compatible or dual-format adapter must preserve schema-versioned restores, title `Continue` gating, and intro-smoke compatibility instead of bypassing them.
- Script/event extraction will likely become the highest-complexity subsystem after M2 and should not be improvised ad hoc.
- Battle implementation risk is high if battle data contracts are not separated cleanly from UI concerns.

## Blockers

- None formally declared yet.

When a blocker is discovered, add:

- blocker description
- owner
- date discovered
- impacted milestone
- temporary mitigation
- unblock condition

## Deferred Decisions

- Whether to add ROM-compatible or dual-format save adapters on top of the native primary save format
- Remaining audio fidelity/parity strategy beyond the bounded native M3 playback implementation
- How much title/intro timing should be driven directly by extracted manifests versus native reinterpretation layers
- When to introduce Blue support after Red reaches stable parity milestones
- Long-term parity strategy against original runtime behavior beyond milestone-local smoke tests

## Next Recommended Steps

1. Scope `M4` around the next early-game progression slice beyond Oak's Lab now that M3 rendering is source-driven.
2. Expand the bounded script and content coverage carefully instead of generalizing the runtime too early.
3. Keep the harness scoped to the accepted intro smoke while broadening focused extractor/runtime tests and live session traces for M4 work.
4. Add explicit manifest fixture snapshots as extraction coverage expands.
5. Keep this ledger current as milestone scope and acceptance evidence change.

## Progress Log

### 2026-03-11

- Narrowed `PokeHarness validate` back to the accepted intro/M3 smoke path and removed the abandoned early-M4 scripted validator plus its external RNG debug endpoint.
- Added runtime session-event tracing for scripts, dialogue, warps, encounters, battles, inventory changes, heals, and save/load outcomes, written to `.runtime-traces/pokemac/session_events.jsonl` for manual session debugging.
- Added focused extractor/runtime/telemetry coverage for the early-M4 slice so Route 1, Viridian, encounters, healing, and parcel/Pokedex state can be validated without relying on a brittle long autoplay harness.
- Extended the extracted field map contract with source-driven connection strips so maps can render adjacent-map border data instead of repeating the local border block everywhere outside bounds.
- Updated field background composition and the field debug map to resolve out-of-bounds blocks through GB-style north/south/west/east connection offsets before falling back to the map border block.
- Added connection-focused extractor and renderer coverage so padded field rendering stays aligned with the original map-header semantics as the playable map set expands.
- Fixed connected outdoor border presentation so crossing an extracted map connection animates like a normal step instead of snapping when the active map changes.

### 2026-03-10

- Kept M3 coverage fixed to `REDS_HOUSE_2F`, `REDS_HOUSE_1F`, `PALLET_TOWN`, and `OAKS_LAB` while removing remaining manual runtime glue inside that slice.
- Replaced hardcoded blocked-tile logic with extracted tileset collision metadata and per-map resolved step collision grids consumed by `PokeContent` and `PokeCore`.
- Replaced fallback Pallet Town and Oak's Lab script paths with extracted map-script triggers and script manifests, including the Pallet north-exit Oak intro and Oak's Lab starter/rival flow.
- Expanded trainer battle extraction/runtime contracts from single-enemy assumptions to source-driven trainer parties and starter-dependent rival resolution.
- Replaced the stub audio contract with bounded ASM-driven M3 music extraction, including track metadata, map music routing, scripted cues, and the rival alternate-start entrypoint.
- Added native runtime music ownership and playback for the M3 slice, with title, map-default, scripted override, battle, rival-exit, and Mom-heal transitions driven from extracted content.
- Extended telemetry and harness validation to assert audio track, reason, and entry transitions during the M3 end-to-end flow.
- Tightened extractor timing fidelity for the bounded music slice by matching the engine's carried note-delay behavior more closely.
- Extended telemetry to surface active map-script triggers and enemy party progress so harnesses and tests can validate the source-driven runtime path directly.
- Updated the field renderer/view baseline so gameplay maps default to the tinted Game Boy presentation, while preserving raw grayscale composition internally and existing `renderMode == realAssets` telemetry semantics.
- Corrected two Oak/Blue choreography parity gaps in the accepted M3 slice: simulated joypad escort paths now execute in the same order as the GB engine, and Blue's counter-starter ball stays visible until his post-walk pickup dialogue reaches the original hide point.
- Replaced the cached pixel-matrix overlay with a shader-based LCD treatment in the field view so DMG palette remap, pixel-cell shaping, and a restrained reflective glass sheen all live in a single display-only pass.
- Added a working field-filter switcher in the gameplay sidebar options section so the UI can swap between authentic DMG, tinted, and raw grayscale field presentation without touching runtime state contracts.
- Optimized field presentation updates so the SwiftUI field view no longer regenerates the full scene bitmap during ordinary body invalidations, and the renderer now caches decoded assets plus recent rendered frames by render signature.
- Reworked gameplay field presentation around a fixed `160x144` Game Boy LCD viewport with a scrolling camera, layered actor composition, border-block padding at map edges, and a DMG-style screen well that keeps interiors and exteriors at the same logical gameplay scale.
- Replaced the last hand-authored M3 warp offset table with source-driven destination-warp resolution, so doors now place the player on the actual destination doorway tile and stairs land directly on their stair tile.
- Added extracted player walking frames for compatible `16x96` overworld sprite sheets and wired the native field view to use the source-style four-phase `stand, walk, stand, walk` cadence during manual movement, scripted movement, and automatic door step-out, including the mirrored second walking pose for vertical steps.
- Normal field movement now paces both repeated key input and the visible walk cycle to the step cadence instead of accepting macOS key-repeat bursts mid-step, removing the acceleration feel during sustained directional movement.
- The macOS field input bridge now watches when the runtime can accept the next directional step instead of sleeping a whole extra repeat interval, so held movement and direction changes chain without the added standing pause between steps, and the field walk-cycle presentation now carries the visible stride frame into same-direction chained steps instead of briefly resetting to a sliding standing pose at each tile boundary; the rendered field view also drives walk-frame sampling with an explicit minimum animation interval so outdoor camera scrolling does not skip the short leg-frame windows, and object-only NPC movement refreshes now preserve any still-active player step animation instead of clearing the leg cadence mid-stride.
- Added runtime-owned field transition sequencing with a field-local DMG-style black fade-out/fade-in for both door and stair warps, while keeping automatic step-out limited to destination door tiles, plus explicit field transition telemetry for harnesses and tests.
- Added a native-first save/load foundation with schema-versioned JSON envelopes, a primary save file under Application Support (or `POKESWIFT_SAVE_ROOT` in harness mode), title-menu `Continue` restore, sidebar save/load actions with confirmation, and save telemetry surfaced through `RuntimeTelemetrySnapshot`.
- Extended the milestone harness and tests to validate post-battle save, relaunch, and `Continue` restore into the Oak's Lab post-rival state, and added focused `PokeCoreTests` coverage for save/restore plus unreadable-save handling.
- Raised the player's battle HUD/platform/sprite row inside the shared Game Boy battle shell so the in-viewport presentation sits correctly after the gameplay-shell migration.
- Revalidated the accepted M3/M4A baseline with `./scripts/extract_red.sh`, `./scripts/validate_milestone.sh`, and `xcodebuild -workspace PokeSwift.xcworkspace -scheme PokeSwift-Workspace -derivedDataPath .build/DerivedData test`.

### 2026-03-09

- Created `SWIFT_PORT.md` as the master full-port ledger for the Swift Pokemon Red project.
- Captured the full end-to-end delivery scope required for a playable native macOS port.
- Recorded module boundaries for `PokeDataModel`, `PokeExtractCLI`, `PokeContent`, `PokeCore`, `PokeUI`, `PokeMac`, `PokeTelemetry`, and `PokeHarness`.
- Marked `M1` and `M2` as `in progress` based on current repo scaffolding, without promoting them to done before end-to-end validation.
- Added extraction, parity, UX, telemetry, and validation matrices to keep milestone progress measurable.
- Established the rule that this file must be updated whenever implementation status, scope, or blockers change.
- Accepted `M1` after successful extractor build, `extract`, `verify`, and deterministic diff validation.
- Accepted `M2` after `./scripts/validate_milestone.sh` completed successfully against the real app.
- Ran `xcodebuild -workspace PokeSwift.xcworkspace -scheme PokeSwift-Workspace -derivedDataPath .build/DerivedData test` successfully to verify the current workspace test suite.
- Raised the Swift port deployment target from macOS `15.0` to macOS `26.0` so title/menu surfaces can use native Liquid Glass directly.
- Reworked the title menu and placeholder surfaces around native Liquid Glass panels and rows to fix low-contrast white-on-white menu presentation.
- Accepted `M3` after the real app validator completed the slice from `New Game` through the first rival battle and returned to the post-battle lab state.
- Added `gameplay_manifest.json` and the bounded M3 extraction/runtime contracts for four maps, slice-specific scripts, dialogue, starter data, and the first rival battle.
- Expanded the telemetry and harness loop to validate field, dialogue, starter-choice, battle, party, and event-flag state end to end.
- Verified deterministic M3 extraction with two temporary output roots and a clean `diff -ru`.
- Accepted `M4A` after replacing placeholder field rendering with a real GB-style compositor driven by extracted tilesets, blocksets, and overworld sprite sheets for the M3 slice.
- Added tileset and overworld sprite manifests to `gameplay_manifest.json`, copied field assets into `Content/Red/Assets/field`, and validated that field scenes report `renderMode == realAssets` with zero asset-loading failures.
- Verified M4A with `./scripts/validate_milestone.sh` and `xcodebuild -workspace PokeSwift.xcworkspace -scheme PokeSwift-Workspace -derivedDataPath .build/DerivedData test`.
