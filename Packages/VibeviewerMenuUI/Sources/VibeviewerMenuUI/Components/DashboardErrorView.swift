import SwiftUI
import VibeviewerShareUI

@MainActor
struct DashboardErrorView: View {
    let message: String
    let onRetry: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.red.opacity(0.9))
                Text("Failed to Refresh Data")
                    .font(.app(.satoshiBold, size: 12))
            }
            
            Text(message)
                .font(.app(.satoshiMedium, size: 11))
                .foregroundStyle(.secondary)
            
            if let onRetry {
                Button {
                    onRetry()
                } label: {
                    Text("Retry")
                }
                .buttonStyle(.vibe(.primary))
                .controlSize(.small)
            }
        }
        .padding(10)
        .maxFrame(true, false, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.25), lineWidth: 1)
        )
    }
}


