# PokeSwift

## Mission

- Build a fully playable, native macOS reinterpretation of Pokemon Red in Swift.
- Treat the checked-in `pret/pokered` disassembly and assets as the canonical gameplay and content source of truth.
- Treat [SWIFT_PORT.md](SWIFT_PORT.md) as the master engineering ledger for scope, milestone state, blockers, and acceptance criteria.

## Core Rules

- Read [SWIFT_PORT.md](SWIFT_PORT.md) and the relevant module files before changing architecture or milestone-critical behavior.
- Fix root causes. Do not patch around parity gaps with Swift-only shortcuts when the source-driven path should own the behavior.
- Do not revert or overwrite unrelated user changes. This repo may be dirty.
- Keep changes scoped to the real ownership boundary of the bug or feature.
- If a task changes scope, completes milestone work, or uncovers a blocker, update [SWIFT_PORT.md](SWIFT_PORT.md) in the same change.

## Source Of Truth Boundaries

- `PokeExtractCLI` is the only place that should parse `.asm`, map data, or other source assets directly.
- The runtime app must consume extracted artifacts from `Content/Red/`, not ad hoc repository parsing.
- Do not hand-edit generated `Content/Red/**` files as a shortcut for extractor changes. Change the extractor, regenerate, and commit the resulting artifacts.
- Do not treat ROM or disassembly build success as proof that the Swift port is correct. Milestone acceptance is driven by the native app, telemetry, focused tests, and real runtime behavior.

## Module Ownership

- `Sources/PokeDataModel/`: shared contracts, manifests, enums, telemetry snapshot models.
- `Sources/PokeExtractCLI/`: deterministic extraction and verification from disassembly/assets.
- `Sources/PokeContent/`: runtime loading and validation for extracted content.
- `Sources/PokeCore/`: headless simulation, scene/runtime state, gameplay systems.
- `Sources/PokeUI/`: reusable SwiftUI rendering, scenes, and shared presentation primitives.
- `App/PokeMac/`: native macOS host shell, lifecycle, input routing, app commands.
- `Sources/PokeTelemetry/`: snapshots, traces, control endpoints, observable runtime state.

## Project Constraints

- The Swift port baseline is macOS `26.0+`. Do not add legacy deployment fallbacks unless the task explicitly changes platform policy.
- Prefer native SwiftUI/AppKit solutions that fit the existing shell instead of bolting emulator-style abstractions onto the app.
- Preserve headless testability in `PokeCore`; UI or host concerns should not leak into the simulation layer.
- Shared schemas should land in `PokeDataModel` before being duplicated across targets.

## Workflow

- Start with `git status` and inspect the touched files before editing.
- Prefer `rg` for code search and read the current implementation instead of assuming the ledger is still accurate for local details.
- When touching extraction, content schemas, scripts, maps, or source-driven runtime behavior, inspect both the extractor and the runtime consumer before editing.
- When touching milestone-sensitive flows, verify the exact acceptance criteria in [SWIFT_PORT.md](SWIFT_PORT.md) first.

## Validation

- Use `./scripts/build_app.sh` for the standard Tuist generate + main scheme build flow.
- Use `./scripts/extract_red.sh` whenever extractor logic or generated runtime content changes.
- Use `./scripts/launch_app.sh` for manual native app runs.
- For a full Swift workspace test sweep, run:
  - `xcodebuild -workspace PokeSwift.xcworkspace -scheme PokeSwift-Workspace -derivedDataPath .build/DerivedData test`
- Prefer the smallest relevant `xcodebuild` build/test invocation for the touched target while iterating, then run the broader validation needed for the change class before finalizing.

## Change-Specific Expectations

- Extraction changes: regenerate `Content/Red/`, verify deterministic output, and update ledger notes if coverage or scope changed.
- Runtime/parity changes: validate through the native app and telemetry, not just unit tests.
- Telemetry changes: keep snapshots and control surfaces stable enough for focused tests and live runtime debugging.
- UI changes: preserve the existing native macOS direction and verify they still work with the current scene/runtime state instead of mocking around it.

## Avoid

- Do not introduce runtime `.asm` parsing.
- Do not bypass the extractor by hardcoding source data into runtime modules.
- Do not mark milestone work done based only on compile success.
- Do not edit generated Xcode artifacts as the source of truth when the Tuist manifests or Swift sources should be changed instead.
