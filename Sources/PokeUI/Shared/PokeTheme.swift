import AppKit
import SwiftUI

public enum AppAppearanceMode: String, CaseIterable, Codable, Sendable {
    case system
    case light
    case retroDark

    public var preferredColorSchemeOverride: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .retroDark:
            return .dark
        }
    }

    public var optionsLabel: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .retroDark:
            return "Dark"
        }
    }

    public func resolved(for colorScheme: ColorScheme) -> AppAppearanceMode {
        switch self {
        case .system:
            return colorScheme == .dark ? .retroDark : .light
        case .light, .retroDark:
            return self
        }
    }

    public func isDark(for colorScheme: ColorScheme) -> Bool {
        resolved(for: colorScheme) == .retroDark
    }

    public var nextOptionMode: AppAppearanceMode {
        switch self {
        case .system:
            return .retroDark
        case .retroDark:
            return .light
        case .light:
            return .system
        }
    }
}

public struct ThemeRGBA: Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    var nsColor: NSColor {
        NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }
}

public struct PokeThemeFieldValues: Equatable, Sendable {
    public let ink: ThemeRGBA
    public let outline: ThemeRGBA
    public let cardFill: ThemeRGBA
    public let slotFill: ThemeRGBA
    public let leadSlotFill: ThemeRGBA
    public let track: ThemeRGBA
    public let portraitFill: ThemeRGBA
    public let stageOuter: ThemeRGBA
    public let stageMiddle: ThemeRGBA
    public let stageInner: ThemeRGBA
    public let glassTint: ThemeRGBA
    public let accentGlassTint: ThemeRGBA
    public let interactiveGlassTint: ThemeRGBA
    public let hoverCardGlassTint: ThemeRGBA
    public let hoverCardBackgroundTint: ThemeRGBA
    public let shellBackdrop: ThemeRGBA
    public let shellBackdropShadow: ThemeRGBA
}

public struct PokeThemeResolvedPalette: Equatable, Sendable {
    public let primaryText: ThemeRGBA
    public let secondaryText: ThemeRGBA
    public let tertiaryText: ThemeRGBA
    public let disabledText: ThemeRGBA
    public let classicBackground: ThemeRGBA
    public let panelBackground: ThemeRGBA
    public let panelGlassTint: ThemeRGBA
    public let panelOutline: ThemeRGBA
    public let plainPanelFill: ThemeRGBA
    public let placeholderFill: ThemeRGBA
    public let menuFocusFill: ThemeRGBA
    public let menuIdleFill: ThemeRGBA
    public let menuFocusGlass: ThemeRGBA
    public let menuIdleGlass: ThemeRGBA
    public let menuFocusStroke: ThemeRGBA
    public let menuIdleStroke: ThemeRGBA
    public let appBackgroundTop: ThemeRGBA
    public let appBackgroundMiddle: ThemeRGBA
    public let appBackgroundBottom: ThemeRGBA
    public let appHighlightGlow: ThemeRGBA
    public let appAccentGlow: ThemeRGBA
    public let appDepthShadow: ThemeRGBA
    public let gameBoyWordmark: ThemeRGBA
    public let dialogueBorder: ThemeRGBA
    public let dialoguePaper: ThemeRGBA
    public let dialogueInsetBorder: ThemeRGBA
    public let dialogueFill: ThemeRGBA
    public let dialogueDotSoft: ThemeRGBA
    public let dialogueDotMid: ThemeRGBA
    public let dialogueDotStrong: ThemeRGBA
    public let dialogueShadow: ThemeRGBA
    public let screenWellFill: ThemeRGBA
    public let screenWellHighlight: ThemeRGBA
    public let screenWellDepth: ThemeRGBA
    public let screenLabel: ThemeRGBA
    public let batteryIndicator: ThemeRGBA
    public let screenRim: ThemeRGBA
    public let screenGlow: ThemeRGBA
    public let screenGlowInner: ThemeRGBA
    public let accentBarMagenta: ThemeRGBA
    public let accentBarBlue: ThemeRGBA
    public let battleEnemyTint: ThemeRGBA
    public let battleEnemyBackground: ThemeRGBA
    public let battlePlayerTint: ThemeRGBA
    public let battlePlayerBackground: ThemeRGBA
    public let field: PokeThemeFieldValues
}

public enum PokeThemePalette {
    public static var lightPalette: PokeThemeResolvedPalette {
        resolve(for: .light)
    }

    public static func resolve(for appearanceMode: AppAppearanceMode) -> PokeThemeResolvedPalette {
        switch appearanceMode.resolved(for: .light) {
        case .light:
            return .light
        case .retroDark:
            return .retroDark
        case .system:
            return .light
        }
    }

