import SwiftUI
import VibeviewerAppEnvironment
import VibeviewerModel
import Observation

public struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.cursorStorage) private var storage

    public init() {}

    public var body: some View {
        Form {
            
        }
        .padding(16)
        .frame(minWidth: 420, minHeight: 300)
        .task { try? await settings.save(using: storage) }
    }
}
