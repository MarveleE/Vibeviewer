import SwiftUI

public struct VibeButtonStyle: ButtonStyle {
    var tintColor: Color

    @GestureState private var isPressing = false
    private let pressScale: CGFloat = 0.94

    public init(_ tint: Color) {
        self.tintColor = tint
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(tintColor)
            .font(.app(.satoshiMedium, size: 12))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .overlayBorder(color: tintColor.opacity(0.2), lineWidth: 0.5, cornerRadius: 100)
            .scaleEffect(configuration.isPressed || isPressing ? pressScale : 1.0)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed || isPressing)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressing) { _, state, _ in
                        state = true
                    }
            )
    }
}

extension ButtonStyle where Self == VibeButtonStyle {
    public static func vibe(_ tint: Color) -> Self {
        VibeButtonStyle(tint)
    }
}