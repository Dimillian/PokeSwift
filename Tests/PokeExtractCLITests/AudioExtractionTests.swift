import XCTest
import PokeDataModel

final class AudioExtractionTests: XCTestCase {
    func testAudioExtractorBuildsEarlyM4ManifestFromRepoSources() throws {
        let manifest = try extractAudioManifest(
            source: SourceTree(repoRoot: PokeExtractCLITestSupport.repoRoot()),
            titleTrackID: "MUSIC_TITLE_SCREEN"
        )

        XCTAssertEqual(manifest.variant, .red)
        XCTAssertEqual(manifest.titleTrackID, "MUSIC_TITLE_SCREEN")
        XCTAssertEqual(
            manifest.mapRoutes,
            [
                .init(mapID: "MUSEUM_1F", musicID: "MUSIC_CITIES1"),
                .init(mapID: "MUSEUM_2F", musicID: "MUSIC_CITIES1"),
                .init(mapID: "OAKS_LAB", musicID: "MUSIC_OAKS_LAB"),
                .init(mapID: "PALLET_TOWN", musicID: "MUSIC_PALLET_TOWN"),
                .init(mapID: "PEWTER_CITY", musicID: "MUSIC_CITIES1"),
                .init(mapID: "PEWTER_GYM", musicID: "MUSIC_GYM"),
                .init(mapID: "PEWTER_MART", musicID: "MUSIC_POKECENTER"),
                .init(mapID: "PEWTER_NIDORAN_HOUSE", musicID: "MUSIC_CITIES1"),
                .init(mapID: "PEWTER_POKECENTER", musicID: "MUSIC_POKECENTER"),
                .init(mapID: "PEWTER_SPEECH_HOUSE", musicID: "MUSIC_CITIES1"),
                .init(mapID: "REDS_HOUSE_1F", musicID: "MUSIC_PALLET_TOWN"),
                .init(mapID: "REDS_HOUSE_2F", musicID: "MUSIC_PALLET_TOWN"),
                .init(mapID: "ROUTE_1", musicID: "MUSIC_ROUTES1"),
                .init(mapID: "ROUTE_2", musicID: "MUSIC_ROUTES1"),
                .init(mapID: "ROUTE_22", musicID: "MUSIC_ROUTES3"),
                .init(mapID: "ROUTE_22_GATE", musicID: "MUSIC_DUNGEON2"),
                .init(mapID: "ROUTE_3", musicID: "MUSIC_ROUTES3"),
                .init(mapID: "VIRIDIAN_CITY", musicID: "MUSIC_CITIES1"),
                .init(mapID: "VIRIDIAN_FOREST", musicID: "MUSIC_DUNGEON2"),
                .init(mapID: "VIRIDIAN_FOREST_NORTH_GATE", musicID: "MUSIC_CITIES1"),
                .init(mapID: "VIRIDIAN_FOREST_SOUTH_GATE", musicID: "MUSIC_CITIES1"),
                .init(mapID: "VIRIDIAN_MART", musicID: "MUSIC_POKECENTER"),
                .init(mapID: "VIRIDIAN_NICKNAME_HOUSE", musicID: "MUSIC_CITIES1"),
                .init(mapID: "VIRIDIAN_POKECENTER", musicID: "MUSIC_POKECENTER"),
                .init(mapID: "VIRIDIAN_SCHOOL_HOUSE", musicID: "MUSIC_CITIES1"),
            ]
        )

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
            "MUSIC_ROUTES3",
            "MUSIC_CITIES1",
            "MUSIC_DUNGEON2",
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
        let manifest = try extractAudioManifest(
            source: SourceTree(repoRoot: PokeExtractCLITestSupport.repoRoot()),
            titleTrackID: "MUSIC_TITLE_SCREEN"
        )

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
        let manifest = try extractAudioManifest(
            source: SourceTree(repoRoot: PokeExtractCLITestSupport.repoRoot()),
            titleTrackID: "MUSIC_TITLE_SCREEN"
        )

        let titleTrack = try XCTUnwrap(manifest.tracks.first { $0.id == "MUSIC_TITLE_SCREEN" })
        let channelTwo = try XCTUnwrap(
            titleTrack.entries.first { $0.id == "default" }?.channels.first { $0.channelNumber == 2 }
        )
        let firstEvent = try XCTUnwrap(channelTwo.prelude.first)

        XCTAssertEqual(firstEvent.duration, 6.0 / 60.0, accuracy: 0.000_001)
    }

