import SwiftUI

public struct VibeButtonStyle: ButtonStyle {
    var tintColor: Color

    @GestureState private var isPressing = false
    private let pressScale: CGFloat = 0.94

    @State private var isHovering: Bool = false

    public init(_ tint: Color) {
        self.tintColor = tint
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(tintColor)
            .font(.app(.satoshiMedium, size: 12))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .overlayBorder(color: tintColor.opacity(isHovering ? 1 : 0.4), lineWidth: 1, cornerRadius: 100)
            .scaleEffect(configuration.isPressed || isPressing ? pressScale : 1.0)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed || isPressing)
            .scaleEffect(isHovering ? 1.05 : 1.0)
            .onHover { isHovering = $0 }
            .animation(.easeInOut(duration: 0.2), value: isHovering)
    }
}

extension ButtonStyle where Self == VibeButtonStyle {
    public static func vibe(_ tint: Color) -> Self {
        VibeButtonStyle(tint)
    }
}
