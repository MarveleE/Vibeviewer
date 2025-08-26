import SwiftUI
import Observation
import VibeviewerModel
import VibeviewerShareUI

struct UsageHeaderView: View {
    enum Action {
        case dashboard
        case logout
    }

    var action: (Action) -> Void

    @Environment(AppSession.self) private var session

    var body: some View {
        HStack {
            Text("Usage")
                .font(.app(.satoshiMedium, size: 16))
                .foregroundStyle(.primary)
            Spacer()

            HStack(spacing: 12) {
                Menu("", systemImage: "ellipsis") {
                    Button("Log out") {
                        action(.logout)
                    }
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(width: 16)
                .foregroundStyle(.secondary)
                .tint(.secondary)

                Button("Dashboard") {
                    action(.dashboard)
                }
                .buttonStyle(.vibe(.secondary))
            }
        }
    }
}