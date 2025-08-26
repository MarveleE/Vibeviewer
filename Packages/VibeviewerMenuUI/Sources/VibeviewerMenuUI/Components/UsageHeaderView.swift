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

    @State var isShowLogout: Bool = false

    @State var isHovering: Bool = false

    var body: some View {
        HStack {
            Text("VibeViewer")
                .font(.app(.satoshiMedium, size: 16))
                .foregroundStyle(.primary)
            Spacer()

            HStack(spacing: 12) {
                Group {
                    if isShowLogout {
                        Button("Log out") { 
                            action(.logout)
                        }
                        .buttonStyle(.vibe(Color(hex: "FF4D4D")))
                        .transition(.blurReplace)
                    } else {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowLogout.toggle()
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .padding(.vertical, 4)
                                .contentShape(.rect)
                        }
                        .foregroundStyle(.secondary)
                        .buttonStyle(.plain)
                        .transition(.blurReplace)
                    }
                }
                .opacity(session.credentials != nil ? 1 : 0)

                Button("Dashboard") {
                    action(.dashboard)
                }
                .buttonStyle(.vibe(.secondary))
            }
        }
        .onHover { isHovering = $0 }
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onChange(of: isHovering) { _, isHovering in
            if !isHovering {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isShowLogout = false
                }
            }
        }
    }
}