    func testAudioExtractorIncludesTitleScreenDrumPreludeEvents() throws {
        let manifest = try extractAudioManifest(
            source: SourceTree(repoRoot: PokeExtractCLITestSupport.repoRoot()),
            titleTrackID: "MUSIC_TITLE_SCREEN"
        )

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

    func testAudioExtractorCarriesPitchSlideTargetsIntoPkmnHealedLead() throws {
        let manifest = try extractAudioManifest(
            source: SourceTree(repoRoot: PokeExtractCLITestSupport.repoRoot()),
            titleTrackID: "MUSIC_TITLE_SCREEN"
        )

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

    func testAudioExtractorUsesASMFrequencyTableForPerfectPitchSquareChannel() throws {
        let manifest = try extractAudioManifest(
            source: SourceTree(repoRoot: PokeExtractCLITestSupport.repoRoot()),
            titleTrackID: "MUSIC_TITLE_SCREEN"
        )

        let oakIntroTrack = try XCTUnwrap(manifest.tracks.first { $0.id == "MUSIC_MEET_PROF_OAK" })
        let channelOne = try XCTUnwrap(
            oakIntroTrack.entries.first { $0.id == "default" }?.channels.first { $0.channelNumber == 1 }
        )
        let firstEvent = try XCTUnwrap(channelOne.prelude.first)
        let frequency = try XCTUnwrap(firstEvent.frequencyHz)

        XCTAssertEqual(frequency, 370.259_887_005_649_7, accuracy: 0.000_001)
    }

    func testAudioExtractorUsesWaveChannelFrequencyFormulaForOakIntroCounterline() throws {
        let manifest = try extractAudioManifest(
            source: SourceTree(repoRoot: PokeExtractCLITestSupport.repoRoot()),
            titleTrackID: "MUSIC_TITLE_SCREEN"
        )

        let oakIntroTrack = try XCTUnwrap(manifest.tracks.first { $0.id == "MUSIC_MEET_PROF_OAK" })
        let channelThree = try XCTUnwrap(
            oakIntroTrack.entries.first { $0.id == "default" }?.channels.first { $0.channelNumber == 3 }
        )
        let firstEvent = try XCTUnwrap(channelThree.prelude.first)
        let frequency = try XCTUnwrap(firstEvent.frequencyHz)

        XCTAssertEqual(frequency, 368.179_775_280_898_87, accuracy: 0.000_001)
    }

    func testAudioExtractorMapsLevelUpSFXChannelsToToneHardware() throws {
        let manifest = try extractAudioManifest(
            source: SourceTree(repoRoot: PokeExtractCLITestSupport.repoRoot()),
            titleTrackID: "MUSIC_TITLE_SCREEN"
        )

        let levelUp = try XCTUnwrap(manifest.soundEffects.first { $0.id == "SFX_LEVEL_UP" })
        let channelFive = try XCTUnwrap(levelUp.channels.first { $0.channelNumber == 5 })
        let channelSix = try XCTUnwrap(levelUp.channels.first { $0.channelNumber == 6 })
        let channelSeven = try XCTUnwrap(levelUp.channels.first { $0.channelNumber == 7 })

        XCTAssertEqual(channelFive.prelude.first?.waveform, .square)
        XCTAssertEqual(channelSix.prelude.first?.waveform, .square)
        XCTAssertEqual(channelSeven.prelude.first?.waveform, .wave)
    }

    func testAudioExtractorCarriesPitchSweepIntoBallPoofSquareChannel() throws {
        let manifest = try extractAudioManifest(
            source: SourceTree(repoRoot: PokeExtractCLITestSupport.repoRoot()),
            titleTrackID: "MUSIC_TITLE_SCREEN"
        )

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

    func testExtractorWritesDeterministicAudioManifestJSON() throws {
        let repoRoot = PokeExtractCLITestSupport.repoRoot()
        let firstOutputRoot = try PokeExtractCLITestSupport.temporaryDirectory()
        let secondOutputRoot = try PokeExtractCLITestSupport.temporaryDirectory()

        try RedContentExtractor.extract(
            configuration: .init(repoRoot: repoRoot, outputRoot: firstOutputRoot)
        )
        try RedContentExtractor.extract(
            configuration: .init(repoRoot: repoRoot, outputRoot: secondOutputRoot)
        )

        let first = try Data(contentsOf: firstOutputRoot.appendingPathComponent("Red/audio_manifest.json"))
        let second = try Data(contentsOf: secondOutputRoot.appendingPathComponent("Red/audio_manifest.json"))
        XCTAssertEqual(first, second)

        let decoded = try JSONDecoder().decode(AudioManifest.self, from: first)
        XCTAssertEqual(decoded.titleTrackID, "MUSIC_TITLE_SCREEN")
        XCTAssertEqual(decoded.mapRoutes.count, 25)
        XCTAssertEqual(decoded.cues.count, 12)
        XCTAssertEqual(decoded.tracks.count, 18)
        XCTAssertNotNil(decoded.tracks.first { $0.id == "MUSIC_MEET_RIVAL" }?.entries.first { $0.id == "alternateStart" })
    }
}
