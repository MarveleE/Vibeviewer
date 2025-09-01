import VibeviewerModel
import SwiftUI

public extension View {
    @ViewBuilder
    func applyPreferredColorScheme(_ appearance: VibeviewerModel.AppAppearance) -> some View {
        switch appearance {
        case .system:
            self
        case .light:
            self.environment(\.colorScheme, .light)
        case .dark:
            self.environment(\.colorScheme, .dark)
        }
    }
}
