import Foundation
import PokeDataModel

public enum RedContentExtractor {
    public static let extractorVersion = "0.1.0"
    private static let sendOutPoofAssetPath = "Assets/battle/effects/send_out_poof.png"
    private static let legacyFieldAnimationDirectory = "Assets/field/animations"
    private static let tilesetAnimationDirectory = "Assets/field/tileset_animations"
    private static let itemAssetDirectory = "Assets/items"
    private static let battleAnimationAssetMap: [(source: String, destination: String)] = [
        ("gfx/battle/move_anim_0.png", "Assets/battle/animations/move_anim_0.png"),
        ("gfx/battle/move_anim_1.png", "Assets/battle/animations/move_anim_1.png"),
    ]
    private static let tilesetAnimationAssetMap: [(source: String, destination: String)] = (1...3).map { frameIndex in
        (
            source: "gfx/tilesets/flower/flower\(frameIndex).png",
            destination: "Assets/field/tileset_animations/flower/flower\(frameIndex).png"
        )
    }
    private static let fieldAssetMap: [(source: String, destination: String)] = [
        ("gfx/tilesets/reds_house.png", "Assets/field/tilesets/reds_house.png"),
        ("gfx/tilesets/overworld.png", "Assets/field/tilesets/overworld.png"),
        ("gfx/tilesets/cavern.png", "Assets/field/tilesets/cavern.png"),
        ("gfx/tilesets/forest.png", "Assets/field/tilesets/forest.png"),
        ("gfx/tilesets/gym.png", "Assets/field/tilesets/gym.png"),
        ("gfx/tilesets/gate.png", "Assets/field/tilesets/gate.png"),
        ("gfx/tilesets/house.png", "Assets/field/tilesets/house.png"),
        ("gfx/tilesets/interior.png", "Assets/field/tilesets/interior.png"),
        ("gfx/tilesets/pokecenter.png", "Assets/field/tilesets/pokecenter.png"),
        ("gfx/tilesets/club.png", "Assets/field/tilesets/club.png"),
        ("gfx/tilesets/ship.png", "Assets/field/tilesets/ship.png"),
        ("gfx/sprites/red.png", "Assets/field/sprites/red.png"),
        ("gfx/sprites/oak.png", "Assets/field/sprites/oak.png"),
        ("gfx/sprites/blue.png", "Assets/field/sprites/blue.png"),
        ("gfx/sprites/mom.png", "Assets/field/sprites/mom.png"),
        ("gfx/sprites/girl.png", "Assets/field/sprites/girl.png"),
        ("gfx/sprites/fisher.png", "Assets/field/sprites/fisher.png"),
        ("gfx/sprites/scientist.png", "Assets/field/sprites/scientist.png"),
        ("gfx/sprites/youngster.png", "Assets/field/sprites/youngster.png"),
        ("gfx/sprites/gambler.png", "Assets/field/sprites/gambler.png"),
        ("gfx/sprites/gambler_asleep.png", "Assets/field/sprites/gambler_asleep.png"),
        ("gfx/sprites/super_nerd.png", "Assets/field/sprites/super_nerd.png"),
        ("gfx/sprites/brunette_girl.png", "Assets/field/sprites/brunette_girl.png"),
        ("gfx/sprites/cooltrainer_f.png", "Assets/field/sprites/cooltrainer_f.png"),
        ("gfx/sprites/balding_guy.png", "Assets/field/sprites/balding_guy.png"),
        ("gfx/sprites/little_girl.png", "Assets/field/sprites/little_girl.png"),
        ("gfx/sprites/bird.png", "Assets/field/sprites/bird.png"),
        ("gfx/sprites/clipboard.png", "Assets/field/sprites/clipboard.png"),
        ("gfx/sprites/clerk.png", "Assets/field/sprites/clerk.png"),
        ("gfx/sprites/cooltrainer_m.png", "Assets/field/sprites/cooltrainer_m.png"),
        ("gfx/sprites/nurse.png", "Assets/field/sprites/nurse.png"),
        ("gfx/sprites/gentleman.png", "Assets/field/sprites/gentleman.png"),
        ("gfx/sprites/fairy.png", "Assets/field/sprites/fairy.png"),
        ("gfx/sprites/gramps.png", "Assets/field/sprites/gramps.png"),
        ("gfx/sprites/fishing_guru.png", "Assets/field/sprites/fishing_guru.png"),
        ("gfx/sprites/granny.png", "Assets/field/sprites/granny.png"),
        ("gfx/sprites/guard.png", "Assets/field/sprites/guard.png"),
        ("gfx/sprites/hiker.png", "Assets/field/sprites/hiker.png"),
        ("gfx/sprites/gym_guide.png", "Assets/field/sprites/gym_guide.png"),
        ("gfx/sprites/swimmer.png", "Assets/field/sprites/swimmer.png"),
        ("gfx/sprites/bike_shop_clerk.png", "Assets/field/sprites/bike_shop_clerk.png"),
        ("gfx/sprites/little_boy.png", "Assets/field/sprites/little_boy.png"),
        ("gfx/sprites/link_receptionist.png", "Assets/field/sprites/link_receptionist.png"),
        ("gfx/sprites/middle_aged_man.png", "Assets/field/sprites/middle_aged_man.png"),
        ("gfx/sprites/middle_aged_woman.png", "Assets/field/sprites/middle_aged_woman.png"),
        ("gfx/sprites/monster.png", "Assets/field/sprites/monster.png"),
        ("gfx/sprites/old_amber.png", "Assets/field/sprites/old_amber.png"),
        ("gfx/sprites/poke_ball.png", "Assets/field/sprites/poke_ball.png"),
        ("gfx/sprites/pokedex.png", "Assets/field/sprites/pokedex.png"),
        ("gfx/sprites/rocket.png", "Assets/field/sprites/rocket.png"),
        ("gfx/sprites/fossil.png", "Assets/field/sprites/fossil.png"),
        ("gfx/blocksets/reds_house.bst", "Assets/field/blocksets/reds_house.bst"),
        ("gfx/blocksets/overworld.bst", "Assets/field/blocksets/overworld.bst"),
        ("gfx/blocksets/cavern.bst", "Assets/field/blocksets/cavern.bst"),
        ("gfx/blocksets/forest.bst", "Assets/field/blocksets/forest.bst"),
        ("gfx/blocksets/gym.bst", "Assets/field/blocksets/gym.bst"),
        ("gfx/blocksets/gate.bst", "Assets/field/blocksets/gate.bst"),
        ("gfx/blocksets/house.bst", "Assets/field/blocksets/house.bst"),
        ("gfx/blocksets/interior.bst", "Assets/field/blocksets/interior.bst"),
        ("gfx/blocksets/pokecenter.bst", "Assets/field/blocksets/pokecenter.bst"),
        ("gfx/blocksets/club.bst", "Assets/field/blocksets/club.bst"),
        ("gfx/blocksets/ship.bst", "Assets/field/blocksets/ship.bst"),
    ]

