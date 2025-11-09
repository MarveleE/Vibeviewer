import SwiftUI
import Observation
import VibeviewerModel
import VibeviewerShareUI

struct UsageHeaderView: View {
    enum Action {
        case dashboard
    }

    var action: (Action) -> Void

    var body: some View {
        HStack {
            Text("VibeViewer")
                .font(.app(.satoshiMedium, size: 16))
                .foregroundStyle(.primary)
            Spacer()

            Button("Dashboard") {
                action(.dashboard)
            }
            .buttonStyle(.vibe(.secondary))
        }
    }
}