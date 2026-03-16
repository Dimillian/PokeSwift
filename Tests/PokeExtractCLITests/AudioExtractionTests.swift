import XCTest
import PokeDataModel

final class AudioExtractionTests: XCTestCase {
    private static let repoManifest: AudioManifest = {
        try! makeFreshManifest()
    }()

    func testAudioExtractorBuildsCurrentSliceManifestFromRepoSources() throws {
        let manifest = Self.repoManifest

        XCTAssertEqual(manifest.variant, .red)
        XCTAssertEqual(manifest.titleTrackID, "MUSIC_TITLE_SCREEN")
        XCTAssertEqual(manifest.mapRoutes.count, 41)
        XCTAssertTrue(manifest.mapRoutes.contains(.init(mapID: "CERULEAN_CITY", musicID: "MUSIC_CITIES2")))
        XCTAssertTrue(manifest.mapRoutes.contains(.init(mapID: "BIKE_SHOP", musicID: "MUSIC_CITIES2")))
        XCTAssertTrue(manifest.mapRoutes.contains(.init(mapID: "BILLS_HOUSE", musicID: "MUSIC_CITIES2")))
        XCTAssertTrue(manifest.mapRoutes.contains(.init(mapID: "CERULEAN_GYM", musicID: "MUSIC_GYM")))
        XCTAssertTrue(manifest.mapRoutes.contains(.init(mapID: "ROUTE_24", musicID: "MUSIC_ROUTES2")))
        XCTAssertTrue(manifest.mapRoutes.contains(.init(mapID: "ROUTE_25", musicID: "MUSIC_ROUTES2")))
        XCTAssertTrue(manifest.mapRoutes.contains(.init(mapID: "ROUTE_1", musicID: "MUSIC_ROUTES1")))
        XCTAssertTrue(manifest.mapRoutes.contains(.init(mapID: "MT_MOON_1F", musicID: "MUSIC_DUNGEON3")))

        let cueByID = Dictionary(uniqueKeysWithValues: manifest.cues.map { ($0.id, $0) })
        XCTAssertEqual(cueByID["title_default"]?.trackID, "MUSIC_TITLE_SCREEN")
        XCTAssertEqual(cueByID["oak_intro"]?.trackID, "MUSIC_MEET_PROF_OAK")
        XCTAssertEqual(cueByID["rival_intro"]?.trackID, "MUSIC_MEET_RIVAL")
        XCTAssertEqual(cueByID["rival_exit"]?.entryID, "alternateStart")
        XCTAssertEqual(cueByID["trainer_intro_male"]?.trackID, "MUSIC_MEET_MALE_TRAINER")
        XCTAssertEqual(cueByID["trainer_intro_female"]?.trackID, "MUSIC_MEET_FEMALE_TRAINER")
        XCTAssertEqual(cueByID["trainer_intro_evil"]?.trackID, "MUSIC_MEET_EVIL_TRAINER")
        XCTAssertEqual(cueByID["trainer_battle"]?.trackID, "MUSIC_TRAINER_BATTLE")
        XCTAssertEqual(cueByID["trainer_victory"]?.trackID, "MUSIC_DEFEATED_TRAINER")
        XCTAssertEqual(cueByID["wild_victory"]?.trackID, "MUSIC_DEFEATED_WILD_MON")
        XCTAssertEqual(cueByID["evolution"]?.trackID, "MUSIC_SAFARI_ZONE")
        XCTAssertEqual(cueByID["mom_heal"]?.trackID, "MUSIC_PKMN_HEALED")
        XCTAssertEqual(cueByID["mom_heal"]?.waitForCompletion, true)
        XCTAssertEqual(cueByID["mom_heal"]?.resumeMusicAfterCompletion, true)
        XCTAssertEqual(cueByID["pokemon_center_healed"]?.trackID, "MUSIC_PKMN_HEALED")
        XCTAssertEqual(cueByID["pokemon_center_healed"]?.waitForCompletion, true)
        XCTAssertEqual(cueByID["pokemon_center_healed"]?.resumeMusicAfterCompletion, true)

        let requiredTrackIDs: Set<String> = [
            "MUSIC_TITLE_SCREEN",
            "MUSIC_PALLET_TOWN",
            "MUSIC_OAKS_LAB",
            "MUSIC_ROUTES1",
            "MUSIC_ROUTES2",
            "MUSIC_ROUTES3",
            "MUSIC_CITIES1",
            "MUSIC_CITIES2",
            "MUSIC_DUNGEON2",
            "MUSIC_DUNGEON3",
            "MUSIC_GYM",
            "MUSIC_POKECENTER",
            "MUSIC_MEET_PROF_OAK",
            "MUSIC_MEET_RIVAL",
            "MUSIC_MEET_MALE_TRAINER",
            "MUSIC_MEET_FEMALE_TRAINER",
            "MUSIC_MEET_EVIL_TRAINER",
            "MUSIC_TRAINER_BATTLE",
            "MUSIC_DEFEATED_TRAINER",
            "MUSIC_DEFEATED_WILD_MON",
            "MUSIC_SAFARI_ZONE",
            "MUSIC_PKMN_HEALED",
        ]
        XCTAssertTrue(requiredTrackIDs.isSubset(of: Set(manifest.tracks.map(\.id))))

        let rivalTrack = try XCTUnwrap(manifest.tracks.first { $0.id == "MUSIC_MEET_RIVAL" })
        XCTAssertNotNil(rivalTrack.entries.first { $0.id == "default" })
        XCTAssertNotNil(rivalTrack.entries.first { $0.id == "alternateStart" })
        XCTAssertEqual(rivalTrack.entries.first { $0.id == "alternateStart" }?.playbackMode, .looping)

        let soundEffectsByID = Dictionary(uniqueKeysWithValues: manifest.soundEffects.map { ($0.id, $0) })
        XCTAssertEqual(soundEffectsByID["SFX_PRESS_AB"]?.requestedChannels, [5])
        XCTAssertEqual(soundEffectsByID["SFX_COLLISION"]?.requestedChannels, [5])
        XCTAssertEqual(soundEffectsByID["SFX_GO_INSIDE"]?.requestedChannels, [8])
        XCTAssertEqual(soundEffectsByID["SFX_GO_OUTSIDE"]?.requestedChannels, [8])
        XCTAssertEqual(soundEffectsByID["SFX_LEVEL_UP"]?.requestedChannels, [5, 6, 7])
        XCTAssertEqual(soundEffectsByID["SFX_POUND"]?.requestedChannels, [8])
    }

