import SwiftUI
import PokeRender

private enum InventorySidebarLayout {
    static let columns = Array(
        repeating: GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 6, alignment: .top),
        count: 4
    )
    static let tileMinHeight: CGFloat = 76
    static let iconTileSize: CGFloat = 24
    static let hoverCardIconSize: CGFloat = 62
    static let hoverCardWidth: CGFloat = 248
}

public struct InventorySidebarContent: View {
    let props: InventorySidebarProps
    let onItemSelected: ((String) -> Void)?

    public init(
        props: InventorySidebarProps,
        onItemSelected: ((String) -> Void)? = nil
    ) {
        self.props = props
        self.onItemSelected = onItemSelected
    }

    public var body: some View {
        if itemCount == 0 {
            VStack(alignment: .leading, spacing: 6) {
                GameBoyPixelText(
                    props.emptyStateTitle.uppercased(),
                    scale: 1.5,
                    color: FieldRetroPalette.ink,
                    fallbackFont: .system(size: 18, weight: .bold, design: .monospaced)
                )
                Text(props.emptyStateDetail)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(props.sections) { section in
                        InventorySidebarSection(
                            section: section,
                            onItemSelected: onItemSelected
                        )
                    }
                }
            }
            .frame(maxHeight: GameplayFieldMetrics.inventoryExpandedMaxHeight)
            .scrollIndicators(.hidden)
            .gameplayHoverCardHost()
        }
    }

    private var itemCount: Int {
        props.sections.reduce(0) { $0 + $1.items.count }
    }
}

private struct InventorySidebarSection: View {
    let section: InventorySidebarSectionProps
    let onItemSelected: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                GameBoyPixelText(
                    section.title.uppercased(),
                    scale: 1.0,
                    color: FieldRetroPalette.ink,
                    fallbackFont: .system(size: 10, weight: .bold, design: .monospaced)
                )

                Capsule(style: .continuous)
                    .fill(FieldRetroPalette.ink.opacity(0.16))
                    .frame(height: 1.5)
            }

            LazyVGrid(columns: InventorySidebarLayout.columns, spacing: 6) {
                ForEach(section.items) { item in
                    InventorySidebarTile(
                        item: item,
                        onItemSelected: onItemSelected
                    )
                }
            }
        }
    }
}

private struct InventorySidebarTile: View {
    let item: InventorySidebarItemProps
    let onItemSelected: ((String) -> Void)?

    @State private var isHovered = false

    private var isActiveTile: Bool {
        isHovered || item.isFocused
    }

    var body: some View {
        HoverCardPresenter(
            isPresented: showsHoverCard,
            cardSide: .leading,
            cardWidth: InventorySidebarLayout.hoverCardWidth,
            spacing: GameplayFieldMetrics.hoverCardSpacing
        ) {
            VStack(spacing: 4) {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Text(item.quantityText.uppercased())
                        .font(.system(size: 6, weight: .bold, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.72))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2.5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(FieldRetroPalette.slotFill.opacity(isActiveTile ? 0.94 : 0.78))
                        )
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(
                                    FieldRetroPalette.ink.opacity(isActiveTile ? 0.14 : 0.08),
                                    lineWidth: 0.75
                                )
                        }
                }
                .padding(.top, 1)
                .padding(.trailing, 1)
                .frame(height: 12)

                InventorySidebarIconTile(
                    iconURL: item.iconURL,
                    label: item.name,
                    size: InventorySidebarLayout.iconTileSize,
                    showsBackground: false
                )
                .frame(maxWidth: .infinity)

