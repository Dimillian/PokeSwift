import SwiftUI
import PokeDataModel

struct FieldAlertBubbleView: View {
    let kind: FieldAlertBubbleKind
    let displayScale: CGFloat

    var body: some View {
        let pixel = max(2, floor(displayScale * 0.75))
        let width = pixel * 14
        let height = pixel * 16

        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color(red: 0.96, green: 0.98, blue: 0.83))
                .frame(width: width, height: height)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: pixel)
                )

            Rectangle()
                .fill(Color.black)
                .frame(width: pixel * 3, height: pixel * 7)
                .offset(x: pixel * 5, y: pixel * 2)

            Rectangle()
                .fill(Color.black)
                .frame(width: pixel * 3, height: pixel * 3)
                .offset(x: pixel * 5, y: pixel * 11)
        }
        .frame(width: width, height: height)
        .opacity(kind == .exclamation ? 1 : 0)
        .shadow(color: .black.opacity(0.3), radius: pixel * 1.25, y: pixel)
        .allowsHitTesting(false)
    }
}

struct FieldViewportTransitionOverlay: View {
    let transition: FieldTransitionTelemetry?

    var body: some View {
        Rectangle()
            .fill(Color.black)
            .opacity(targetOpacity)
            .animation(.linear(duration: 0.12), value: transition?.phase)
            .allowsHitTesting(false)
    }

    private var targetOpacity: Double {
        transition?.phase == "fadingOut" ? 1 : 0
    }
}
