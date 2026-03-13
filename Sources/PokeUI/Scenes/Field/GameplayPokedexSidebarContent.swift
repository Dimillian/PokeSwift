import AppKit
import SwiftUI
import PokeRender

private enum PokedexSortMode: String, CaseIterable {
    case dexNumber = "DEX #"
    case name = "NAME"
    case type = "TYPE"
}

struct PokedexSidebarContent: View {
    let props: PokedexSidebarProps
    @State private var selectedEntryID: String?
    @State private var searchText = ""
    @State private var isSearchFocused = false
    @State private var sortMode: PokedexSortMode = .dexNumber
    @State private var sortAscending = true
    @State private var displayMode: PokedexDisplayMode = .list

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            pokedexHeader

            if props.entries.isEmpty {
                emptyState
            } else if let selectedEntryID, let entry = props.entries.first(where: { $0.id == selectedEntryID }), entry.isOwned {
                PokedexDetailView(entry: entry) {
                    withAnimation(.snappy(duration: 0.2)) {
                        self.selectedEntryID = nil
                    }
                }
            } else {
                controlsSection

                if filteredEntries.isEmpty {
                    emptySearchState
                } else {
                    entriesContent
                }
            }
        }
    }

    private var pokedexHeader: some View {
        HStack(spacing: 8) {
            if selectedEntryID != nil {
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        selectedEntryID = nil
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .bold))
                        Text("LIST")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(FieldRetroPalette.ink.opacity(0.62))
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 10) {
                    pokedexHeaderStat(
                        iconName: "checkmark.circle.fill",
                        label: "OWNED",
                        value: props.ownedCount,
                        tint: FieldRetroPalette.ink.opacity(0.74),
                        labelOpacity: 0.58
                    )

                    Capsule(style: .continuous)
                        .fill(FieldRetroPalette.outline.opacity(0.14))
                        .frame(width: 3, height: 18)

                    pokedexHeaderStat(
                        iconName: "eye.fill",
                        label: "SEEN",
                        value: props.seenCount,
                        tint: FieldRetroPalette.ink.opacity(0.6),
                        labelOpacity: 0.44
                    )
                }
            }
            Spacer(minLength: 4)
        }
    }

    private func pokedexHeaderStat(
        iconName: String,
        label: String,
        value: Int,
        tint: Color,
        labelOpacity: Double
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(tint)

            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(FieldRetroPalette.ink.opacity(labelOpacity))

            Text("\(value)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(tint)
        }
    }

    private var controlsSection: some View {
        VStack(spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                searchField
                compactDisplayModePicker
            }

            sortControls
        }
    }

    private var sortControls: some View {
        HStack(spacing: 4) {
            ForEach(PokedexSortMode.allCases, id: \.rawValue) { mode in
                Button {
                    withAnimation(.snappy(duration: 0.15)) {
                        if sortMode == mode {
                            sortAscending.toggle()
                        } else {
                            sortMode = mode
                            sortAscending = true
                        }
                    }
                } label: {
                    HStack(spacing: 2) {
                        Text(mode.rawValue)
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))

                        if sortMode == mode {
                            Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                                .font(.system(size: 7, weight: .bold))
                        }
                    }
                    .foregroundStyle(
                        FieldRetroPalette.ink.opacity(sortMode == mode ? 0.82 : 0.42)
                    )
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        sortMode == mode
                            ? FieldRetroPalette.accentGlassTint.opacity(0.38)
                            : Color.clear,
                        in: Capsule(style: .continuous)
                    )
                    .overlay {
                        if sortMode == mode {
                            Capsule(style: .continuous)
                                .stroke(FieldRetroPalette.outline.opacity(0.08), lineWidth: 1)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            Spacer()

            HStack(spacing: 4) {
                if !searchText.isEmpty {
                    Text("\(filteredEntries.count) found")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.42))
                }
            }
        }
    }

    private var searchField: some View {
        GameplaySidebarInsetSurface(
            padding: EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10),
            tint: FieldRetroPalette.accentGlassTint
        ) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(FieldRetroPalette.ink.opacity(0.46))

                PokedexSearchField(
                    text: $searchText,
                    isFocused: $isSearchFocused
                ) {
                    dismissSearchField()
                }
                .frame(maxWidth: .infinity)

                Button(action: clearAndDismissSearchField) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(isSearchFocused ? 0.42 : 0.22))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss search")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var compactDisplayModePicker: some View {
        HStack(spacing: 8) {
            ForEach(PokedexDisplayMode.allCases) { mode in
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        displayMode = mode
                    }
                } label: {
                    ZStack {
                        Capsule(style: .continuous)
                            .fill(displayMode == mode ? FieldRetroPalette.slotFill.opacity(0.92) : .clear)

                        Image(systemName: mode.iconName)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(FieldRetroPalette.ink.opacity(displayMode == mode ? 0.88 : 0.58))
                    .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule(style: .continuous)
                .fill(FieldRetroPalette.slotFill.opacity(0.38))
        )
        .overlay {
            Capsule(style: .continuous)
                .stroke(FieldRetroPalette.outline.opacity(0.08), lineWidth: 1)
        }
        .glassEffect(
            .regular.tint(FieldRetroPalette.interactiveGlassTint),
            in: Capsule(style: .continuous)
        )
        .fixedSize()
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            GameBoyPixelText(
                "NO DATA",
                scale: 1.5,
                color: FieldRetroPalette.ink,
                fallbackFont: .system(size: 18, weight: .bold, design: .monospaced)
            )
            Text("No Pokémon data recorded yet.")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(FieldRetroPalette.ink.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }

    private var filteredEntries: [PokedexSidebarEntryProps] {
        props.entries
            .filter(matchesSearch)
            .sorted(by: isOrderedBefore)
    }

    private var emptySearchState: some View {
        VStack(alignment: .leading, spacing: 6) {
            GameBoyPixelText(
                "NO MATCH",
                scale: 1.5,
                color: FieldRetroPalette.ink,
                fallbackFont: .system(size: 18, weight: .bold, design: .monospaced)
            )
            Text("No Pok\u{00E9}mon match \"\(searchText)\".")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(FieldRetroPalette.ink.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }

    private var pokedexList: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(filteredEntries) { entry in
                    PokedexEntryRow(entry: entry) {
                        select(entry)
                    }
                }
            }
        }
        .frame(maxHeight: 380)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    @ViewBuilder
    private var entriesContent: some View {
        switch displayMode {
        case .list:
            pokedexList
        case .grid:
            pokedexGrid
        }
    }

    private var pokedexGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(filteredEntries) { entry in
                    PokedexGridEntryCell(entry: entry) {
                        select(entry)
                    }
                }
            }
        }
        .frame(maxHeight: 380)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
    }

    private func select(_ entry: PokedexSidebarEntryProps) {
        guard entry.isOwned else { return }
        withAnimation(.snappy(duration: 0.2)) {
            selectedEntryID = entry.id
        }
    }

    private var searchQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func dismissSearchField() {
        isSearchFocused = false
    }

    private func clearAndDismissSearchField() {
        searchText = ""
        dismissSearchField()
    }

    private func matchesSearch(_ entry: PokedexSidebarEntryProps) -> Bool {
        guard searchQuery.isEmpty == false else { return true }

        if "\(entry.dexNumber)".localizedStandardContains(searchQuery) {
            return true
        }

        if entry.isSeen, entry.displayName.localizedStandardContains(searchQuery) {
            return true
        }

        if entry.isSeen,
           let primaryType = entry.primaryType,
           primaryType.localizedStandardContains(searchQuery) {
            return true
        }

        if entry.isSeen,
           let secondaryType = entry.secondaryType,
           secondaryType.localizedStandardContains(searchQuery) {
            return true
        }

        return false
    }

    private func isOrderedBefore(_ lhs: PokedexSidebarEntryProps, _ rhs: PokedexSidebarEntryProps) -> Bool {
        let result: Bool
        switch sortMode {
        case .dexNumber:
            result = lhs.dexNumber < rhs.dexNumber
        case .name:
            result = lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        case .type:
            let lhsType = lhs.primaryType ?? ""
            let rhsType = rhs.primaryType ?? ""
            if lhsType == rhsType {
                result = lhs.dexNumber < rhs.dexNumber
            } else {
                result = lhsType.localizedCaseInsensitiveCompare(rhsType) == .orderedAscending
            }
        }

        return sortAscending ? result : !result
    }
}

