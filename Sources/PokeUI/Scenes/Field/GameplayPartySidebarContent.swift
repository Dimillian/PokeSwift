import SwiftUI
import PokeDataModel
import PokeRender

struct PartySidebarContent: View {
    let props: PartySidebarProps
    let onRowSelected: ((Int) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PartySidebarPrompt(promptText: props.promptText)
            PartySidebarRowsContent(props: props, onRowSelected: onRowSelected)
        }
    }
}

struct PartySidebarPrompt: View {
    let promptText: String?

    var body: some View {
        if let promptText {
            Text(promptText.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(FieldRetroPalette.ink.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct PartySidebarRowsContent: View {
    let props: PartySidebarProps
    let onRowSelected: ((Int) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: rowSpacing) {
            ForEach(0..<props.totalSlots, id: \.self) { index in
                if props.pokemon.indices.contains(index) {
                    PartySidebarRow(
                        props: props.pokemon[index],
                        slotNumber: index + 1,
                        rowIndex: index,
                        density: props.rowDensity,
                        onSelect: onRowSelected
                    )
                } else {
                    EmptyPartySidebarRow(slotNumber: index + 1)
                }
            }
        }
    }

    private var rowSpacing: CGFloat {
        props.rowDensity == .compact ? 8 : 10
    }
}

struct PartySidebarRow: View {
    let props: PartySidebarPokemonProps
    let slotNumber: Int
    let rowIndex: Int
    let density: PartySidebarRowDensity
    let onSelect: ((Int) -> Void)?

    @State private var isHovered = false

    var body: some View {
        HoverCardPresenter(
            isPresented: isHovered,
            cardSide: .leading,
            cardWidth: PartyPokemonHoverCard.layoutWidth,
            spacing: GameplayFieldMetrics.hoverCardSpacing
        ) {
            GameplaySidebarInsetSurface(
                padding: rowPadding,
                tint: surfaceTint
            ) {
                rowContent
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(borderColor, lineWidth: props.isFocused || props.isSelected ? 1.5 : 1)
            }
            .contentShape(.rect(cornerRadius: 16))
            .onTapGesture {
                guard props.isSelectable else { return }
                onSelect?(rowIndex)
            }
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.14)) {
                    isHovered = hovering
                }
            }
        } hoverCard: {
            PartyPokemonHoverCard(props: props)
        }
        .opacity(props.isSelectable || props.selectionAnnotation != nil || props.isLead ? 1 : 0.92)
        .zIndex(isHovered ? 1 : 0)
    }

    @ViewBuilder
    private var rowContent: some View {
        switch density {
        case .standard:
            HStack(alignment: .top, spacing: 12) {
                PartyPokemonSpriteTile(props: props, density: density)

                VStack(alignment: .leading, spacing: 8) {
                    headerRow
                    standardMetricRow(summary: "HP \(props.currentHP)/\(props.maxHP)") {
                        PartyHPBar(currentHP: props.currentHP, maxHP: props.maxHP)
                            .frame(maxWidth: .infinity)
                    }
                    standardMetricRow(summary: experienceSummary) {
                        ExperienceBar(
                            totalExperience: props.totalExperience,
                            levelStartExperience: props.levelStartExperience,
                            nextLevelExperience: props.nextLevelExperience
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        case .compact:
            HStack(alignment: .top, spacing: 10) {
                PartyPokemonSpriteTile(props: props, density: density)

                VStack(alignment: .leading, spacing: 6) {
                    headerRow
                    HStack(alignment: .top, spacing: 8) {
                        compactMetricColumn(title: "HP", summary: "\(props.currentHP)/\(props.maxHP)") {
                            PartyHPBar(
                                currentHP: props.currentHP,
                                maxHP: props.maxHP,
                                height: GameplayFieldMetrics.partyCompactMetricBarHeight
                            )
                        }
                        compactMetricColumn(title: "EXP", summary: compactExperienceSummary) {
                            ExperienceBar(
                                totalExperience: props.totalExperience,
                                levelStartExperience: props.levelStartExperience,
                                nextLevelExperience: props.nextLevelExperience,
                                height: GameplayFieldMetrics.partyCompactMetricBarHeight
                            )
                        }
                    }
                }
            }
        }
    }

    private var experienceSummary: String {
        let progress = max(0, props.totalExperience - props.levelStartExperience)
        let needed = max(1, props.nextLevelExperience - props.levelStartExperience)
        return "EXP \(progress)/\(needed)"
    }

    private var compactExperienceSummary: String {
        let progress = max(0, props.totalExperience - props.levelStartExperience)
        let needed = max(1, props.nextLevelExperience - props.levelStartExperience)
        return "\(progress)/\(needed)"
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(slotNumber)")
                .font(.system(size: density == .compact ? 12 : 13, weight: .bold, design: .monospaced))
                .foregroundStyle(FieldRetroPalette.ink.opacity(0.58))
                .frame(width: density == .compact ? 14 : 16, alignment: .leading)

            Text(props.displayName.uppercased())
                .font(.system(size: density == .compact ? 13 : 15, weight: .bold, design: .monospaced))
                .foregroundStyle(FieldRetroPalette.ink)
                .lineLimit(1)

            if let selectionAnnotation = props.selectionAnnotation {
                Text(selectionAnnotation.uppercased())
                    .font(.system(size: density == .compact ? 9 : 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(annotationColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Text("Lv\(props.level)")
                .font(.system(size: density == .compact ? 11 : 12, weight: .medium, design: .monospaced))
                .foregroundStyle(FieldRetroPalette.ink.opacity(0.7))
                .lineLimit(1)
        }
    }

    private func standardMetricRow<Content: View>(
        summary: String,
        @ViewBuilder bar: () -> Content
    ) -> some View {
        HStack(spacing: 10) {
            bar()
            Text(summary)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(FieldRetroPalette.ink.opacity(0.72))
        }
    }

    private func compactMetricColumn<Content: View>(
        title: String,
        summary: String,
        @ViewBuilder bar: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink.opacity(0.5))
                    .frame(
                        width: GameplayFieldMetrics.partyCompactMetricLabelWidth,
                        alignment: .leading
                    )

                Text(summary)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            bar()
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rowPadding: EdgeInsets {
        density == .compact
            ? GameplayFieldMetrics.partyCompactRowPadding
            : EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
    }

    private var surfaceTint: Color {
        if props.isFocused || props.isSelected {
            return FieldRetroPalette.accentGlassTint
        }
        return props.isLead ? FieldRetroPalette.accentGlassTint : FieldRetroPalette.interactiveGlassTint
    }

    private var annotationColor: Color {
        if props.isSelectable {
            return FieldRetroPalette.ink.opacity(0.56)
        }
        return Color(red: 0.53, green: 0.24, blue: 0.19)
    }

    private var borderColor: Color {
        if props.isFocused || props.isSelected {
            return FieldRetroPalette.outline.opacity(0.2)
        }
        return props.isLead ? FieldRetroPalette.outline.opacity(0.16) : FieldRetroPalette.outline.opacity(0.08)
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
    let density: PartySidebarRowDensity

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(FieldRetroPalette.portraitFill.opacity(0.9))

            if let spriteURL = props.spriteURL {
                PixelAssetView(url: spriteURL, label: props.displayName, whiteIsTransparent: true)
                    .padding(innerPadding)
            } else {
                Text(String(props.displayName.prefix(2)).uppercased())
                    .font(.system(size: fallbackFontSize, weight: .black, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(FieldRetroPalette.outline.opacity(0.12), lineWidth: 1)
        }
        .frame(width: tileSize, height: tileSize)
        .glassEffect(
            .regular.tint(FieldRetroPalette.interactiveGlassTint),
            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
    }

    private var tileSize: CGFloat {
        density == .compact ? GameplayFieldMetrics.partyCompactSpriteSize : 46
    }

    private var cornerRadius: CGFloat {
        density == .compact ? 10 : 12
    }

    private var innerPadding: CGFloat {
        density == .compact ? 3 : 4
    }

    private var fallbackFontSize: CGFloat {
        density == .compact ? 11 : 14
    }
}

struct PartyPokemonHoverCard: View {
    static let layoutWidth: CGFloat = 248

    let props: PartySidebarPokemonProps

    var body: some View {
        GameplayHoverCardSurface {
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