    public struct Configuration: Sendable {
        public let repoRoot: URL
        public let outputRoot: URL

        public init(repoRoot: URL, outputRoot: URL) {
            self.repoRoot = repoRoot
            self.outputRoot = outputRoot
        }
    }

    public static func extract(configuration: Configuration) throws {
        let variantRoot = configuration.outputRoot.appendingPathComponent("Red", isDirectory: true)
        try FileManager.default.createDirectory(at: variantRoot, withIntermediateDirectories: true, attributes: nil)
        try removeItemIfExists(at: variantRoot.appendingPathComponent(legacyFieldAnimationDirectory))
        try removeItemIfExists(at: variantRoot.appendingPathComponent(tilesetAnimationDirectory))
        try removeItemIfExists(at: variantRoot.appendingPathComponent(itemAssetDirectory))

        let source = try SourceTree(repoRoot: configuration.repoRoot)
        let charmap = try parseCharmap(at: source.charmapURL)
        let constants = try parseConstants(source: source)
        let titleManifest = try parseTitleManifest(source: source)
        let gameManifest = makeGameManifest(source: source)
        let gameplayManifest = try extractGameplayManifest(source: source)
        let battleAnimationManifest = try extractBattleAnimationManifest(source: source)
        let audioManifest = try extractAudioManifest(source: source, titleTrackID: constants.musicTrack)

        try writeJSON(gameManifest, to: variantRoot.appendingPathComponent("game_manifest.json"))
        try writeJSON(constants, to: variantRoot.appendingPathComponent("constants.json"))
        try writeJSON(charmap, to: variantRoot.appendingPathComponent("charmap.json"))
        try writeJSON(titleManifest, to: variantRoot.appendingPathComponent("title_manifest.json"))
        try writeJSON(gameplayManifest, to: variantRoot.appendingPathComponent("gameplay_manifest.json"))
        try writeJSON(battleAnimationManifest, to: variantRoot.appendingPathComponent("battle_animation_manifest.json"))
        try writeJSON(audioManifest, to: variantRoot.appendingPathComponent("audio_manifest.json"))

        for (sourcePath, destination) in source.assetMap.sorted(by: { $0.key < $1.key }) {
            let sourceURL = configuration.repoRoot.appendingPathComponent(sourcePath)
            let destinationURL = variantRoot.appendingPathComponent(destination)
            try copyAsset(from: sourceURL, to: destinationURL)
        }
        for fieldAsset in fieldAssetMap {
            let sourceURL = configuration.repoRoot.appendingPathComponent(fieldAsset.source)
            let destinationURL = variantRoot.appendingPathComponent(fieldAsset.destination)
            try copyAsset(from: sourceURL, to: destinationURL)
        }
        for battleAsset in battleAssetMap(from: gameplayManifest) {
            let sourceURL = configuration.repoRoot.appendingPathComponent(battleAsset.source)
            let destinationURL = variantRoot.appendingPathComponent(battleAsset.destination)
            try copyAsset(from: sourceURL, to: destinationURL)
        }
        for battleAnimationAsset in battleAnimationAssetMap {
            let sourceURL = configuration.repoRoot.appendingPathComponent(battleAnimationAsset.source)
            let destinationURL = variantRoot.appendingPathComponent(battleAnimationAsset.destination)
            try copyAsset(from: sourceURL, to: destinationURL)
        }
        for animationAsset in tilesetAnimationAssetMap {
            let sourceURL = configuration.repoRoot.appendingPathComponent(animationAsset.source)
            let destinationURL = variantRoot.appendingPathComponent(animationAsset.destination)
            try copyAsset(from: sourceURL, to: destinationURL)
        }
        for itemAsset in pokespriteItemAssetMap(from: gameplayManifest.items) {
            let sourceURL = configuration.repoRoot.appendingPathComponent(itemAsset.source)
            let destinationURL = variantRoot.appendingPathComponent(itemAsset.destination)
            try copyAsset(from: sourceURL, to: destinationURL)
        }
        try copyAsset(
            from: configuration.repoRoot.appendingPathComponent("gfx/battle/move_anim_0.png"),
            to: variantRoot.appendingPathComponent(sendOutPoofAssetPath)
        )
    }