private struct PokedexSearchField: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let onEmptyDelete: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.placeholderString = "Search Pok\u{00E9}mon"
        textField.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        textField.textColor = .labelColor
        textField.lineBreakMode = .byTruncatingTail
        return textField
    }

    func updateNSView(_ textField: NSTextField, context: Context) {
        context.coordinator.parent = self

        if textField.stringValue != text {
            textField.stringValue = text
        }

        guard let window = textField.window else { return }
        let firstResponder = window.firstResponder
        let isFirstResponder = firstResponder === textField || firstResponder === window.fieldEditor(false, for: textField)

        if isFocused, isFirstResponder == false {
            window.makeFirstResponder(textField)
        } else if isFocused == false, isFirstResponder {
            window.makeFirstResponder(nil)
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: PokedexSearchField

        init(parent: PokedexSearchField) {
            self.parent = parent
        }

        func controlTextDidBeginEditing(_ notification: Notification) {
            guard parent.isFocused == false else { return }
            DispatchQueue.main.async {
                self.parent.isFocused = true
            }
        }

        func controlTextDidEndEditing(_ notification: Notification) {
            guard parent.isFocused else { return }
            DispatchQueue.main.async {
                self.parent.isFocused = false
            }
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else { return }
            let updatedText = textField.stringValue
            guard parent.text != updatedText else { return }
            DispatchQueue.main.async {
                self.parent.text = updatedText
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard commandSelector == #selector(NSResponder.deleteBackward(_:)),
                  parent.text.isEmpty else {
                return false
            }

            parent.onEmptyDelete()
            return true
        }
    }
}

// MARK: - Detail View

private struct PokedexDetailView: View {
    let entry: PokedexSidebarEntryProps
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            PokedexDetailContent(entry: entry)
        }
        .frame(maxHeight: 420)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity
        ))
    }
}

