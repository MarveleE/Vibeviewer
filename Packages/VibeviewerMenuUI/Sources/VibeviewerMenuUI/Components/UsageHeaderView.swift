import SwiftUI
import Observation
import VibeviewerModel
import VibeviewerShareUI

struct UsageHeaderView: View {
    enum Action {
        case dashboard
    }

    var action: (Action) -> Void

    @Environment(AppSession.self) private var session

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Usage")
                    .font(.app(.satoshiMedium, size: 16))
                    .foregroundStyle(.primary)
                Text("2min ago")
                    .font(.app(.satoshiRegular, size: 10))
                    .foregroundStyle(.tertiary)
            }
            Spacer()

            HStack(spacing: 12) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                Button("Dashboard") {
                    action(.dashboard)
                }
                .buttonStyle(.vibe(.secondary))
            }
        }
    }
}