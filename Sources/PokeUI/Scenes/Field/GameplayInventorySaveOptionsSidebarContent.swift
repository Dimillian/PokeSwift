import SwiftUI
import PokeRender

struct InventorySidebarContent: View {
    let props: InventorySidebarProps

    var body: some View {
        if props.items.isEmpty {
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
                LazyVStack(spacing: 8) {
                    ForEach(props.items) { item in
                        GameplaySidebarInsetSurface {
                            HStack(spacing: 12) {
                                Text(item.name.uppercased())
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundStyle(FieldRetroPalette.ink)
                                Spacer(minLength: 8)
                                Text(item.quantityText)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(FieldRetroPalette.ink.opacity(0.7))
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: GameplayFieldMetrics.inventoryExpandedMaxHeight)
            .scrollIndicators(.hidden)
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
                .padding(1.5)
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
                        styleButton(for: .dmgTinted)
                        styleButton(for: .dmgAuthentic)
                        styleButton(for: .rawGrayscale)
                    }
                }
            }
        }
    }

    private func buttonStroke(for style: FieldDisplayStyle) -> Color {
        selectedStyle == style ? FieldRetroPalette.ink.opacity(0.18) : FieldRetroPalette.ink.opacity(0.06)
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
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(buttonStroke(for: style), lineWidth: selectedStyle == style ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func styleTitle(for style: FieldDisplayStyle) -> String {
        switch style {
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
