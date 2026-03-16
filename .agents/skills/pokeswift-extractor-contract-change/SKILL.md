---
name: pokeswift-extractor-contract-change
description: Investigate, implement, and validate PokeSwift extraction or shared-contract changes without breaking the source-driven pipeline. Use when work touches `PokeExtractCLI`, `PokeDataModel`, `PokeContent`, generated `Content/Red` artifacts, or any bug where the issue may be in extracted data, schema shape, content loading, or extractor-to-runtime contract drift.
---

# PokeSwift Extractor Contract Change

Read [AGENTS.md](../../../AGENTS.md) and [SWIFT_PORT.md](../../../SWIFT_PORT.md) before changing milestone-sensitive behavior.

Treat generated content as evidence, not authoring surface. Prefer fixing the first broken contract layer instead of compensating in runtime code.

## Workflow

1. Define the failing contract.
   Capture the exact value or shape that is wrong: missing dialogue ID, wrong warp/checkpoint, broken map script, bad trainer manifest, missing audio cue metadata, stale item/species/move field, or loader decode mismatch.

2. Trace the first diverging layer.
   Use this order:
   `pret/pokered asm/data -> PokeExtractCLI -> Content/Red -> PokeDataModel/PokeContent -> PokeCore/PokeUI`.
   Fix the first layer that differs from the expected source-driven result.

3. Pick the right ownership boundary.
   If the extracted value is wrong, change `PokeExtractCLI`.
   If the extracted value is right but the shared model cannot represent it, change `PokeDataModel` first.
   If the model is right but loading or validation is wrong, change `PokeContent`.
   Only change `PokeCore` or `PokeUI` after the upstream contract is correct.

4. Regenerate instead of patching artifacts.
   After extractor changes, run `./scripts/extract_red.sh`.
   Never hand-edit `Content/Red/**` as the fix.

5. Validate upstream first, then downstream.
   Run focused `PokeExtractCLITests` and `PokeContentTests`.
   Then run the smallest runtime or UI tests that consume the changed contract.
   Update `SWIFT_PORT.md` if the shipped scope, milestone boundary, or system ledger changed.

## Ownership Guide

- `PokeExtractCLI`
  Own parsing, normalization, template assembly, and deterministic manifest generation.
  Search here for battle text templates, trainer dialogues, encounter tables, map objects/scripts, warps, marts, items, audio cues, and source-derived flags.

- `Content/Red`
  Treat as generated output.
  Diff it to confirm what changed, but do not author fixes here.

- `PokeDataModel`
  Own shared manifests and save/telemetry schemas.
  Put contract changes here before duplicating structure in loaders or runtime code.

- `PokeContent`
  Own content loading, validation, and repo-contract tests.
  Fix this layer when manifests are correct but decoding, validation, or loader defaults are wrong.

- `PokeCore` and `PokeUI`
  Consume contracts.
  Change these only after upstream data and shared types are proven correct.

## Common Triggers

- wrong Pokecenter blackout checkpoint or player start location
- missing trainer lose dialogue or battle text token
- battle text template drift against `common_text.asm`
- encounter table, mart, item, species, move, or evolution manifest mismatch
- audio metadata or dialogue-event extraction mismatch
- schema bumps that require loader and save defaults
- `Content/Red` diffs that look suspicious after extractor work

## File Checklist

- Read [Sources/PokeExtractCLI](../../../Sources/PokeExtractCLI) for parser and manifest generation ownership.
- Read [Sources/PokeDataModel](../../../Sources/PokeDataModel) for shared schemas.
- Read [Sources/PokeContent](../../../Sources/PokeContent) for loader and contract validation ownership.
- Inspect [Content/Red](../../../Content/Red) only to confirm generated output, never as the source of truth.
- Read [SWIFT_PORT.md](../../../SWIFT_PORT.md) if the contract change alters shipped scope or milestone claims.

## Validation Matrix

- If extraction logic changed:
  Run `./scripts/extract_red.sh`.

- If manifests or schemas changed:
  Run focused `PokeExtractCLITests` and `PokeContentTests`.

- If runtime consumers changed because of the contract:
  Run the smallest relevant `PokeCoreTests` or `PokeUITests` slice.

- If file moves or target-sensitive edits happened during the change:
  Run `tuist generate --no-open` before broader validation.

## Failure Shields

- Do not hand-edit `Content/Red/**`.
- Do not bury schema drift in runtime `if` statements.
- Do not change runtime behavior first when the extractor output is already wrong.
- Do not stop at compile success; prove regenerated artifacts and loaders both validate.
- Do not forget save/schema coupling when shared models change.

## Review Mode

When reviewing an extractor or contract patch:

- Start from `git diff --stat` and the changed generated artifacts.
- Check whether the extractor output matches the expected Red source or just "looks plausible."
- Look for missing shared-model updates when new fields appear.
- Look for loader defaults or decode paths that silently discard new data.
- Treat unexplained `Content/Red` diffs as first-class findings.

## Output Expectations

Report these points clearly:

- expected source-driven contract
- first diverging layer
- files changed and why
- regenerated artifacts touched
- upstream and downstream validation run
- whether `SWIFT_PORT.md` changed
