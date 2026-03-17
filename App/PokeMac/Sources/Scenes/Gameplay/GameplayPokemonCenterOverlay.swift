import SwiftUI
import PokeDataModel
import PokeUI

struct PokemonCenterHealingOverlay: View {
    let healing: FieldHealingTelemetry

    var body: some View {
        GameplayHoverCardSurface(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Text("HEALING MACHINE")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(GameplayFieldStyleTokens.ink)

                HStack(alignment: .center, spacing: 16) {
                    PokemonCenterBallWell(healing: healing)

                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(monitorFill)
                            .overlay {
                                VStack(spacing: 5) {
                                    Capsule()
                                        .fill(GameplayFieldStyleTokens.ink.opacity(0.82))
                                        .frame(width: 58, height: 6)
                                    HStack(spacing: 5) {
                                        ForEach(0..<4, id: \.self) { index in
                                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                                .fill(signalFill(for: index))
                                                .frame(width: 10, height: 8)
                                        }
                                    }
                                }
                            }
                            .frame(width: 104, height: 68)

                        Text(statusText)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(GameplayFieldStyleTokens.ink.opacity(0.72))

                        Text(progressText)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(GameplayFieldStyleTokens.ink.opacity(0.88))
                    }
                }
            }
        }
    }

    private var monitorFill: Color {
        switch healing.phase {
        case .healedJingle:
            return GameplayFieldStyleTokens.ink.opacity(0.78)
        case .machineActive:
            return healing.pulseStep.isMultiple(of: 2) ? PokeThemePalette.fieldLeadSlotFill.opacity(0.92) : PokeThemePalette.fieldCardFill
        default:
            return PokeThemePalette.fieldCardFill
        }
    }

    private func signalFill(for index: Int) -> Color {
        if healing.phase == .healedJingle {
            return (index + healing.pulseStep).isMultiple(of: 2)
                ? GameplayFieldStyleTokens.ink.opacity(0.88)
                : PokeThemePalette.fieldLeadSlotFill.opacity(0.8)
        }

        let litCount = min(4, max(1, healing.activeBallCount))
        return index < litCount
            ? PokeThemePalette.fieldLeadSlotFill.opacity(index == litCount - 1 ? 0.94 : 0.72)
            : GameplayFieldStyleTokens.ink.opacity(0.2)
    }

    private var statusText: String {
        switch healing.phase {
        case .priming:
            return "PREPARING"
        case .machineActive:
            return "ADDING PARTY BALLS"
        case .healedJingle:
            return "POKeMON HEALED"
        default:
            return "HEALING"
        }
    }

    private var progressText: String {
        switch healing.phase {
        case .machineActive, .healedJingle:
            return "\(healing.activeBallCount)/\(healing.totalBallCount) LOADED"
        default:
            return "STANDBY"
        }
    }
}

struct PokemonCenterBallWell: View {
    let healing: FieldHealingTelemetry

    var body: some View {
        ZStack {
            Circle()
                .fill(GameplayFieldStyleTokens.ink.opacity(0.92))

            Circle()
                .stroke(GameplayFieldStyleTokens.ink.opacity(0.28), lineWidth: 2)
                .padding(5)

            Circle()
                .stroke(PokeThemePalette.fieldLeadSlotFill.opacity(healing.phase == .healedJingle ? 0.7 : 0.36), lineWidth: 1)
                .padding(12)

            ForEach(0..<max(healing.totalBallCount, 1), id: \.self) { index in
                let point = ballPoint(for: index, total: healing.totalBallCount)
                let isVisible = index < visibleBallCount

                PokemonCenterBallToken(
                    isVisible: isVisible,
                    isFlashing: healing.phase == .healedJingle && (index + healing.pulseStep).isMultiple(of: 2),
                    isNewest: healing.phase == .machineActive && index == max(0, healing.activeBallCount - 1)
                )
                .position(point)
            }
        }
        .frame(width: 112, height: 112)
        .animation(.easeInOut(duration: 0.16), value: healing.activeBallCount)
        .animation(.easeInOut(duration: 0.14), value: healing.pulseStep)
    }

    private var visibleBallCount: Int {
        switch healing.phase {
        case .priming:
            return 0
        default:
            return min(healing.activeBallCount, healing.totalBallCount)
        }
    }

    private func ballPoint(for index: Int, total: Int) -> CGPoint {
        let clampedTotal = max(1, min(total, 6))
        let layouts: [[CGPoint]] = [
            [CGPoint(x: 56, y: 56)],
            [CGPoint(x: 40, y: 56), CGPoint(x: 72, y: 56)],
            [CGPoint(x: 56, y: 36), CGPoint(x: 39, y: 70), CGPoint(x: 73, y: 70)],
            [CGPoint(x: 40, y: 40), CGPoint(x: 72, y: 40), CGPoint(x: 40, y: 72), CGPoint(x: 72, y: 72)],
            [CGPoint(x: 56, y: 30), CGPoint(x: 38, y: 49), CGPoint(x: 74, y: 49), CGPoint(x: 44, y: 77), CGPoint(x: 68, y: 77)],
            [CGPoint(x: 38, y: 34), CGPoint(x: 56, y: 34), CGPoint(x: 74, y: 34), CGPoint(x: 38, y: 76), CGPoint(x: 56, y: 76), CGPoint(x: 74, y: 76)],
        ]

        let positions = layouts[clampedTotal - 1]
        return positions[min(index, positions.count - 1)]
    }
}

struct PokemonCenterBallToken: View {
    let isVisible: Bool
    let isFlashing: Bool
    let isNewest: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(baseOpacity))

            Circle()
                .fill(PokeThemePalette.fieldLeadSlotFill.opacity(topOpacity))
                .mask(
                    Rectangle()
                        .frame(width: 20, height: 10)
                        .offset(y: -5)
                )

            Rectangle()
                .fill(GameplayFieldStyleTokens.ink.opacity(baseOpacity))
                .frame(width: 20, height: 2)

            Circle()
                .fill(Color.white.opacity(baseOpacity))
                .frame(width: 6, height: 6)
                .overlay {
                    Circle()
                        .stroke(GameplayFieldStyleTokens.ink.opacity(baseOpacity), lineWidth: 1)
                }

            Circle()
                .stroke(GameplayFieldStyleTokens.ink.opacity(baseOpacity), lineWidth: 1)
        }
        .frame(width: 20, height: 20)
        .scaleEffect(isNewest ? 1.12 : 1)
        .opacity(isVisible ? 1 : 0.08)
        .shadow(
            color: PokeThemePalette.fieldLeadSlotFill.opacity(isVisible ? (isFlashing ? 0.34 : 0.18) : 0),
            radius: isFlashing ? 8 : 4
        )
    }

    private var baseOpacity: Double {
        isVisible ? 0.98 : 0.18
    }

    private var topOpacity: Double {
        if isFlashing {
            return 0.98
        }
        if isNewest {
            return 0.94
        }
        return isVisible ? 0.82 : 0.12
    }
}