    public static let primaryText = dynamic(\.primaryText)
    public static let secondaryText = dynamic(\.secondaryText)
    public static let tertiaryText = dynamic(\.tertiaryText)
    public static let disabledText = dynamic(\.disabledText)
    public static let classicBackground = dynamic(\.classicBackground)
    public static let panelBackground = dynamic(\.panelBackground)
    public static let panelGlassTint = dynamic(\.panelGlassTint)
    public static let panelOutline = dynamic(\.panelOutline)
    public static let plainPanelFill = dynamic(\.plainPanelFill)
    public static let placeholderFill = dynamic(\.placeholderFill)
    public static let menuFocusFill = dynamic(\.menuFocusFill)
    public static let menuIdleFill = dynamic(\.menuIdleFill)
    public static let menuFocusGlass = dynamic(\.menuFocusGlass)
    public static let menuIdleGlass = dynamic(\.menuIdleGlass)
    public static let menuFocusStroke = dynamic(\.menuFocusStroke)
    public static let menuIdleStroke = dynamic(\.menuIdleStroke)
    public static let appBackgroundTop = dynamic(\.appBackgroundTop)
    public static let appBackgroundMiddle = dynamic(\.appBackgroundMiddle)
    public static let appBackgroundBottom = dynamic(\.appBackgroundBottom)
    public static let appHighlightGlow = dynamic(\.appHighlightGlow)
    public static let appAccentGlow = dynamic(\.appAccentGlow)
    public static let appDepthShadow = dynamic(\.appDepthShadow)
    public static let gameBoyWordmark = dynamic(\.gameBoyWordmark)
    public static let dialogueBorder = dynamic(\.dialogueBorder)
    public static let dialoguePaper = dynamic(\.dialoguePaper)
    public static let dialogueInsetBorder = dynamic(\.dialogueInsetBorder)
    public static let dialogueFill = dynamic(\.dialogueFill)
    public static let dialogueDotSoft = dynamic(\.dialogueDotSoft)
    public static let dialogueDotMid = dynamic(\.dialogueDotMid)
    public static let dialogueDotStrong = dynamic(\.dialogueDotStrong)
    public static let dialogueShadow = dynamic(\.dialogueShadow)
    public static let screenWellFill = dynamic(\.screenWellFill)
    public static let screenWellHighlight = dynamic(\.screenWellHighlight)
    public static let screenWellDepth = dynamic(\.screenWellDepth)
    public static let screenLabel = dynamic(\.screenLabel)
    public static let batteryIndicator = dynamic(\.batteryIndicator)
    public static let screenRim = dynamic(\.screenRim)
    public static let screenGlow = dynamic(\.screenGlow)
    public static let screenGlowInner = dynamic(\.screenGlowInner)
    public static let accentBarMagenta = dynamic(\.accentBarMagenta)
    public static let accentBarBlue = dynamic(\.accentBarBlue)
    public static let battleEnemyTint = dynamic(\.battleEnemyTint)
    public static let battleEnemyBackground = dynamic(\.battleEnemyBackground)
    public static let battlePlayerTint = dynamic(\.battlePlayerTint)
    public static let battlePlayerBackground = dynamic(\.battlePlayerBackground)

    public static let fieldInk = dynamicField(\.ink)
    public static let fieldOutline = dynamicField(\.outline)
    public static let fieldCardFill = dynamicField(\.cardFill)
    public static let fieldSlotFill = dynamicField(\.slotFill)
    public static let fieldLeadSlotFill = dynamicField(\.leadSlotFill)
    public static let fieldTrack = dynamicField(\.track)
    public static let fieldPortraitFill = dynamicField(\.portraitFill)
    public static let fieldStageOuter = dynamicField(\.stageOuter)
    public static let fieldStageMiddle = dynamicField(\.stageMiddle)
    public static let fieldStageInner = dynamicField(\.stageInner)
    public static let fieldGlassTint = dynamicField(\.glassTint)
    public static let fieldAccentGlassTint = dynamicField(\.accentGlassTint)
    public static let fieldInteractiveGlassTint = dynamicField(\.interactiveGlassTint)
    public static let fieldHoverCardGlassTint = dynamicField(\.hoverCardGlassTint)
    public static let fieldHoverCardBackgroundTint = dynamicField(\.hoverCardBackgroundTint)
    public static let fieldShellBackdrop = dynamicField(\.shellBackdrop)
    public static let fieldShellBackdropShadow = dynamicField(\.shellBackdropShadow)

