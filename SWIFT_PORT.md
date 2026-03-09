# SWIFT_PORT

## Vision
Build a fully playable, native macOS reinterpretation of Pokemon Red in Swift, using the `pret/pokered` disassembly in this repository as the source of truth for game data, scripted behavior, rules, and content coverage.

The port target is not "run the ROM." The target is:

- a native macOS app with a Swift engine and native UI shell
- deterministic content extracted from the disassembly into tracked runtime artifacts
- a headless, testable simulation core that can be validated independently of rendering
- a telemetry and automation surface that allows full agentic validation loops until milestone acceptance is actually reached

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

### Current State Summary

Milestones `M1` and `M2` are complete as of `2026-03-09`.

The repo now contains:

- Tuist manifests
- the planned Swift module layout
- a working Red extraction CLI and committed `Content/Red` artifacts
- a native macOS app that reaches `launch -> splash -> titleAttract -> titleMenu`
- telemetry and harness targets with working build, launch, input, latest-snapshot, quit, and validate flows
- a passing workspace test run across the current module test targets
- a macOS `26.0+` baseline for the Swift port so native Liquid Glass UI can be used without legacy fallback surfaces

Acceptance was proven with the documented validation command, a deterministic extraction diff check, and a successful `xcodebuild test` run for the workspace scheme.

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
| `PokeHarness` | Agentic automation | Build/launch wrappers, telemetry polling, synthetic input, smoke validation, clean shutdown orchestration | Game state ownership, content decoding |

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
| Content extraction pipeline | `in progress` | Deterministic Red extraction covering all runtime content categories | `constants/*.asm`, `data/**`, `engine/**`, `maps/**`, `gfx/**`, `audio/**`, `scripts/**`, `text/**` | `PokeExtractCLI`, `PokeDataModel` | extractor summaries, deterministic diff checks, verify command output | M1 title-scope extraction is accepted; expand coverage beyond title assets and manifests |
| Runtime content loading | `in progress` | Decode all extracted manifests and fail fast on missing/invalid content | `Content/Red/**` | `PokeContent`, `PokeDataModel` | content load failures, manifest versions, asset lookup failures | Lock manifest schemas and loader validation rules |
| Text / charmap / font pipeline | `in progress` | Native text rendering with original charmap semantics and full dialogue support | `constants/charmap.asm`, text sources, font assets | `PokeExtractCLI`, `PokeContent`, `PokeUI` | charmap coverage checks, missing glyph traces, rendered text snapshots | Complete title text now, then expand to full dialogue and naming screens |
| Intro / splash / title flow | `done` | Native reproduction of title flow with required transitions and menu logic | `engine/movie/intro.asm`, `engine/movie/title.asm`, `engine/movie/title2.asm`, `gfx/title/**`, `gfx/splash/**` | `PokeExtractCLI`, `PokeCore`, `PokeUI`, `PokeMac` | scene state snapshots, menu focus traces, asset load failures | Extend from accepted title flow into gameplay scenes in M3 |
| Save / load / persistence | `not started` | Usable save system for full-game progression and restart | save format references, WRAM/SRAM behaviors, menu flows | `PokeCore`, `PokeContent`, `PokeMac`, `PokeTelemetry` | save slot inventory, load failures, save/load timing traces | Decide save compatibility strategy before implementation |
| Overworld map loading | `not started` | All maps load with correct tilesets, warps, objects, metadata | `maps/**`, `data/maps/**`, tileset data | `PokeExtractCLI`, `PokeContent`, `PokeCore`, `PokeUI` | current map id/name, tileset id, warp traces, missing map asset reports | Define extracted map manifest schema |
| Overworld rendering | `not started` | Native tile and sprite rendering with deterministic visual composition | map assets, sprite assets, tilesets | `PokeUI`, `PokeCore`, `PokeContent` | render surface dimensions, visible map region, sprite layer traces | Decide camera/render abstraction after title renderer is stable |
| Player movement and collisions | `not started` | Correct grid movement, collision, ledges, doors, warps, cut/surf/bike gating | movement/collision logic in disassembly | `PokeCore`, `PokeTelemetry` | player position, heading, blocked movement reasons, warp transitions | Build headless field simulation after M2 |
| NPC objects and trainer objects | `not started` | Correct object spawning, movement, facing, trainer line-of-sight, interactions | object event data, scripts, map data | `PokeExtractCLI`, `PokeCore`, `PokeTelemetry` | object states, interaction target ids, trainer trigger traces | Extract object/event schema with stable ids |
| Script engine and event flags | `not started` | Full script execution and event flag parity | `scripts/**`, event tables, map scripts, flag constants | `PokeExtractCLI`, `PokeCore`, `PokeTelemetry` | current script id, active flags, script transitions, blocking reasons | Define extracted script/event intermediate representation |
| Inventory, items, shops, PC | `not started` | Functional bag, PC storage, marts, item use, hidden items | item data, shop tables, menu scripts | `PokeExtractCLI`, `PokeCore`, `PokeUI`, `PokeTelemetry` | bag contents, item actions, mart transactions, storage traces | Extract item catalogs and menu layouts |
| Party, stats, moves, evolution | `not started` | Correct party state, stat growth, level up, learnsets, evolution rules | species/move data, evolution tables | `PokeExtractCLI`, `PokeCore`, `PokeTelemetry` | party summary, move learn events, evolution triggers, stat deltas | Define extracted battle/trainer data contracts |
| Battle engine | `not started` | Wild, trainer, scripted, and special battle parity | battle engine code, move data, trainer data, effects tables | `PokeExtractCLI`, `PokeCore`, `PokeUI`, `PokeTelemetry` | battle state snapshots, turn/action logs, HP/status deltas | Separate battle domain model before UI work |
| Battle UI | `not started` | Native battle presentation, menus, animations, text, outcomes | battle assets, menu text, move/item strings | `PokeUI`, `PokeMac`, `PokeCore` | active combatants, current menu, damage/result events | Build after battle core produces stable state snapshots |
| Encounters, fishing, gifts, trades, fossils, legendaries | `not started` | Full world content progression parity | encounter tables, map scripts, NPC scripts, gift/trade data | `PokeExtractCLI`, `PokeCore`, `PokeTelemetry` | encounter source, gift/trade state, one-off content completion flags | Expand extraction beyond core loop data |
| Menus, naming, Pokedex, party UI | `not started` | Full native menu/navigation stack with gameplay parity | menu scripts, text resources, species data | `PokeCore`, `PokeUI`, `PokeMac`, `PokeTelemetry` | current menu stack, selection state, naming input events | Build generic menu framework after title menu is stable |
| Audio / music / SFX | `not started` | Native playback matching timing and event hooks closely enough for parity | `audio/**`, music/sfx data, track references | `PokeExtractCLI`, `PokeCore`, `PokeMac` | current track/sfx ids, audio load failures, playback state | Keep identifier extraction early; playback comes later |
| Native macOS shell and UX | `in progress` | Native menus, settings, scaling, input mapping, window behavior, accessibility basics | app-level design decisions and extracted content constraints | `PokeMac`, `PokeUI`, `PokeTelemetry` | window scale, focused scene, input bindings, command usage | Title-shell scope is accepted; expand settings and accessibility with later gameplay milestones |
| Telemetry, debug tooling, parity harnesses | `in progress` | Stable state snapshots, control hooks, regression harnesses, parity/debug surfaces | runtime state plus extracted content metadata | `PokeTelemetry`, `PokeHarness`, `PokeCore` | JSONL traces, latest snapshot endpoint, smoke validators, debug overlay | M2 telemetry and harness contract is accepted; grow telemetry with overworld, scripts, and battle systems |