                Text(item.name.uppercased())
                    .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.55)
                    .frame(maxWidth: .infinity, minHeight: 18, alignment: .top)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, minHeight: InventorySidebarLayout.tileMinHeight, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                FieldRetroPalette.slotFill.opacity(isActiveTile ? 0.92 : 0.78),
                                FieldRetroPalette.cardFill.opacity(isActiveTile ? 0.64 : 0.46),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isActiveTile ? FieldRetroPalette.ink.opacity(0.26) : FieldRetroPalette.outline.opacity(0.12),
                        lineWidth: isActiveTile ? 1.5 : 1
                    )
            }
            .overlay(alignment: .bottom) {
                Capsule(style: .continuous)
                    .fill(FieldRetroPalette.ink.opacity(isActiveTile ? 0.34 : 0))
                    .frame(width: 18, height: 2.5)
                    .padding(.bottom, 4)
            }
            .glassEffect(
                .regular.tint(isActiveTile ? FieldRetroPalette.accentGlassTint : FieldRetroPalette.interactiveGlassTint.opacity(0.5)),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .shadow(
                color: isActiveTile ? FieldRetroPalette.shellBackdropShadow.opacity(0.18) : .clear,
                radius: 6,
                y: 2
            )
            .contentShape(.rect)
            .onTapGesture {
                guard item.isEnabled else { return }
                onItemSelected?(item.id)
            }
            .onHover(perform: updateHoverState)
            .opacity(item.isEnabled ? 1 : 0.58)
        } hoverCard: {
            InventorySidebarHoverCard(item: item)
        }
        .zIndex(showsHoverCard ? 1 : 0)
    }

    private var showsHoverCard: Bool {
        isActiveTile
    }

    private func updateHoverState(_ hovering: Bool) {
        withAnimation(.easeOut(duration: 0.14)) {
            isHovered = hovering
        }
    }
}

private struct InventorySidebarIconTile: View {
    let iconURL: URL?
    let label: String
    let size: CGFloat
    let showsBackground: Bool