    public static func verify(configuration: Configuration) throws {
        let variantRoot = configuration.outputRoot.appendingPathComponent("Red", isDirectory: true)
        let decoder = JSONDecoder()
        let required = [
            "game_manifest.json",
            "constants.json",
            "charmap.json",
            "title_manifest.json",
            "gameplay_manifest.json",
            "battle_animation_manifest.json",
            "audio_manifest.json",
            "Assets/title/pokemon_logo.png",
            "Assets/title/player.png",
            "Assets/splash/gamefreak_logo.png",
            "Assets/field/tilesets/reds_house.png",
            "Assets/field/tilesets/overworld.png",
            "Assets/field/tilesets/cavern.png",
            "Assets/field/tilesets/forest.png",
            "Assets/field/tilesets/gym.png",
            "Assets/field/tilesets/gate.png",
            "Assets/field/tilesets/house.png",
            "Assets/field/tilesets/interior.png",
            "Assets/field/tilesets/pokecenter.png",
            "Assets/field/tilesets/club.png",
            "Assets/field/tilesets/ship.png",
            "Assets/field/sprites/red.png",
            "Assets/field/sprites/oak.png",
            "Assets/field/sprites/blue.png",
            "Assets/field/sprites/mom.png",
            "Assets/field/sprites/girl.png",
            "Assets/field/sprites/fisher.png",
            "Assets/field/sprites/scientist.png",
            "Assets/field/sprites/youngster.png",
            "Assets/field/sprites/gambler.png",
            "Assets/field/sprites/gambler_asleep.png",
            "Assets/field/sprites/super_nerd.png",
            "Assets/field/sprites/brunette_girl.png",
            "Assets/field/sprites/cooltrainer_f.png",
            "Assets/field/sprites/balding_guy.png",
            "Assets/field/sprites/little_girl.png",
            "Assets/field/sprites/bird.png",
            "Assets/field/sprites/clipboard.png",
            "Assets/field/sprites/clerk.png",
            "Assets/field/sprites/cooltrainer_m.png",
            "Assets/field/sprites/nurse.png",
            "Assets/field/sprites/gentleman.png",
            "Assets/field/sprites/fairy.png",
            "Assets/field/sprites/gramps.png",
            "Assets/field/sprites/fishing_guru.png",
            "Assets/field/sprites/granny.png",
            "Assets/field/sprites/guard.png",
            "Assets/field/sprites/hiker.png",
            "Assets/field/sprites/gym_guide.png",
            "Assets/field/sprites/swimmer.png",
            "Assets/field/sprites/bike_shop_clerk.png",
            "Assets/field/sprites/little_boy.png",
            "Assets/field/sprites/link_receptionist.png",
            "Assets/field/sprites/middle_aged_man.png",
            "Assets/field/sprites/middle_aged_woman.png",
            "Assets/field/sprites/monster.png",
            "Assets/field/sprites/old_amber.png",
            "Assets/field/sprites/poke_ball.png",
            "Assets/field/sprites/pokedex.png",
            "Assets/field/sprites/rocket.png",
            "Assets/field/sprites/fossil.png",
            "Assets/field/blocksets/reds_house.bst",
            "Assets/field/blocksets/overworld.bst",
            "Assets/field/blocksets/cavern.bst",
            "Assets/field/blocksets/forest.bst",
            "Assets/field/blocksets/gym.bst",
            "Assets/field/blocksets/gate.bst",
            "Assets/field/blocksets/house.bst",
            "Assets/field/blocksets/interior.bst",
            "Assets/field/blocksets/pokecenter.bst",
            "Assets/field/blocksets/club.bst",
            "Assets/field/blocksets/ship.bst",
            "Assets/battle/animations/move_anim_0.png",
            "Assets/battle/animations/move_anim_1.png",
            sendOutPoofAssetPath,
        ] + tilesetAnimationAssetMap.map { $0.destination }

        for relativePath in required {
            let url = variantRoot.appendingPathComponent(relativePath)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw ExtractorError.missingOutput(url.path)
            }
        }