    func testAudioExtractorQuantizesOakLabLeadToEngineFrameDurations() throws {
        let manifest = Self.repoManifest

        let oakLabTrack = try XCTUnwrap(manifest.tracks.first { $0.id == "MUSIC_OAKS_LAB" })
        let channelOne = try XCTUnwrap(
            oakLabTrack.entries.first { $0.id == "default" }?.channels.first { $0.channelNumber == 1 }
        )
        let opening = Array(channelOne.prelude.prefix(4))
        XCTAssertEqual(opening.count, 4)

        XCTAssertEqual(opening[0].duration, 6.0 / 60.0, accuracy: 0.000_001)
        XCTAssertEqual(opening[1].duration, 7.0 / 60.0, accuracy: 0.000_001)
        XCTAssertEqual(opening[2].duration, 6.0 / 60.0, accuracy: 0.000_001)
        XCTAssertEqual(opening[3].duration, 7.0 / 60.0, accuracy: 0.000_001)
        XCTAssertEqual(opening[1].startTime, 6.0 / 60.0, accuracy: 0.000_001)
        XCTAssertEqual(opening[2].startTime, 13.0 / 60.0, accuracy: 0.000_001)
        XCTAssertEqual(opening[3].startTime, 19.0 / 60.0, accuracy: 0.000_001)
    }

    func testAudioExtractorAppliesTrackTempoToSecondaryChannels() throws {
        let manifest = Self.repoManifest

        let titleTrack = try XCTUnwrap(manifest.tracks.first { $0.id == "MUSIC_TITLE_SCREEN" })
        let channelTwo = try XCTUnwrap(
            titleTrack.entries.first { $0.id == "default" }?.channels.first { $0.channelNumber == 2 }
        )
        let firstEvent = try XCTUnwrap(channelTwo.prelude.first)

        XCTAssertEqual(firstEvent.duration, 6.0 / 60.0, accuracy: 0.000_001)
    }

    func testAudioExtractorIncludesTitleScreenDrumPreludeEvents() throws {
        let manifest = Self.repoManifest

        let titleTrack = try XCTUnwrap(manifest.tracks.first { $0.id == "MUSIC_TITLE_SCREEN" })
        let channelFour = try XCTUnwrap(
            titleTrack.entries.first { $0.id == "default" }?.channels.first { $0.channelNumber == 4 }
        )
        let firstEvent = try XCTUnwrap(channelFour.prelude.first)

        XCTAssertFalse(channelFour.prelude.isEmpty)
        XCTAssertEqual(firstEvent.waveform, .noise)
        XCTAssertGreaterThan(try XCTUnwrap(firstEvent.frequencyHz), 0)
        XCTAssertNotNil(firstEvent.noiseShortMode)
        XCTAssertGreaterThan(firstEvent.duration, 0)
    }

