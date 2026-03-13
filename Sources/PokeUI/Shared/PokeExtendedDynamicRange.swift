import AppKit
import QuartzCore
import SwiftUI

public extension View {
    @ViewBuilder
    func pokeExtendedDynamicRange(
        enabled: Bool = true,
        preferredDynamicRange: CALayer.DynamicRange = .high,
        contentsHeadroom: CGFloat = 0
    ) -> some View {
        if enabled {
            PokeExtendedDynamicRangeHost(
                preferredDynamicRange: preferredDynamicRange,
                contentsHeadroom: contentsHeadroom
            ) {
                self
            }
        } else {
            self
        }
    }
}

private struct PokeExtendedDynamicRangeHost<Content: View>: NSViewRepresentable {
    let preferredDynamicRange: CALayer.DynamicRange
    let contentsHeadroom: CGFloat
    let content: Content

    init(
        preferredDynamicRange: CALayer.DynamicRange,
        contentsHeadroom: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.preferredDynamicRange = preferredDynamicRange
        self.contentsHeadroom = contentsHeadroom
        self.content = content()
    }

    func makeNSView(context: Context) -> PokeExtendedDynamicRangeHostingView<Content> {
        let view = PokeExtendedDynamicRangeHostingView(rootView: content)
        view.requestedDynamicRange = preferredDynamicRange
        view.requestedContentsHeadroom = contentsHeadroom
        view.configureDynamicRange()
        return view
    }

    func updateNSView(_ nsView: PokeExtendedDynamicRangeHostingView<Content>, context: Context) {
        nsView.rootView = content
        nsView.requestedDynamicRange = preferredDynamicRange
        nsView.requestedContentsHeadroom = contentsHeadroom
        nsView.configureDynamicRange()
    }
}

private final class PokeExtendedDynamicRangeHostingView<Content: View>: NSHostingView<Content> {
    var requestedDynamicRange: CALayer.DynamicRange = .high
    var requestedContentsHeadroom: CGFloat = 0

    required init(rootView: Content) {
        super.init(rootView: rootView)
        sizingOptions = [.intrinsicContentSize]
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.contentsFormat = .RGBA16Float
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isOpaque: Bool {
        false
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureDynamicRange()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        configureDynamicRange()
    }

    func configureDynamicRange() {
        wantsLayer = true
        guard let layer else { return }

        layer.backgroundColor = NSColor.clear.cgColor
        layer.contentsFormat = .RGBA16Float
        layer.toneMapMode = .ifSupported

        let screenSupportsHDR = (window?.screen?.maximumPotentialExtendedDynamicRangeColorComponentValue ?? 1) > 1.01
        let shouldSuppressHDR = NSApplication.shared.applicationShouldSuppressHighDynamicRangeContent
        let shouldEnableHDR = screenSupportsHDR && !shouldSuppressHDR

        layer.preferredDynamicRange = shouldEnableHDR ? requestedDynamicRange : .standard
        layer.contentsHeadroom = shouldEnableHDR ? requestedContentsHeadroom : 0
    }
}
