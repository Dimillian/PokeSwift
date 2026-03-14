import Foundation
import PokeDataModel

private struct AudioConstantDefinition {
    let id: String
    let label: String
    let order: Int
}

func extractAudioManifest(source: SourceTree, titleTrackID: String) throws -> AudioManifest {
    let musicConstants = try parseAudioConstants(repoRoot: source.repoRoot, prefix: "MUSIC_")
    let soundEffectConstants = try parseAudioConstants(repoRoot: source.repoRoot, prefix: "SFX_")
    let mapRoutes = try parseGameplayCoverageMapRoutes(repoRoot: source.repoRoot)
    let musicHeaders = try parseMusicHeaders(repoRoot: source.repoRoot)
    let soundEffectHeaders = try parseSoundEffectHeaders(repoRoot: source.repoRoot)
    let labelIndex = try buildMusicLabelIndex(repoRoot: source.repoRoot)
    let soundEffectLabelIndex = try buildSoundEffectLabelIndex(repoRoot: source.repoRoot)
    let waveTables = try parseWaveSampleTables(repoRoot: source.repoRoot)
    let pitchRegisters = try parsePitchRegisters(repoRoot: source.repoRoot)
    let noiseInstruments = try parseNoiseInstrumentTables(repoRoot: source.repoRoot)

    let cueDefinitions: [AudioManifest.Cue] = [
        .init(id: "title_default", assetID: titleTrackID),
        .init(id: "oak_intro", assetID: "MUSIC_MEET_PROF_OAK"),
        .init(id: "rival_intro", assetID: "MUSIC_MEET_RIVAL"),
        .init(id: "rival_exit", assetID: "MUSIC_MEET_RIVAL", entryID: "alternateStart"),
        .init(id: "trainer_intro_male", assetID: "MUSIC_MEET_MALE_TRAINER"),
        .init(id: "trainer_intro_female", assetID: "MUSIC_MEET_FEMALE_TRAINER"),
        .init(id: "trainer_intro_evil", assetID: "MUSIC_MEET_EVIL_TRAINER"),
        .init(id: "trainer_battle", assetID: "MUSIC_TRAINER_BATTLE"),
        .init(id: "trainer_victory", assetID: "MUSIC_DEFEATED_TRAINER"),
        .init(id: "wild_victory", assetID: "MUSIC_DEFEATED_WILD_MON"),
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
    ]

    let requiredTrackIDs = Array(
        Set([titleTrackID] + mapRoutes.map(\.musicID) + cueDefinitions.filter { $0.assetKind == .music }.map(\.assetID))
    ).sorted()

    var fileParsers: [String: ParsedMusicFile] = [:]
    var tracks: [AudioManifest.Track] = []
    var soundEffects: [AudioManifest.SoundEffect] = []

    for trackID in requiredTrackIDs {
        guard let constant = musicConstants.first(where: { $0.id == trackID }) else {
            throw ExtractorError.invalidArguments("missing music constant mapping for \(trackID)")
        }
        guard let header = musicHeaders[constant.label], let firstChannel = header.channels.first else {
            throw ExtractorError.invalidArguments("missing music header for \(trackID)")
        }
        guard let sourceFile = labelIndex[firstChannel.label] else {
            throw ExtractorError.invalidArguments("missing music source file for \(firstChannel.label)")
        }
        let parser: ParsedMusicFile
        if let cached = fileParsers[sourceFile] {
            parser = cached
        } else {
            let parsed = try parseMusicFile(at: source.repoRoot.appendingPathComponent(sourceFile))
            fileParsers[sourceFile] = parsed
            parser = parsed
        }

        var entries: [AudioManifest.Entry] = [
            try renderTrackEntry(
                id: "default",
                channelEntries: header.channels,
                parser: parser,
                waveTables: waveTables,
                pitchRegisters: pitchRegisters,
                noiseInstruments: noiseInstruments
            ),
        ]

        if trackID == "MUSIC_MEET_RIVAL" {
            let alternateChannels = header.channels.map {
                MusicChannelHeader(channelNumber: $0.channelNumber, label: "\($0.label)_AlternateStart")
            }
            entries.append(
                try renderTrackEntry(
                    id: "alternateStart",
                    channelEntries: alternateChannels,
                    parser: parser,
                    waveTables: waveTables,
                    pitchRegisters: pitchRegisters,
                    noiseInstruments: noiseInstruments
                )
            )
        }

        tracks.append(
            AudioManifest.Track(
                id: trackID,
                sourceLabel: header.label,
                sourceFile: sourceFile,
                entries: entries
            )
        )
    }

    for constant in soundEffectConstants {
        guard let header = soundEffectHeaders[constant.label], let firstChannel = header.channels.first else {
            continue
        }
        guard let sourceFile = soundEffectLabelIndex[firstChannel.label] else {
            continue
        }
        let parser: ParsedMusicFile
        if let cached = fileParsers[sourceFile] {
            parser = cached
        } else {
            let parsed = try parseMusicFile(at: source.repoRoot.appendingPathComponent(sourceFile))
            fileParsers[sourceFile] = parsed
            parser = parsed
        }

        let entry = try renderTrackEntry(
            id: "default",
            channelEntries: header.channels,
            parser: parser,
            waveTables: waveTables,
            pitchRegisters: pitchRegisters,
            noiseInstruments: noiseInstruments
        )

        soundEffects.append(
            AudioManifest.SoundEffect(
                id: constant.id,
                sourceLabel: header.label,
                sourceFile: sourceFile,
                bank: header.bank,
                priority: constant.order,
                order: constant.order,
                requestedChannels: header.channels.map(\.channelNumber),
                channels: entry.channels
            )
        )
    }

    return AudioManifest(
        variant: .red,
        titleTrackID: titleTrackID,
        mapRoutes: mapRoutes,
        cues: cueDefinitions,
        tracks: tracks.sorted { $0.id < $1.id },
        soundEffects: soundEffects.sorted { $0.order < $1.order }
    )
}

private func parseAudioConstants(repoRoot: URL, prefix: String) throws -> [AudioConstantDefinition] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("constants/music_constants.asm"))
    let regex = try NSRegularExpression(pattern: #"music_const\s+([A-Z0-9_]+),\s+([A-Za-z0-9_]+)"#)
    let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    var result: [AudioConstantDefinition] = []
    var order = 0
    for match in regex.matches(in: contents, range: nsRange) {
        guard
            let idRange = Range(match.range(at: 1), in: contents),
            let labelRange = Range(match.range(at: 2), in: contents)
        else {
            continue
        }
        let id = String(contents[idRange])
        guard id.hasPrefix(prefix) else { continue }
        result.append(.init(id: id, label: String(contents[labelRange]), order: order))
        order += 1
    }
    return result
}