## End-to-End Delivery Checklist

### Foundations

- [x] Tuist workspace is stable and reproducible
- [x] module boundaries are enforced by imports and target graph
- [x] deterministic content root for Red is committed and documented
- [x] build, launch, and validate commands are documented and reliable
- [x] SWIFT_PORT remains current during every milestone

### Extraction and Content

- [ ] charmap extraction
- [ ] text extraction and normalization
- [ ] constants extraction
- [ ] title and intro manifests
- [ ] map manifests
- [ ] tileset and sprite manifests
- [ ] item, move, species, trainer, and encounter catalogs
- [ ] event/script extraction
- [ ] audio identifier extraction
- [ ] extraction verification and determinism tests

### Core Runtime

- [ ] launch/title scene state machine
- [ ] overworld simulation
- [ ] event flag system
- [ ] script runner
- [ ] save/load state management
- [ ] party and trainer state
- [ ] battle simulation
- [ ] menu stack and naming input
- [ ] economy/progression systems

### Presentation

- [ ] title/intro visuals
- [ ] overworld tile renderer
- [ ] sprite renderer
- [ ] text box system
- [ ] battle UI
- [ ] menu UI
- [ ] Pokedex / PC / shop UI
- [ ] accessibility and scaling pass

### Validation

- [ ] unit tests for extractors and content decoders
- [ ] scene/state tests for runtime transitions
- [ ] automation harness for build/launch/input/quit
- [ ] telemetry schema tests
- [ ] golden fixture validation for extracted content
- [ ] milestone smoke tests
- [ ] future parity comparison harness against original behavior