    func testAudioExtractorUsesGBNoiseClockFormulaForDoorTransitionSFX() throws {
        let manifest = Self.repoManifest

        let goInside = try XCTUnwrap(manifest.soundEffects.first { $0.id == "SFX_GO_INSIDE" })
        let channelEight = try XCTUnwrap(goInside.channels.first { $0.channelNumber == 8 })
        let opening = Array(channelEight.prelude.prefix(2))
        let firstFrequency = try XCTUnwrap(opening[0].frequencyHz)
        let secondFrequency = try XCTUnwrap(opening[1].frequencyHz)

        XCTAssertEqual(opening.count, 2)
        XCTAssertEqual(opening[0].waveform, .noise)
        XCTAssertEqual(firstFrequency, 4_096, accuracy: 0.000_001)
        XCTAssertEqual(secondFrequency, 5_461.333_333_333_333, accuracy: 0.000_001)
    }

    func testAudioExtractorCarriesPitchSlideTargetsIntoPkmnHealedLead() throws {
        let manifest = Self.repoManifest

        let healTrack = try XCTUnwrap(manifest.tracks.first { $0.id == "MUSIC_PKMN_HEALED" })
        let channelOne = try XCTUnwrap(
            healTrack.entries.first { $0.id == "default" }?.channels.first { $0.channelNumber == 1 }
        )
        let opening = Array(channelOne.prelude.prefix(3))
        let firstSlideTarget = try XCTUnwrap(opening[0].pitchSlideTargetHz)
        let firstFrequency = try XCTUnwrap(opening[0].frequencyHz)
        let secondSlideTarget = try XCTUnwrap(opening[1].pitchSlideTargetHz)
        let secondFrequency = try XCTUnwrap(opening[1].frequencyHz)
        let thirdSlideTarget = try XCTUnwrap(opening[2].pitchSlideTargetHz)
        let slideFrames = opening.compactMap(\.pitchSlideFrameCount)

        XCTAssertEqual(opening.count, 3)
        XCTAssertEqual(slideFrames, [14, 13, 14])
        XCTAssertEqual(firstSlideTarget, firstFrequency, accuracy: 0.000_001)
        XCTAssertLessThan(secondSlideTarget, secondFrequency)
        XCTAssertEqual(thirdSlideTarget, 661.979_797_979_798, accuracy: 0.000_001)
    }

    func testAudioExtractorCarriesRawGBVibratoIntoCeruleanLead() throws {
        let manifest = Self.repoManifest

        let ceruleanTrack = try XCTUnwrap(manifest.tracks.first { $0.id == "MUSIC_CITIES2" })
        let channelOne = try XCTUnwrap(
            ceruleanTrack.entries.first { $0.id == "default" }?.channels.first { $0.channelNumber == 1 }
        )
        let firstVibratoEvent = try XCTUnwrap(
            channelOne.loop.first {
                $0.vibratoExtentUp > 0 || $0.vibratoExtentDown > 0
            }
        )

        XCTAssertEqual(firstVibratoEvent.vibratoDelayFrames, 8)
        XCTAssertEqual(firstVibratoEvent.vibratoExtentUp, 2)
        XCTAssertEqual(firstVibratoEvent.vibratoExtentDown, 1)
        XCTAssertEqual(firstVibratoEvent.vibratoRateFrames, 2)
    }

    func testAudioExtractorUsesASMFrequencyTableForPerfectPitchSquareChannel() throws {
        let manifest = Self.repoManifest

        let oakIntroTrack = try XCTUnwrap(manifest.tracks.first { $0.id == "MUSIC_MEET_PROF_OAK" })
        let channelOne = try XCTUnwrap(
            oakIntroTrack.entries.first { $0.id == "default" }?.channels.first { $0.channelNumber == 1 }
        )
        let firstEvent = try XCTUnwrap(channelOne.prelude.first)
        let frequency = try XCTUnwrap(firstEvent.frequencyHz)

        XCTAssertEqual(frequency, 370.259_887_005_649_7, accuracy: 0.000_001)
    }

