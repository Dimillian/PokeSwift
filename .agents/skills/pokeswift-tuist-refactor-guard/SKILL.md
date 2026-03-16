---
name: pokeswift-tuist-refactor-guard
description: Plan, review, and execute PokeSwift refactors without breaking the Tuist workspace, target graph, or module ownership boundaries. Use when moving or splitting Swift files, reorganizing `Sources/` or `App/`, decomposing large runtime or UI files, cleaning up feature slices, or checking whether a proposed refactor is safe for PokeSwift's Tuist-based workspace.
---

# PokeSwift Tuist Refactor Guard

Read [AGENTS.md](../../../AGENTS.md) and [SWIFT_PORT.md](../../../SWIFT_PORT.md) before changing milestone-sensitive code.

Optimize for safe structure changes, not broad churn. Keep public behavior stable unless the user explicitly asked for behavior changes.

## Workflow

1. Map the refactor boundary first.
   Start with `git status --short`.
   Identify which layer owns the change: `PokeExtractCLI`, `PokeContent`, `PokeDataModel`, `PokeCore`, `PokeUI`, `PokeTelemetry`, or `App/PokeMac`.
   Prefer one ownership slice at a time.

2. Preserve the target graph.
   Do not invent new targets unless the user explicitly needs an architectural change.
   Prefer moving logic inside existing targets and files that already compile under the current `Project.swift`.
   Keep façade APIs stable when splitting oversized files so downstream call sites do not drift unnecessarily.

3. Refactor by feature slice.
   Split large files along existing seams:
   app shell into coordinator, router, path, scene, or input bridge pieces;
   runtime into state, title, field, dialogue, scripts, battle, telemetry, or save extensions;
   UI into scene, shared view, render, and props-builder files.
   Keep extracted helpers close to the current target-owned boundary.

4. Regenerate Tuist immediately after moves or deletions.
   After renames, deletions, or new source files, run `tuist generate --no-open` before deeper validation.
   In this repo, stale generated project references are a common failure mode after file moves.

5. Validate in layers.
   Run the smallest relevant focused tests first.
   Then run the broader workspace or app build that matches the refactor surface.
   If scripts mutate generated metadata, restore or regenerate it before final staging.

## Refactor Patterns

- `GameRuntime`-scale changes
  Keep the façade stable.
  Extract extensions by domain such as `+State`, `+Title`, `+Field`, `+Dialogue`, `+Scripts`, `+Battle`, `+Telemetry`, or `+Save`.

- `PokeUI` scene cleanup
  Separate scene props, stage views, overlays, and shared primitives.
  Do not move gameplay logic from `PokeCore` into SwiftUI views.

- `PokeMac` shell changes
  Split host concerns such as lifecycle, commands, launch orchestration, and activation behavior without changing gameplay ownership.

- `PokeExtractCLI` and content-loading changes
  Keep extraction deterministic and runtime consumption explicit.
  Do not let a refactor hide a schema change.

## File Checklist

- Read [Project.swift](../../../Project.swift), [Workspace.swift](../../../Workspace.swift), and [Tuist.swift](../../../Tuist.swift) before making graph-sensitive changes.
- Read [AGENTS.md](../../../AGENTS.md) for repo constraints.
- Read [SWIFT_PORT.md](../../../SWIFT_PORT.md) if the touched code affects milestones, parity boundaries, or shipped scope.
- Inspect the owning target under [Sources](../../../Sources) or [App](../../../App) before moving code.

## Validation Matrix

- After file moves, deletes, or additions:
  Run `tuist generate --no-open`.

- For runtime or shared logic refactors:
  Prefer `xcodebuild -workspace PokeSwift.xcworkspace -scheme PokeSwift-Workspace -derivedDataPath .build/DerivedData test`.

- For UI-only refactors:
  Run the smallest relevant `PokeUITests` or `PokeRenderTests`, then build `PokeMac`.

- For app-shell changes:
  Build with `./scripts/build_app.sh`.
  Use `./scripts/launch_app.sh` only when native run behavior is part of the refactor risk.

- For extractor-adjacent refactors:
  Run `./scripts/extract_red.sh` and focused extractor/content tests if the change could affect generated artifacts or content loading.

## Failure Shields

- Do not hand-edit generated `Content/Red/**` files to compensate for refactor fallout.
- Do not trust `swift test`; this repo validates through the workspace.
- Do not leave file moves unverified; regenerate Tuist immediately.
- Do not widen a refactor into behavior changes unless the user asked for both.
- Do not move code across target boundaries casually; check dependencies in `Project.swift` first.
- Do not edit generated Xcode artifacts as a source of truth.

## Review Mode

When reviewing a proposed refactor:

- Check whether the write set crosses too many targets at once.
- Look for hidden contract changes in schemas, save models, telemetry, or generated content.
- Confirm the public API remains stable where the refactor claims behavior preservation.
- Ask whether `tuist generate --no-open` was run after moves.
- Treat stale project references, missing target membership, and broken workspace builds as first-class findings.

## Output Expectations

Report these points clearly:

- refactor boundary
- target ownership
- whether the Tuist graph stayed stable
- validation run
- residual risks, especially around moved files, generated content, and unverified runtime paths
