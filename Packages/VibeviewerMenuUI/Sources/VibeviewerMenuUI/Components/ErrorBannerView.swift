import SwiftUI

@MainActor
struct ErrorBannerView: View {
    let message: String?

    var body: some View {
        if let msg = message, !msg.isEmpty {
            Text(msg)
                .foregroundStyle(.red)
                .font(.caption)
        }
    }
}
