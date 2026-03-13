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
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("OWNED")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(FieldRetroPalette.ink.opacity(0.62))
                        Text("\(props.ownedCount)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(FieldRetroPalette.ink.opacity(0.74))
                    }
                    HStack(spacing: 6) {
                        Text("SEEN")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(FieldRetroPalette.ink.opacity(0.48))
                        Text("\(props.seenCount)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(FieldRetroPalette.ink.opacity(0.56))
                    }
                }
            }
            Spacer(minLength: 4)
            if selectedEntryID == nil {
                Text("\(props.ownedCount)/\(props.totalCount)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink.opacity(0.74))
            }
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

                TextField("Search Pok\u{00E9}mon", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink)

                if searchText.isEmpty == false {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(FieldRetroPalette.ink.opacity(0.34))
                    }
                    .buttonStyle(.plain)
                }
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

// MARK: - Detail View

private struct PokedexDetailView: View {
    let entry: PokedexSidebarEntryProps
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                spriteAndIdentity
                typeBadgesRow
                if entry.speciesCategory != nil || entry.heightText != nil || entry.weightText != nil {
                    physicalDataSection
                }
                baseStatsSection
                if let description = entry.descriptionText {
                    descriptionSection(description)
                }
            }
        }
        .frame(maxHeight: 420)
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity
        ))
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

    private var physicalDataSection: some View {
        GameplaySidebarInsetSurface(
            padding: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        ) {
            HStack(spacing: 0) {
                if let height = entry.heightText {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("HT")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(FieldRetroPalette.ink.opacity(0.48))
                        Text(height)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(FieldRetroPalette.ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let weight = entry.weightText {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("WT")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(FieldRetroPalette.ink.opacity(0.48))
                        Text(weight)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(FieldRetroPalette.ink)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - List Row

private struct PokedexEntryRow: View {
    let entry: PokedexSidebarEntryProps
    let onTap: () -> Void

    var body: some View {
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
            .opacity(entry.isOwned ? 1 : (entry.isSeen ? 0.72 : 0.5))
        }
        .buttonStyle(.plain)
        .disabled(!entry.isOwned)
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

private struct PokedexGridEntryCell: View {
    let entry: PokedexSidebarEntryProps
    let onTap: () -> Void

    var body: some View {
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
            .opacity(entry.isOwned ? 1 : (entry.isSeen ? 0.72 : 0.52))
        }
        .buttonStyle(.plain)
        .disabled(!entry.isOwned)
    }

    @ViewBuilder
    private var spriteOrPlaceholder: some View {
        if let spriteURL = entry.spriteURL {
            PixelAssetView(url: spriteURL, label: entry.displayName, whiteIsTransparent: true)
                .aspectRatio(contentMode: .fit)
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