## Milestone Board

| Milestone | Status | Scope | Exit Criteria | Notes |
| --- | --- | --- | --- | --- |
| `M1` Extraction Foundation | `done` | Red-only title-scope extraction, loader schemas, deterministic content output | extraction and verify commands succeed; deterministic output is proven; runtime can load extracted content | Accepted on `2026-03-09` via extractor build, extract/verify, deterministic diff check, and loader-backed app boot |
| `M2` Native Boot + Title | `done` | launch, splash, title attract, title menu, telemetry, harness validation loop | native app builds and launches; title flow works; telemetry and harness acceptance checks pass | Accepted on `2026-03-09` via `./scripts/validate_milestone.sh` and passing workspace tests |
| `M3` First Playable Slice | `not started` | intro to player room, Pallet Town, Oak trigger, lab, starter choice, first rival battle | one serious vertical slice is playable end to end | Depends on overworld, scripts, menus, and initial battle support |
| `M4` Early-Game Progression | `not started` | route and town progression through early-game loop | stable field loop, trainers, encounters, marts, healing, save/load | Scope to be refined after M3 |
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
| Audio ids stub | optional | `done` | title/intro track references | `audio_manifest.json` | `PokeExtractCLI` | Replace stub-only behavior with playback later |
| Maps | no | `not started` | `maps/**`, `data/maps/**` | future map manifests | `PokeExtractCLI` | Define map manifest schema after M2 |
| Species / moves / items | no | `not started` | `data/pokemon/**`, `data/moves/**`, `data/items/**` | future catalogs | `PokeExtractCLI` | Plan extraction after title milestone |
| Scripts / events / flags | no | `not started` | `scripts/**`, event constants | future script/event manifests | `PokeExtractCLI` | Define IR for script execution and flag references |
| Battle data | no | `not started` | battle engine data, trainer/move tables | future battle manifests | `PokeExtractCLI` | Defer until M3 planning |

## Gameplay Parity Matrix

| Gameplay Area | Parity Goal | Status | Blocking Dependencies | Telemetry Needed | Notes |
| --- | --- | --- | --- | --- | --- |
| Boot and scene progression | Native app reaches title menu reliably | `done` | content loader, title assets, runtime state machine | current scene, scene timestamps, failures | Accepted in harness and validation script |
| Title menu input | Directional navigation and confirm/cancel/start | `done` | runtime input mapping, app key routing | recent input events, focused entry, disabled states | `Continue` is disabled and validated in M2 |
| Placeholder routing | Explicit non-silent routing for unavailable paths | `done` | scene state machine, placeholder view | active placeholder id/reason | `New Game` and `Options` route to placeholders in M2 |
| Overworld movement | Full field control and collisions | `not started` | maps, object data, collision rules, renderer | map id, position, heading, blocked reasons | M3+ |
| NPC interaction | Correct interaction and script triggering | `not started` | objects, scripts, text engine | target object id, script id, dialogue state | M3+ |
| Story progression | Event flag and scripted sequence parity | `not started` | event flags, script runner, map triggers | active flags, story milestones, last trigger | M3+ |
| Battles | Correct outcomes and flow | `not started` | species/move/trainer data, battle engine, UI | battle snapshots, turn logs, HP/status, rewards | M3+ |
| Save/load | Persistent progression | `not started` | save schema, runtime serialization, UI | slot metadata, save result, load result | M3+ |
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
| Save slots UI | native save management | `not started` | `PokeMac`, `PokeUI`, `PokeCore` | future save/load acceptance |
| Accessibility basics | readable text, focus order, scaling policy | `not started` | `PokeUI`, `PokeMac` | future accessibility checklist |

