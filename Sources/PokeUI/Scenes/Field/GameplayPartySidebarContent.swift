import SwiftUI
import PokeDataModel

struct PartySidebarContent: View {
    let props: PartySidebarProps

    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<props.totalSlots, id: \.self) { index in
                if props.pokemon.indices.contains(index) {
                    PartySidebarRow(
                        props: props.pokemon[index],
                        slotNumber: index + 1
                    )
                } else {
                    EmptyPartySidebarRow(slotNumber: index + 1)
                }
            }
        }
    }
}

struct PartySidebarRow: View {
    let props: PartySidebarPokemonProps
    let slotNumber: Int

    @State private var isHovered = false

    var body: some View {
        HoverCardPresenter(
            isPresented: isHovered,
            cardSide: .leading,
            cardWidth: PartyPokemonHoverCard.layoutWidth,
            spacing: GameplayFieldMetrics.hoverCardSpacing
        ) {
            GameplaySidebarInsetSurface(
                tint: props.isLead ? FieldRetroPalette.accentGlassTint : FieldRetroPalette.interactiveGlassTint
            ) {
                HStack(alignment: .top, spacing: 12) {
                    PartyPokemonSpriteTile(props: props)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(slotNumber)")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(FieldRetroPalette.ink.opacity(0.58))
                                .frame(width: 16, alignment: .leading)

                            Text(props.displayName.uppercased())
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundStyle(FieldRetroPalette.ink)

                            Spacer(minLength: 8)

                            Text("Lv\(props.level)")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(FieldRetroPalette.ink.opacity(0.7))
                        }

                        HStack(spacing: 10) {
                            PartyHPBar(currentHP: props.currentHP, maxHP: props.maxHP)
                                .frame(maxWidth: .infinity)

                            Text("HP \(props.currentHP)/\(props.maxHP)")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(FieldRetroPalette.ink.opacity(0.72))
                        }

                        HStack(spacing: 10) {
                            ExperienceBar(
                                totalExperience: props.totalExperience,
                                levelStartExperience: props.levelStartExperience,
                                nextLevelExperience: props.nextLevelExperience
                            )
                            .frame(maxWidth: .infinity)

                            Text(experienceSummary)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(FieldRetroPalette.ink.opacity(0.72))
                        }
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(props.isLead ? FieldRetroPalette.outline.opacity(0.16) : FieldRetroPalette.outline.opacity(0.08), lineWidth: 1)
            }
            .contentShape(.rect(cornerRadius: 16))
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.14)) {
                    isHovered = hovering
                }
            }
        } hoverCard: {
            PartyPokemonHoverCard(props: props)
        }
        .zIndex(isHovered ? 1 : 0)
    }

    private var experienceSummary: String {
        let progress = max(0, props.totalExperience - props.levelStartExperience)
        let needed = max(1, props.nextLevelExperience - props.levelStartExperience)
        return "EXP \(progress)/\(needed)"
    }
}

struct EmptyPartySidebarRow: View {
    let slotNumber: Int

    var body: some View {
        GameplaySidebarInsetSurface {
            HStack(spacing: 10) {
                Text("\(slotNumber)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink.opacity(0.42))
                    .frame(width: 16, alignment: .leading)

                Text("---")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink.opacity(0.36))

                Spacer()
            }
        }
    }
}

struct PartyPokemonSpriteTile: View {
    let props: PartySidebarPokemonProps

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(FieldRetroPalette.portraitFill.opacity(0.9))

            if let spriteURL = props.spriteURL {
                PixelAssetView(url: spriteURL, label: props.displayName, whiteIsTransparent: true)
                    .padding(4)
            } else {
                Text(String(props.displayName.prefix(2)).uppercased())
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(FieldRetroPalette.outline.opacity(0.12), lineWidth: 1)
        }
        .frame(width: 46, height: 46)
        .glassEffect(
            .regular.tint(FieldRetroPalette.interactiveGlassTint),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }
}

struct PartyPokemonHoverCard: View {
    static let layoutWidth: CGFloat = 248

    let props: PartySidebarPokemonProps

