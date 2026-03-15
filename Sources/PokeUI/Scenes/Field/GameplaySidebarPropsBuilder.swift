import Foundation
import PokeDataModel

public enum GameplaySidebarPropsBuilder {
    public static func makeProfile(
        trainerName: String,
        locationName: String,
        scene: RuntimeScene,
        playerPosition: TilePoint?,
        facing: FacingDirection?,
        portrait: TrainerPortraitProps,
        money: Int,
        ownedBadgeIDs: Set<String>
    ) -> TrainerProfileProps {
        var statusItems = [sceneStatusLabel(scene)]
        if let playerPosition {
            statusItems.append("X\(playerPosition.x) Y\(playerPosition.y)")
        }
        if let facing {
            statusItems.append(facing.rawValue.uppercased())
        }

        let badges = makeBadges(ownedBadgeIDs: ownedBadgeIDs)

        return TrainerProfileProps(
            trainerName: trainerName,
            locationName: locationName,
            portrait: portrait,
            badges: badges,
            badgeSummaryText: "\(badges.filter(\.isEarned).count)/\(badges.count)",
            moneyText: formatMoney(money),
            statusItems: statusItems
        )
    }

    public static func makeParty(
        from party: PartyTelemetry?,
        speciesDetailsByID: [String: PartySidebarSpeciesDetails] = [:],
        moveDetailsByID: [String: PartySidebarMoveDetails] = [:],
        mode: PartySidebarInteractionMode = .passive,
        focusedIndex: Int? = nil,
        selectedIndex: Int? = nil,
        selectableIndices: Set<Int> = [],
        annotationByIndex: [Int: String] = [:],
        promptText: String? = nil,
        totalSlots: Int = 6
    ) -> PartySidebarProps {
        let mappedPokemon: [PartySidebarPokemonProps] = party?.pokemon.enumerated().map { index, pokemon in
            let speciesDetails = speciesDetailsByID[pokemon.speciesID]
            let moves = pokemon.moveStates.enumerated().map { moveIndex, move -> PartySidebarMoveProps in
                let moveDetails = moveDetailsByID[move.id]

                return PartySidebarMoveProps(
                    id: "\(pokemon.speciesID)-move-\(moveIndex)-\(move.id)",
                    moveID: move.id,
                    displayName: moveDetails?.displayName ?? move.id,
                    typeLabel: moveDetails?.typeLabel,
                    currentPP: move.currentPP,
                    maxPP: moveDetails?.maxPP,
                    power: moveDetails?.power,
                    accuracy: moveDetails?.accuracy
                )
            }

            return PartySidebarPokemonProps(
                id: "\(pokemon.speciesID)-\(index)",
                speciesID: pokemon.speciesID,
                displayName: pokemon.displayName,
                level: pokemon.level,
                totalExperience: pokemon.experience.total,
                levelStartExperience: pokemon.experience.levelStart,
                nextLevelExperience: pokemon.experience.nextLevel,
                currentHP: pokemon.currentHP,
                maxHP: max(1, pokemon.maxHP),
                statHP: max(1, pokemon.maxHP),
                attack: pokemon.attack,
                defense: pokemon.defense,
                speed: pokemon.speed,
                special: pokemon.special,
                hpGrowthOutlook: pokemon.growthOutlook.hp,
                attackGrowthOutlook: pokemon.growthOutlook.attack,
                defenseGrowthOutlook: pokemon.growthOutlook.defense,
                speedGrowthOutlook: pokemon.growthOutlook.speed,
                specialGrowthOutlook: pokemon.growthOutlook.special,
                isLead: index == 0,
                isSelectable: selectableIndices.contains(index),
                isFocused: focusedIndex == index,
                isSelected: selectedIndex == index,
                selectionAnnotation: annotationByIndex[index],
                spriteURL: speciesDetails?.spriteURL,
                typeLabels: [speciesDetails?.primaryType, speciesDetails?.secondaryType].compactMap { $0 },
                moves: moves
            )
        } ?? []

        return PartySidebarProps(
            pokemon: mappedPokemon,
            totalSlots: totalSlots,
            mode: mode,
            promptText: promptText
        )
    }

