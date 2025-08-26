import SwiftUI
import VibeviewerShareUI
import VibeviewerAppEnvironment
import VibeviewerModel

struct MenuFooterView: View {
    let email: String
    @Environment(\.dashboardRefreshService) private var refresher
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(email)
                .font(.app(.satoshiRegular, size: 10))
                .foregroundStyle(.secondary)
            
            Spacer()

            Button {
                Task {  
                    await refresher.refreshNow()
                }
            } label: {
                HStack(spacing: 4) {
                    if refresher.isRefreshing {
                        ProgressView()
                            .controlSize(.mini)
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .frame(width: 16, height: 16)
                    } 
                    Text("Refresh")
                            .font(.app(.satoshiMedium, size: 12))
                }
            }
            .buttonStyle(.vibe(Color(hex: "5B67E2").opacity(0.8)))
            .animation(.easeInOut(duration: 0.2), value: refresher.isRefreshing) 

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit")
                    .font(.app(.satoshiMedium, size: 12))
            }
            .buttonStyle(.vibe(Color(hex: "F58283").opacity(0.8)))
        }
    }
}
