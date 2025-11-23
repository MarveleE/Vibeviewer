import SwiftUI
import VibeviewerShareUI

@MainActor
struct UnloginView: View {
    enum LoginMethod: String, CaseIterable, Identifiable {
        case web
        case cookie
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .web:
                return "Web Login"
            case .cookie:
                return "Cookie Login"
            }
        }
        
        var description: String {
            switch self {
            case .web:
                return "Open Cursor login page and automatically capture your cookies after login."
            case .cookie:
                return "Paste your Cursor cookie header (from browser Developer Tools) to log in directly."
            }
        }
    }
    
    let onWebLogin: () -> Void
    let onCookieLogin: (String) -> Void
    
    @State private var selectedLoginMethod: LoginMethod = .web
    @State private var manualCookie: String = ""
    @State private var manualCookieError: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Login to Cursor")
                .font(.app(.satoshiBold, size: 16))
            
            Text("Choose a login method that works best for you.")
                .font(.app(.satoshiMedium, size: 11))
                .foregroundStyle(.secondary)
            
            Picker("Login Method", selection: $selectedLoginMethod) {
                ForEach(LoginMethod.allCases) { method in
                    Text(method.title).tag(method)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            
            Text(selectedLoginMethod.description)
                .font(.app(.satoshiMedium, size: 11))
                .foregroundStyle(.secondary)
            
            Group {
                switch selectedLoginMethod {
                case .web:
                    Button {
                        onWebLogin()
                    } label: {
                        Text("Login via Web")
                    }
                    .buttonStyle(.vibe(.primary))
                    
                case .cookie:
                    manualCookieLoginView
                }
            }
        }
        .maxFrame(true, false, alignment: .leading)
    }
    
    @ViewBuilder
    private var manualCookieLoginView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cursor Cookie Header")
                .font(.app(.satoshiMedium, size: 12))
            
            TextEditor(text: $manualCookie)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 80, maxHeight: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .overlay {
                    if manualCookie.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Example:\nCookie: cursor_session=...; other_key=...")
                            .foregroundStyle(Color.secondary.opacity(0.7))
                            .font(.app(.satoshiMedium, size: 10))
                            .padding(6)
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity,
                                alignment: .topLeading
                            )
                    }
                }
            
            if let error = manualCookieError {
                Text(error)
                    .font(.app(.satoshiMedium, size: 10))
                    .foregroundStyle(.red)
            }
            
            HStack {
                Spacer()
                Button("Login with Cookie") {
                    submitManualCookie()
                }
                .buttonStyle(.vibe(.primary))
                .disabled(normalizedCookieHeader(from: manualCookie).isEmpty)
            }
        }
    }
    
    private func submitManualCookie() {
        let normalized = normalizedCookieHeader(from: manualCookie)
        guard !normalized.isEmpty else {
            manualCookieError = "Cookie header cannot be empty."
            return
        }
        manualCookieError = nil
        onCookieLogin(normalized)
    }
    
    /// 归一化用户输入的 Cookie 字符串：
    /// - 去除首尾空白
    /// - 支持用户直接粘贴包含 `Cookie:` 或 `cookie:` 前缀的完整请求头
    private func normalizedCookieHeader(from input: String) -> String {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return "" }
        
        let lowercased = value.lowercased()
        if lowercased.hasPrefix("cookie:") {
            if let range = value.range(of: ":", options: .caseInsensitive) {
                let afterColon = value[range.upperBound...]
                value = String(afterColon).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return value
    }
}


