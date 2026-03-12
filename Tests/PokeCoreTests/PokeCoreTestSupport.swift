import XCTest
@testable import PokeCore
import PokeContent
import PokeDataModel

@MainActor
func fixtureContent(
    gameplayManifest: GameplayManifest? = nil,
    audioManifest: AudioManifest? = nil
) -> LoadedContent {
    LoadedContent(
        rootURL: URL(fileURLWithPath: "/tmp", isDirectory: true),
        gameManifest: .init(contentVersion: "test", variant: .red, sourceCommit: "abc", extractorVersion: "1", sourceFiles: []),
        constantsManifest: .init(variant: .red, sourceFiles: [], watchedKeys: ["PAD_A", "PAD_B", "PAD_START"], musicTrack: "MUSIC_TITLE_SCREEN", titleMonSelectionConstant: "STARTER1"),
        charmapManifest: .init(variant: .red, entries: [.init(token: "A", value: 0x80, sourceSection: "test")]),
        titleManifest: .init(
            variant: .red,
            sourceFiles: [],
            titleMonSpecies: "STARTER1",
            menuEntries: [
                .init(id: "newGame", label: "New Game", enabledByDefault: true),
                .init(id: "continue", label: "Continue", enabledByDefault: false),
                .init(id: "options", label: "Options", enabledByDefault: true),
            ],
            logoBounceSequence: [],
            assets: [],
            timings: .init(launchFadeSeconds: 0.4, splashDurationSeconds: 1.2, attractPromptDelaySeconds: 0.8)
        ),
        audioManifest: audioManifest ?? fixtureAudioManifest(),
        gameplayManifest: gameplayManifest ?? fixtureGameplayManifest()
    )
}

@MainActor
func fixtureGameplayManifest(
    dialogues: [DialogueManifest] = [],
    fieldInteractions: [FieldInteractionManifest] = [],
    scripts: [ScriptManifest] = [],
    species: [SpeciesManifest] = [],
    items: [ItemManifest] = [],
    moves: [MoveManifest] = [],
    typeEffectiveness: [TypeEffectivenessManifest] = [],
    wildEncounterTables: [WildEncounterTableManifest] = [],
    maps: [MapManifest]? = nil,
    tilesets: [TilesetManifest]? = nil,
    trainerAIMoveChoiceModifications: [TrainerAIMoveChoiceModificationManifest] = [],
    trainerBattles: [TrainerBattleManifest] = [],
    marts: [MartManifest] = []
) -> GameplayManifest {
    GameplayManifest(
        maps: maps ?? [
            .init(
                id: "REDS_HOUSE_2F",
                displayName: "Red's House 2F",
                defaultMusicID: "MUSIC_PALLET_TOWN",
                borderBlockID: 0x0A,
                blockWidth: 4,
                blockHeight: 4,
                stepWidth: 8,
                stepHeight: 8,
                tileset: "REDS_HOUSE_2",
                blockIDs: Array(repeating: 0x05, count: 16),
                stepCollisionTileIDs: Array(repeating: 0x01, count: 64),
                warps: [],
                backgroundEvents: [],
                objects: []
            ),
        ],
        tilesets: tilesets ?? [
            .init(
                id: "REDS_HOUSE_2",
                imagePath: "Assets/field/tilesets/reds_house.png",
                blocksetPath: "Assets/field/blocksets/reds_house.bst",
                sourceTileSize: 8,
                blockTileWidth: 4,
                blockTileHeight: 4,
                collision: .init(
                    passableTileIDs: [0x01, 0x02],
                    warpTileIDs: [],
                    doorTileIDs: [],
                    tilePairCollisions: [],
                    ledges: []
                )
            ),
        ],
        overworldSprites: [
            .init(
                id: "SPRITE_RED",
                imagePath: "Assets/field/sprites/red.png",
                frameWidth: 16,
                frameHeight: 16,
                facingFrames: .init(
                    down: .init(x: 0, y: 0, width: 16, height: 16),
                    up: .init(x: 0, y: 16, width: 16, height: 16),
                    left: .init(x: 0, y: 32, width: 16, height: 16),
                    right: .init(x: 0, y: 32, width: 16, height: 16, flippedHorizontally: true)
                )
            ),
        ],
        dialogues: dialogues,
        fieldInteractions: fieldInteractions,
        eventFlags: .init(flags: []),
        mapScripts: [],
        scripts: scripts,
        items: items,
        marts: marts,
        species: species,
        moves: moves,
        typeEffectiveness: typeEffectiveness,
        wildEncounterTables: wildEncounterTables,
        trainerAIMoveChoiceModifications: trainerAIMoveChoiceModifications,
        trainerBattles: trainerBattles,
        playerStart: .init(mapID: "REDS_HOUSE_2F", position: .init(x: 4, y: 4), facing: .down, playerName: "RED", rivalName: "BLUE", initialFlags: [])
    )
}

