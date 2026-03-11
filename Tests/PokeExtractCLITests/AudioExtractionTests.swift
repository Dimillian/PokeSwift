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
                .init(mapID: "OAKS_LAB", musicID: "MUSIC_OAKS_LAB"),
                .init(mapID: "PALLET_TOWN", musicID: "MUSIC_PALLET_TOWN"),
                .init(mapID: "REDS_HOUSE_1F", musicID: "MUSIC_PALLET_TOWN"),
                .init(mapID: "REDS_HOUSE_2F", musicID: "MUSIC_PALLET_TOWN"),
                .init(mapID: "ROUTE_1", musicID: "MUSIC_ROUTES1"),
                .init(mapID: "VIRIDIAN_CITY", musicID: "MUSIC_CITIES1"),
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
        XCTAssertEqual(cueByID["trainer_battle"]?.trackID, "MUSIC_TRAINER_BATTLE")
        XCTAssertEqual(cueByID["mom_heal"]?.trackID, "MUSIC_PKMN_HEALED")
        XCTAssertEqual(cueByID["mom_heal"]?.waitForCompletion, true)
        XCTAssertEqual(cueByID["mom_heal"]?.resumeMusicAfterCompletion, true)

        let requiredTrackIDs: Set<String> = [
            "MUSIC_TITLE_SCREEN",
            "MUSIC_PALLET_TOWN",
            "MUSIC_OAKS_LAB",
            "MUSIC_ROUTES1",
            "MUSIC_CITIES1",
            "MUSIC_POKECENTER",
            "MUSIC_MEET_PROF_OAK",
            "MUSIC_MEET_RIVAL",
            "MUSIC_TRAINER_BATTLE",
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
        XCTAssertEqual(decoded.mapRoutes.count, 10)
        XCTAssertEqual(decoded.cues.count, 6)
        XCTAssertEqual(decoded.tracks.count, 10)
        XCTAssertNotNil(decoded.tracks.first { $0.id == "MUSIC_MEET_RIVAL" }?.entries.first { $0.id == "alternateStart" })
    }
}
