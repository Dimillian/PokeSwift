---
name: pokeswift-parity-fix
description: Investigate and fix PokeSwift gameplay parity regressions against `pret/pokered` using the repo's source-driven pipeline. Use when a user reports behavior drift from Pokemon Red, asks for parity work in battle/progression/maps/save/load/audio/UI, needs tracing from pokered assembly and data through `PokeExtractCLI`, `Content/Red`, and `PokeCore` or `PokeUI`, or wants a PokeSwift parity review or fix instead of generic Swift refactoring.
---

# Pokeswift Parity Fix

Read [AGENTS.md](../../../AGENTS.md) and [SWIFT_PORT.md](../../../SWIFT_PORT.md) before changing milestone-sensitive behavior.

Prefer source-driven fixes. Do not patch runtime behavior if the real defect lives in extraction, generated content, or a broken contract between modules.

## Workflow

1. Define the exact parity target.
   Capture the user-visible behavior that should match Red.
   If the report is vague, anchor it to a concrete flow: map transition, trainer battle, move effect, blackout, evolution, audio cue, save/load path, or UI presentation beat.

2. Reproduce before editing.
   Start with `git status --short`.
   Read the owning implementation instead of guessing.
   Use the smallest reproduction that proves the bug: focused tests, telemetry traces, or a native app run.

3. Trace the ownership chain.
   Use this order whenever behavior originates from Red:
   `pret/pokered asm/data -> PokeExtractCLI -> Content/Red -> PokeContent/PokeDataModel -> PokeCore -> PokeUI/PokeMac`.
   Stop at the first layer that diverges from expected behavior and fix that layer.

4. Patch the narrowest correct boundary.
   Change extractor code if generated content is wrong.
   Regenerate `Content/Red/**` instead of hand-editing generated artifacts.
   Change `PokeDataModel` first if a shared schema contract is wrong.
   Keep `PokeCore` headless; keep host/UI concerns out of simulation code.

5. Validate at the correct level.
   Use focused extraction/content tests for extractor changes.
   Use focused runtime or UI tests for consumer changes.
   Run the native app when milestone-sensitive behavior is involved.
   Update `SWIFT_PORT.md` in the same change set when scope, milestone status, or a meaningful parity boundary changes.

## Ownership Guide

- `PokeExtractCLI`
  Own parser, normalization, and generated manifest bugs.
  Search here first for missing trainer text, wrong warps, map scripts, item data, encounter tables, audio metadata, and battle templates.

- `Content/Red`
  Treat as generated evidence, not authoring surface.
  Diff it to confirm extraction output, but fix the extractor and regenerate.

- `PokeDataModel` and `PokeContent`
  Own schema and loading contracts.
  Use this layer when extraction is correct but runtime sees missing or mis-modeled fields.

- `PokeCore`
  Own gameplay simulation, battle rules, progression flags, persistence, and telemetry production.
  Fix here when the manifest is correct but runtime semantics drift from Red.

- `PokeUI` and `PokeMac`
  Own native presentation, rendering, app shell, and input/host behavior.
  Fix here only when the underlying runtime state is correct and the visible behavior is wrong.

## File Checklist

- Always read [AGENTS.md](../../../AGENTS.md).
- Always read [SWIFT_PORT.md](../../../SWIFT_PORT.md) for milestone-sensitive work.
- For extraction scope, inspect [Sources/PokeExtractCLI](../../../Sources/PokeExtractCLI).
- For runtime behavior, inspect [Sources/PokeCore](../../../Sources/PokeCore).
- For presentation issues, inspect [Sources/PokeUI](../../../Sources/PokeUI) and [App/PokeMac](../../../App/PokeMac).
- For shared contracts, inspect [Sources/PokeDataModel](../../../Sources/PokeDataModel) and [Sources/PokeContent](../../../Sources/PokeContent).

## Validation Matrix

- If Tuist manifests or source moves changed:
  Run `tuist generate --no-open`.

- If extractor logic or generated content changed:
  Run `./scripts/extract_red.sh`.
  Then run focused `PokeExtractCLITests` and `PokeContentTests`.

- If runtime logic changed:
  Prefer workspace `xcodebuild` over `swift test`.
  Use the smallest relevant test slice first, then broaden as needed.

- If UI or rendering changed:
  Run focused `PokeUITests` or `PokeRenderTests`, then build `PokeMac`.

- If the bug is only credible through native execution:
  Use `POKESWIFT_WATCH_MODE=0 ./scripts/launch_app.sh`.
  Probe telemetry endpoints such as `/health` and `/quit` when relevant.

## Failure Shields

- Do not introduce runtime `.asm` parsing.
- Do not hand-edit `Content/Red/**`.
- Do not classify compile success as parity proof.
- Do not use `swift test` at repo root; this repo validates through the workspace.
- Do not rewrite broad runtime/UI areas when a single extractor or contract bug explains the issue.
- Do not ignore dirty files; work around unrelated changes and keep your diff scoped.

## Review Mode

When asked to review a parity patch instead of fixing it:

- Start from `git status --short` and `git diff --stat`.
- Prioritize regressions that break Red behavior, extraction fidelity, schema contracts, or native validation.
- Cross-check suspicious behavior against `pret/pokered` assembly/data before calling it a bug.
- Prefer findings with a concrete ownership path: wrong extractor output, wrong generated artifact, wrong runtime rule, wrong presentation contract, or missing test coverage.

## Output Expectations

Report these points clearly:

- expected Red behavior
- first diverging layer
- files changed and why
- validation run
- whether `SWIFT_PORT.md` was updated or intentionally left unchanged
