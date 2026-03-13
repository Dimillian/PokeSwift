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
        VStack(spacing: 8) {
            FieldDisplayStyleOptionsRow(selectedStyle: $fieldDisplayStyle)

            ForEach(props.rows) { row in
                SidebarActionRow(
                    props: row,
                    rendersAsButton: row.isEnabled,
                    onAction: row.isEnabled ? onAction : nil
                )
            }
        }
    }
}

struct FieldDisplayStyleOptionsRow: View {
    @Binding var selectedStyle: FieldDisplayStyle

    private let styles: [FieldDisplayStyle] = [.dmgTinted, .dmgAuthentic, .rawGrayscale]

    var body: some View {
        GameplaySidebarInsetSurface(
            padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12),
            tint: FieldRetroPalette.accentGlassTint
        ) {
            VStack(alignment: .leading, spacing: 10) {
                GameBoyPixelText(
                    "FIELD FILTER",
                    scale: 1.5,
                    color: FieldRetroPalette.ink,
                    fallbackFont: .system(size: 13, weight: .bold, design: .monospaced)
                )

                GlassEffectContainer(spacing: 10) {
                    HStack(spacing: 8) {
                        ForEach(styles, id: \.self) { style in
                            Button {
                                selectedStyle = style
                            } label: {
                                GameplaySidebarInsetSurface(
                                    padding: EdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 8),
                                    tint: selectedStyle == style ? FieldRetroPalette.accentGlassTint : FieldRetroPalette.interactiveGlassTint
                                ) {
                                    GameBoyPixelText(
                                        style.sidebarOptionTitle.uppercased(),
                                        scale: 1,
                                        color: buttonTextColor(for: style),
                                        fallbackFont: .system(size: 11, weight: .bold, design: .monospaced)
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(buttonStroke(for: style), lineWidth: selectedStyle == style ? 1.5 : 1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
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
