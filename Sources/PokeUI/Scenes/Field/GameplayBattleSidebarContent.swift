import SwiftUI
import PokeDataModel

struct BattleSummaryContent: View {
    let props: BattleSidebarProps

    private var phaseTitle: String {
        switch props.phase {
        case "introText":
            return "Intro"
        case "moveSelection":
            return "Move Select"
        case "resolvingTurn":
            return "Resolving"
        case "turnText":
            return "Turn Text"
        case "battleComplete":
            return "Result"
        default:
            return props.phase.uppercased()
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(props.trainerName.uppercased())
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink)
                    Text(props.kind == .wild ? "WILD ENCOUNTER" : "TRAINER BATTLE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.56))
                }

                Spacer(minLength: 8)

                GameplaySidebarChipSurface(tint: FieldRetroPalette.accentGlassTint) {
                    Text(phaseTitle.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.82))
                }
            }

            BattleCombatantStatusRow(
                title: "FOE",
                pokemon: props.enemyPokemon,
                accentFill: FieldRetroPalette.slotFill.opacity(0.82),
                showsExperience: false
            )

            BattleCombatantStatusRow(
                title: "YOU",
                pokemon: props.playerPokemon,
                accentFill: FieldRetroPalette.leadSlotFill,
                showsExperience: true
            )

            Text(props.promptText.uppercased())
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(FieldRetroPalette.ink.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct BattleActionContent: View {
    let props: BattleSidebarProps

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if props.actionRows.isEmpty {
                Text("NO MOVE CHOICES AVAILABLE IN THIS PHASE.")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(props.actionRows) { action in
                    if action.kind == .run {
                        BattleActionDivider()
                    }

                    BattleActionSidebarRow(
                        title: action.title,
                        detail: action.detail,
                        isSelectable: action.isSelectable,
                        isFocused: action.isFocused
                    )
                }
            }
        }
    }
}

struct BattleCombatantStatusRow: View {
    let title: String
    let pokemon: PartyPokemonTelemetry
    let accentFill: Color
    let showsExperience: Bool

    var body: some View {
        GameplaySidebarInsetSurface(tint: FieldRetroPalette.accentGlassTint) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.54))
                    Text(pokemon.displayName.uppercased())
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink)
                    Spacer(minLength: 8)
                    Text("LV\(pokemon.level)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.68))
                }

                HStack(spacing: 10) {
                    PartyHPBar(currentHP: pokemon.currentHP, maxHP: pokemon.maxHP)
                        .frame(maxWidth: .infinity)
                    Text("\(pokemon.currentHP)/\(pokemon.maxHP)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.72))
                }

                if showsExperience {
                    HStack(spacing: 10) {
                        ExperienceBar(
                            totalExperience: pokemon.experience.total,
                            levelStartExperience: pokemon.experience.levelStart,
                            nextLevelExperience: pokemon.experience.nextLevel
                        )
                        .frame(maxWidth: .infinity)

                        Text(experienceSummary)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(FieldRetroPalette.ink.opacity(0.72))
                    }
                }
            }
        }
        .background(accentFill.opacity(0.2), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var experienceSummary: String {
        let progress = max(0, pokemon.experience.total - pokemon.experience.levelStart)
        let needed = max(1, pokemon.experience.nextLevel - pokemon.experience.levelStart)
        return "EXP \(progress)/\(needed)"
    }
}

struct BattleActionSidebarRow: View {
    let title: String
    let detail: String?
    let isSelectable: Bool
    let isFocused: Bool

    var body: some View {
        GameplaySidebarInsetSurface(
            tint: isFocused ? FieldRetroPalette.accentGlassTint : FieldRetroPalette.interactiveGlassTint
        ) {
            HStack(spacing: 12) {
                Text(titlePrefix + title.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(textColor)

                Spacer(minLength: 8)

                if let detail {
                    Text(detail.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(textColor.opacity(0.86))
                }
            }
        }
        .opacity(isSelectable ? 1 : 0.7)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor, lineWidth: isFocused ? 1.5 : 1)
        }
    }

    private var titlePrefix: String {
        isFocused ? "▶ " : "  "
    }

    private var textColor: Color {
        if isSelectable == false {
            return FieldRetroPalette.ink.opacity(0.36)
        }
        return isFocused ? FieldRetroPalette.ink : FieldRetroPalette.ink.opacity(0.82)
    }

    private var borderColor: Color {
        FieldRetroPalette.outline.opacity(isFocused ? 0.18 : 0.06)
    }
}

struct BattleActionDivider: View {
    var body: some View {
        Rectangle()
            .fill(FieldRetroPalette.outline.opacity(0.12))
            .frame(height: 1)
            .padding(.vertical, 2)
    }
}
