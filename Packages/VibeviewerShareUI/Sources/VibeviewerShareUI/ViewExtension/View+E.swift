import SwiftUI
import Foundation

public extension View {
    func maxFrame(
        _ width: Bool = true, _ height: Bool = true, alignment: SwiftUI.Alignment = .center
    ) -> some View {
        Group {
            if width, height {
                frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            } else if width {
                frame(maxWidth: .infinity, alignment: alignment)
            } else if height {
                frame(maxHeight: .infinity, alignment: alignment)
            } else {
                self
            }
        }
    }

    func cornerRadiusWithCorners(
        _ radius: CGFloat, corners: RectCorner = .allCorners
    ) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }

    func linearBorder(
        color: Color, cornerRadius: CGFloat, lineWidth: CGFloat = 1, from: UnitPoint = .top,
        to: UnitPoint = .center
    ) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .inset(by: lineWidth)
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: color.opacity(0.1), location: 0),
                            .init(color: color.opacity(0.02), location: 0.5),
                            .init(color: color.opacity(0.06), location: 1),
                        ], startPoint: from, endPoint: to),
                    lineWidth: lineWidth
                )

        )
    }

    func linearBorder(
        stops: [Gradient.Stop], cornerRadius: CGFloat, lineWidth: CGFloat = 1,
        from: UnitPoint = .top, to: UnitPoint = .center
    ) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .inset(by: lineWidth)
                .stroke(
                    LinearGradient(stops: stops, startPoint: from, endPoint: to),
                    lineWidth: lineWidth
                )

        )
    }

    func overlayBorder(
        color: Color,
        lineWidth: CGFloat = 1,
        insets: CGFloat = 0,
        cornerRadius: CGFloat = 0,
        hidden: Bool = false
    ) -> some View {
        overlay(
            RoundedCorner(radius: cornerRadius, corners: .allCorners)
                .fill(color)
                .mask(
                    RoundedCorner(radius: cornerRadius, corners: .allCorners)
                        .stroke(style: .init(lineWidth: lineWidth))
                )
                .allowsHitTesting(false)
                .padding(insets)
        )
    }

    func extendTapGesture(_ value: CGFloat = 8, _ action: @escaping () -> Void) -> some View {
        self
            .padding(value)
            .contentShape(Rectangle())
            .onTapGesture {
                action()
            }
            .padding(-value)
    }
}

public struct RectCorner: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let topLeft: RectCorner = RectCorner(rawValue: 1 << 0)
    public static let topRight: RectCorner = RectCorner(rawValue: 1 << 1)
    public static let bottomLeft: RectCorner = RectCorner(rawValue: 1 << 2)
    public static let bottomRight: RectCorner = RectCorner(rawValue: 1 << 3)
    public static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

struct RoundedCorner: Shape, InsettableShape {
    var radius: CGFloat
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let topLeft = corners.contains(.topLeft) ? radius : 0
        let topRight = corners.contains(.topRight) ? radius : 0
        let bottomLeft = corners.contains(.bottomLeft) ? radius : 0
        let bottomRight = corners.contains(.bottomRight) ? radius : 0

        if #available(iOS 17.0, macOS 14.0, *) {
            return UnevenRoundedRectangle(
                topLeadingRadius: topLeft,
                bottomLeadingRadius: bottomLeft,
                bottomTrailingRadius: bottomRight,
                topTrailingRadius: topRight,
                style: .continuous
            ).path(in: rect)
        } else {
            if corners == .allCorners {
                return RoundedRectangle(cornerRadius: radius, style: .continuous).path(in: rect)
            } else {
                return Path(rect)
            }
        }
    }

    nonisolated func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.radius -= amount
        return shape
    }
}