@MainActor
func fixtureAudioManifest() -> AudioManifest {
    AudioManifest(
        variant: .red,
        titleTrackID: "MUSIC_TITLE_SCREEN",
        mapRoutes: [.init(mapID: "REDS_HOUSE_2F", musicID: "MUSIC_PALLET_TOWN")],
        cues: [
            .init(id: "title_default", assetID: "MUSIC_TITLE_SCREEN"),
            .init(id: "trainer_intro_male", assetID: "MUSIC_MEET_MALE_TRAINER"),
            .init(id: "trainer_intro_female", assetID: "MUSIC_MEET_FEMALE_TRAINER"),
            .init(id: "trainer_intro_evil", assetID: "MUSIC_MEET_EVIL_TRAINER"),
            .init(id: "trainer_battle", assetID: "MUSIC_TRAINER_BATTLE"),
            .init(
                id: "mom_heal",
                assetID: "MUSIC_PKMN_HEALED",
                waitForCompletion: true,
                resumeMusicAfterCompletion: true
            ),
            .init(
                id: "pokemon_center_healed",
                assetID: "MUSIC_PKMN_HEALED",
                waitForCompletion: true,
                resumeMusicAfterCompletion: true
            ),
        ],
        tracks: [
            .init(
                id: "MUSIC_TITLE_SCREEN",
                sourceLabel: "Music_TitleScreen",
                sourceFile: "audio/music/titlescreen.asm",
                entries: [.init(id: "default", sourceLabel: "Music_TitleScreen_Ch1", playbackMode: .looping, channels: [])]
            ),
            .init(
                id: "MUSIC_PALLET_TOWN",
                sourceLabel: "Music_PalletTown",
                sourceFile: "audio/music/pallettown.asm",
                entries: [.init(id: "default", sourceLabel: "Music_PalletTown_Ch1", playbackMode: .looping, channels: [])]
            ),
            .init(
                id: "MUSIC_MEET_MALE_TRAINER",
                sourceLabel: "Music_MeetMaleTrainer",
                sourceFile: "audio/music/meettrainer.asm",
                entries: [.init(id: "default", sourceLabel: "Music_MeetMaleTrainer_Ch1", playbackMode: .looping, channels: [])]
            ),
            .init(
                id: "MUSIC_MEET_FEMALE_TRAINER",
                sourceLabel: "Music_MeetFemaleTrainer",
                sourceFile: "audio/music/meettrainer.asm",
                entries: [.init(id: "default", sourceLabel: "Music_MeetFemaleTrainer_Ch1", playbackMode: .looping, channels: [])]
            ),
            .init(
                id: "MUSIC_MEET_EVIL_TRAINER",
                sourceLabel: "Music_MeetEvilTrainer",
                sourceFile: "audio/music/meettrainer.asm",
                entries: [.init(id: "default", sourceLabel: "Music_MeetEvilTrainer_Ch1", playbackMode: .looping, channels: [])]
            ),
            .init(
                id: "MUSIC_TRAINER_BATTLE",
                sourceLabel: "Music_TrainerBattle",
                sourceFile: "audio/music/trainerbattle.asm",
                entries: [.init(id: "default", sourceLabel: "Music_TrainerBattle_Ch1", playbackMode: .looping, channels: [])]
            ),
            .init(
                id: "MUSIC_PKMN_HEALED",
                sourceLabel: "Music_PkmnHealed",
                sourceFile: "audio/music/pkmnhealed.asm",
                entries: [.init(id: "default", sourceLabel: "Music_PkmnHealed_Ch1", playbackMode: .oneShot, channels: [])]
            ),
        ],
        soundEffects: [
            .init(
                id: "SFX_PRESS_AB",
                sourceLabel: "SFX_Press_AB",
                sourceFile: "audio/sfx/press_ab.asm",
                bank: 2,
                priority: 0,
                order: 0,
                requestedChannels: [5],
                channels: []
            ),
            .init(
                id: "SFX_COLLISION",
                sourceLabel: "SFX_Collision",
                sourceFile: "audio/sfx/collision.asm",
                bank: 2,
                priority: 0,
                order: 0,
                requestedChannels: [5],
                channels: []
            ),
            .init(
                id: "SFX_HEALING_MACHINE",
                sourceLabel: "SFX_HealingMachine",
                sourceFile: "audio/sfx/healing_machine_1.asm",
                bank: 1,
                priority: 0,
                order: 0,
                requestedChannels: [5],
                channels: []
            ),
        ]
    )
}

