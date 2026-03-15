import Foundation
import PokeDataModel

func buildFieldInteractions(maps: [MapManifest], repoRoot: URL) throws -> [FieldInteractionManifest] {
    var interactions: [FieldInteractionManifest] = try maps.compactMap { map in
        guard let nurseObject = map.objects.first(where: { $0.sprite == "SPRITE_NURSE" }) else {
            return nil
        }

        return FieldInteractionManifest(
            id: pokemonCenterFieldInteractionID(for: map.id),
            kind: .pokemonCenterHealing,
            introDialogueID: "pokemon_center_welcome",
            prompt: .init(kind: .yesNo, dialogueID: "pokemon_center_shall_we_heal"),
            acceptedDialogueID: "pokemon_center_need_your_pokemon",
            successDialogueID: "pokemon_center_fighting_fit",
            farewellDialogueID: "pokemon_center_farewell",
            healingSequence: .init(
                nurseObjectID: nurseObject.id,
                machineSoundEffectID: "SFX_HEALING_MACHINE",
                healedAudioCueID: "pokemon_center_healed",
                blackoutCheckpoint: try blackoutCheckpointForPokemonCenter(
                    mapID: map.id,
                    maps: maps,
                    repoRoot: repoRoot
                )
            )
        )
    }

    if maps.contains(where: { $0.id == "MUSEUM_1F" }) {
        interactions.append(
            FieldInteractionManifest(
                id: museumAdmissionFieldInteractionID(for: "MUSEUM_1F"),
                kind: .paidAdmission,
                introDialogueID: "museum1_f_scientist1_would_you_like_to_come_in",
                prompt: .init(kind: .yesNo, dialogueID: "museum1_f_scientist1_would_you_like_to_come_in"),
                acceptedDialogueID: "museum1_f_scientist1_thank_you",
                successDialogueID: "museum1_f_scientist1_take_plenty_of_time",
                declinedDialogueID: "museum1_f_scientist1_come_again",
                farewellDialogueID: "museum1_f_scientist1_come_again",
                paidAdmission: .init(
                    price: 50,
                    successFlagID: "EVENT_BOUGHT_MUSEUM_TICKET",
                    insufficientFundsDialogueID: "museum1_f_scientist1_dont_have_enough_money",
                    purchaseSoundEffectID: "SFX_PURCHASE",
                    deniedExitPath: [.down]
                )
            )
        )
    }

    return interactions
}

func buildPlayerStart(repoRoot: URL) throws -> PlayerStartManifest {
    PlayerStartManifest(
        mapID: "REDS_HOUSE_2F",
        position: .init(x: 4, y: 4),
        facing: .down,
        playerName: "RED",
        rivalName: "BLUE",
        initialFlags: [],
        defaultBlackoutCheckpoint: try parseFlyWarpCheckpoint(repoRoot: repoRoot, mapID: "PALLET_TOWN")
    )
}

// MARK: - Relocated helpers (internal for GameplayObjectExtraction, buildMarts, buildScripts)

func martID(for mapID: String) -> String {
    mapID.lowercased()
}

func pokemonCenterFieldInteractionID(for mapID: String) -> String {
    mapID == "VIRIDIAN_POKECENTER" ? "pokemon_center_healing" : "\(mapID.lowercased())_pokemon_center_healing"
}

func museumAdmissionFieldInteractionID(for mapID: String) -> String {
    "\(mapID.lowercased())_admission"
}

// MARK: - Private helpers

private func blackoutCheckpointForPokemonCenter(
    mapID: String,
    maps: [MapManifest],
    repoRoot: URL
) throws -> BlackoutCheckpointManifest? {
    guard let overworldMapID = maps
        .first(where: { $0.id == mapID })?
        .warps
        .first?
        .targetMapID else {
        return nil
    }

    return try parseFlyWarpCheckpoint(repoRoot: repoRoot, mapID: overworldMapID)
}

func parseFlyWarpCheckpoint(repoRoot: URL, mapID: String) throws -> BlackoutCheckpointManifest? {
    let contents = try String(contentsOf: repoRoot.appendingPathComponent("data/maps/special_warps.asm"))
    let labelToken = mapID
        .split(separator: "_")
        .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
        .joined()

    let pattern = #"\.\#(labelToken):\s+fly_warp\s+\#(mapID),\s+(\d+),\s+(\d+)"#
    let regex = try NSRegularExpression(pattern: pattern)
    let nsRange = NSRange(contents.startIndex..<contents.endIndex, in: contents)
    guard let match = regex.firstMatch(in: contents, range: nsRange),
          let xRange = Range(match.range(at: 1), in: contents),
          let yRange = Range(match.range(at: 2), in: contents) else {
        return nil
    }

    return BlackoutCheckpointManifest(
        mapID: mapID,
        position: .init(x: Int(contents[xRange]) ?? 0, y: Int(contents[yRange]) ?? 0),
        facing: .down
    )
}
