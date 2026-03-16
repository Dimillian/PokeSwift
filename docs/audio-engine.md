# PokeSwift Audio Engine

## Purpose

PokeSwift does not emulate the original Game Boy APU register-by-register at runtime. Instead, it extracts Pokemon Red's music and sound-effect scripts into a source-driven `AudioManifest`, then renders those timed events into PCM audio in Swift and plays them through `AVAudioEngine`.

This gives the project a native macOS audio pipeline while still keeping the disassembly as the source of truth for notes, timing, envelopes, pitch movement, wave data, noise timing, routing, and cue selection.

The current implementation lives primarily in:

- `Sources/PokeExtractCLI/AudioExtraction.swift`
- `Sources/PokeDataModel/ContentModels.swift`
- `Sources/PokeContent/Loading/ContentLoading.swift`
- `Sources/PokeAudio/Contracts/RuntimeAudio.swift`
- `Sources/PokeAudio/RuntimeState/RuntimeAudioState.swift`
- `Sources/PokeAudio/Host/PokeAudioService.swift`
- `Sources/PokeAudio/Host/PokeAudioRenderer.swift`
- `Sources/PokeAudio/Host/PokeAudioRenderTypes.swift`
- `Sources/PokeCore/Runtime/Audio/GameRuntime+Audio.swift`

## End-To-End Pipeline

The audio path has four stages:

1. The extractor parses `pret/pokered` audio headers, channel scripts, pitch tables, wave tables, noise instruments, map music routes, and cue definitions.
2. The extractor converts that source data into `AudioManifest`, which is written to `Content/Red/audio_manifest.json`.
3. Runtime systems issue `MusicPlaybackRequest` and `SoundEffectPlaybackRequest` values against the loaded manifest.
4. `PokeCore` gameplay orchestration talks to the shared `PokeAudio` contract, and `PokeAudioService` renders the requested manifest slice into stereo PCM buffers and schedules them on `AVAudioEngine`.

That means the runtime app never parses `.asm` directly. It only consumes the extracted artifact.

## Extracted Data Model

`AudioManifest` is the contract between extraction and playback.

At a high level:

- `tracks` holds music tracks.
- `soundEffects` holds one-shot SFX definitions.
- `mapRoutes` maps map IDs to music track IDs.
- `cues` names higher-level gameplay cues such as healing jingles or intro music.

The important unit is `AudioManifest.Event`. Each event is already normalized into a timed, waveform-specific instruction with fields such as:

- `startTime` and `duration`
- `waveform`: `square`, `wave`, or `noise`
- `frequencyHz` and, when available, the original `frequencyRegister`
- envelope data
- duty-cycle and duty-pattern data
- wave-table samples
- stereo enable bits
- vibrato and pitch-slide metadata
- `noiseShortMode` for the Game Boy noise LFSR mode

Events are grouped like this:

- `Track` -> multiple `Entry` values
- `Entry` -> multiple `ChannelProgram` values
- `ChannelProgram` -> `prelude` events and `loop` events

That split lets the runtime distinguish between:

- one-shot content, where only `prelude` matters
- looping content, where an optional intro prelude is followed by a loop body

## What The Extractor Actually Does

`extractAudioManifest()` in `Sources/PokeExtractCLI/AudioExtraction.swift` parses the original audio sources and resolves them into a renderable representation.

Key extraction responsibilities:

- Parse music and SFX constant tables so the runtime can refer to stable IDs such as `MUSIC_PALLET_TOWN` or `SFX_GO_INSIDE`.
- Parse music headers and sound-effect headers to discover which software channels belong to each asset.
- Parse channel scripts and follow labels, calls, and loops.
- Resolve waveform-specific state such as duty cycle, wave tables, note type, envelopes, stereo panning, vibrato, pitch slide, and noise parameters.
- Turn Game Boy note commands into absolute-time events in seconds.
- Split channels into `prelude` and `loop` when a `sound_loop 0, ...` creates an infinite loop point.

The extractor treats software channels as source-level channels:

- `1` and `5` map to hardware pulse channel 1
- `2` and `6` map to hardware pulse channel 2
- `3` and `7` map to the wave channel
- `4` and `8` map to the noise channel

That mapping is preserved into the runtime so music and SFX can contend for the same underlying Game Boy-style hardware lanes.

### Timing Normalization

The extractor converts note lengths into seconds before runtime playback. The runtime therefore does not need to understand the full original music macro language.