    public static func makePokedex(
        allSpecies: [PokedexSpeciesData],
        ownedSpeciesIDs: Set<String>,
        seenSpeciesIDs: Set<String>,
        speciesEncounterCounts: [String: Int] = [:],
        selectedEntryID: String? = nil
    ) -> PokedexSidebarProps {
        var ownedCount = 0
        var seenCount = 0
        let entries = allSpecies.map { species -> PokedexSidebarEntryProps in
            let isOwned = ownedSpeciesIDs.contains(species.id)
            let isSeen = seenSpeciesIDs.contains(species.id)
            if isOwned { ownedCount += 1 }
            if isSeen || isOwned { seenCount += 1 }
            return PokedexSidebarEntryProps(
                id: species.id,
                dexNumber: species.dexNumber,
                displayName: species.displayName,
                isOwned: isOwned,
                isSeen: isSeen,
                spriteURL: (isOwned || isSeen) ? species.spriteURL : nil,
                primaryType: (isOwned || isSeen) ? species.primaryType : nil,
                secondaryType: (isOwned || isSeen) ? species.secondaryType : nil,
                speciesCategory: isOwned ? species.speciesCategory : nil,
                heightText: isOwned ? species.heightText : nil,
                weightText: isOwned ? species.weightText : nil,
                descriptionText: isOwned ? species.descriptionText : nil,
                preEvolution: isOwned ? species.preEvolution : nil,
                evolutions: isOwned ? species.evolutions : [],
                learnedMoves: isOwned ? species.learnedMoves : [],
                detailFields: isOwned
                    ? pokedexDetailFields(
                        heightText: species.heightText,
                        weightText: species.weightText,
                        encounterCount: speciesEncounterCounts[species.id] ?? 0
                    )
                    : [],
                baseHP: isOwned ? species.baseHP : 0,
                baseAttack: isOwned ? species.baseAttack : 0,
                baseDefense: isOwned ? species.baseDefense : 0,
                baseSpeed: isOwned ? species.baseSpeed : 0,
                baseSpecial: isOwned ? species.baseSpecial : 0
            )
        }

        return PokedexSidebarProps(
            entries: entries,
            ownedCount: ownedCount,
            seenCount: seenCount,
            totalCount: entries.count,
            selectedEntryID: selectedEntryID
        )
    }

    public struct PokedexSpeciesData: Sendable {
        public let id: String
        public let dexNumber: Int
        public let displayName: String
        public let primaryType: String
        public let secondaryType: String?
        public let spriteURL: URL?
        public let speciesCategory: String?
        public let heightText: String?
        public let weightText: String?
        public let descriptionText: String?
        public let preEvolution: PokedexSidebarEvolutionProps?
        public let evolutions: [PokedexSidebarEvolutionProps]
        public let learnedMoves: [PokedexSidebarLearnedMoveProps]
        public let baseHP: Int
        public let baseAttack: Int
        public let baseDefense: Int
        public let baseSpeed: Int
        public let baseSpecial: Int

        public init(
            id: String, dexNumber: Int, displayName: String,
            primaryType: String, secondaryType: String?, spriteURL: URL?,
            speciesCategory: String?, heightText: String?, weightText: String?,
            descriptionText: String?,
            preEvolution: PokedexSidebarEvolutionProps? = nil,
            evolutions: [PokedexSidebarEvolutionProps] = [],
            learnedMoves: [PokedexSidebarLearnedMoveProps] = [],
            baseHP: Int, baseAttack: Int, baseDefense: Int, baseSpeed: Int, baseSpecial: Int
        ) {
            self.id = id
            self.dexNumber = dexNumber
            self.displayName = displayName
            self.primaryType = primaryType
            self.secondaryType = secondaryType
            self.spriteURL = spriteURL
            self.speciesCategory = speciesCategory
            self.heightText = heightText
            self.weightText = weightText
            self.descriptionText = descriptionText
            self.preEvolution = preEvolution
            self.evolutions = evolutions
            self.learnedMoves = learnedMoves
            self.baseHP = baseHP
            self.baseAttack = baseAttack
            self.baseDefense = baseDefense
            self.baseSpeed = baseSpeed
            self.baseSpecial = baseSpecial
        }
    }

    public static func makeInventory(items: [InventorySidebarItemProps] = []) -> InventorySidebarProps {
        InventorySidebarProps(
            title: "Bag",
            items: items,
            emptyStateTitle: "No items yet",
            emptyStateDetail: "No items collected in the current save."
        )
    }