    private static func dynamic(_ keyPath: KeyPath<PokeThemeResolvedPalette, ThemeRGBA>) -> Color {
        Color(nsColor: dynamicNSColor(keyPath))
    }

    private static func dynamicField(_ keyPath: KeyPath<PokeThemeFieldValues, ThemeRGBA>) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            resolve(for: appearanceMode(for: appearance)).field[keyPath: keyPath].nsColor
        })
    }

    private static func dynamicNSColor(_ keyPath: KeyPath<PokeThemeResolvedPalette, ThemeRGBA>) -> NSColor {
        NSColor(name: nil) { appearance in
            resolve(for: appearanceMode(for: appearance))[keyPath: keyPath].nsColor
        }
    }

    private static func appearanceMode(for appearance: NSAppearance) -> AppAppearanceMode {
        let bestMatch = appearance.bestMatch(from: [.darkAqua, .aqua]) ?? .aqua
        return bestMatch == .darkAqua ? .retroDark : .light
    }
}

private struct PokeAppearanceModeKey: EnvironmentKey {
    static let defaultValue: AppAppearanceMode = .system
}

public extension EnvironmentValues {
    var pokeAppearanceMode: AppAppearanceMode {
        get { self[PokeAppearanceModeKey.self] }
        set { self[PokeAppearanceModeKey.self] = newValue }
    }
}

public extension View {
    func pokeAppearanceMode(_ appearanceMode: AppAppearanceMode) -> some View {
        environment(\.pokeAppearanceMode, appearanceMode)
    }
}

private extension PokeThemeResolvedPalette {
    static let light = PokeThemeResolvedPalette(
        primaryText: .init(red: 0.1, green: 0.11, blue: 0.1),
        secondaryText: .init(red: 0.1, green: 0.11, blue: 0.1, alpha: 0.72),
        tertiaryText: .init(red: 0.1, green: 0.11, blue: 0.1, alpha: 0.52),
        disabledText: .init(red: 0.1, green: 0.11, blue: 0.1, alpha: 0.46),
        classicBackground: .init(red: 1, green: 1, blue: 1),
        panelBackground: .init(red: 1, green: 1, blue: 1, alpha: 0.18),
        panelGlassTint: .init(red: 0.82, green: 0.91, blue: 0.78, alpha: 0.38),
        panelOutline: .init(red: 0, green: 0, blue: 0, alpha: 0.08),
        plainPanelFill: .init(red: 1, green: 1, blue: 1),
        placeholderFill: .init(red: 0, green: 0, blue: 0, alpha: 0.24),
        menuFocusFill: .init(red: 0.8, green: 0.9, blue: 0.73, alpha: 0.3),
        menuIdleFill: .init(red: 1, green: 1, blue: 1, alpha: 0.12),
        menuFocusGlass: .init(red: 0.77, green: 0.89, blue: 0.72, alpha: 0.45),
        menuIdleGlass: .init(red: 1, green: 1, blue: 1, alpha: 0.18),
        menuFocusStroke: .init(red: 0, green: 0, blue: 0, alpha: 0.14),
        menuIdleStroke: .init(red: 0, green: 0, blue: 0, alpha: 0.07),
        appBackgroundTop: .init(red: 0.95, green: 0.96, blue: 0.9),
        appBackgroundMiddle: .init(red: 0.84, green: 0.88, blue: 0.76),
        appBackgroundBottom: .init(red: 0.73, green: 0.79, blue: 0.64),
        appHighlightGlow: .init(red: 1, green: 1, blue: 1, alpha: 0.42),
        appAccentGlow: .init(red: 0.73, green: 0.84, blue: 0.74, alpha: 0.22),
        appDepthShadow: .init(red: 0.34, green: 0.39, blue: 0.26, alpha: 0.06),
        gameBoyWordmark: .init(red: 0.17, green: 0.22, blue: 0.68),
        dialogueBorder: .init(red: 0, green: 0, blue: 0),
        dialoguePaper: .init(red: 0.95, green: 0.95, blue: 0.92),
        dialogueInsetBorder: .init(red: 0, green: 0, blue: 0),
        dialogueFill: .init(red: 0.98, green: 0.98, blue: 0.95),
        dialogueDotSoft: .init(red: 0, green: 0, blue: 0, alpha: 0.18),
        dialogueDotMid: .init(red: 0, green: 0, blue: 0, alpha: 0.38),
        dialogueDotStrong: .init(red: 0, green: 0, blue: 0, alpha: 0.72),
        dialogueShadow: .init(red: 0, green: 0, blue: 0, alpha: 0.08),
        screenWellFill: .init(red: 0.36, green: 0.37, blue: 0.43),
        screenWellHighlight: .init(red: 1, green: 1, blue: 1, alpha: 0.08),
        screenWellDepth: .init(red: 0, green: 0, blue: 0, alpha: 0.12),
        screenLabel: .init(red: 1, green: 1, blue: 1, alpha: 0.78),
        batteryIndicator: .init(red: 0.96, green: 0.23, blue: 0.2),
        screenRim: .init(red: 0.18, green: 0.28, blue: 0.08),
        screenGlow: .init(red: 0.48, green: 0.76, blue: 0.45, alpha: 0),
        screenGlowInner: .init(red: 0.88, green: 0.97, blue: 0.8, alpha: 0),
        accentBarMagenta: .init(red: 0.42, green: 0.07, blue: 0.27),
        accentBarBlue: .init(red: 0.16, green: 0.17, blue: 0.55),
        battleEnemyTint: .init(red: 0.92, green: 0.96, blue: 0.84, alpha: 0.42),
        battleEnemyBackground: .init(red: 1, green: 1, blue: 1, alpha: 0.18),
        battlePlayerTint: .init(red: 0.78, green: 0.9, blue: 0.76, alpha: 0.46),
        battlePlayerBackground: .init(red: 0.86, green: 0.93, blue: 0.8, alpha: 0.22),
        field: .init(
            ink: .init(red: 0.16, green: 0.18, blue: 0.12),
            outline: .init(red: 0, green: 0, blue: 0),
            cardFill: .init(red: 0.88, green: 0.9, blue: 0.78),
            slotFill: .init(red: 0.8, green: 0.84, blue: 0.69),
            leadSlotFill: .init(red: 0.74, green: 0.8, blue: 0.63),
            track: .init(red: 0.55, green: 0.62, blue: 0.49),
            portraitFill: .init(red: 0.76, green: 0.82, blue: 0.68),
            stageOuter: .init(red: 0.68, green: 0.74, blue: 0.58),
            stageMiddle: .init(red: 0.79, green: 0.84, blue: 0.68),
            stageInner: .init(red: 0.92, green: 0.92, blue: 0.84),
            glassTint: .init(red: 0.82, green: 0.9, blue: 0.77, alpha: 0.42),
            accentGlassTint: .init(red: 0.73, green: 0.84, blue: 0.74, alpha: 0.48),
            interactiveGlassTint: .init(red: 0.91, green: 0.94, blue: 0.86, alpha: 0.4),
            hoverCardGlassTint: .init(red: 0.74, green: 0.9, blue: 0.72, alpha: 0.4),
            hoverCardBackgroundTint: .init(red: 0.8, green: 0.9, blue: 0.76, alpha: 0.2),
            shellBackdrop: .init(red: 0.94, green: 0.94, blue: 0.89),
            shellBackdropShadow: .init(red: 0.33, green: 0.39, blue: 0.26)
        )
    )