Global track state such as tempo and master volume is resolved first. Channel-local state then advances as instructions are interpreted.

### Pitch And Modulation Extraction

When present, the extractor keeps both a high-level value and the original Game Boy-flavored register form:

- `frequencyHz` and `frequencyRegister`
- `pitchSlideTargetHz` and `pitchSlideTargetRegister`
- approximate vibrato values plus GB-style frame/extents metadata

That dual representation is important because the runtime often prefers register-derived behavior for parity, especially for pulse sweep and vibrato behavior that feels closer to the hardware when applied as register movement rather than smooth analog modulation.

### Noise Extraction

Noise events are extracted from `noise_note` and drum data into:

- a clock frequency in Hz
- `noiseShortMode`
- amplitude and envelope data

The extractor also resolves drum instruments into concrete timed noise events. The current implementation uses the corrected Game Boy noise clock formula, so the output rate of doors, cries, and percussion matches the source-driven polynomial-counter timing instead of an earlier incorrect slower fallback.

## Runtime Contract

Runtime code talks to audio through `RuntimeAudioPlaying` in `Sources/PokeAudio/Contracts/RuntimeAudio.swift`.

The API is intentionally small:

- `playMusic(request:completion:)`
- `playSFX(request:completion:)`
- `stopAllMusic()`

`MusicPlaybackRequest` identifies a `trackID` and optional `entryID`.

`SoundEffectPlaybackRequest` identifies a `soundEffectID` and can also carry:

- `frequencyModifier`
- `tempoModifier`

Those modifiers exist because some GB sound effects are parameterized at playback time rather than existing as one fixed sample.

## Runtime Architecture

The runtime audio module is split into three pieces, while gameplay ownership stays in `PokeCore`.

### 1. `PokeAudioService`

`Sources/PokeAudio/Host/PokeAudioService.swift` owns native host orchestration:

- `AVAudioEngine`
- separate music and SFX mixer nodes
- four music player nodes and four SFX player nodes
- render caches
- background render scheduling
- loop scheduling
- hardware-channel SFX arbitration

It does not synthesize samples directly anymore.

### 2. `PokeAudioRenderer`

`Sources/PokeAudio/Host/PokeAudioRenderer.swift` owns the actual offline render path:

- event adjustment for runtime SFX modifiers
- event-to-sample rendering
- waveform-specific synthesis
- envelope, vibrato, and pitch-slide application
- conditioning passes such as DC blocking
- creation of `AVAudioPCMBuffer` values

### 3. `PokeAudioRenderTypes`

`Sources/PokeAudio/Host/PokeAudioRenderTypes.swift` defines shared render settings and data structures:

- `PokeAudioMixDefaults`
- `PokeAudioRenderOptions`
- `PokeAudioRenderedSamples`
- `PokeAudioRenderedChannelBuffers`
- `PokeAudioRenderedAsset`

### 4. `PokeCore` Audio Orchestration

`Sources/PokeCore/Runtime/Audio/GameRuntime+Audio.swift` still owns gameplay-level audio decisions:

- which cue or track should play for a given game state
- when map music should resume after one-shot cues
- when battle presentation should request staged sound effects
- when UI, dialogue, and field interactions should block on audio completion

That split is intentional: `PokeAudio` owns the reusable audio engine and contract, while `PokeCore` owns gameplay timing and intent.

## Engine Graph And Playback Model

`PokeAudioService` builds this graph:

- `musicPlayers[0...3]` -> `musicMixerNode`
- `soundEffectPlayers[0...3]` -> `soundEffectMixerNode`
- both mixers -> `engine.mainMixerNode`

Important default gains:

- master output: `0.6`
- music bus: `0.4`
- SFX bus: `1.0`

This intentionally keeps music lower than UI/battle/field effects at the native host level.

The service prewarms music renders and eagerly primes the title track so common music starts without a cold render on first playback.

## Caching Strategy

The engine does not render every note in real time while the game is running. It renders a whole requested asset into buffers, caches it, and reuses the result.

Two caches are maintained:

- `musicRenderCache`
- `soundEffectRenderCache`

Cache keys differ:

- music: `music:<trackID>:<entryID>`
- SFX: `sfx:<soundEffectID>:<frequencyModifier>:<tempoModifier>`

This is important for parameterized sound effects. A cry or effect played with different modifiers becomes a different rendered asset.

## Music Playback Flow

When music is requested:

1. `PokeAudioService` looks up the requested `Track` and `Entry`.
2. It ensures the engine is running.
3. It stops existing music players and increments an internal request ID.
4. If the rendered asset is cached, playback starts immediately.
5. Otherwise the service enqueues a background render on `renderQueue`.

If the entry is looping:

- `prelude` is scheduled first, if present.
- when the prelude completes, the cached `loop` buffer is rescheduled with `.loops`.

If the entry is one-shot:

- the prelude buffer is scheduled once
- completion is fired after `rendered.maxDuration`

## Sound-Effect Playback Flow

SFX playback is similar but adds hardware-channel contention, which matters for Game Boy parity.

When SFX is requested:

1. The service looks up the extracted `SoundEffect`.
2. It maps the sound effect's requested software channels onto one of four hardware channels.
3. It checks whether those hardware channels are already occupied by active SFX.
4. It compares extracted `order` values to decide whether the new effect may replace an active one.
5. It renders or reuses the buffered SFX asset.
6. It temporarily mutes music on the occupied hardware channels by setting the matching music player volume to `0`.
7. When the effect finishes, it restores the music player volume to `1`.

This is a pragmatic native approximation of GB channel stealing: a sound effect can take over a hardware lane and suppress whatever music would have used that lane during the overlap.

## Render Options: Music Versus SFX

The renderer uses different options for music and sound effects.

Current defaults:

- music sample gain: `0.16`
- SFX sample gain: `0.24`
- music noise multiplier: `0.68`
- SFX noise multiplier: `1.0`
- both currently enable noise smoothing

This split exists because music channel-4 percussion and one-shot noise effects do not want the exact same final gain structure. In practice:

- hotter SFX gain helps doors and cries cut through correctly
- reduced music noise gain keeps percussion from overdriving the mix

## Event Adjustment For Runtime SFX Modifiers

Before rendering an SFX asset, `PokeAudioRenderer` can adjust the extracted event stream using the request's modifiers.

### Frequency Modifier

`frequencyModifier` is applied by adjusting the low byte of the extracted frequency register and carrying into the high bits when needed. The renderer then recomputes `frequencyHz` from the adjusted register.

This preserves the original Game Boy-style pitch semantics better than naively multiplying the frequency by a scalar.

### Tempo Modifier

`tempoModifier` rescales event `startTime` and `duration`.

One quirk intentionally preserved in the implementation:

- software channel `8` does not apply the tempo scale

That mirrors how these parameterized effect paths are currently interpreted by the extractor/runtime contract.

## PCM Buffer Construction

`renderedAudioAsset()` renders one `AudioManifest.ChannelProgram` at a time.

For each channel it:

1. adjusts `prelude` and `loop` events if the playback request modifies them
2. renders each segment into left/right float arrays
3. converts those arrays into `AVAudioPCMBuffer`
4. records the channel duration

All runtime rendering currently targets:

- sample rate: `44_100 Hz`
- channel count: `2`

Stereo is implemented by writing the sample into the left and/or right array depending on the event's panning flags.

## Waveform Synthesis

The renderer has three waveform paths.

### Square Channels

Pulse channels use an anti-aliased square-wave synthesizer.

Important details:

- frequency comes from the extracted register or Hz value after pitch-slide and vibrato adjustment
- duty cycle can come from a static duty or a rotating GB duty pattern
- a `polyBLEP` correction is applied at the discontinuities

The reason for `polyBLEP` is to reduce aliasing that would otherwise make high notes and bright timbres sound harsh or machine-like in the native host.

### Wave Channel

The wave channel uses the extracted `waveSamples` table.

Important details:

- phase advances according to the event frequency
- sample lookup uses linear interpolation between adjacent wave-table points
- if no wave table is present, the implementation falls back to a sine-like placeholder rather than crashing

Linear interpolation is important because nearest-neighbor stepping made the original native playback rougher and less faithful than the current implementation.

### Noise Channel

The noise channel uses a deterministic Game Boy-style linear-feedback shift register instead of a hash-based pseudo-random source.

Important details:

- the extracted event provides `clockHz`
- `noiseShortMode` selects the short or long LFSR variant
- the LFSR is advanced whenever local event time crosses the next noise clock step
- the output bit is converted into `+1` or `-1`

This is the main reason doors, cries, and percussion now sound like intentional GB noise instead of generic digital static.

## Modulation And Dynamics

Several GB behaviors are applied during rendering.

### Envelope

`envelopeAdjustedAmplitude()` applies the extracted envelope step duration and direction. This allows notes and noise hits to fade in the same discrete style implied by the source script.