## Telemetry and Agentic Validation Matrix

The M1/M2 contract requires telemetry that is stable enough for repeated build-launch-drive-verify loops.

| Capability | Target | Status | Surface | Owner | Acceptance Use |
| --- | --- | --- | --- | --- | --- |
| Latest runtime snapshot | machine-readable current state | `done` | JSON endpoint and JSONL trace | `PokeTelemetry` | used by harness and validation script |
| Scene identity | `launch`, `splash`, `titleAttract`, `titleMenu`, placeholder substates | `done` | runtime snapshot | `PokeCore`, `PokeTelemetry` | validated through end-to-end loop |
| Menu telemetry | menu entries, focus index, disabled state | `done` | runtime snapshot | `PokeCore`, `PokeTelemetry` | validated through synthetic input flow |
| Input event telemetry | recent synthetic and real inputs | `done` | runtime snapshot / trace | `PokeCore`, `PokeTelemetry` | confirmed during harness validation |
| Content / asset failures | load failures are visible, not silent | `done` | runtime snapshot / trace | `PokeContent`, `PokeTelemetry` | surfaced in snapshot contract |
| Render/window state | scale and render dimensions | `done` | runtime snapshot | `PokeMac`, `PokeTelemetry` | exposed in M2 telemetry contract |
| Build command | one stable app build command | `done` | repo script / harness command | `PokeHarness` | used in milestone automation |
| Launch command | one stable app launch command | `done` | repo script / harness command | `PokeHarness` | used in milestone automation |
| Synthetic input injection | up/down/confirm/cancel/start | `done` | harness to telemetry control surface | `PokeHarness`, `PokeTelemetry` | validated end to end |
| Clean shutdown | deterministic stop path | `done` | harness command | `PokeHarness` | quit handshake fixed and validated |
| Smoke validator | end-to-end M2 acceptance script | `done` | harness validate command | `PokeHarness` | `./scripts/validate_milestone.sh` passes |

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
| telemetry schema tests | no | yes | `done` | `PokeTelemetryTests` plus harness/validation coverage |
| harness command tests | no | yes | `done` | build/launch/latest/input/quit/validate exercised through M2 loop |
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
- disabled `Continue`
- explicit placeholder destinations for unavailable actions
- lightweight debug surface
- telemetry stable enough for harness control

## Open Risks

- The exact extracted schema surface can drift if multiple agents add fields without freezing `PokeDataModel` first.
- Title flow implementation can appear complete while still lacking deterministic telemetry, which would block true milestone acceptance.
- Asset path conventions can drift between extractor output and runtime loading unless the runtime-facing layout is explicitly frozen.
- Save format strategy is still undecided; postponing it too long may create avoidable rework in menus and progression state.
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

- Whether save data should be ROM-compatible, app-native, or dual-format
- Exact audio playback implementation strategy
- How much title/intro timing should be driven directly by extracted manifests versus native reinterpretation layers
- When to introduce Blue support after Red reaches stable parity milestones
- Long-term parity strategy against original runtime behavior beyond milestone-local smoke tests

## Next Recommended Steps

1. Start M3 planning around the first playable overworld slice.
2. Define the extracted map, object, and script manifest schemas before runtime work expands.
3. Preserve the accepted M2 telemetry and harness contract while growing gameplay coverage.
4. Add explicit manifest fixture snapshots as extraction coverage expands.
5. Keep this ledger current as M3 scope is frozen.

## Progress Log

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
