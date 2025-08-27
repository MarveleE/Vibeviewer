import SwiftUI
import VibeviewerShareUI
import VibeviewerAppEnvironment
import VibeviewerModel

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    
    @State private var refreshFrequency: String = ""
    @State private var usageHistoryLimit: String = ""
    @State private var pauseOnScreenSleep: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.app(.satoshiBold, size: 18))
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Refresh Frequency (minutes)")
                        .font(.app(.satoshiMedium, size: 12))
                    
                    TextField("5", text: $refreshFrequency)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Usage History Limit")
                        .font(.app(.satoshiMedium, size: 12))
                    
                    TextField("10", text: $usageHistoryLimit)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                
                Toggle("Pause refresh when screen sleeps", isOn: $pauseOnScreenSleep)
                    .font(.app(.satoshiMedium, size: 12))
            }
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.vibe(Color(hex: "F58283").opacity(0.8)))
                
                Button("Save") {
                    saveSettings()
                    dismiss()
                }
                .buttonStyle(.vibe(Color(hex: "5B67E2").opacity(0.8)))
            }
        }
        .padding(20)
        .frame(width: 320, height: 240)
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        refreshFrequency = String(appSettings.overview.refreshInterval)
        usageHistoryLimit = String(appSettings.usageHistory.limit)
        pauseOnScreenSleep = appSettings.pauseOnScreenSleep
    }
    
    private func saveSettings() {
        if let refreshValue = Int(refreshFrequency) {
            appSettings.overview.refreshInterval = refreshValue
        }
        
        if let limitValue = Int(usageHistoryLimit) {
            appSettings.usageHistory.limit = limitValue
        }
        
        appSettings.pauseOnScreenSleep = pauseOnScreenSleep
    }
}