    func testAudioExtractorUsesWaveChannelFrequencyFormulaForOakIntroCounterline() throws {
        let manifest = Self.repoManifest

        let oakIntroTrack = try XCTUnwrap(manifest.tracks.first { $0.id == "MUSIC_MEET_PROF_OAK" })
        let channelThree = try XCTUnwrap(
            oakIntroTrack.entries.first { $0.id == "default" }?.channels.first { $0.channelNumber == 3 }
        )
        let firstEvent = try XCTUnwrap(channelThree.prelude.first)
        let frequency = try XCTUnwrap(firstEvent.frequencyHz)

        XCTAssertEqual(frequency, 368.179_775_280_898_87, accuracy: 0.000_001)
    }

    func testAudioExtractorMapsLevelUpSFXChannelsToToneHardware() throws {
        let manifest = Self.repoManifest

        let levelUp = try XCTUnwrap(manifest.soundEffects.first { $0.id == "SFX_LEVEL_UP" })
        let channelFive = try XCTUnwrap(levelUp.channels.first { $0.channelNumber == 5 })
        let channelSix = try XCTUnwrap(levelUp.channels.first { $0.channelNumber == 6 })
        let channelSeven = try XCTUnwrap(levelUp.channels.first { $0.channelNumber == 7 })

        XCTAssertEqual(channelFive.prelude.first?.waveform, .square)
        XCTAssertEqual(channelSix.prelude.first?.waveform, .square)
        XCTAssertEqual(channelSeven.prelude.first?.waveform, .wave)
    }

    func testAudioExtractorCarriesPitchSweepIntoBallPoofSquareChannel() throws {
        let manifest = Self.repoManifest

        let ballPoof = try XCTUnwrap(manifest.soundEffects.first { $0.id == "SFX_BALL_POOF" })
        let channelFive = try XCTUnwrap(ballPoof.channels.first { $0.channelNumber == 5 })
        let firstEvent = try XCTUnwrap(channelFive.prelude.first)
        let targetRegister = try XCTUnwrap(firstEvent.pitchSlideTargetRegister)
        let targetHz = try XCTUnwrap(firstEvent.pitchSlideTargetHz)
        let frameCount = try XCTUnwrap(firstEvent.pitchSlideFrameCount)

        XCTAssertEqual(firstEvent.waveform, .square)
        XCTAssertEqual(firstEvent.frequencyRegister, 1024)
        XCTAssertGreaterThan(targetRegister, 1024)
        XCTAssertEqual(frameCount, 16)
        XCTAssertGreaterThan(targetHz, 128)
    }

    func testAudioExtractorCarriesDutyCyclePatternIntoCrySquareChannel() throws {
        let manifest = Self.repoManifest

        let cry = try XCTUnwrap(manifest.soundEffects.first { $0.id == "SFX_CRY_00" })
        let channelFive = try XCTUnwrap(cry.channels.first { $0.channelNumber == 5 })
        let firstEvent = try XCTUnwrap(channelFive.prelude.first)
        let dutyCycle = try XCTUnwrap(firstEvent.dutyCycle)

        XCTAssertEqual(firstEvent.waveform, .square)
        XCTAssertEqual(dutyCycle, 0.75, accuracy: 0.000_001)
        XCTAssertEqual(firstEvent.dutyCyclePattern, 0xF5)
        XCTAssertEqual(firstEvent.dutyCyclePatternStepOffset, 0)
    }

    func testExtractorWritesDeterministicAudioManifestJSON() throws {
        let first = try Self.encodeJSON(Self.makeFreshManifest())
        let second = try Self.encodeJSON(Self.makeFreshManifest())
        XCTAssertEqual(first, second)

        let decoded = try JSONDecoder().decode(AudioManifest.self, from: first)
        XCTAssertEqual(decoded.titleTrackID, "MUSIC_TITLE_SCREEN")
        XCTAssertEqual(decoded.mapRoutes.count, 41)
        XCTAssertEqual(decoded.cues.count, 13)
        XCTAssertEqual(decoded.tracks.count, 22)
        XCTAssertNotNil(decoded.tracks.first { $0.id == "MUSIC_MEET_RIVAL" }?.entries.first { $0.id == "alternateStart" })
    }

    private static func makeFreshManifest() throws -> AudioManifest {
        try extractAudioManifest(
            source: SourceTree(repoRoot: PokeExtractCLITestSupport.repoRoot()),
            titleTrackID: "MUSIC_TITLE_SCREEN"
        )
    }

    private static func encodeJSON<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(value) + Data("\n".utf8)
    }
}