    static let retroDark = PokeThemeResolvedPalette(
        primaryText: .init(red: 0.9, green: 0.96, blue: 0.89),
        secondaryText: .init(red: 0.86, green: 0.94, blue: 0.87, alpha: 0.76),
        tertiaryText: .init(red: 0.82, green: 0.9, blue: 0.82, alpha: 0.54),
        disabledText: .init(red: 0.82, green: 0.88, blue: 0.8, alpha: 0.42),
        classicBackground: .init(red: 0.08, green: 0.1, blue: 0.09),
        panelBackground: .init(red: 0.15, green: 0.19, blue: 0.17, alpha: 0.74),
        panelGlassTint: .init(red: 0.27, green: 0.39, blue: 0.3, alpha: 0.32),
        panelOutline: .init(red: 0.64, green: 0.76, blue: 0.67, alpha: 0.14),
        plainPanelFill: .init(red: 0.13, green: 0.16, blue: 0.14),
        placeholderFill: .init(red: 0.58, green: 0.84, blue: 0.66, alpha: 0.18),
        menuFocusFill: .init(red: 0.34, green: 0.53, blue: 0.37, alpha: 0.42),
        menuIdleFill: .init(red: 0.16, green: 0.22, blue: 0.18, alpha: 0.54),
        menuFocusGlass: .init(red: 0.48, green: 0.78, blue: 0.54, alpha: 0.34),
        menuIdleGlass: .init(red: 0.23, green: 0.33, blue: 0.25, alpha: 0.26),
        menuFocusStroke: .init(red: 0.64, green: 0.95, blue: 0.68, alpha: 0.24),
        menuIdleStroke: .init(red: 0.58, green: 0.78, blue: 0.61, alpha: 0.12),
        appBackgroundTop: .init(red: 0.08, green: 0.1, blue: 0.09),
        appBackgroundMiddle: .init(red: 0.11, green: 0.15, blue: 0.12),
        appBackgroundBottom: .init(red: 0.16, green: 0.22, blue: 0.17),
        appHighlightGlow: .init(red: 0.62, green: 0.92, blue: 0.71, alpha: 0.08),
        appAccentGlow: .init(red: 0.31, green: 0.61, blue: 0.39, alpha: 0.18),
        appDepthShadow: .init(red: 0, green: 0, blue: 0, alpha: 0.28),
        gameBoyWordmark: .init(red: 0.7, green: 0.85, blue: 0.78),
        dialogueBorder: .init(red: 0.8, green: 0.92, blue: 0.78, alpha: 0.24),
        dialoguePaper: .init(red: 0.12, green: 0.15, blue: 0.13),
        dialogueInsetBorder: .init(red: 0.04, green: 0.05, blue: 0.04),
        dialogueFill: .init(red: 0.18, green: 0.23, blue: 0.19),
        dialogueDotSoft: .init(red: 0.45, green: 0.71, blue: 0.5, alpha: 0.22),
        dialogueDotMid: .init(red: 0.54, green: 0.84, blue: 0.59, alpha: 0.45),
        dialogueDotStrong: .init(red: 0.71, green: 0.98, blue: 0.74, alpha: 0.82),
        dialogueShadow: .init(red: 0, green: 0, blue: 0, alpha: 0.28),
        screenWellFill: .init(red: 0.07, green: 0.08, blue: 0.08),
        screenWellHighlight: .init(red: 0.67, green: 0.98, blue: 0.74, alpha: 0.1),
        screenWellDepth: .init(red: 0, green: 0, blue: 0, alpha: 0.42),
        screenLabel: .init(red: 0.88, green: 0.97, blue: 0.89, alpha: 0.74),
        batteryIndicator: .init(red: 0.92, green: 0.33, blue: 0.3),
        screenRim: .init(red: 0.44, green: 0.7, blue: 0.35),
        screenGlow: .init(red: 0.41, green: 0.84, blue: 0.48, alpha: 0.28),
        screenGlowInner: .init(red: 0.84, green: 1, blue: 0.84, alpha: 0.12),
        accentBarMagenta: .init(red: 0.61, green: 0.24, blue: 0.48),
        accentBarBlue: .init(red: 0.38, green: 0.51, blue: 0.86),
        battleEnemyTint: .init(red: 0.19, green: 0.29, blue: 0.2, alpha: 0.58),
        battleEnemyBackground: .init(red: 0.26, green: 0.37, blue: 0.26, alpha: 0.3),
        battlePlayerTint: .init(red: 0.24, green: 0.41, blue: 0.28, alpha: 0.62),
        battlePlayerBackground: .init(red: 0.31, green: 0.48, blue: 0.33, alpha: 0.34),
        field: .init(
            ink: .init(red: 0.88, green: 0.95, blue: 0.87),
            outline: .init(red: 0.88, green: 0.98, blue: 0.89, alpha: 0.24),
            cardFill: .init(red: 0.16, green: 0.21, blue: 0.18),
            slotFill: .init(red: 0.2, green: 0.28, blue: 0.22),
            leadSlotFill: .init(red: 0.24, green: 0.34, blue: 0.26),
            track: .init(red: 0.29, green: 0.38, blue: 0.3),
            portraitFill: .init(red: 0.21, green: 0.31, blue: 0.24),
            stageOuter: .init(red: 0.12, green: 0.16, blue: 0.13),
            stageMiddle: .init(red: 0.18, green: 0.24, blue: 0.19),
            stageInner: .init(red: 0.24, green: 0.31, blue: 0.26),
            glassTint: .init(red: 0.28, green: 0.44, blue: 0.32, alpha: 0.3),
            accentGlassTint: .init(red: 0.36, green: 0.62, blue: 0.42, alpha: 0.38),
            interactiveGlassTint: .init(red: 0.25, green: 0.35, blue: 0.27, alpha: 0.34),
            hoverCardGlassTint: .init(red: 0.39, green: 0.69, blue: 0.45, alpha: 0.32),
            hoverCardBackgroundTint: .init(red: 0.19, green: 0.31, blue: 0.22, alpha: 0.24),
            shellBackdrop: .init(red: 0.15, green: 0.2, blue: 0.17),
            shellBackdropShadow: .init(red: 0, green: 0, blue: 0, alpha: 0.42)
        )
    )
}
