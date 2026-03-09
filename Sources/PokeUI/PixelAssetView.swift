import AppKit
import SwiftUI

public struct PixelAssetView: View {
    private let url: URL
    private let label: String

    public init(url: URL, label: String) {
        self.url = url
        self.label = label
    }

    public var body: some View {
        Group {
            if let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .antialiased(false)
                    .aspectRatio(contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.black.opacity(0.24))
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                            Text(label)
                                .font(.system(.caption, design: .monospaced))
                        }
                        .foregroundStyle(.secondary)
                        .padding(8)
                    }
            }
        }
        .accessibilityLabel(label)
    }
}