    public static func makeSaveSection(summary: String = "Locked", actions: [SidebarActionRowProps]? = nil) -> SaveSidebarProps {
        SaveSidebarProps(
            title: "Save",
            summary: summary,
            actions: actions ?? [
                .init(id: "save", title: "Save Game", detail: "Unavailable", isEnabled: false),
                .init(id: "load", title: "Load Save", detail: "Unavailable", isEnabled: false),
            ]
        )
    }

    public static func makeOptionsSection(
        isMusicEnabled: Bool,
        appearanceMode: AppAppearanceMode,
        gameBoyShellStyle: GameBoyShellStyle,
        gameplayHDREnabled: Bool,
        textSpeed: TextSpeed = .medium,
        battleAnimation: BattleAnimation = .on,
        battleStyle: BattleStyle = .shift
    ) -> OptionsSidebarProps {
        OptionsSidebarProps(
            title: "Options",
            shellPickerTitle: "GB Shell",
            shellOptions: GameBoyShellStyle.allCases.map { shellStyle in
                GameBoyShellStyleOptionProps(
                    id: shellStyle.actionID,
                    shellStyle: shellStyle,
                    title: shellStyle.optionsLabel,
                    isSelected: shellStyle == gameBoyShellStyle
                )
            },
            rows: [
                .init(id: "appearanceMode", title: "Appearance", detail: appearanceMode.optionsLabel, isEnabled: true),
                .init(id: "gameplayHDR", title: "HDR Effects", detail: gameplayHDREnabled ? "On" : "Off", isEnabled: true),
                .init(id: "textSpeed", title: "Text Speed", detail: textSpeed.label, isEnabled: true),
                .init(id: "battleScene", title: "Battle Scene", detail: battleAnimation.label, isEnabled: true),
                .init(id: "battleStyle", title: "Battle Style", detail: battleStyle.label, isEnabled: true),
                .init(id: "music", title: "Music", detail: isMusicEnabled ? "On" : "Off", isEnabled: true),
            ]
        )
    }
}

// MARK: - Private Helpers

extension GameplaySidebarPropsBuilder {
    private static func pokedexDetailFields(
        heightText: String?,
        weightText: String?,
        encounterCount: Int
    ) -> [PokedexSidebarDetailFieldProps] {
        var fields: [PokedexSidebarDetailFieldProps] = []
        if let heightText {
            fields.append(.init(id: "height", label: "HT", value: heightText))
        }
        if let weightText {
            fields.append(.init(id: "weight", label: "WT", value: weightText))
        }
        fields.append(.init(id: "encounters", label: "ENCOUNTERS", value: "\(max(0, encounterCount))"))
        return fields
    }

    private static func sceneStatusLabel(_ scene: RuntimeScene) -> String {
        switch scene {
        case .field:
            "FIELD"
        case .dialogue:
            "DIALOGUE"
        case .scriptedSequence:
            "SCRIPT"
        case .starterChoice:
            "STARTER"
        case .battle:
            "BATTLE"
        case .evolution:
            "EVOLVE"
        case .titleMenu:
            "MENU"
        case .titleAttract:
            "ATTRACT"
        case .launch:
            "LAUNCH"
        case .splash:
            "SPLASH"
        case .naming:
            "NAMING"
        case .oakIntro:
            "INTRO"
        case .titleOptions:
            "OPTIONS"
        case .placeholder:
            "PLACEHOLDER"
        }
    }

    private static func makeBadges(ownedBadgeIDs: Set<String>) -> [TrainerBadgeProps] {
        let normalizedBadgeIDs = Set(ownedBadgeIDs.map(normalizedBadgeID))
        return badgeDefinitions.map { definition in
            TrainerBadgeProps(
                id: definition.id,
                shortLabel: definition.shortLabel,
                isEarned: normalizedBadgeIDs.contains(definition.id)
            )
        }
    }

    private static func normalizedBadgeID(_ badgeID: String) -> String {
        badgeID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_badge", with: "")
            .replacingOccurrences(of: "badge", with: "")
    }

    private static func formatMoney(_ amount: Int) -> String {
        "¥\(moneyFormatter.string(from: NSNumber(value: amount)) ?? "\(amount)")"
    }

    private static let moneyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    private static let badgeDefinitions: [(id: String, shortLabel: String)] = [
        ("boulder", "B"),
        ("cascade", "C"),
        ("thunder", "T"),
        ("rainbow", "R"),
        ("soul", "S"),
        ("marsh", "M"),
        ("volcano", "V"),
        ("earth", "E"),
    ]
}