@MainActor
func drainBattleText(_ runtime: GameRuntime, maxTicks: Int = 240) {
    advanceBattleTextUntilMoveSelection(runtime, maxTicks: maxTicks)
}

@MainActor
func advanceBattleTextUntilMoveSelection(_ runtime: GameRuntime, maxTicks: Int = 240) {
    let pollInterval = 0.01
    let deadline = Date().addingTimeInterval(Double(maxTicks) * pollInterval)

    while Date() < deadline {
        guard let battle = runtime.currentSnapshot().battle else {
            XCTFail("battle ended before returning to move selection")
            return
        }
        if battle.phase == "moveSelection" {
            return
        }
        if battle.phase == "trainerAboutToUseDecision" {
            runtime.handle(button: .down)
        }
        runtime.handle(button: .confirm)
        RunLoop.current.run(until: Date().addingTimeInterval(pollInterval))
    }

    XCTAssertEqual(runtime.currentSnapshot().battle?.phase, "moveSelection", "battle text did not resolve to move selection")
}

@MainActor
func advanceBattleUntilPhase(
    _ runtime: GameRuntime,
    phase targetPhase: String,
    maxTicks: Int = 240
) {
    let pollInterval = 0.01
    let deadline = Date().addingTimeInterval(Double(maxTicks) * pollInterval)

    while Date() < deadline {
        guard let battle = runtime.currentSnapshot().battle else {
            XCTFail("battle ended before reaching phase \(targetPhase)")
            return
        }
        if battle.phase == targetPhase {
            return
        }
        if battle.phase == "trainerAboutToUseDecision", targetPhase != "trainerAboutToUseDecision" {
            runtime.handle(button: .down)
        }
        runtime.handle(button: .confirm)
        RunLoop.current.run(until: Date().addingTimeInterval(pollInterval))
    }

    XCTAssertEqual(runtime.currentSnapshot().battle?.phase, targetPhase, "battle did not reach phase \(targetPhase)")
}

@MainActor
func drainBattleUntilComplete(_ runtime: GameRuntime, maxTicks: Int = 240) {
    resolveBattleUntilComplete(runtime, maxTicks: maxTicks)
}

@MainActor
func resolveBattleUntilComplete(
    _ runtime: GameRuntime,
    maxTicks: Int = 240,
    observe: ((BattleTelemetry) -> Void)? = nil
) {
    let pollInterval = 0.01
    let deadline = Date().addingTimeInterval(Double(maxTicks) * pollInterval)

    while runtime.scene == .battle, Date() < deadline {
        if let battle = runtime.currentSnapshot().battle {
            observe?(battle)
            if battle.phase == "trainerAboutToUseDecision" {
                runtime.handle(button: .down)
            }
            runtime.handle(button: .confirm)
        }
        RunLoop.current.run(until: Date().addingTimeInterval(pollInterval))
    }

    XCTAssertNotEqual(runtime.scene, .battle, "battle did not resolve")
}