func parseGameplayCoverageMapRoutes(repoRoot: URL) throws -> [AudioManifest.MapRoute] {
    let requiredMaps = gameplayCoverageMapIDs
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/maps/songs.asm"))
    let regex = try NSRegularExpression(pattern: #"db\s+(MUSIC_[A-Z0-9_]+),\s+BANK\([A-Za-z0-9_]+\)\s*;\s*([A-Z0-9_]+)"#)
    let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    var routes: [AudioManifest.MapRoute] = []
    for match in regex.matches(in: contents, range: nsRange) {
        guard
            let musicRange = Range(match.range(at: 1), in: contents),
            let mapRange = Range(match.range(at: 2), in: contents)
        else {
            continue
        }
        let mapID = String(contents[mapRange])
        guard requiredMaps.contains(mapID) else { continue }
        routes.append(.init(mapID: mapID, musicID: String(contents[musicRange])))
    }
    guard routes.count == requiredMaps.count else {
        throw ExtractorError.invalidArguments("failed to resolve all gameplay coverage map music routes")
    }
    return routes.sorted { $0.mapID < $1.mapID }
}

private struct MusicHeader {
    let label: String
    let bank: Int
    let channels: [MusicChannelHeader]
}

private struct MusicChannelHeader {
    let channelNumber: Int
    let label: String
}

private func parseMusicHeaders(repoRoot: URL) throws -> [String: MusicHeader] {
    let headerFiles = [
        (path: "audio/headers/musicheaders1.asm", bank: 1),
        (path: "audio/headers/musicheaders2.asm", bank: 2),
        (path: "audio/headers/musicheaders3.asm", bank: 3),
    ]
    var headers: [String: MusicHeader] = [:]

    for file in headerFiles {
        let contents = try String(contentsOf: repoRoot.appendingPathComponent(file.path))
        let lines = contents.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var index = 0
        while index < lines.count {
            let rawLine = lines[index].split(separator: ";", maxSplits: 1).first.map(String.init) ?? ""
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasSuffix("::") else {
                index += 1
                continue
            }

            let label = String(line.dropLast(2))
            index += 1
            guard index < lines.count else { break }
            let countLine = (lines[index].split(separator: ";", maxSplits: 1).first.map(String.init) ?? "")
                .trimmingCharacters(in: .whitespaces)
            guard let countMatch = countLine.firstMatch(of: /channel_count\s+(\d+)/),
                  let channelCount = Int(countMatch.output.1) else {
                continue
            }
            index += 1
            var channels: [MusicChannelHeader] = []
            for _ in 0..<channelCount where index < lines.count {
                let channelLine = (lines[index].split(separator: ";", maxSplits: 1).first.map(String.init) ?? "")
                    .trimmingCharacters(in: .whitespaces)
                if let match = channelLine.firstMatch(of: /channel\s+(\d+),\s+([A-Za-z0-9_\.]+)/),
                   let channelNumber = Int(match.output.1) {
                    channels.append(.init(channelNumber: channelNumber, label: String(match.output.2)))
                }
                index += 1
            }
            headers[label] = MusicHeader(label: label, bank: file.bank, channels: channels)
        }
    }

    return headers
}

private func parseSoundEffectHeaders(repoRoot: URL) throws -> [String: MusicHeader] {
    let headerFiles = [
        (path: "audio/headers/sfxheaders1.asm", bank: 1),
        (path: "audio/headers/sfxheaders2.asm", bank: 2),
        (path: "audio/headers/sfxheaders3.asm", bank: 3),
    ]
    var headers: [String: MusicHeader] = [:]

    for file in headerFiles {
        let contents = try String(contentsOf: repoRoot.appendingPathComponent(file.path))
        let lines = contents.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var index = 0
        while index < lines.count {
            let rawLine = lines[index].split(separator: ";", maxSplits: 1).first.map(String.init) ?? ""
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasSuffix("::"), line != "SFX_Headers_1::", line != "SFX_Headers_2::", line != "SFX_Headers_3::" else {
                index += 1
                continue
            }

            let label = String(line.dropLast(2))
            index += 1
            guard index < lines.count else { break }
            let countLine = (lines[index].split(separator: ";", maxSplits: 1).first.map(String.init) ?? "")
                .trimmingCharacters(in: .whitespaces)
            guard let countMatch = countLine.firstMatch(of: /channel_count\s+(\d+)/),
                  let channelCount = Int(countMatch.output.1) else {
                continue
            }
            index += 1
            var channels: [MusicChannelHeader] = []
            for _ in 0..<channelCount where index < lines.count {
                let channelLine = (lines[index].split(separator: ";", maxSplits: 1).first.map(String.init) ?? "")
                    .trimmingCharacters(in: .whitespaces)
                if let match = channelLine.firstMatch(of: /channel\s+(\d+),\s+([A-Za-z0-9_\.]+)/),
                   let channelNumber = Int(match.output.1) {
                    channels.append(.init(channelNumber: channelNumber, label: String(match.output.2)))
                }
                index += 1
            }
            headers[label] = MusicHeader(label: label, bank: file.bank, channels: channels)
        }
    }

    return headers
}

private func buildMusicLabelIndex(repoRoot: URL) throws -> [String: String] {
    let musicRoot = repoRoot.appendingPathComponent("audio/music", isDirectory: true)
    let files = try FileManager.default.contentsOfDirectory(
        at: musicRoot,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
    )

    var index: [String: String] = [:]
    for fileURL in files where fileURL.pathExtension == "asm" {
        let contents = try String(contentsOf: fileURL)
        let relativePath = "audio/music/\(fileURL.lastPathComponent)"
        let regex = try NSRegularExpression(pattern: #"(?m)^([A-Za-z0-9_\.]+)::?$"#)
        let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
        for match in regex.matches(in: contents, range: nsRange) {
            guard let range = Range(match.range(at: 1), in: contents) else { continue }
            index[String(contents[range])] = relativePath
        }
    }
    return index
}

private func buildSoundEffectLabelIndex(repoRoot: URL) throws -> [String: String] {
    let soundEffectRoot = repoRoot.appendingPathComponent("audio/sfx", isDirectory: true)
    let files = try FileManager.default.contentsOfDirectory(
        at: soundEffectRoot,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
    )

    var index: [String: String] = [:]
    for fileURL in files where fileURL.pathExtension == "asm" {
        let contents = try String(contentsOf: fileURL)
        let relativePath = "audio/sfx/\(fileURL.lastPathComponent)"
        let regex = try NSRegularExpression(pattern: #"(?m)^([A-Za-z0-9_\.]+)::?$"#)
        let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
        for match in regex.matches(in: contents, range: nsRange) {
            guard let range = Range(match.range(at: 1), in: contents) else { continue }
            index[String(contents[range])] = relativePath
        }
    }
    return index
}

private struct ParsedMusicFile {
    let blocks: [String: MusicBlock]
}

private struct MusicBlock {
    let label: String
    let nextLabel: String?
    let instructions: [MusicInstruction]
}

private enum MusicInstruction {
    case tempo(Int)
    case volume(Int, Int)
    case dutyCycle(Int)
    case pitchSweep(Int, Int)
    case vibrato(Int, Int, Int)
    case pitchSlide(Int, Int, String)
    case togglePerfectPitch
    case noteType(Int, Int, Int)
    case drumSpeed(Int)
    case drumNote(Int, Int)
    case octave(Int)
    case note(String, Int)
    case squareNote(Int, Int, Int, Int)
    case noiseNote(Int, Int, Int, Int)
    case rest(Int)
    case soundCall(String)
    case soundLoop(Int, String)
    case soundRet
}

private struct ChannelState {
    var currentTime: Double = 0
    var tempo: Int = 120
    var masterVolume: Double = 1
    var noteSpeed: Int = 12
    var noteDelayFraction: Int = 0
    var noteVolume: Double = 0.8
    var envelopeStepDuration: Double?
    var envelopeDirection: Int = 0
    var octave: Int = 4
    var dutyCycle: Double = 0.5
    var waveSamples: [Double]?
    var perfectPitchEnabled = false
    var vibratoDelaySeconds: Double = 0
    var vibratoDepthSemitones: Double = 0
    var vibratoRateHz: Double = 0
    var pendingPitchSlide: PendingPitchSlide?
    var channel1PitchSweep: Channel1PitchSweepState?
    var waveform: AudioManifest.Waveform
}

private struct TimedEvent {
    let startTime: Double
    let duration: Double
    let frequencyHz: Double?
    let frequencyRegister: Int?
    let amplitude: Double
    let dutyCycle: Double?
    let envelopeStepDuration: Double?
    let envelopeDirection: Int
    let waveSamples: [Double]?
    let vibratoDelaySeconds: Double
    let vibratoDepthSemitones: Double
    let vibratoRateHz: Double
    let pitchSlideTargetHz: Double?
    let pitchSlideTargetRegister: Int?
    let pitchSlideFrameCount: Int?
    let noiseShortMode: Bool?
    let waveform: AudioManifest.Waveform
}

private struct TrackGlobalAudioState {
    let tempo: Int
    let masterVolume: Double
}

private struct EntryRenderResult {
    let playbackMode: AudioManifest.PlaybackMode
    let prelude: [TimedEvent]
    let loop: [TimedEvent]
}

private struct PendingPitchSlide {
    let targetHz: Double?
    let targetRegister: Int?
    let lengthModifier: Int
}

private struct Channel1PitchSweepState {
    let periodNibble: Int
    let shiftMagnitude: Int
    let decreasesPitch: Bool
}

private struct NoiseInstrumentEventTemplate {
    let startTime: Double
    let duration: Double
    let amplitude: Double
    let envelopeStepDuration: Double?
    let envelopeDirection: Int
    let clockHz: Double
    let shortMode: Bool
}

private func parseMusicFile(at url: URL) throws -> ParsedMusicFile {
    let contents = try String(contentsOf: url)
    let rawLines = contents.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    var orderedLabels: [String] = []
    var instructionsByLabel: [String: [MusicInstruction]] = [:]
    var currentLabel: String?
    var currentGlobalLabel: String?

    for rawLine in rawLines {
        let withoutComment = rawLine.split(separator: ";", maxSplits: 1).first.map(String.init) ?? ""
        let trimmed = withoutComment.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty == false else { continue }

        if trimmed.hasSuffix("::") || trimmed.hasSuffix(":") {
            let labelText = trimmed.hasSuffix("::") ? String(trimmed.dropLast(2)) : String(trimmed.dropLast())
            let fullLabel: String
            if labelText.hasPrefix(".") {
                guard let currentGlobalLabel else {
                    throw ExtractorError.invalidArguments("local audio label without global scope in \(url.lastPathComponent)")
                }
                fullLabel = currentGlobalLabel + labelText
            } else {
                currentGlobalLabel = labelText
                fullLabel = labelText
            }
            currentLabel = fullLabel
            orderedLabels.append(fullLabel)
            instructionsByLabel[fullLabel] = []
            continue
        }

        guard let currentLabel, let instruction = parseMusicInstruction(trimmed) else {
            continue
        }
        instructionsByLabel[currentLabel, default: []].append(instruction)
    }

    var blocks: [String: MusicBlock] = [:]
    for (index, label) in orderedLabels.enumerated() {
        blocks[label] = MusicBlock(
            label: label,
            nextLabel: orderedLabels.indices.contains(index + 1) ? orderedLabels[index + 1] : nil,
            instructions: instructionsByLabel[label] ?? []
        )
    }
    return ParsedMusicFile(blocks: blocks)
}

private func parseMusicInstruction(_ line: String) -> MusicInstruction? {
    if let match = line.firstMatch(of: /tempo\s+(-?\d+)/), let value = Int(match.output.1) {
        return .tempo(value)
    }
    if let match = line.firstMatch(of: /volume\s+(-?\d+),\s*(-?\d+)/),
       let left = Int(match.output.1),
       let right = Int(match.output.2) {
        return .volume(left, right)
    }
    if let match = line.firstMatch(of: /duty_cycle\s+(-?\d+)/), let value = Int(match.output.1) {
        return .dutyCycle(value)
    }
    if let match = line.firstMatch(of: /pitch_sweep\s+(-?\d+),\s*(-?\d+)/),
       let time = Int(match.output.1),
       let shift = Int(match.output.2) {
        return .pitchSweep(time, shift)
    }
    if let match = line.firstMatch(of: /vibrato\s+(-?\d+),\s*(-?\d+),\s*(-?\d+)/),
       let first = Int(match.output.1),
       let second = Int(match.output.2),
       let third = Int(match.output.3) {
        return .vibrato(first, second, third)
    }
    if let match = line.firstMatch(of: /pitch_slide\s+(-?\d+),\s*(-?\d+),\s*([A-G][#_]|C_|D_|E_|F_|G_|A_|B_)/),
       let length = Int(match.output.1),
       let octave = Int(match.output.2) {
        return .pitchSlide(length, octave, String(match.output.3))
    }
    if line == "toggle_perfect_pitch" {
        return .togglePerfectPitch
    }
    if let match = line.firstMatch(of: /note_type\s+(-?\d+),\s*(-?\d+),\s*(-?\d+)/),
       let length = Int(match.output.1),
       let volume = Int(match.output.2),
       let fade = Int(match.output.3) {
        return .noteType(length, volume, fade)
    }
    if let match = line.firstMatch(of: /drum_speed\s+(-?\d+)/), let value = Int(match.output.1) {
        return .drumSpeed(value)
    }
    if let match = line.firstMatch(of: /drum_note\s+(-?\d+),\s*(-?\d+)/),
       let instrument = Int(match.output.1),
       let length = Int(match.output.2) {
        return .drumNote(instrument, length)
    }
    if let match = line.firstMatch(of: /octave\s+(-?\d+)/), let value = Int(match.output.1) {
        return .octave(value)
    }
    if let match = line.firstMatch(of: /note\s+([A-G][#_]|__[A-Z]?|C_|D_|E_|F_|G_|A_|B_),\s*(-?\d+)/),
       let length = Int(match.output.2) {
        return .note(String(match.output.1), length)
    }
    if let match = line.firstMatch(of: /square_note\s+(-?\d+),\s*(-?\d+),\s*(-?\d+),\s*(-?\d+)/),
       let length = Int(match.output.1),
       let volume = Int(match.output.2),
       let fade = Int(match.output.3),
       let register = Int(match.output.4) {
        return .squareNote(length, volume, fade, register)
    }
    if let match = line.firstMatch(of: /noise_note\s+(-?\d+),\s*(-?\d+),\s*(-?\d+),\s*(-?\d+)/),
       let length = Int(match.output.1),
       let volume = Int(match.output.2),
       let fade = Int(match.output.3),
       let counter = Int(match.output.4) {
        return .noiseNote(length, volume, fade, counter)
    }
    if let match = line.firstMatch(of: /rest\s+(-?\d+)/), let length = Int(match.output.1) {
        return .rest(length)
    }
    if let match = line.firstMatch(of: /sound_call\s+([A-Za-z0-9_\.]+)/) {
        return .soundCall(String(match.output.1))
    }
    if let match = line.firstMatch(of: /sound_loop\s+(-?\d+),\s+([A-Za-z0-9_\.]+)/),
       let count = Int(match.output.1) {
        return .soundLoop(count, String(match.output.2))
    }
    if line == "sound_ret" {
        return .soundRet
    }
    return nil
}

private func renderTrackEntry(
    id: String,
    channelEntries: [MusicChannelHeader],
    parser: ParsedMusicFile,
    waveTables: [Int: [Double]],
    pitchRegisters: [String: Int],
    noiseInstruments: [Int: [NoiseInstrumentEventTemplate]]
) throws -> AudioManifest.Entry {
    let globalState = resolveTrackGlobalAudioState(
        entryLabel: channelEntries.first?.label ?? id,
        parser: parser
    )
    let channelPrograms = try channelEntries.map { header in
        let waveform = waveform(for: header.channelNumber)
        let result = try renderChannelEntry(
            label: header.label,
            parser: parser,
            initialState: ChannelState(
                tempo: globalState.tempo,
                masterVolume: globalState.masterVolume,
                waveSamples: waveform == .wave ? waveTables[0] : nil,
                waveform: waveform
            ),
            waveTables: waveTables,
            pitchRegisters: pitchRegisters,
            noiseInstruments: noiseInstruments
        )
        return AudioManifest.ChannelProgram(
            channelNumber: header.channelNumber,
            prelude: result.prelude.map(audioEvent(from:)),
            loop: result.loop.map(audioEvent(from:))
        )
    }

    let playbackMode: AudioManifest.PlaybackMode = channelPrograms.contains(where: { $0.loop.isEmpty == false }) ? .looping : .oneShot
    return AudioManifest.Entry(
        id: id,
        sourceLabel: channelEntries.first?.label ?? id,
        playbackMode: playbackMode,
        channels: channelPrograms
    )
}

private func waveform(for channelNumber: Int) -> AudioManifest.Waveform {
    switch channelNumber {
    case 1, 2, 5, 6:
        return .square
    case 3, 7:
        return .wave
    case 4, 8:
        return .noise
    default:
        return .noise
    }
}

private func resolveTrackGlobalAudioState(entryLabel: String, parser: ParsedMusicFile) -> TrackGlobalAudioState {
    var tempo = 120
    var masterVolume = 1.0
    var currentLabel: String? = entryLabel
    var visited: Set<String> = []

    while let label = currentLabel, let block = parser.blocks[label], visited.insert(label).inserted {
        for instruction in block.instructions {
            switch instruction {
            case let .tempo(value):
                tempo = max(1, value)
            case let .volume(left, right):
                masterVolume = max(0, min(1, (Double(left + right) / 2) / 7))
            case .note, .rest:
                return TrackGlobalAudioState(tempo: tempo, masterVolume: masterVolume)
            default:
                continue
            }
        }
        currentLabel = block.nextLabel
    }

    return TrackGlobalAudioState(tempo: tempo, masterVolume: masterVolume)
}

private func renderChannelEntry(
    label: String,
    parser: ParsedMusicFile,
    initialState: ChannelState,
    waveTables: [Int: [Double]],
    pitchRegisters: [String: Int],
    noiseInstruments: [Int: [NoiseInstrumentEventTemplate]],
    visitedLabels: Set<String> = []
) throws -> EntryRenderResult {
    if visitedLabels.contains(label) {
        throw ExtractorError.invalidArguments("detected recursive audio channel entry cycle at \(label)")
    }
    var state = initialState
    var events: [TimedEvent] = []
    var labelStates: [String: ChannelState] = [:]
    var labelEventStartIndex: [String: Int] = [:]
    var currentLabel = label

    while let block = parser.blocks[currentLabel] {
        if labelStates[currentLabel] == nil {
            labelStates[currentLabel] = state
            labelEventStartIndex[currentLabel] = events.count
        }

        for instruction in block.instructions {
            switch instruction {
            case let .tempo(value):
                state.tempo = max(1, value)
                state.noteDelayFraction = 0
            case let .volume(left, right):
                state.masterVolume = max(0, min(1, (Double(left + right) / 2) / 7))
            case let .dutyCycle(value):
                state.dutyCycle = dutyCycle(for: value)
            case let .pitchSweep(time, shift):
                state.channel1PitchSweep = makeChannel1PitchSweepState(
                    timeNibble: time,
                    signedShiftMagnitude: shift
                )
            case let .vibrato(length, depth, rate):
                state.vibratoDelaySeconds = Double(max(0, length)) / 60
                state.vibratoDepthSemitones = Double(abs(depth)) / 64
                state.vibratoRateHz = rate <= 0 ? 0 : 60 / Double(rate * 2)
            case let .pitchSlide(length, octave, noteName):
                let targetRegister = frequencyRegister(
                    for: noteName,
                    octave: octave,
                    perfectPitchEnabled: state.perfectPitchEnabled,
                    pitchRegisters: pitchRegisters
                )
                state.pendingPitchSlide = PendingPitchSlide(
                    targetHz: targetRegister.map { frequencyHz(forRegister: $0, waveform: state.waveform) },
                    targetRegister: targetRegister,
                    lengthModifier: max(0, length - 1)
                )
            case .togglePerfectPitch:
                state.perfectPitchEnabled.toggle()
            case let .noteType(length, volume, parameter):
                state.noteSpeed = max(1, length)
                if state.waveform == .wave {
                    state.noteVolume = waveChannelVolume(for: volume)
                    state.waveSamples = waveTables[max(0, min(8, abs(parameter)))] ?? waveTables[0]
                    state.envelopeStepDuration = nil
                    state.envelopeDirection = 0
                } else {
                    state.noteVolume = max(0, min(1, Double(volume) / 15))
                    state.envelopeStepDuration = envelopeStepDuration(for: parameter)
                    state.envelopeDirection = envelopeDirection(for: parameter)
                }
            case let .drumSpeed(value):
                state.noteSpeed = max(1, value)
            case let .drumNote(instrumentID, length):
                let duration = advanceNoteDurationSeconds(length: length, state: &state)
                if let instrumentEvents = noiseInstruments[instrumentID] {
                    events.append(contentsOf: renderNoiseInstrument(instrumentEvents, startingAt: state.currentTime))
                }
                state.currentTime += duration
            case let .octave(value):
                state.octave = value
            case let .note(name, length):
                let duration = advanceNoteDurationSeconds(length: length, state: &state)
                let noteRegister = frequencyRegister(
                    for: name,
                    octave: state.octave,
                    perfectPitchEnabled: state.perfectPitchEnabled,
                    pitchRegisters: pitchRegisters
                )
                let pitchSlide = state.pendingPitchSlide
                state.pendingPitchSlide = nil
                events.append(
                    TimedEvent(
                        startTime: state.currentTime,
                        duration: duration,
                        frequencyHz: noteRegister.map { frequencyHz(forRegister: $0, waveform: state.waveform) },
                        frequencyRegister: noteRegister,
                        amplitude: state.masterVolume * state.noteVolume,
                        dutyCycle: state.waveform == .square ? state.dutyCycle : nil,
                        envelopeStepDuration: state.envelopeStepDuration,
                        envelopeDirection: state.envelopeDirection,
                        waveSamples: state.waveSamples,
                        vibratoDelaySeconds: state.vibratoDelaySeconds,
                        vibratoDepthSemitones: state.vibratoDepthSemitones,
                        vibratoRateHz: state.vibratoRateHz,
                        pitchSlideTargetHz: pitchSlide?.targetHz,
                        pitchSlideTargetRegister: pitchSlide?.targetRegister,
                        pitchSlideFrameCount: pitchSlide.map { max(1, noteFrameCount(for: duration) - $0.lengthModifier) },
                        noiseShortMode: nil,
                        waveform: state.waveform
                    )
                )
                state.currentTime += duration
            case let .squareNote(length, volume, fade, register):
                let duration = Double(max(1, length + 1)) / 60
                let noteRegister = register == 0 ? nil : register
                let pitchSlide = state.pendingPitchSlide
                state.pendingPitchSlide = nil
                let channel1SweepTarget = noteRegister.flatMap { register in
                    renderChannel1PitchSweepTarget(
                        startRegister: register,
                        duration: duration,
                        sweepState: state.channel1PitchSweep
                    )
                }
                events.append(
                    TimedEvent(
                        startTime: state.currentTime,
                        duration: duration,
                        frequencyHz: noteRegister.map { frequencyHz(forRegister: $0, waveform: .square) },
                        frequencyRegister: noteRegister,
                        amplitude: state.masterVolume * max(0, min(1, Double(volume) / 15)),
                        dutyCycle: state.dutyCycle,
                        envelopeStepDuration: envelopeStepDuration(for: fade),
                        envelopeDirection: envelopeDirection(for: fade),
                        waveSamples: nil,
                        vibratoDelaySeconds: 0,
                        vibratoDepthSemitones: 0,
                        vibratoRateHz: 0,
                        pitchSlideTargetHz: pitchSlide?.targetHz ?? channel1SweepTarget?.targetHz,
                        pitchSlideTargetRegister: pitchSlide?.targetRegister ?? channel1SweepTarget?.targetRegister,
                        pitchSlideFrameCount: pitchSlide.map { max(1, noteFrameCount(for: duration) - $0.lengthModifier) } ?? channel1SweepTarget?.frameCount,
                        noiseShortMode: nil,
                        waveform: .square
                    )
                )
                state.currentTime += duration
            case let .noiseNote(length, volume, fade, polynomialCounter):
                let duration = Double(max(1, length + 1)) / 60
                let (clockHz, shortMode) = noiseClockParameters(for: polynomialCounter)
                events.append(
                    TimedEvent(
                        startTime: state.currentTime,
                        duration: duration,
                        frequencyHz: clockHz,
                        frequencyRegister: nil,
                        amplitude: state.masterVolume * max(0, min(1, Double(volume) / 15)),
                        dutyCycle: nil,
                        envelopeStepDuration: envelopeStepDuration(for: fade),
                        envelopeDirection: envelopeDirection(for: fade),
                        waveSamples: nil,
                        vibratoDelaySeconds: 0,
                        vibratoDepthSemitones: 0,
                        vibratoRateHz: 0,
                        pitchSlideTargetHz: nil,
                        pitchSlideTargetRegister: nil,
                        pitchSlideFrameCount: nil,
                        noiseShortMode: shortMode,
                        waveform: .noise
                    )
                )
                state.currentTime += duration
            case let .rest(length):
                state.currentTime += advanceNoteDurationSeconds(length: length, state: &state)
            case let .soundCall(target):
                let resolved = resolveLabelReference(target, from: currentLabel)
                let subroutine = try renderSubroutine(
                    label: resolved,
                    parser: parser,
                    initialState: state,
                    waveTables: waveTables,
                    pitchRegisters: pitchRegisters,
                    noiseInstruments: noiseInstruments
                )
                events.append(contentsOf: subroutine.events)
                state = subroutine.state
            case let .soundLoop(count, target):
                let resolved = resolveLabelReference(target, from: currentLabel)
                if count == 0 {
                    if let startIndex = labelEventStartIndex[resolved],
                       let loopStartTime = labelStates[resolved]?.currentTime {
                        let loopPrelude = Array(events[..<startIndex])
                        let loopEvents = loopEventsSlice(
                            events: events,
                            startIndex: startIndex,
                            loopStartTime: loopStartTime,
                            waveform: state.waveform,
                            endTime: state.currentTime
                        )
                        return EntryRenderResult(playbackMode: .looping, prelude: loopPrelude, loop: loopEvents)
                    }

                    let recursive = try renderChannelEntry(
                        label: resolved,
                        parser: parser,
                        initialState: state,
                        waveTables: waveTables,
                        pitchRegisters: pitchRegisters,
                        noiseInstruments: noiseInstruments,
                        visitedLabels: visitedLabels.union([label])
                    )
                    let shiftedPrelude = recursive.prelude.map { shiftTimedEvent($0, by: state.currentTime) }
                    return EntryRenderResult(
                        playbackMode: recursive.playbackMode,
                        prelude: events + shiftedPrelude,
                        loop: recursive.loop
                    )
                }

                let startIndex = labelEventStartIndex[resolved]
                    ?? ((events.isEmpty == false) ? 0 : nil)
                let segmentStartTime = labelStates[resolved]?.currentTime
                    ?? initialState.currentTime

                if let startIndex, startIndex < events.count {
                    appendRepeatedSegment(
                        events: &events,
                        state: &state,
                        startIndex: startIndex,
                        segmentStartTime: segmentStartTime ?? state.currentTime,
                        waveform: state.waveform,
                        additionalRepeats: max(0, count - 1)
                    )
                } else {
                    throw ExtractorError.invalidArguments("unsupported forward audio loop \(resolved)")
                }
            case .soundRet:
                return EntryRenderResult(playbackMode: .oneShot, prelude: events, loop: [])
            }
        }

        guard let nextLabel = block.nextLabel else {
            break
        }
        currentLabel = nextLabel
    }

    return EntryRenderResult(playbackMode: .oneShot, prelude: events, loop: [])
}

private func renderSubroutine(
    label: String,
    parser: ParsedMusicFile,
    initialState: ChannelState,
    waveTables: [Int: [Double]],
    pitchRegisters: [String: Int],
    noiseInstruments: [Int: [NoiseInstrumentEventTemplate]]
) throws -> (events: [TimedEvent], state: ChannelState) {
    var state = initialState
    var events: [TimedEvent] = []
    var labelEventStartIndex: [String: Int] = [:]
    var labelStartTimes: [String: Double] = [:]
    var currentLabel = label
    var safety = 0

    while let block = parser.blocks[currentLabel] {
        safety += 1
        if safety > 2048 {
            throw ExtractorError.invalidArguments("audio subroutine exceeded safety limit at \(label)")
        }
        if labelEventStartIndex[currentLabel] == nil {
            labelEventStartIndex[currentLabel] = events.count
            labelStartTimes[currentLabel] = state.currentTime
        }

        for instruction in block.instructions {
            switch instruction {
            case let .tempo(value):
                state.tempo = max(1, value)
                state.noteDelayFraction = 0
            case let .volume(left, right):
                state.masterVolume = max(0, min(1, (Double(left + right) / 2) / 7))
            case let .dutyCycle(value):
                state.dutyCycle = dutyCycle(for: value)
            case let .pitchSweep(time, shift):
                state.channel1PitchSweep = makeChannel1PitchSweepState(
                    timeNibble: time,
                    signedShiftMagnitude: shift
                )
            case let .vibrato(length, depth, rate):
                state.vibratoDelaySeconds = Double(max(0, length)) / 60
                state.vibratoDepthSemitones = Double(abs(depth)) / 64
                state.vibratoRateHz = rate <= 0 ? 0 : 60 / Double(rate * 2)
            case let .pitchSlide(length, octave, noteName):
                let targetRegister = frequencyRegister(
                    for: noteName,
                    octave: octave,
                    perfectPitchEnabled: state.perfectPitchEnabled,
                    pitchRegisters: pitchRegisters
                )
                state.pendingPitchSlide = PendingPitchSlide(
                    targetHz: targetRegister.map { frequencyHz(forRegister: $0, waveform: state.waveform) },
                    targetRegister: targetRegister,
                    lengthModifier: max(0, length - 1)
                )
            case .togglePerfectPitch:
                state.perfectPitchEnabled.toggle()
            case let .noteType(length, volume, parameter):
                state.noteSpeed = max(1, length)
                if state.waveform == .wave {
                    state.noteVolume = waveChannelVolume(for: volume)
                    state.waveSamples = waveTables[max(0, min(8, abs(parameter)))] ?? waveTables[0]
                    state.envelopeStepDuration = nil
                    state.envelopeDirection = 0
                } else {
                    state.noteVolume = max(0, min(1, Double(volume) / 15))
                    state.envelopeStepDuration = envelopeStepDuration(for: parameter)
                    state.envelopeDirection = envelopeDirection(for: parameter)
                }
            case let .drumSpeed(value):
                state.noteSpeed = max(1, value)
            case let .drumNote(instrumentID, length):
                let duration = advanceNoteDurationSeconds(length: length, state: &state)
                if let instrumentEvents = noiseInstruments[instrumentID] {
                    events.append(contentsOf: renderNoiseInstrument(instrumentEvents, startingAt: state.currentTime))
                }
                state.currentTime += duration
            case let .octave(value):
                state.octave = value
            case let .note(name, length):
                let duration = advanceNoteDurationSeconds(length: length, state: &state)
                let noteRegister = frequencyRegister(
                    for: name,
                    octave: state.octave,
                    perfectPitchEnabled: state.perfectPitchEnabled,
                    pitchRegisters: pitchRegisters
                )
                let pitchSlide = state.pendingPitchSlide
                state.pendingPitchSlide = nil
                events.append(
                    TimedEvent(
                        startTime: state.currentTime,
                        duration: duration,
                        frequencyHz: noteRegister.map { frequencyHz(forRegister: $0, waveform: state.waveform) },
                        frequencyRegister: noteRegister,
                        amplitude: state.masterVolume * state.noteVolume,
                        dutyCycle: state.waveform == .square ? state.dutyCycle : nil,
                        envelopeStepDuration: state.envelopeStepDuration,
                        envelopeDirection: state.envelopeDirection,
                        waveSamples: state.waveSamples,
                        vibratoDelaySeconds: state.vibratoDelaySeconds,
                        vibratoDepthSemitones: state.vibratoDepthSemitones,
                        vibratoRateHz: state.vibratoRateHz,
                        pitchSlideTargetHz: pitchSlide?.targetHz,
                        pitchSlideTargetRegister: pitchSlide?.targetRegister,
                        pitchSlideFrameCount: pitchSlide.map { max(1, noteFrameCount(for: duration) - $0.lengthModifier) },
                        noiseShortMode: nil,
                        waveform: state.waveform
                    )
                )
                state.currentTime += duration
            case let .squareNote(length, volume, fade, register):
                let duration = Double(max(1, length + 1)) / 60
                let noteRegister = register == 0 ? nil : register
                let pitchSlide = state.pendingPitchSlide
                state.pendingPitchSlide = nil
                let channel1SweepTarget = noteRegister.flatMap { register in
                    renderChannel1PitchSweepTarget(
                        startRegister: register,
                        duration: duration,
                        sweepState: state.channel1PitchSweep
                    )
                }
                events.append(
                    TimedEvent(
                        startTime: state.currentTime,
                        duration: duration,
                        frequencyHz: noteRegister.map { frequencyHz(forRegister: $0, waveform: .square) },
                        frequencyRegister: noteRegister,
                        amplitude: state.masterVolume * max(0, min(1, Double(volume) / 15)),
                        dutyCycle: state.dutyCycle,
                        envelopeStepDuration: envelopeStepDuration(for: fade),
                        envelopeDirection: envelopeDirection(for: fade),
                        waveSamples: nil,
                        vibratoDelaySeconds: 0,
                        vibratoDepthSemitones: 0,
                        vibratoRateHz: 0,
                        pitchSlideTargetHz: pitchSlide?.targetHz ?? channel1SweepTarget?.targetHz,
                        pitchSlideTargetRegister: pitchSlide?.targetRegister ?? channel1SweepTarget?.targetRegister,
                        pitchSlideFrameCount: pitchSlide.map { max(1, noteFrameCount(for: duration) - $0.lengthModifier) } ?? channel1SweepTarget?.frameCount,
                        noiseShortMode: nil,
                        waveform: .square
                    )
                )
                state.currentTime += duration
            case let .noiseNote(length, volume, fade, polynomialCounter):
                let duration = Double(max(1, length + 1)) / 60
                let (clockHz, shortMode) = noiseClockParameters(for: polynomialCounter)
                events.append(
                    TimedEvent(
                        startTime: state.currentTime,
                        duration: duration,
                        frequencyHz: clockHz,
                        frequencyRegister: nil,
                        amplitude: state.masterVolume * max(0, min(1, Double(volume) / 15)),
                        dutyCycle: nil,
                        envelopeStepDuration: envelopeStepDuration(for: fade),
                        envelopeDirection: envelopeDirection(for: fade),
                        waveSamples: nil,
                        vibratoDelaySeconds: 0,
                        vibratoDepthSemitones: 0,
                        vibratoRateHz: 0,
                        pitchSlideTargetHz: nil,
                        pitchSlideTargetRegister: nil,
                        pitchSlideFrameCount: nil,
                        noiseShortMode: shortMode,
                        waveform: .noise
                    )
                )
                state.currentTime += duration
            case let .rest(length):
                state.currentTime += advanceNoteDurationSeconds(length: length, state: &state)
            case let .soundCall(target):
                let subroutine = try renderSubroutine(
                    label: resolveLabelReference(target, from: currentLabel),
                    parser: parser,
                    initialState: state,
                    waveTables: waveTables,
                    pitchRegisters: pitchRegisters,
                    noiseInstruments: noiseInstruments
                )
                events.append(contentsOf: subroutine.events)
                state = subroutine.state
            case let .soundLoop(count, target):
                guard count > 0 else {
                    throw ExtractorError.invalidArguments("unsupported infinite loop inside audio subroutine \(label)")
                }
                let resolved = resolveLabelReference(target, from: currentLabel)
                let startIndex = labelEventStartIndex[resolved]
                    ?? ((events.isEmpty == false) ? 0 : nil)
                let segmentStartTime = labelStartTimes[resolved]
                    ?? initialState.currentTime

                if let startIndex, startIndex < events.count {
                    appendRepeatedSegment(
                        events: &events,
                        state: &state,
                        startIndex: startIndex,
                        segmentStartTime: segmentStartTime ?? state.currentTime,
                        waveform: state.waveform,
                        additionalRepeats: max(0, count - 1)
                    )
                } else {
                    throw ExtractorError.invalidArguments("unsupported forward audio loop \(resolved) in subroutine \(label)")
                }
            case .soundRet:
                return (events, state)
            }
        }

        guard let nextLabel = block.nextLabel else { break }
        currentLabel = nextLabel
    }

    return (events, state)
}

private func appendRepeatedSegment(
    events: inout [TimedEvent],
    state: inout ChannelState,
    startIndex: Int,
    segmentStartTime: Double,
    waveform: AudioManifest.Waveform,
    additionalRepeats: Int
) {
    guard additionalRepeats > 0 else { return }
    let segment = Array(events[startIndex...])
    let normalized: [TimedEvent]
    let segmentDuration: Double
    if let firstEvent = segment.first {
        normalized = segment.map { shiftTimedEvent($0, by: -firstEvent.startTime) }
        segmentDuration = segment
            .map { $0.startTime + $0.duration }
            .max()
            .map { $0 - firstEvent.startTime } ?? 0
    } else {
        segmentDuration = max(0, state.currentTime - segmentStartTime)
        normalized = segmentDuration > 0 ? [silentTimedEvent(duration: segmentDuration, waveform: waveform)] : []
    }
    guard segmentDuration > 0 else { return }

    for _ in 0..<additionalRepeats {
        events.append(contentsOf: normalized.map { shiftTimedEvent($0, by: state.currentTime) })
        state.currentTime += segmentDuration
    }
}

private func loopEventsSlice(
    events: [TimedEvent],
    startIndex: Int,
    loopStartTime: Double,
    waveform: AudioManifest.Waveform,
    endTime: Double
) -> [TimedEvent] {
    if startIndex < events.count {
        return events[startIndex...].map {
            shiftTimedEvent($0, by: -loopStartTime)
        }
    }

    let silentDuration = max(0, endTime - loopStartTime)
    guard silentDuration > 0 else { return [] }
    return [silentTimedEvent(duration: silentDuration, waveform: waveform)]
}

private func silentTimedEvent(duration: Double, waveform: AudioManifest.Waveform) -> TimedEvent {
    TimedEvent(
        startTime: 0,
        duration: duration,
        frequencyHz: nil,
        frequencyRegister: nil,
        amplitude: 0,
        dutyCycle: nil,
        envelopeStepDuration: nil,
        envelopeDirection: 0,
        waveSamples: nil,
        vibratoDelaySeconds: 0,
        vibratoDepthSemitones: 0,
        vibratoRateHz: 0,
        pitchSlideTargetHz: nil,
        pitchSlideTargetRegister: nil,
        pitchSlideFrameCount: nil,
        noiseShortMode: nil,
        waveform: waveform
    )
}

private func resolveLabelReference(_ target: String, from currentLabel: String) -> String {
    guard target.hasPrefix(".") else { return target }
    let scope = currentLabel
        .split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        .first
        .map(String.init) ?? currentLabel
    return scope + target
}

private func audioEvent(from event: TimedEvent) -> AudioManifest.Event {
    AudioManifest.Event(
        startTime: event.startTime,
        duration: event.duration,
        frequencyHz: event.frequencyHz,
        frequencyRegister: event.frequencyRegister,
        amplitude: event.amplitude,
        dutyCycle: event.dutyCycle,
        envelopeStepDuration: event.envelopeStepDuration,
        envelopeDirection: event.envelopeDirection,
        waveSamples: event.waveSamples,
        vibratoDelaySeconds: event.vibratoDelaySeconds,
        vibratoDepthSemitones: event.vibratoDepthSemitones,
        vibratoRateHz: event.vibratoRateHz,
        pitchSlideTargetHz: event.pitchSlideTargetHz,
        pitchSlideTargetRegister: event.pitchSlideTargetRegister,
        pitchSlideFrameCount: event.pitchSlideFrameCount,
        noiseShortMode: event.noiseShortMode,
        waveform: event.waveform
    )
}

private func shiftTimedEvent(_ event: TimedEvent, by offset: Double) -> TimedEvent {
    TimedEvent(
        startTime: max(0, event.startTime + offset),
        duration: event.duration,
        frequencyHz: event.frequencyHz,
        frequencyRegister: event.frequencyRegister,
        amplitude: event.amplitude,
        dutyCycle: event.dutyCycle,
        envelopeStepDuration: event.envelopeStepDuration,
        envelopeDirection: event.envelopeDirection,
        waveSamples: event.waveSamples,
        vibratoDelaySeconds: event.vibratoDelaySeconds,
        vibratoDepthSemitones: event.vibratoDepthSemitones,
        vibratoRateHz: event.vibratoRateHz,
        pitchSlideTargetHz: event.pitchSlideTargetHz,
        pitchSlideTargetRegister: event.pitchSlideTargetRegister,
        pitchSlideFrameCount: event.pitchSlideFrameCount,
        noiseShortMode: event.noiseShortMode,
        waveform: event.waveform
    )
}

private func renderNoiseInstrument(
    _ templates: [NoiseInstrumentEventTemplate],
    startingAt startTime: Double
) -> [TimedEvent] {
    templates.map { template in
        TimedEvent(
            startTime: startTime + template.startTime,
            duration: template.duration,
            frequencyHz: template.clockHz,
            frequencyRegister: nil,
            amplitude: template.amplitude,
            dutyCycle: nil,
            envelopeStepDuration: template.envelopeStepDuration,
            envelopeDirection: template.envelopeDirection,
            waveSamples: nil,
            vibratoDelaySeconds: 0,
            vibratoDepthSemitones: 0,
            vibratoRateHz: 0,
            pitchSlideTargetHz: nil,
            pitchSlideTargetRegister: nil,
            pitchSlideFrameCount: nil,
            noiseShortMode: template.shortMode,
            waveform: .noise
        )
    }
}

private func dutyCycle(for value: Int) -> Double {
    switch value {
    case 0: return 0.125
    case 1: return 0.25
    case 3: return 0.75
    default: return 0.5
    }
}

private func waveChannelVolume(for value: Int) -> Double {
    switch max(0, min(3, value)) {
    case 0: return 0
    case 1: return 1
    case 2: return 0.5
    default: return 0.25
    }
}

private func envelopeDirection(for fade: Int) -> Int {
    if fade < 0 { return 1 }
    if fade > 0 { return -1 }
    return 0
}

private func envelopeStepDuration(for fade: Int) -> Double? {
    let period = abs(fade)
    guard period > 0 else { return nil }
    return Double(period) / 64
}

private struct RenderedChannel1PitchSweepTarget {
    let targetHz: Double
    let targetRegister: Int
    let frameCount: Int
}

// Channel 1 `pitch_sweep` commands program NR10 directly, so approximate the
// hardware sweep into a single register target over the rendered note duration.
private func makeChannel1PitchSweepState(
    timeNibble: Int,
    signedShiftMagnitude: Int
) -> Channel1PitchSweepState? {
    let shiftMagnitude = abs(signedShiftMagnitude) & 0x7
    guard shiftMagnitude > 0 else { return nil }

    return Channel1PitchSweepState(
        periodNibble: timeNibble & 0xf,
        shiftMagnitude: shiftMagnitude,
        decreasesPitch: signedShiftMagnitude < 0
    )
}

private func renderChannel1PitchSweepTarget(
    startRegister: Int,
    duration: Double,
    sweepState: Channel1PitchSweepState?
) -> RenderedChannel1PitchSweepTarget? {
    guard let sweepState else { return nil }

    let periodBits = sweepState.periodNibble & 0x7
    let periodTicks = periodBits == 0 ? 8 : periodBits
    let stepDuration = Double(periodTicks) / 128
    guard stepDuration > 0 else { return nil }

    let iterations = max(1, Int((duration / stepDuration).rounded(.down)))
    var currentRegister = startRegister

    for _ in 0..<iterations {
        let delta = currentRegister >> sweepState.shiftMagnitude
        guard delta > 0 else { break }

        let nextRegister = sweepState.decreasesPitch
            ? currentRegister - delta
            : currentRegister + delta

        guard (1...2047).contains(nextRegister) else { break }
        currentRegister = nextRegister
    }

    guard currentRegister != startRegister else { return nil }

    return RenderedChannel1PitchSweepTarget(
        targetHz: frequencyHz(forRegister: currentRegister, waveform: .square),
        targetRegister: currentRegister,
        frameCount: noteFrameCount(for: duration)
    )
}

private func advanceNoteDurationSeconds(length: Int, state: inout ChannelState) -> Double {
    let noteLengthUnits = max(1, length)
    let noteSpeed = max(1, state.noteSpeed)
    let tempo = max(1, state.tempo)

    // The audio engine carries a fractional byte across note delays instead of using
    // a smooth average duration, so fast tracks must be quantized to whole frames.
    let noteLengthProduct = (noteLengthUnits * noteSpeed) & 0xff
    let totalDelay = (state.noteDelayFraction + (noteLengthProduct * tempo)) & 0xffff
    let frameCount = max(1, totalDelay >> 8)

    state.noteDelayFraction = totalDelay & 0xff
    return Double(frameCount) / 60
}

private func noteFrameCount(for duration: Double) -> Int {
    max(1, Int((duration * 60).rounded()))
}

private func parseWaveSampleTables(repoRoot: URL) throws -> [Int: [Double]] {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("audio/wave_samples.asm"))
    let rawLines = contents.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    var currentIndex: Int?
    var currentValues: [Double] = []
    var tables: [Int: [Double]] = [:]

    func flushCurrent() {
        guard let currentIndex, currentValues.isEmpty == false else { return }
        tables[currentIndex] = currentValues
    }

    for rawLine in rawLines {
        let withoutComment = rawLine.split(separator: ";", maxSplits: 1).first.map(String.init) ?? ""
        let trimmed = withoutComment.trimmingCharacters(in: .whitespaces)
        guard trimmed.isEmpty == false else { continue }

        if let match = trimmed.firstMatch(of: /\.wave(\d+)/), let value = Int(match.output.1) {
            flushCurrent()
            currentIndex = value
            currentValues = []
            continue
        }

        guard trimmed.hasPrefix("dn"), currentIndex != nil else { continue }
        let payload = trimmed.dropFirst(2)
        let values = payload
            .split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            .map { (Double($0) / 15 * 2) - 1 }
        currentValues.append(contentsOf: values)
    }

    flushCurrent()

    if let wave5 = tables[5] {
        for index in 6...8 {
            tables[index] = tables[index] ?? wave5
        }
    }

    return tables
}

private func parseNoiseInstrumentTables(repoRoot: URL) throws -> [Int: [NoiseInstrumentEventTemplate]] {
    let regex = try NSRegularExpression(pattern: #"noise_note\s+(-?\d+),\s*(-?\d+),\s*(-?\d+),\s*(-?\d+)"#)
    var result: [Int: [NoiseInstrumentEventTemplate]] = [:]

    for instrumentID in 1...19 {
        let url = repoRoot.appendingPathComponent(String(format: "audio/sfx/noise_instrument%02d_1.asm", instrumentID))
        let contents = try String(contentsOf: url)
        let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
        var startTime = 0.0
        var events: [NoiseInstrumentEventTemplate] = []

        for match in regex.matches(in: contents, range: nsRange) {
            guard
                let lengthRange = Range(match.range(at: 1), in: contents),
                let volumeRange = Range(match.range(at: 2), in: contents),
                let fadeRange = Range(match.range(at: 3), in: contents),
                let counterRange = Range(match.range(at: 4), in: contents),
                let length = Int(contents[lengthRange]),
                let volume = Int(contents[volumeRange]),
                let fade = Int(contents[fadeRange]),
                let polynomialCounter = Int(contents[counterRange])
            else {
                continue
            }

            let duration = Double(max(1, length + 1)) / 60.0
            let (clockHz, shortMode) = noiseClockParameters(for: polynomialCounter)
            events.append(
                NoiseInstrumentEventTemplate(
                    startTime: startTime,
                    duration: duration,
                    amplitude: max(0, min(1, Double(volume) / 15)),
                    envelopeStepDuration: envelopeStepDuration(for: fade),
                    envelopeDirection: envelopeDirection(for: fade),
                    clockHz: clockHz,
                    shortMode: shortMode
                )
            )
            startTime += duration
        }

        result[instrumentID] = events
    }

    return result
}

private func parsePitchRegisters(repoRoot: URL) throws -> [String: Int] {
    let noteOrder = ["C_", "C#", "D_", "D#", "E_", "F_", "F#", "G_", "G#", "A_", "A#", "B_"]
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("audio/notes.asm"))
    let regex = try NSRegularExpression(pattern: #"dw\s+\$([0-9A-Fa-f]{4})"#)
    let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    let matches = regex.matches(in: contents, range: nsRange)
    guard matches.count >= noteOrder.count else {
        throw ExtractorError.invalidArguments("failed to resolve all pitch registers from audio/notes.asm")
    }
    var registers: [String: Int] = [:]
    for (index, noteName) in noteOrder.enumerated() {
        guard let range = Range(matches[index].range(at: 1), in: contents),
              let value = Int(contents[range], radix: 16) else {
            throw ExtractorError.invalidArguments("failed to parse pitch register for \(noteName)")
        }
        registers[noteName] = value
    }
    return registers
}

private func frequencyRegister(
    for name: String,
    octave: Int,
    perfectPitchEnabled: Bool,
    pitchRegisters: [String: Int]
) -> Int? {
    guard let baseRegister = pitchRegisters[name] else { return nil }
    let shiftCount = max(0, octave - 1)
    let signedRegister = Int(Int16(bitPattern: UInt16(baseRegister)))
    var hardwareRegister = (signedRegister >> shiftCount) + 0x0800
    if perfectPitchEnabled {
        hardwareRegister += 1
    }
    return hardwareRegister
}

private func frequencyHz(forRegister hardwareRegister: Int, waveform: AudioManifest.Waveform) -> Double {
    let frequencyBits = hardwareRegister & 0x07ff
    let denominator = 2048 - frequencyBits
    guard denominator > 0 else { return 0 }
    let numerator: Double = waveform == .wave ? 65_536 : 131_072
    return numerator / Double(denominator)
}

private func frequencyHz(
    for name: String,
    octave: Int,
    waveform: AudioManifest.Waveform,
    perfectPitchEnabled: Bool,
    pitchRegisters: [String: Int]
) -> Double? {
    guard waveform != .noise,
          let hardwareRegister = frequencyRegister(
              for: name,
              octave: octave,
              perfectPitchEnabled: perfectPitchEnabled,
              pitchRegisters: pitchRegisters
          ) else {
        return nil
    }
    return frequencyHz(forRegister: hardwareRegister, waveform: waveform)
}

private func noiseClockParameters(for polynomialCounter: Int) -> (Double, Bool) {
    let divisorCode = polynomialCounter & 0b111
    let shortMode = (polynomialCounter & 0b1000) != 0
    let shift = (polynomialCounter >> 4) & 0b1111
    let divisor: Double = divisorCode == 0 ? 8 : Double(divisorCode * 16)
    let clockHz = 524_288 / divisor / pow(2, Double(shift + 1))
    return (clockHz, shortMode)
}
