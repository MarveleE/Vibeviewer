import SwiftUI
import VibeviewerAppEnvironment
import VibeviewerModel

public struct SettingsView: View {
    @State private var settings: AppSettings = .init()
    @Environment(\.cursorStorage) private var storage

    public init() {}

    public var body: some View {
        Form {
            
        }
        .padding(16)
        .frame(minWidth: 420, minHeight: 300)
        .task { self.settings = await self.storage.loadSettings() }
        .onChange(of: self.settings) { _, newValue in
            Task { try? await self.storage.saveSettings(newValue) }
        }
    }
}