        _ = try decoder.decode(GameManifest.self, from: Data(contentsOf: variantRoot.appendingPathComponent("game_manifest.json")))
        _ = try decoder.decode(ConstantsManifest.self, from: Data(contentsOf: variantRoot.appendingPathComponent("constants.json")))
        _ = try decoder.decode(CharmapManifest.self, from: Data(contentsOf: variantRoot.appendingPathComponent("charmap.json")))
        _ = try decoder.decode(TitleSceneManifest.self, from: Data(contentsOf: variantRoot.appendingPathComponent("title_manifest.json")))
        let gameplayManifest = try decoder.decode(GameplayManifest.self, from: Data(contentsOf: variantRoot.appendingPathComponent("gameplay_manifest.json")))
        _ = try decoder.decode(BattleAnimationManifest.self, from: Data(contentsOf: variantRoot.appendingPathComponent("battle_animation_manifest.json")))
        _ = try decoder.decode(AudioManifest.self, from: Data(contentsOf: variantRoot.appendingPathComponent("audio_manifest.json")))

        for battleAsset in battleAssetMap(from: gameplayManifest) {
            let url = variantRoot.appendingPathComponent(battleAsset.destination)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw ExtractorError.missingOutput(url.path)
            }
        }
        for itemAsset in pokespriteItemAssetMap(from: gameplayManifest.items) {
            let url = variantRoot.appendingPathComponent(itemAsset.destination)
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw ExtractorError.missingOutput(url.path)
            }
        }

        let sendOutPoofURL = variantRoot.appendingPathComponent(sendOutPoofAssetPath)
        guard FileManager.default.fileExists(atPath: sendOutPoofURL.path) else {
            throw ExtractorError.missingOutput(sendOutPoofURL.path)
        }
    }

    public static func parseCharmap(at url: URL) throws -> CharmapManifest {
        try CharmapParser.parse(contentsOf: url, variant: .red)
    }

    private static func makeGameManifest(source: SourceTree) -> GameManifest {
        GameManifest(
            contentVersion: "m6_5_red_bag_grid_v1",
            variant: .red,
            sourceCommit: source.gitCommit,
            extractorVersion: extractorVersion,
            sourceFiles: source.manifestSources
        )
    }

    private static func parseConstants(source: SourceTree) throws -> ConstantsManifest {
        let titleContents = try String(contentsOf: source.titleURL, encoding: .utf8)
        let menuContents = try String(contentsOf: source.mainMenuURL, encoding: .utf8)

        guard let watchedKeys = menuContents.firstMatch(of: /ld a,\s+(PAD_A \| PAD_B \| PAD_START)/)?.output.1 else {
            throw ExtractorError.invalidArguments("Failed to parse watched menu keys from main_menu.asm")
        }

        guard let musicTrack = titleContents.firstMatch(of: /ld a,\s+(MUSIC_TITLE_SCREEN)/)?.output.1 else {
            throw ExtractorError.invalidArguments("Failed to parse title music track from title.asm")
        }

        return ConstantsManifest(
            variant: .red,
            sourceFiles: [
                .init(path: "engine/movie/title.asm", purpose: "title music and title-mon selection"),
                .init(path: "engine/menus/main_menu.asm", purpose: "menu key handling"),
            ],
            watchedKeys: watchedKeys.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) },
            musicTrack: String(musicTrack),
            titleMonSelectionConstant: try parseTitleMonSelectionToken(from: titleContents)
        )
    }

    private static func parseTitleManifest(source: SourceTree) throws -> TitleSceneManifest {
        let titleContents = try String(contentsOf: source.titleURL, encoding: .utf8)
        let title2Contents = try String(contentsOf: source.title2URL, encoding: .utf8)
        let titleMonsContents = try String(contentsOf: source.titleMonsURL, encoding: .utf8)
        let pokemonConstantsContents = try String(contentsOf: source.pokemonConstantsURL, encoding: .utf8)
        let starterAliases = parseStarterSpeciesAliases(from: pokemonConstantsContents)
        return TitleSceneManifest(
            variant: .red,
            sourceFiles: source.manifestSources,
            titleMonSpecies: try parseTitleMonSelection(from: titleContents, starterAliases: starterAliases),
            titleMonSpeciesPool: try parseTitleMonPool(
                from: titleMonsContents,
                starterAliases: starterAliases,
                variant: .red
            ),
            menuEntries: [
                .init(id: "newGame", label: "New Game", enabledByDefault: true),
                .init(id: "continue", label: "Continue", enabledByDefault: false),
                .init(id: "options", label: "Options", enabledByDefault: true),
            ],
            logoBounceSequence: try parseLogoBounceSteps(from: titleContents),
            titleMonScrollInSequence: try parseTitleScrollInSteps(from: title2Contents),
            titleMonScrollOutSequence: try parseTitleScrollOutSteps(from: title2Contents),
            assets: [
                .init(id: "pokemon_logo", relativePath: "Assets/title/pokemon_logo.png", kind: "titleLogo"),
                .init(id: "red_version", relativePath: "Assets/title/red_version.png", kind: "version"),
                .init(id: "player", relativePath: "Assets/title/player.png", kind: "titleCharacter"),
                .init(id: "gamefreak_inc", relativePath: "Assets/title/gamefreak_inc.png", kind: "titleWordmark"),
                .init(id: "splash_logo", relativePath: "Assets/splash/gamefreak_logo.png", kind: "splashLogo"),
                .init(id: "splash_presents", relativePath: "Assets/splash/gamefreak_presents.png", kind: "splashText"),
                .init(id: "splash_copyright", relativePath: "Assets/splash/copyright.png", kind: "copyright"),
                .init(id: "falling_star", relativePath: "Assets/splash/falling_star.png", kind: "splashAccent"),
            ],
            timings: .init(launchFadeSeconds: 0.4, splashDurationSeconds: 1.2, attractPromptDelaySeconds: 0.8)
        )
    }

    private static func parseTitleMonSelectionToken(from contents: String) throws -> String {
        guard let match = contents.firstMatch(of: /IF DEF\(_RED\)\s+ld a,\s+([A-Z0-9_]+)/) else {
            throw ExtractorError.invalidArguments("Failed to parse Red title-mon selection")
        }
        return String(match.output.1)
    }

    private static func parseTitleMonSelection(
        from contents: String,
        starterAliases: [String: String]
    ) throws -> String {
        let token = try parseTitleMonSelectionToken(from: contents)
        return starterAliases[token] ?? token
    }

    public static func parseLogoBounceSteps(from contents: String) throws -> [LogoBounceStep] {
        try TitleManifestParser.parseBounceSequence(contents)
    }

    public static func parseTitleScrollInSteps(from contents: String) throws -> [TitleScrollStep] {
        try parseTitleScrollSteps(
            from: contents,
            pattern: /TitleScroll_In:\s*(?:;[^\n]*\s*)*db\s+([^\n]+)/,
            label: "TitleScroll_In"
        )
    }

    public static func parseTitleScrollOutSteps(from contents: String) throws -> [TitleScrollStep] {
        try parseTitleScrollSteps(
            from: contents,
            pattern: /TitleScroll_Out:\s*(?:;[^\n]*\s*)*db\s+([^\n]+)/,
            label: "TitleScroll_Out"
        )
    }

    private static func parseTitleScrollSteps(
        from contents: String,
        pattern: Regex<(Substring, Substring)>,
        label: String
    ) throws -> [TitleScrollStep] {
        guard let lineMatch = contents.firstMatch(of: pattern) else {
            throw ExtractorError.invalidArguments("Missing \(label) section")
        }

        let tokenString = String(lineMatch.output.1)
        let tokens = tokenString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .prefix { $0 != "0" && $0 != "$00" }
        let bytes = try tokens.map(parseByte)

        return bytes.map { byte in
            TitleScrollStep(speed: Int((byte & 0xF0) >> 4), frames: Int(byte & 0x0F))
        }
    }

    public static func parseTitleMonPool(
        from contents: String,
        starterAliases: [String: String],
        variant: GameVariant
    ) throws -> [String] {
        let variantMarker = variant == .red ? "_RED" : "_BLUE"
        guard let sectionRange = contents.range(of: "IF DEF(\(variantMarker))") else {
            throw ExtractorError.invalidArguments("Missing \(variant.rawValue.capitalized) title mon pool")
        }
        guard let endRange = contents[sectionRange.upperBound...].range(of: "ENDC") else {
            throw ExtractorError.invalidArguments("Unterminated \(variant.rawValue.capitalized) title mon pool")
        }

        let section = contents[sectionRange.upperBound..<endRange.lowerBound]
        let entries = section
            .split(whereSeparator: \.isNewline)
            .compactMap { rawLine -> String? in
                let line = rawLine.split(separator: ";", maxSplits: 1).first?.trimmingCharacters(in: .whitespaces) ?? ""
                guard line.hasPrefix("db ") else { return nil }
                let token = line.replacingOccurrences(of: "db", with: "")
                    .trimmingCharacters(in: .whitespaces)
                return starterAliases[token] ?? token
            }

        guard entries.isEmpty == false else {
            throw ExtractorError.invalidArguments("Empty \(variant.rawValue.capitalized) title mon pool")
        }

        return entries
    }

    private static func parseStarterSpeciesAliases(from contents: String) -> [String: String] {
        let pattern = /DEF\s+(STARTER[123])\s+EQU\s+([A-Z0-9_]+)/
        return contents.matches(of: pattern).reduce(into: [:]) { partial, match in
            partial[String(match.output.1)] = String(match.output.2)
        }
    }

    private static func parseByte(_ token: String) throws -> UInt8 {
        if token.hasPrefix("$"), let value = UInt8(token.dropFirst(), radix: 16) {
            return value
        }
        if let value = Int(token), (-128...255).contains(value) {
            return UInt8(bitPattern: Int8(truncatingIfNeeded: value))
        }
        throw ExtractorError.invalidArguments("Unsupported byte literal: \(token)")
    }

    private static func copyAsset(from source: URL, to destination: URL) throws {
        guard FileManager.default.fileExists(atPath: source.path) else {
            throw ExtractorError.missingSource(source.path)
        }
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        let data = try Data(contentsOf: source)
        try write(data: data, to: destination)
    }

    private static func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(value)
        try write(data: data + Data("\n".utf8), to: url)
    }

    private static func write(data: Data, to url: URL) throws {
        if let existing = try? Data(contentsOf: url), existing == data {
            return
        }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        try data.write(to: url, options: .atomic)
    }

    private static func removeItemIfExists(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private static func battleAssetMap(from gameplayManifest: GameplayManifest) -> [(source: String, destination: String)] {
        let pokemonAssets = gameplayManifest.species
            .flatMap { species -> [(source: String, destination: String)] in
                guard let battleSprite = species.battleSprite else { return [] }
                let frontFilename = URL(fileURLWithPath: battleSprite.frontImagePath).lastPathComponent
                let backStem = URL(fileURLWithPath: battleSprite.backImagePath)
                    .deletingPathExtension()
                    .lastPathComponent
                let backFilename = "\(backStem)b.png"
                return [
                    ("gfx/pokemon/front/\(frontFilename)", battleSprite.frontImagePath),
                    ("gfx/pokemon/back/\(backFilename)", battleSprite.backImagePath),
                ]
            }
        let trainerAssets = Set(gameplayManifest.trainerBattles.compactMap(\.trainerSpritePath)).map { path in
            let filename = URL(fileURLWithPath: path).lastPathComponent
            return ("gfx/trainers/\(filename)", path)
        }
        let playerAssets = [
            ("gfx/player/red.png", "Assets/battle/trainers/red.png"),
            ("gfx/player/redb.png", "Assets/battle/trainers/redb.png"),
        ]

        return (pokemonAssets + trainerAssets + playerAssets)
            .sorted { lhs, rhs in lhs.destination < rhs.destination }
    }

}