    var body: some View {
        GameplaySidebarCardSurface(
            tint: FieldRetroPalette.hoverCardGlassTint,
            backgroundColor: FieldRetroPalette.hoverCardBackgroundTint,
            showsOutline: false
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    PartyPokemonLargeSpriteTile(props: props)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(props.displayName.uppercased())
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(FieldRetroPalette.ink)

                        GlassEffectContainer(spacing: 8) {
                            HStack(spacing: 6) {
                                ForEach(props.typeLabels, id: \.self) { typeLabel in
                                    GameplaySidebarChipSurface(
                                        backgroundColor: FieldRetroPalette.pokemonTypeBadgeBackground(for: typeLabel),
                                        tint: FieldRetroPalette.pokemonTypeGlassTint(for: typeLabel)
                                    ) {
                                        Text(typeLabel)
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundStyle(FieldRetroPalette.ink.opacity(0.82))
                                    }
                                }
                            }
                        }

                        Text("Lv\(props.level)  HP \(props.currentHP)/\(props.maxHP)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(FieldRetroPalette.ink.opacity(0.72))

                        Text(experienceSummary)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(FieldRetroPalette.ink.opacity(0.72))
                    }
                }

                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 8) {
                    PartyPokemonStatPill(label: "HP", value: props.statHP, growthOutlook: props.hpGrowthOutlook)
                    PartyPokemonStatPill(label: "ATK", value: props.attack, growthOutlook: props.attackGrowthOutlook)
                    PartyPokemonStatPill(label: "DEF", value: props.defense, growthOutlook: props.defenseGrowthOutlook)
                    PartyPokemonStatPill(label: "SPD", value: props.speed, growthOutlook: props.speedGrowthOutlook)
                    PartyPokemonStatPill(label: "SPC", value: props.special, growthOutlook: props.specialGrowthOutlook)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("MOVES")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.56))

                    if props.moveNames.isEmpty {
                        Text("No moves known")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(FieldRetroPalette.ink.opacity(0.62))
                    } else {
                        ForEach(Array(props.moveNames.enumerated()), id: \.offset) { _, moveName in
                            Text(moveName.uppercased())
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(FieldRetroPalette.ink)
                        }
                    }
                }
            }
        }
        .frame(width: Self.layoutWidth, alignment: .leading)
    }

    private var experienceSummary: String {
        let progress = max(0, props.totalExperience - props.levelStartExperience)
        let needed = max(1, props.nextLevelExperience - props.levelStartExperience)
        return "EXP \(progress)/\(needed)"
    }
}

struct PartyPokemonLargeSpriteTile: View {
    let props: PartySidebarPokemonProps

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(FieldRetroPalette.portraitFill)

            if let spriteURL = props.spriteURL {
                PixelAssetView(url: spriteURL, label: props.displayName, whiteIsTransparent: true)
                    .padding(6)
            } else {
                Text(String(props.displayName.prefix(2)).uppercased())
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(FieldRetroPalette.outline.opacity(0.12), lineWidth: 1)
        }
        .frame(width: 76, height: 76)
        .glassEffect(
            .regular.tint(FieldRetroPalette.accentGlassTint),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }
}

struct PartyPokemonStatPill: View {
    let label: String
    let value: Int
    let growthOutlook: PokemonStatGrowthTelemetry

    private var fillColor: Color {
        switch growthOutlook {
        case .favored:
            return Color(red: 0.69, green: 0.82, blue: 0.59)
        case .lagging:
            return Color(red: 0.86, green: 0.69, blue: 0.64)
        case .neutral:
            return FieldRetroPalette.slotFill
        }
    }

    private var textColor: Color {
        switch growthOutlook {
        case .favored:
            return Color(red: 0.18, green: 0.34, blue: 0.12)
        case .lagging:
            return Color(red: 0.46, green: 0.18, blue: 0.16)
        case .neutral:
            return FieldRetroPalette.ink.opacity(0.82)
        }
    }

    var body: some View {
        HStack {
            Text(label)
            Spacer(minLength: 8)
            Text("\(value)")
        }
        .font(.system(size: 11, weight: .bold, design: .monospaced))
        .foregroundStyle(textColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(fillColor.opacity(0.86), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .glassEffect(
            .regular.tint(fillColor.opacity(0.32)),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }
}

struct HoverCardPresenter<Content: View, HoverCard: View>: View {
    enum CardSide {
        case leading
        case trailing
    }

    let isPresented: Bool
    let cardSide: CardSide
    let cardWidth: CGFloat
    let spacing: CGFloat
    let content: Content
    let hoverCard: HoverCard

    init(
        isPresented: Bool,
        cardSide: CardSide,
        cardWidth: CGFloat,
        spacing: CGFloat,
        @ViewBuilder content: () -> Content,
        @ViewBuilder hoverCard: () -> HoverCard
    ) {
        self.isPresented = isPresented
        self.cardSide = cardSide
        self.cardWidth = cardWidth
        self.spacing = spacing
        self.content = content()
        self.hoverCard = hoverCard()
    }

    var body: some View {
        content
            .overlay(alignment: overlayAlignment) {
                if isPresented {
                    hoverCard
                        .frame(width: cardWidth, alignment: .leading)
                        .offset(x: horizontalOffset)
                        .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
                        .allowsHitTesting(false)
                }
            }
            .animation(.easeOut(duration: 0.14), value: isPresented)
    }

    private var overlayAlignment: Alignment {
        switch cardSide {
        case .leading:
            return .topLeading
        case .trailing:
            return .topTrailing
        }
    }

    private var horizontalOffset: CGFloat {
        switch cardSide {
        case .leading:
            return -(cardWidth + spacing)
        case .trailing:
            return spacing
        }
    }
}