@MainActor
func advanceBattlePresentationBatch(_ runtime: GameRuntime, maxTicks: Int = 120) {
    waitUntil(
        runtime.battlePresentationTask == nil &&
            (runtime.gameplayState?.battle?.pendingPresentationBatches.isEmpty == false),
        message: "battle did not pause for the next presentation batch",
        maxTicks: maxTicks
    )
    runtime.handle(button: .confirm)
}

@MainActor
func waitUntil(
    _ predicate: @autoclosure @escaping () -> Bool,
    message: String,
    maxTicks: Int = 80
) {
    if predicate() {
        return
    }

    let pollInterval = 0.01
    let deadline = Date().addingTimeInterval(Double(maxTicks) * pollInterval)

    while Date() < deadline {
        if predicate() {
            return
        }
        RunLoop.current.run(until: Date().addingTimeInterval(pollInterval))
    }

    XCTAssertTrue(predicate(), message)
}

@MainActor
func captureBattleTimeline(
    _ runtime: GameRuntime,
    duration: TimeInterval = 0.45,
    pollInterval: TimeInterval = 0.005
) -> [BattleTelemetry] {
    var history: [BattleTelemetry] = []
    let deadline = Date().addingTimeInterval(duration)

    while Date() < deadline {
        if let snapshot = runtime.currentSnapshot().battle,
           history.last != snapshot {
            history.append(snapshot)
        }
        RunLoop.current.run(until: Date().addingTimeInterval(pollInterval))
    }

    if let snapshot = runtime.currentSnapshot().battle,
       history.last != snapshot {
        history.append(snapshot)
    }

    return history
}

@MainActor
func advanceDialogueUntilComplete(_ runtime: GameRuntime, maxInteractions: Int = 8) {
    var remaining = maxInteractions
    while runtime.dialogueState != nil {
        XCTAssertGreaterThan(remaining, 0, "dialogue did not complete")
        remaining -= 1
        runtime.handle(button: .confirm)
    }
}

@MainActor
func drainDialogueAndScripts(
    _ runtime: GameRuntime,
    until predicate: (RuntimeTelemetrySnapshot) -> Bool,
    maxInteractions: Int = 64
) {
    var remaining = maxInteractions
    while predicate(runtime.currentSnapshot()) == false {
        XCTAssertGreaterThan(remaining, 0, "dialogue/script sequence did not reach expected state")
        remaining -= 1
        switch runtime.scene {
        case .dialogue:
            runtime.handle(button: .confirm)
        case .field, .scriptedSequence:
            runtime.advanceDeferredQueueIfNeeded()
            runtime.runActiveScript()
        default:
            XCTFail("unexpected scene while draining dialogue/script sequence: \(runtime.scene)")
            return
        }
    }
}

actor RecordingTelemetryPublisher: TelemetryPublisher {
    private(set) var events: [RuntimeSessionEvent] = []

    func publish(snapshot: RuntimeTelemetrySnapshot) async {}

    func publish(event: RuntimeSessionEvent) async {
        events.append(event)
    }

    func waitForEventCount(_ expectedCount: Int, attempts: Int = 40) async {
        for _ in 0..<attempts where events.count < expectedCount {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }
}

@MainActor
func repoRoot() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
}

@MainActor
func makeRepoRuntime(audioPlayer: RuntimeAudioPlaying? = nil) throws -> GameRuntime {
    let contentRoot = repoRoot().appendingPathComponent("Content/Red", isDirectory: true)
    let content = try FileSystemContentLoader(rootURL: contentRoot).load()
    return GameRuntime(content: content, telemetryPublisher: nil, audioPlayer: audioPlayer)
}