public enum CharmapParser {
    public static func parse(contentsOf url: URL, variant: GameVariant) throws -> CharmapManifest {
        let contents = try String(contentsOf: url, encoding: .utf8)
        let regex = try NSRegularExpression(pattern: #"charmap\s+"([^"]+)",\s+\$([0-9A-Fa-f]{2})"#)
        var currentSection = "default"
        var entries: [CharmapEntry] = []

        for line in contents.split(separator: "\n", omittingEmptySubsequences: false) {
            let stringLine = String(line).trimmingCharacters(in: .whitespaces)
            if stringLine.hasPrefix(";") {
                currentSection = stringLine
                continue
            }

            let rawLine = String(line)
            let nsRange = NSRange(rawLine.startIndex..<rawLine.endIndex, in: rawLine)
            guard let match = regex.firstMatch(in: rawLine, range: nsRange),
                  let tokenRange = Range(match.range(at: 1), in: rawLine),
                  let valueRange = Range(match.range(at: 2), in: rawLine) else {
                continue
            }

            entries.append(
                CharmapEntry(
                    token: String(rawLine[tokenRange]),
                    value: Int(rawLine[valueRange], radix: 16) ?? 0,
                    sourceSection: currentSection
                )
            )
        }

        return CharmapManifest(variant: variant, entries: entries)
    }
}

public enum TitleManifestParser {
    public static func parseBounceSequence(_ contents: String) throws -> [LogoBounceStep] {
        guard let sectionRange = contents.range(of: ".TitleScreenPokemonLogoYScrolls:") else {
            throw ExtractorError.invalidArguments("Missing title logo bounce section")
        }

        let tail = contents[sectionRange.upperBound...]
        var steps: [LogoBounceStep] = []
        for rawLine in tail.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix(".ScrollTitleScreenPokemonLogo") || line == "db 0" || line.hasPrefix("db 0 ") {
                break
            }
            if let match = line.firstMatch(of: /db\s+(-?\d+),\s*(\d+)/),
               let delta = Int(match.output.1),
               let frames = Int(match.output.2) {
                steps.append(.init(yDelta: delta, frames: frames))
            }
        }
        return steps
    }
}