    var body: some View {
        Group {
            if showsBackground {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(FieldRetroPalette.portraitFill)

                    iconContent
                        .padding(size * 0.12)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(FieldRetroPalette.outline.opacity(0.1), lineWidth: 1)
                }
                .glassEffect(
                    .regular.tint(FieldRetroPalette.accentGlassTint),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
            } else {
                iconContent
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private var iconContent: some View {
        if let iconURL {
            PixelAssetView(url: iconURL, label: label)
        } else {
            Text(String(label.prefix(2)).uppercased())
                .font(.system(size: size * 0.34, weight: .black, design: .monospaced))
                .foregroundStyle(FieldRetroPalette.ink)
        }
    }
}

private struct InventorySidebarHoverCard: View {
    let item: InventorySidebarItemProps

    private let insetPadding = EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)

    var body: some View {
        GameplayHoverCardSurface(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    InventorySidebarIconTile(
                        iconURL: item.iconURL,
                        label: item.name,
                        size: InventorySidebarLayout.hoverCardIconSize,
                        showsBackground: true
                    )

                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.name.uppercased())
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(FieldRetroPalette.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        PartyPokemonCompactChipSurface(
                            backgroundColor: FieldRetroPalette.slotFill.opacity(0.82),
                            tint: FieldRetroPalette.interactiveGlassTint
                        ) {
                            Text(item.quantityText.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(FieldRetroPalette.ink.opacity(0.82))
                        }
                    }
                }

                GameplaySidebarInsetSurface(
                    padding: insetPadding,
                    tint: FieldRetroPalette.interactiveGlassTint
                ) {
                    Text(item.descriptionText)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let tmhm = item.tmhm {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MOVE")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(FieldRetroPalette.ink.opacity(0.56))

                        GameplaySidebarInsetSurface(
                            padding: insetPadding,
                            tint: FieldRetroPalette.interactiveGlassTint
                        ) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(tmhm.moveName.uppercased())
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(FieldRetroPalette.ink)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)

                                GlassEffectContainer(spacing: 6) {
                                    HStack(spacing: 4) {
                                        InventorySidebarMetadataChip(text: tmhm.typeLabel.uppercased())
                                        InventorySidebarMetadataChip(text: tmhm.maxPPText.uppercased())
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct InventorySidebarMetadataChip: View {
    let text: String

    var body: some View {
        GameplaySidebarChipSurface(
            backgroundColor: FieldRetroPalette.slotFill.opacity(0.86),
            tint: FieldRetroPalette.interactiveGlassTint
        ) {
            Text(text)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(FieldRetroPalette.ink.opacity(0.76))
                .lineLimit(1)
        }
    }
}

struct SaveSidebarContent: View {
    let props: SaveSidebarProps
    let onAction: ((String) -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            ForEach(props.actions) { action in
                SidebarActionRow(props: action, rendersAsButton: true, onAction: onAction)
            }
        }
    }
}

struct OptionsSidebarContent: View {
    let props: OptionsSidebarProps
    @Binding var fieldDisplayStyle: FieldDisplayStyle
    let onAction: ((String) -> Void)?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                FieldDisplayStyleOptionsRow(selectedStyle: $fieldDisplayStyle)
                GameBoyShellOptionsRow(
                    title: props.shellPickerTitle,
                    options: props.shellOptions,
                    onAction: onAction
                )

                ForEach(props.rows) { row in
                    SidebarActionRow(
                        props: row,
                        rendersAsButton: row.isEnabled,
                        onAction: row.isEnabled ? onAction : nil
                    )
                }
            }
        }
        .frame(maxHeight: GameplayFieldMetrics.optionsExpandedMaxHeight)
        .scrollIndicators(.hidden)
    }
}

struct GameBoyShellOptionsRow: View {
    let title: String
    let options: [GameBoyShellStyleOptionProps]
    let onAction: ((String) -> Void)?

    var body: some View {
        GameplaySidebarInsetSurface(
            padding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10),
            tint: FieldRetroPalette.accentGlassTint
        ) {
            VStack(alignment: .leading, spacing: 8) {
                GameBoyPixelText(
                    title.uppercased(),
                    scale: 1.5,
                    color: FieldRetroPalette.ink,
                    fallbackFont: .system(size: 13, weight: .bold, design: .monospaced)
                )

                HStack(alignment: .top, spacing: 6) {
                    ForEach(options) { option in
                        Button {
                            onAction?(option.id)
                        } label: {
                            GameBoyShellSwatchButton(props: option)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct GameBoyShellSwatchButton: View {
    let props: GameBoyShellStyleOptionProps

    var body: some View {
        VStack(spacing: 4) {
            swatch
                .frame(height: 34)

            Text(props.title.uppercased())
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(labelColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 18, alignment: .top)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(FieldRetroPalette.slotFill.opacity(props.isSelected ? 0.34 : 0.16))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    props.isSelected ? FieldRetroPalette.ink.opacity(0.22) : FieldRetroPalette.ink.opacity(0.06),
                    lineWidth: props.isSelected ? 1.5 : 1
                )
        }
    }

    private var swatch: some View {
        ZStack {
            swatchBase

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.34),
                            .white.opacity(0.08),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(props.isSelected ? FieldRetroPalette.ink.opacity(0.85) : .white.opacity(0.4))
                .frame(width: 6, height: 6)
                .padding(5)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white.opacity(0.26), lineWidth: 1)
        }
        .shadow(
            color: swatchShadow,
            radius: props.isSelected ? 7 : 4,
            y: props.isSelected ? 4 : 2
        )
    }

    @ViewBuilder
    private var swatchBase: some View {
        switch props.shellStyle {
        case .classic:
            HStack(spacing: 0) {
                Rectangle()
                    .fill(PokeThemePalette.resolve(for: .light).field.shellBackdrop.color)
                Rectangle()
                    .fill(PokeThemePalette.resolve(for: .retroDark).field.shellBackdrop.color)
            }
        case .kiwi, .dandelion, .teal, .grape:
            let palette = PokeThemePalette.gameBoyShellPalette(
                shellStyle: props.shellStyle,
                appearanceMode: .light,
                colorScheme: .light
            )
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(palette.backdrop.color)
        }
    }

    private var swatchShadow: Color {
        switch props.shellStyle {
        case .classic:
            return Color.black.opacity(props.isSelected ? 0.16 : 0.08)
        case .kiwi, .dandelion, .teal, .grape:
            let palette = PokeThemePalette.gameBoyShellPalette(
                shellStyle: props.shellStyle,
                appearanceMode: .light,
                colorScheme: .light
            )
            return palette.shadow.color.opacity(props.isSelected ? 0.46 : 0.28)
        }
    }

    private var labelColor: Color {
        props.isSelected ? FieldRetroPalette.ink : FieldRetroPalette.ink.opacity(0.72)
    }
}

struct FieldDisplayStyleOptionsRow: View {
    @Binding var selectedStyle: FieldDisplayStyle

    var body: some View {
        GameplaySidebarInsetSurface(
            padding: EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10),
            tint: FieldRetroPalette.accentGlassTint
        ) {
            VStack(alignment: .leading, spacing: 8) {
                GameBoyPixelText(
                    "FIELD FILTER",
                    scale: 1.5,
                    color: FieldRetroPalette.ink,
                    fallbackFont: .system(size: 13, weight: .bold, design: .monospaced)
                )

                GlassEffectContainer(spacing: 6) {
                    HStack(spacing: 5) {
                        styleButton(for: .gbcCompatibility)
                        styleButton(for: .dmgTinted)
                        styleButton(for: .dmgAuthentic)
                        styleButton(for: .rawGrayscale)
                    }
                }
            }
        }
    }

    private func buttonTextColor(for style: FieldDisplayStyle) -> Color {
        selectedStyle == style ? FieldRetroPalette.ink : FieldRetroPalette.ink.opacity(0.72)
    }

    private func styleButton(for style: FieldDisplayStyle) -> some View {
        Button {
            selectedStyle = style
        } label: {
            GameplaySidebarInsetSurface(
                padding: EdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 4),
                tint: selectedStyle == style ? FieldRetroPalette.accentGlassTint : FieldRetroPalette.interactiveGlassTint
            ) {
                GameBoyPixelText(
                    styleTitle(for: style),
                    scale: 0.78,
                    color: buttonTextColor(for: style),
                    fallbackFont: .system(size: 9, weight: .bold, design: .monospaced)
                )
                .frame(maxWidth: .infinity, minHeight: 16)
            }
        }
        .buttonStyle(.plain)
    }

    private func styleTitle(for style: FieldDisplayStyle) -> String {
        switch style {
        case .gbcCompatibility:
            return "GBC"
        case .dmgTinted:
            return "TINTED"
        case .dmgAuthentic:
            return "DMG"
        case .rawGrayscale:
            return "GRAY"
        }
    }
}

struct SidebarActionRow: View {
    let props: SidebarActionRowProps
    let rendersAsButton: Bool
    let onAction: ((String) -> Void)?

    var body: some View {
        Group {
            if rendersAsButton {
                Button {
                    onAction?(props.id)
                } label: {
                    rowBody
                }
                .buttonStyle(.plain)
                .disabled(props.isEnabled == false)
            } else {
                rowBody
            }
        }
        .opacity(props.isEnabled ? 1 : 0.58)
    }

    private var rowBody: some View {
        GameplaySidebarInsetSurface(
            tint: rendersAsButton ? FieldRetroPalette.accentGlassTint : FieldRetroPalette.interactiveGlassTint
        ) {
            HStack(spacing: 12) {
                GameBoyPixelText(
                    props.title.uppercased(),
                    scale: 1.5,
                    color: FieldRetroPalette.ink,
                    fallbackFont: .system(size: 13, weight: .bold, design: .monospaced)
                )
                Spacer(minLength: 8)
                if let detail = props.detail {
                    Text(detail.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.66))
                }
            }
        }
    }
}
