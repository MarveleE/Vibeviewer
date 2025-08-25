import Observation
import SwiftUI
import VibeviewerAppEnvironment
import VibeviewerModel

public struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.cursorStorage) private var storage

    public init() {}

    public var body: some View {
        Form {}
            .padding(16)
            .frame(minWidth: 420, minHeight: 300)
            .task { try? await self.settings.save(using: self.storage) }
    }
}