### Vibrato

There are two vibrato paths:

- a GB-flavored register toggle path using `vibratoDelayFrames`, `vibratoExtentUp`, `vibratoExtentDown`, and `vibratoRateFrames`
- a fallback continuous semitone LFO path using `vibratoDepthSemitones` and `vibratoRateHz`

The register-based path is preferred when enough source data is present because it behaves more like the original engine.

### Pitch Slide

Pitch slides interpolate from the extracted starting register to the extracted target register over a frame-count-derived duration.

Again, the implementation prefers register movement over pure Hz interpolation because that tracks the source engine more closely.

### Duty Pattern Progression

For square channels, `duty_cycle_pattern` data is rotated over time so repeating pulse timbres evolve the way the original track script intends.

## Click Prevention And Conditioning

Native PCM playback needs some conditioning that the original hardware never exposed as a PCM buffer problem.

### De-Click Envelope

Each rendered event applies a very short fade-in/fade-out envelope at its edges. This reduces audible clicks at note boundaries.

### DC Blocking

After a segment is rendered, the engine optionally applies a simple one-pole DC blocker:

`output = input - previousInput + pole * previousOutput`

The important implementation detail is that this is only applied when the segment contains square-wave events.

That restriction exists because applying the same cleanup to low-frequency noise-only SFX made effects like doors too weak and scratchy.

### Noise Smoothing

Noise rendering can apply a lightweight low-pass filter:

- SFX keep a strong noise presence
- music percussion uses the same idea but at a lower effective gain

This was introduced to tame scratchiness without destroying the GB character of doors, cries, and channel-4 percussion.

## Frequency Conversion

When the runtime needs Hz from a Game Boy register, it uses the standard GB formulas:

- square channels: `131072 / (2048 - frequencyRegister)`
- wave channel: `65536 / (2048 - frequencyRegister)`

The renderer also clamps extreme values using `maxRenderableFrequencyRatio` so the native host does not try to synthesize unstable near-Nyquist content.

## What This Engine Is, And What It Is Not

This engine is:

- source-driven
- manifest-based
- channel-aware
- parity-oriented
- native to Swift and `AVAudioEngine`

This engine is not:

- a cycle-accurate Game Boy APU emulator
- a runtime `.asm` interpreter
- a ROM-audio mixer that steps hardware registers every CPU cycle

Instead, it is an offline event renderer backed by extracted source data.

That trade-off is deliberate. It keeps the runtime architecture simple and native while still preserving the original game's authored musical behavior and most of the audible hardware character that matters for parity.

## Why The Current Rewrite Sounds Better Than The Earlier Native Pass

The current version improved parity by fixing several concrete problems:

- square channels now use anti-aliased pulse synthesis instead of harsher naive toggling
- wave playback now interpolates instead of stepping abruptly
- noise uses a GB-style LFSR instead of hash noise
- the extractor now computes the correct GB noise clock for `noise_note`
- DC blocking is limited to the square-wave path where it actually helps
- music and SFX use different noise gain treatment so percussion and one-shot effects can both sound correct

Those changes matter more than cosmetic refactoring because the biggest audible regressions were caused by the wrong synthesis model, not just by mix values.

## Known Design Trade-Offs

A few behaviors are worth keeping in mind if you extend this system:

- Rendering is asset-based, not sample-accurate over full game state transitions.
- Music/SFX interaction is approximated by hardware-lane muting and replacement, not by full shared-register emulation.
- Looping happens at the buffer level after extracted loop detection.
- The runtime trusts the extractor to encode most GB semantics ahead of time.

If parity issues appear, the bug may live in either place:

- extractor logic, if the manifest encodes the wrong event stream
- runtime renderer logic, if the manifest is correct but the PCM synthesis is wrong

## Debugging Strategy

When audio sounds wrong, the fastest way to localize the issue is:

1. Check whether the extracted `AudioManifest.Event` values look plausible.
2. Confirm the right track/SFX and entry are being requested.
3. Verify the correct hardware channel mapping and SFX arbitration.
4. Check whether the issue is waveform-specific: square, wave, or noise.
5. Only then tune gains or conditioning.

For this codebase, many of the hardest parity bugs have turned out to be extractor or synthesis issues, not mixer-bus issues.

## Validation

When validating audio work, prefer running extraction and runtime audio separately.

### Extraction Audio Tests

This repo's extractor audio tests have a normal XCTest class name, so the target-level selector works:

```bash
tuist test PokeSwift-Workspace --derived-data-path .build/DerivedData --no-selective-testing -- \
  -only-testing:PokeExtractCLITests/AudioExtractionTests
```

### Runtime Audio Tests

The runtime audio tests live in `Tests/PokeCoreTests/AudioRuntimeTests.swift`, but the test methods are declared on `extension PokeCoreTests`, so file-style selectors such as `PokeCoreTests/AudioRuntimeTests` do not select any real tests.

Use explicit method selectors instead:

```bash
tuist test PokeSwift-Workspace --derived-data-path .build/DerivedData --no-selective-testing -- \
  -only-testing:PokeCoreTests/PokeCoreTests/testRepoGeneratedWildBattleExitRestoresRouteMusic \
  -only-testing:PokeCoreTests/PokeCoreTests/testRepoGeneratedDoorAndWarpTransitionsChooseExpectedSoundEffects \
  -only-testing:PokeCoreTests/PokeCoreTests/testRepoGeneratedOakIntroAndLabArrivalUpdateAudioTelemetry \
  -only-testing:PokeCoreTests/PokeCoreTests/testRepoGeneratedManualTrainerInteractionUsesEncounterMusicThenFieldIntroBeforeBattle \
  -only-testing:PokeCoreTests/PokeCoreTests/testDialoguePageEventsBlockProgressUntilSoundCompletes \
  -only-testing:PokeCoreTests/PokeCoreTests/testBlockedMovementCollisionSoundDoesNotStackUntilPlaybackCompletes \
  -only-testing:PokeCoreTests/PokeCoreTests/testDialogueWithoutBlockingEventsAdvancesEvenIfBlockingFlagLeaked \
  -only-testing:PokeCoreTests/PokeCoreTests/testRepoGeneratedRivalBattleAudioTransitionsFromIntroToBattleToExitAndBack \
  -only-testing:PokeCoreTests/PokeCoreTests/testRepoGeneratedBattleMoveUsesExtractedMoveSoundEffect \
  -only-testing:PokeCoreTests/PokeCoreTests/testWildCaptureUsesCaughtAndDexAddedSoundEffects \
  -only-testing:PokeCoreTests/PokeCoreTests/testRepoGeneratedOrdinaryTrainerLossBlackoutsToViridianCityAndRestartsMapMusic \
  -only-testing:PokeCoreTests/PokeCoreTests/testRepoGeneratedWildLossUsesFallbackBlackoutCheckpointAndMoneyPenalty \
  -only-testing:PokeCoreTests/PokeCoreTests/testRepoGeneratedTrainerLossResetsAutoMovedTrainerBeforeBlackout \
  -only-testing:PokeCoreTests/PokeCoreTests/testTrainerVictoryMusicStartsInBattleBeforePostBattleDialogue \
  -only-testing:PokeCoreTests/PokeCoreTests/testMomHealJingleRestoresMapDefaultAfterCompletion \
  -only-testing:PokeCoreTests/PokeCoreTests/testWildVictoryMusicStartsBeforeExperienceAndLevelUpSoundUsesLevelMessage \
  -only-testing:PokeCoreTests/PokeCoreTests/testMusicToggleStopsPlaybackAndResumesCurrentTrack \
  -only-testing:PokeCoreTests/PokeCoreTests/testDisabledMusicDefersPlaybackUntilReenabled
```

### App Host Build

After audio engine or target-boundary changes, also confirm the native app still links the audio host correctly:

```bash
tuist build PokeMac --path .
```

## Extension Guidelines

If you change this engine, keep these rules in mind:

- Preserve the extractor/runtime contract in `AudioManifest`.
- Prefer source-driven fixes over hardcoded runtime exceptions.
- Keep runtime playback inside `PokeAudio`; do not start parsing `.asm` in the app.
- Treat waveform parity and timing parity as first-class correctness issues.
- Validate both extraction and runtime when touching noise, vibrato, pitch, or looping behavior.

## Summary

PokeSwift's audio engine is a native Swift reconstruction of Pokemon Red's sound behavior built from extracted source data rather than live hardware emulation.

The extractor converts GB audio scripts into timed channel events. `PokeCore` decides when gameplay should request music or sound effects, and the shared `PokeAudio` host renders those events into stereo PCM with waveform-specific synthesis, Game Boy-aware modulation, and a small amount of conditioning needed for clean native playback. `PokeAudioService` then schedules the rendered buffers through `AVAudioEngine` while preserving channel contention and priority behavior close to the original game.