@MainActor
func findConnectionStart(
    from sourceMapID: String,
    moving direction: FacingDirection,
    expecting targetMapID: String,
    requiredFlags: [String] = []
) throws -> TilePoint {
    let probe = try makeRepoRuntime()
    let map = try XCTUnwrap(probe.content.map(id: sourceMapID))

    for y in 0..<map.stepHeight {
        for x in 0..<map.stepWidth {
            probe.gameplayState = probe.makeInitialGameplayState()
            probe.scene = .field
            probe.substate = "field"
            probe.gameplayState?.mapID = sourceMapID
            probe.gameplayState?.playerPosition = .init(x: x, y: y)
            probe.gameplayState?.facing = direction
            probe.gameplayState?.activeFlags.formUnion(requiredFlags)
            probe.movePlayer(in: direction)
            if probe.gameplayState?.mapID == targetMapID {
                return .init(x: x, y: y)
            }
        }
    }

    XCTFail("failed to find a \(direction.rawValue) connection from \(sourceMapID) to \(targetMapID)")
    return .init(x: 0, y: 0)
}

@MainActor
func findGrassTile(in runtime: GameRuntime, mapID: String) throws -> TilePoint {
    let map = try XCTUnwrap(runtime.content.map(id: mapID))
    for y in 0..<map.stepHeight {
        for x in 0..<map.stepWidth {
            let point = TilePoint(x: x, y: y)
            if runtime.isStandingOnGrass(in: map, position: point) {
                return point
            }
        }
    }

    XCTFail("failed to find grass in \(mapID)")
    return .init(x: 0, y: 0)
}

@MainActor
func waitForSnapshot(
    _ runtime: GameRuntime,
    timeout: TimeInterval = 1.5,
    matching predicate: (RuntimeTelemetrySnapshot) -> Bool
) async throws -> RuntimeTelemetrySnapshot {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        let snapshot = runtime.currentSnapshot()
        if predicate(snapshot) {
            return snapshot
        }
        try await Task.sleep(for: .milliseconds(10))
    }
    throw XCTSkip("timed out waiting for expected runtime snapshot")
}
@MainActor
final class RecordingAudioPlayer: RuntimeAudioPlaying {
    private(set) var musicRequests: [MusicPlaybackRequest] = []
    private(set) var soundEffectRequests: [SoundEffectPlaybackRequest] = []
    private(set) var stopAllMusicCount = 0
    private var pendingCompletions: [() -> Void] = []

    var pendingCompletionCount: Int {
        pendingCompletions.count
    }

    func playMusic(request: MusicPlaybackRequest, completion: (@MainActor @Sendable () -> Void)?) {
        musicRequests.append(request)
        if let completion {
            pendingCompletions.append(completion)
        }
    }

    func playSFX(
        request: SoundEffectPlaybackRequest,
        completion: (@MainActor @Sendable () -> Void)?
    ) -> SoundEffectPlaybackResult {
        soundEffectRequests.append(request)
        if let completion {
            pendingCompletions.append(completion)
        }
        return .init(soundEffectID: request.soundEffectID, status: .started)
    }

    func stopAllMusic() {
        stopAllMusicCount += 1
    }

    func completePendingPlayback() {
        guard pendingCompletions.isEmpty == false else { return }
        let completion = pendingCompletions.removeFirst()
        completion()
    }
}

enum InMemorySaveStoreError: Error {
    case corrupt
}

final class InMemorySaveStore: @unchecked Sendable, SaveStore {
    var envelope: GameSaveEnvelope?
    var metadataError: Error?

    func hasSaveFile() -> Bool {
        envelope != nil || metadataError != nil
    }

    func loadMetadata() throws -> GameSaveMetadata? {
        if let metadataError {
            throw metadataError
        }
        return envelope?.metadata
    }

    func loadSave() throws -> GameSaveEnvelope? {
        if let metadataError {
            throw metadataError
        }
        return envelope
    }

    func save(_ envelope: GameSaveEnvelope) throws {
        self.envelope = envelope
        metadataError = nil
    }

    func deleteSave() throws {
        envelope = nil
    }
}