public enum ExtractorError: Error, CustomStringConvertible {
    case invalidArguments(String)
    case missingSource(String)
    case missingOutput(String)

    public var description: String {
        switch self {
        case let .invalidArguments(message):
            return message
        case let .missingSource(path):
            return "Missing source asset: \(path)"
        case let .missingOutput(path):
            return "Missing extracted output: \(path)"
        }
    }
}

struct SourceTree {
    let repoRoot: URL
    let charmapURL: URL
    let titleURL: URL
    let title2URL: URL
    let titleMonsURL: URL
    let pokemonConstantsURL: URL
    let splashURL: URL
    let mainMenuURL: URL
    let assetMap: [String: String]
    let manifestSources: [SourceReference]
    let gitCommit: String

    init(repoRoot: URL) throws {
        self.repoRoot = repoRoot
        charmapURL = repoRoot.appendingPathComponent("constants/charmap.asm")
        titleURL = repoRoot.appendingPathComponent("engine/movie/title.asm")
        title2URL = repoRoot.appendingPathComponent("engine/movie/title2.asm")
        titleMonsURL = repoRoot.appendingPathComponent("data/pokemon/title_mons.asm")
        pokemonConstantsURL = repoRoot.appendingPathComponent("constants/pokemon_constants.asm")
        splashURL = repoRoot.appendingPathComponent("engine/movie/splash.asm")
        mainMenuURL = repoRoot.appendingPathComponent("engine/menus/main_menu.asm")
        assetMap = [
            "gfx/title/pokemon_logo.png": "Assets/title/pokemon_logo.png",
            "gfx/title/red_version.png": "Assets/title/red_version.png",
            "gfx/title/player.png": "Assets/title/player.png",
            "gfx/title/gamefreak_inc.png": "Assets/title/gamefreak_inc.png",
            "gfx/splash/gamefreak_logo.png": "Assets/splash/gamefreak_logo.png",
            "gfx/splash/gamefreak_presents.png": "Assets/splash/gamefreak_presents.png",
            "gfx/splash/copyright.png": "Assets/splash/copyright.png",
            "gfx/splash/falling_star.png": "Assets/splash/falling_star.png",
            "gfx/font/font.png": "Assets/font/font.png",
            "gfx/font/font_extra.png": "Assets/font/font_extra.png",
            "gfx/font/font_battle_extra.png": "Assets/font/font_battle_extra.png",
            "gfx/font/AB.png": "Assets/font/AB.png",
            "gfx/font/P.png": "Assets/font/P.png",
            "gfx/font/ED.png": "Assets/font/ED.png",
            "gfx/tilesets/cavern.png": "Assets/field/tilesets/cavern.png",
            "gfx/sprites/fossil.png": "Assets/field/sprites/fossil.png",
            "gfx/sprites/rocket.png": "Assets/field/sprites/rocket.png",
        ]
        manifestSources = [
            .init(path: "constants/charmap.asm", purpose: "font/text token mapping"),
            .init(path: "constants/pokemon_constants.asm", purpose: "title species alias resolution"),
            .init(path: "engine/movie/title.asm", purpose: "title timing and bounce sequence"),
            .init(path: "engine/movie/title2.asm", purpose: "title-screen secondary routines"),
            .init(path: "data/pokemon/title_mons.asm", purpose: "title-screen random mon pool"),
            .init(path: "engine/movie/splash.asm", purpose: "splash source reference"),
            .init(path: "engine/menus/main_menu.asm", purpose: "menu key handling"),
            .init(path: "gfx/title", purpose: "title raster assets"),
            .init(path: "gfx/splash", purpose: "splash raster assets"),
            .init(path: "gfx/font", purpose: "font raster assets"),
            .init(path: "gfx/tilesets", purpose: "field tileset raster assets"),
            .init(path: "gfx/sprites", purpose: "overworld sprite raster assets"),
            .init(path: "gfx/blocksets", purpose: "field blockset binaries"),
        ]
        gitCommit = Self.captureGitCommit(repoRoot: repoRoot)
    }

    private static func captureGitCommit(repoRoot: URL) -> String {
        let process = Process()
        process.currentDirectoryURL = repoRoot
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git", "rev-parse", "--short=12", "HEAD"]
        let stdout = Pipe()
        process.standardOutput = stdout
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            return String(decoding: stdout.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return "unknown"
        }
    }
}