private struct PokedexDetailContent: View {
    let entry: PokedexSidebarEntryProps

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            spriteAndIdentity
            typeBadgesRow
            if entry.detailFields.isEmpty == false {
                detailFieldsSection
            }
            baseStatsSection
            if let description = entry.descriptionText {
                descriptionSection(description)
            }
        }
    }

    private var spriteAndIdentity: some View {
        HStack(alignment: .top, spacing: 14) {
            if let spriteURL = entry.spriteURL {
                GameplaySidebarInsetSurface(
                    padding: EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8),
                    tint: FieldRetroPalette.accentGlassTint
                ) {
                    PixelAssetView(url: spriteURL, label: entry.displayName, whiteIsTransparent: true)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                }
                .frame(width: 96)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(String(format: "#%03d", entry.dexNumber))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink.opacity(0.56))

                GameBoyPixelText(
                    entry.displayName.uppercased(),
                    scale: 1.5,
                    color: FieldRetroPalette.ink,
                    fallbackFont: .system(size: 16, weight: .bold, design: .monospaced)
                )

                if let category = entry.speciesCategory {
                    Text(category.uppercased() + " POKéMON")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.56))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var typeBadgesRow: some View {
        HStack(spacing: 6) {
            if let primaryType = entry.primaryType {
                PokedexTypeBadgeFull(typeLabel: primaryType)
            }
            if let secondaryType = entry.secondaryType {
                PokedexTypeBadgeFull(typeLabel: secondaryType)
            }
        }
    }

    private var detailFieldsSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("FIELD DATA")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(FieldRetroPalette.ink.opacity(0.48))

            VStack(alignment: .leading, spacing: 4) {
                ForEach(entry.detailFields) { field in
                    PokedexDetailFieldRow(field: field)
                }
            }
        }
    }

    private var baseStatsSection: some View {
        GameplaySidebarInsetSurface(
            padding: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        ) {
            VStack(alignment: .leading, spacing: 6) {
                Text("BASE STATS")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink.opacity(0.48))

                VStack(spacing: 5) {
                    PokedexStatRow(label: "HP", value: entry.baseHP)
                    PokedexStatRow(label: "ATK", value: entry.baseAttack)
                    PokedexStatRow(label: "DEF", value: entry.baseDefense)
                    PokedexStatRow(label: "SPD", value: entry.baseSpeed)
                    PokedexStatRow(label: "SPC", value: entry.baseSpecial)
                }
            }
        }
    }

    private func descriptionSection(_ text: String) -> some View {
        GameplaySidebarInsetSurface(
            padding: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12),
            tint: FieldRetroPalette.accentGlassTint
        ) {
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(FieldRetroPalette.ink.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Stat Row

private struct PokedexStatRow: View {
    let label: String
    let value: Int

    private var fraction: CGFloat {
        min(1, CGFloat(value) / 255.0)
    }

    private var barColor: Color {
        switch fraction {
        case ..<0.3:
            return Color(red: 0.74, green: 0.39, blue: 0.33)
        case ..<0.5:
            return Color(red: 0.79, green: 0.66, blue: 0.28)
        default:
            return Color(red: 0.47, green: 0.67, blue: 0.33)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(FieldRetroPalette.ink.opacity(0.62))
                .frame(width: 28, alignment: .leading)

            Text("\(value)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(FieldRetroPalette.ink.opacity(0.82))
                .frame(width: 28, alignment: .trailing)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(FieldRetroPalette.track.opacity(0.82))
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(barColor)
                        .frame(width: max(0, proxy.size.width * fraction))
                }
            }
            .frame(height: 6)
        }
    }
}

private struct PokedexDetailFieldRow: View {
    let field: PokedexSidebarDetailFieldProps

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(field.label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(FieldRetroPalette.ink.opacity(0.5))
                .frame(width: 84, alignment: .leading)

            Text(field.value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(FieldRetroPalette.ink.opacity(0.84))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - List Row

private struct PokedexEntryRow: View {
    let entry: PokedexSidebarEntryProps
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        HoverCardPresenter(
            isPresented: showsHoverCard,
            cardSide: .leading,
            cardWidth: PokedexHoverCard.layoutWidth,
            spacing: GameplayFieldMetrics.hoverCardSpacing
        ) {
            Button(action: onTap) {
                GameplaySidebarInsetSurface(
                    padding: EdgeInsets(top: 7, leading: 10, bottom: 7, trailing: 10),
                    tint: entry.isOwned ? FieldRetroPalette.accentGlassTint : FieldRetroPalette.interactiveGlassTint
                ) {
                    HStack(spacing: 8) {
                        dexNumber

                        spriteOrPlaceholder
                            .frame(width: 32, height: 32)

                        speciesName

                        Spacer(minLength: 4)

                        if entry.isOwned || entry.isSeen {
                            typeBadges
                        }

                        statusIndicator
                    }
                }
                .opacity(entry.isOwned || entry.isSeen ? 1 : 0.5)
            }
            .buttonStyle(.plain)
            .disabled(!entry.isOwned)
            .onHover(perform: updateHoverState)
        } hoverCard: {
            PokedexHoverCard(entry: entry)
        }
        .zIndex(showsHoverCard ? 1 : 0)
    }

    private var showsHoverCard: Bool {
        isHovered && entry.isOwned
    }

    private func updateHoverState(_ hovering: Bool) {
        withAnimation(.easeOut(duration: 0.14)) {
            isHovered = hovering
        }
    }

    private var dexNumber: some View {
        Text(String(format: "%03d", entry.dexNumber))
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(FieldRetroPalette.ink.opacity(entry.isOwned ? 0.72 : (entry.isSeen ? 0.56 : 0.42)))
            .frame(width: 30, alignment: .leading)
    }

    @ViewBuilder
    private var spriteOrPlaceholder: some View {
        if let spriteURL = entry.spriteURL {
            PixelAssetView(url: spriteURL, label: entry.displayName, whiteIsTransparent: true)
                .aspectRatio(contentMode: .fit)
                .opacity(entry.isOwned ? 1 : 0.2)
        } else if entry.isSeen {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(FieldRetroPalette.slotFill.opacity(0.4))
                .overlay {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.22))
                }
        } else {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(FieldRetroPalette.slotFill.opacity(0.5))
                .overlay {
                    Text("?")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.22))
                }
        }
    }

    private var speciesName: some View {
        Text(entry.isSeen ? entry.displayName.uppercased() : "-----")
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundStyle(FieldRetroPalette.ink.opacity(entry.isOwned ? 0.88 : (entry.isSeen ? 0.56 : 0.34)))
            .lineLimit(1)
    }

    @ViewBuilder
    private var typeBadges: some View {
        HStack(spacing: 3) {
            if let primaryType = entry.primaryType {
                PokedexTypeBadge(typeLabel: primaryType)
            }
            if let secondaryType = entry.secondaryType {
                PokedexTypeBadge(typeLabel: secondaryType)
            }
        }
    }

    private var statusIndicator: some View {
        Group {
            if entry.isOwned {
                Circle()
                    .fill(Color(red: 0.47, green: 0.67, blue: 0.33))
                    .frame(width: 8, height: 8)
            } else if entry.isSeen {
                Image(systemName: "eye")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(FieldRetroPalette.ink.opacity(0.36))
            } else {
                Circle()
                    .stroke(FieldRetroPalette.ink.opacity(0.18), lineWidth: 1)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

private struct PokedexHoverCard: View {
    static let layoutWidth: CGFloat = 260

    let entry: PokedexSidebarEntryProps

    var body: some View {
        GameplayHoverCardSurface {
            PokedexDetailContent(entry: entry)
        }
        .frame(width: Self.layoutWidth, alignment: .leading)
    }
}

private struct PokedexGridEntryCell: View {
    let entry: PokedexSidebarEntryProps
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        HoverCardPresenter(
            isPresented: showsHoverCard,
            cardSide: .leading,
            cardWidth: PokedexHoverCard.layoutWidth,
            spacing: GameplayFieldMetrics.hoverCardSpacing
        ) {
            Button(action: onTap) {
                GameplaySidebarInsetSurface(
                    padding: EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6),
                    tint: entry.isOwned ? FieldRetroPalette.accentGlassTint : FieldRetroPalette.interactiveGlassTint
                ) {
                    VStack(spacing: 6) {
                        HStack {
                            Text(String(format: "%03d", entry.dexNumber))
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(FieldRetroPalette.ink.opacity(entry.isSeen ? 0.62 : 0.4))
                            Spacer(minLength: 0)
                            statusIndicator
                        }

                        spriteOrPlaceholder
                            .frame(width: 36, height: 36)

                        Text(entry.isSeen ? entry.displayName.uppercased() : "-----")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(FieldRetroPalette.ink.opacity(entry.isOwned ? 0.84 : (entry.isSeen ? 0.54 : 0.32)))
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                }
                .opacity(entry.isOwned || entry.isSeen ? 1 : 0.52)
            }
            .buttonStyle(.plain)
            .disabled(!entry.isOwned)
            .onHover(perform: updateHoverState)
        } hoverCard: {
            PokedexHoverCard(entry: entry)
        }
        .zIndex(showsHoverCard ? 1 : 0)
    }

    private var showsHoverCard: Bool {
        isHovered && entry.isOwned
    }

    private func updateHoverState(_ hovering: Bool) {
        withAnimation(.easeOut(duration: 0.14)) {
            isHovered = hovering
        }
    }

    @ViewBuilder
    private var spriteOrPlaceholder: some View {
        if let spriteURL = entry.spriteURL {
            PixelAssetView(url: spriteURL, label: entry.displayName, whiteIsTransparent: true)
                .aspectRatio(contentMode: .fit)
                .opacity(entry.isOwned ? 1 : 0.2)
        } else if entry.isSeen {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(FieldRetroPalette.slotFill.opacity(0.4))
                .overlay {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.22))
                }
        } else {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(FieldRetroPalette.slotFill.opacity(0.5))
                .overlay {
                    Text("?")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(FieldRetroPalette.ink.opacity(0.22))
                }
        }
    }

    private var statusIndicator: some View {
        Group {
            if entry.isOwned {
                Circle()
                    .fill(Color(red: 0.47, green: 0.67, blue: 0.33))
                    .frame(width: 7, height: 7)
            } else if entry.isSeen {
                Image(systemName: "eye")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(FieldRetroPalette.ink.opacity(0.34))
            } else {
                Circle()
                    .stroke(FieldRetroPalette.ink.opacity(0.18), lineWidth: 1)
                    .frame(width: 7, height: 7)
            }
        }
    }
}

// MARK: - Type Badges

private enum PokedexDisplayMode: String, CaseIterable, Identifiable {
    case list
    case grid

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .list:
            return "list.bullet"
        case .grid:
            return "square.grid.2x2"
        }
    }
}

private struct PokedexTypeBadge: View {
    let typeLabel: String

    var body: some View {
        Text(typeLabel.prefix(3).uppercased())
            .font(.system(size: 8, weight: .heavy, design: .monospaced))
            .foregroundStyle(FieldRetroPalette.ink.opacity(0.72))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                FieldRetroPalette.pokemonTypeBadgeBackground(for: typeLabel),
                in: Capsule(style: .continuous)
            )
    }
}

private struct PokedexTypeBadgeFull: View {
    let typeLabel: String

    var body: some View {
        Text(typeLabel.uppercased())
            .font(.system(size: 10, weight: .heavy, design: .monospaced))
            .foregroundStyle(FieldRetroPalette.ink.opacity(0.78))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                FieldRetroPalette.pokemonTypeBadgeBackground(for: typeLabel),
                in: Capsule(style: .continuous)
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(FieldRetroPalette.outline.opacity(0.08), lineWidth: 1)
            }
    }
}
